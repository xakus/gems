import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../constants/config.dart';
import '../utils/password_hasher.dart';
import '../utils/temp_password_generator.dart';

/// Синглтон для работы с SQLite.
/// Инициализирует схему и создаёт дефолтного ADMIN при первом запуске.
class DatabaseHelper {
  DatabaseHelper._();
  static final DatabaseHelper instance = DatabaseHelper._();

  Database? _db;

  Future<Database> get database async {
    _db ??= await _init();
    return _db!;
  }

  Future<Database> _init() async {
    // Инициализация FFI для desktop
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    final supportDir = await getApplicationSupportDirectory();
    final dbPath = p.join(supportDir.path, kDatabaseFileName);

    return openDatabase(
      dbPath,
      version: kDatabaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  /// Создание схемы при первом запуске
  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE users (
        id                   INTEGER PRIMARY KEY AUTOINCREMENT,
        first_name           TEXT    NOT NULL,
        last_name            TEXT    NOT NULL,
        username             TEXT    UNIQUE NOT NULL,
        password_hash        TEXT    NOT NULL,
        password_salt        TEXT    NOT NULL,
        role                 TEXT    NOT NULL CHECK(role IN ('USER','ADMIN')),
        is_active            INTEGER NOT NULL DEFAULT 1,
        must_change_password INTEGER NOT NULL DEFAULT 1,
        is_deleted           INTEGER NOT NULL DEFAULT 0,
        deleted_at           TEXT,
        created_at           TEXT    NOT NULL,
        updated_at           TEXT    NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE settings (
        user_id  INTEGER PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
        theme    TEXT NOT NULL DEFAULT 'light',
        language TEXT NOT NULL DEFAULT 'en'
      )
    ''');

    await db.execute('''
      CREATE TABLE app_meta (
        key   TEXT PRIMARY KEY,
        value TEXT
      )
    ''');

    await _createAuditLogTable(db);

    await db.insert('app_meta', {'key': kMetaDbVersion, 'value': '$version'});
    await db.insert('app_meta', {'key': kMetaFirstRun, 'value': 'true'});

    await _seedAdmin(db);
  }

  /// Создаёт таблицу журнала аудита
  Future<void> _createAuditLogTable(Database db) async {
    await db.execute('''
      CREATE TABLE audit_log (
        id                INTEGER PRIMARY KEY AUTOINCREMENT,
        action            TEXT NOT NULL,
        performed_by_id   INTEGER NOT NULL,
        performed_by_name TEXT NOT NULL,
        target_user_id    INTEGER NOT NULL,
        target_user_name  TEXT NOT NULL,
        changes           TEXT,
        created_at        TEXT NOT NULL
      )
    ''');
  }

  /// Миграции при обновлении схемы
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // v1 → v2: мягкое удаление + журнал аудита
    if (oldVersion < 2) {
      await db.execute(
        'ALTER TABLE users ADD COLUMN is_deleted INTEGER NOT NULL DEFAULT 0',
      );
      await db.execute('ALTER TABLE users ADD COLUMN deleted_at TEXT');
      await _createAuditLogTable(db);
    }

    await db.insert(
      'app_meta',
      {'key': kMetaDbVersion, 'value': '$newVersion'},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Создаёт дефолтного ADMIN с временным паролем
  Future<String> _seedAdmin(Database db) async {
    final tempPassword = kDefaultAdminUsername;
    final salt = PasswordHasher.generateSalt();
    final hash = PasswordHasher.hash(tempPassword, salt);
    final now = DateTime.now().toIso8601String();

    final adminId = await db.insert('users', {
      'first_name': 'Admin',
      'last_name': 'AMOTES',
      'username': kDefaultAdminUsername,
      'password_hash': hash,
      'password_salt': salt,
      'role': kRoleAdmin,
      'is_active': 1,
      'must_change_password': 1,
      'created_at': now,
      'updated_at': now,
    });

    await db.insert('settings', {
      'user_id': adminId,
      'theme': kDefaultTheme,
      'language': kDefaultLocale,
    });

    // Сохраняем временный пароль в app_meta для показа пользователю
    await db.insert('app_meta', {
      'key': 'admin_temp_password',
      'value': tempPassword,
    });

    return tempPassword;
  }

  /// Возвращает временный пароль ADMIN (null если уже показан/удалён)
  Future<String?> getAdminTempPassword() async {
    final db = await database;
    final rows = await db.query(
      'app_meta',
      where: 'key = ?',
      whereArgs: ['admin_temp_password'],
    );
    return rows.isNotEmpty ? rows.first['value'] as String? : null;
  }

  /// Удаляет временный пароль из meta после показа
  Future<void> clearAdminTempPassword() async {
    final db = await database;
    await db.delete('app_meta', where: 'key = ?', whereArgs: ['admin_temp_password']);
  }

  /// Возвращает значение из app_meta
  Future<String?> getMeta(String key) async {
    final db = await database;
    final rows = await db.query('app_meta', where: 'key = ?', whereArgs: [key]);
    return rows.isNotEmpty ? rows.first['value'] as String? : null;
  }

  /// Устанавливает значение в app_meta
  Future<void> setMeta(String key, String value) async {
    final db = await database;
    await db.insert(
      'app_meta',
      {'key': key, 'value': value},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
}

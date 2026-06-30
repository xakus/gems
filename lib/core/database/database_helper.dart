import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../constants/config.dart';
import '../utils/password_hasher.dart';

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
    await _createCompressorTemplatesTable(db);
    await _createTestTables(db);

    await db.insert('app_meta', {'key': kMetaDbVersion, 'value': '$version'});
    await db.insert('app_meta', {'key': kMetaFirstRun, 'value': 'true'});

    await _seedAdmin(db);
  }

  /// Создаёт таблицу шаблонов настроек компрессора
  Future<void> _createCompressorTemplatesTable(Database db) async {
    await db.execute('''
      CREATE TABLE compressor_templates (
        id                 INTEGER PRIMARY KEY AUTOINCREMENT,
        name               TEXT    NOT NULL,
        compressor_name    TEXT    NOT NULL,
        power_kwt          REAL    NOT NULL,
        voltage_v          REAL    NOT NULL,
        current_a          REAL    NOT NULL,
        speed_rpm          REAL    NOT NULL,
        frequency_hz       REAL    NOT NULL,
        productivity_l_min REAL    NOT NULL,
        pressure_bar       REAL    NOT NULL,
        hold_time_min      REAL    NOT NULL DEFAULT 0,
        receiver_volume_l  REAL    NOT NULL,
        created_at         TEXT    NOT NULL,
        updated_at         TEXT    NOT NULL
      )
    ''');
  }

  /// Создаёт таблицы модуля тестирования двигателей:
  /// test_runs — метаданные запусков, test_measurements — тайм-серия измерений,
  /// test_events — журнал событий теста (для архива и отчётов).
  Future<void> _createTestTables(Database db) async {
    // Запуски тестов: один ряд = один проведённый тест
    await db.execute('''
      CREATE TABLE test_runs (
        id                 INTEGER PRIMARY KEY AUTOINCREMENT,
        stand_id           INTEGER NOT NULL,
        test_mode          TEXT    NOT NULL,
        power_kwt          REAL    NOT NULL,
        voltage_v          REAL    NOT NULL,
        current_a          REAL    NOT NULL,
        speed_rpm          REAL    NOT NULL,
        frequency_hz       REAL    NOT NULL,
        status             TEXT    NOT NULL,
        error_code         TEXT,
        insulation_mohm    REAL,
        winding_resistance REAL,
        started_by_id      INTEGER NOT NULL,
        started_by_name    TEXT    NOT NULL,
        started_at         TEXT    NOT NULL,
        finished_at        TEXT
      )
    ''');

    // Измерения (тайм-серия) — для графиков и отчётов.
    // phase: 1/2/3 для трёхфазных метрик (напряжение, ток), 0 — однофазные.
    await db.execute('''
      CREATE TABLE test_measurements (
        id          INTEGER PRIMARY KEY AUTOINCREMENT,
        run_id      INTEGER NOT NULL REFERENCES test_runs(id) ON DELETE CASCADE,
        metric      TEXT    NOT NULL,
        phase       INTEGER NOT NULL DEFAULT 0,
        value       REAL    NOT NULL,
        unit        TEXT    NOT NULL,
        recorded_at TEXT    NOT NULL
      )
    ''');
    await db.execute(
      'CREATE INDEX idx_measurements_run_metric '
      'ON test_measurements(run_id, metric)',
    );

    // Журнал событий теста (старт, успех фазы 1, ошибка, экстренный стоп, финиш)
    await db.execute('''
      CREATE TABLE test_events (
        id         INTEGER PRIMARY KEY AUTOINCREMENT,
        run_id     INTEGER NOT NULL REFERENCES test_runs(id) ON DELETE CASCADE,
        event_type TEXT    NOT NULL,
        message    TEXT,
        created_at TEXT    NOT NULL
      )
    ''');
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

    // v2 → v3: таблица шаблонов компрессора
    if (oldVersion < 3) {
      await _createCompressorTemplatesTable(db);
    }

    // v3 → v4: таблицы модуля тестирования двигателей
    if (oldVersion < 4) {
      await _createTestTables(db);
    }

    // v4 → v5: фаза измерения (трёхфазные напряжение/ток)
    if (oldVersion < 5) {
      await db.execute(
        'ALTER TABLE test_measurements ADD COLUMN phase INTEGER NOT NULL DEFAULT 0',
      );
    }

    await db.insert('app_meta', {
      'key': kMetaDbVersion,
      'value': '$newVersion',
    }, conflictAlgorithm: ConflictAlgorithm.replace);
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
    await db.delete(
      'app_meta',
      where: 'key = ?',
      whereArgs: ['admin_temp_password'],
    );
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
    await db.insert('app_meta', {
      'key': key,
      'value': value,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }
}

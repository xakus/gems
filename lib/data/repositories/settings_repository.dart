import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../../core/database/database_helper.dart';
import '../models/user_settings.dart';

/// Репозиторий настроек пользователя
class SettingsRepository {
  final DatabaseHelper _db = DatabaseHelper.instance;

  /// Возвращает настройки пользователя. Создаёт запись если нет.
  Future<UserSettings> getByUserId(int userId) async {
    final db = await _db.database;
    final rows = await db.query(
      'settings',
      where: 'user_id = ?',
      whereArgs: [userId],
    );
    if (rows.isNotEmpty) return UserSettings.fromMap(rows.first);

    // Создаём дефолтные настройки
    final defaults = UserSettings(userId: userId);
    await db.insert('settings', defaults.toMap());
    return defaults;
  }

  /// Обновляет настройки
  Future<void> update(UserSettings settings) async {
    final db = await _db.database;
    await db.insert(
      'settings',
      settings.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Обновляет тему
  Future<void> updateTheme(int userId, String theme) async {
    final db = await _db.database;
    await db.update(
      'settings',
      {'theme': theme},
      where: 'user_id = ?',
      whereArgs: [userId],
    );
  }

  /// Обновляет язык
  Future<void> updateLanguage(int userId, String language) async {
    final db = await _db.database;
    await db.update(
      'settings',
      {'language': language},
      where: 'user_id = ?',
      whereArgs: [userId],
    );
  }
}

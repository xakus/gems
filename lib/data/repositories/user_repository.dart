import '../../core/constants/config.dart';
import '../../core/database/database_helper.dart';
import '../models/user.dart';

/// Репозиторий для работы с таблицей users.
/// Проверки ролей выполняются здесь, не в UI.
class UserRepository {
  final DatabaseHelper _db = DatabaseHelper.instance;

  /// Возвращает пользователя по логину (или null)
  Future<User?> findByUsername(String username) async {
    final db = await _db.database;
    final rows = await db.query('users', where: 'username = ?', whereArgs: [username]);
    return rows.isNotEmpty ? User.fromMap(rows.first) : null;
  }

  /// Возвращает пользователя по ID (или null)
  Future<User?> findById(int id) async {
    final db = await _db.database;
    final rows = await db.query('users', where: 'id = ?', whereArgs: [id]);
    return rows.isNotEmpty ? User.fromMap(rows.first) : null;
  }

  /// Возвращает всех пользователей
  Future<List<User>> getAll() async {
    final db = await _db.database;
    final rows = await db.query('users', orderBy: 'created_at ASC');
    return rows.map(User.fromMap).toList();
  }

  /// Создаёт нового пользователя. Только для ADMIN.
  Future<User> create(User user, {required UserRole requesterRole}) async {
    if (requesterRole != UserRole.admin) {
      throw Exception('Недостаточно прав для создания пользователя');
    }
    final db = await _db.database;
    final id = await db.insert('users', user.toMap());
    return user.copyWith(id: id);
  }

  /// Обновляет хеш и соль пароля пользователя
  Future<void> updatePassword({
    required int userId,
    required String newHash,
    required String newSalt,
    required bool mustChangePassword,
  }) async {
    final db = await _db.database;
    await db.update(
      'users',
      {
        'password_hash': newHash,
        'password_salt': newSalt,
        'must_change_password': mustChangePassword ? 1 : 0,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [userId],
    );
  }

  /// Активирует / деактивирует пользователя. Только для ADMIN.
  Future<void> setActive({
    required int targetUserId,
    required bool isActive,
    required int requesterUserId,
    required UserRole requesterRole,
  }) async {
    if (requesterRole != UserRole.admin) {
      throw Exception('Недостаточно прав');
    }
    if (targetUserId == requesterUserId && !isActive) {
      throw Exception('Нельзя деактивировать самого себя');
    }
    if (!isActive) {
      await _guardLastAdmin(targetUserId);
    }
    final db = await _db.database;
    await db.update(
      'users',
      {'is_active': isActive ? 1 : 0, 'updated_at': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [targetUserId],
    );
  }

  /// Сбрасывает пароль пользователя на временный. Только для ADMIN.
  Future<String> resetPassword({
    required int targetUserId,
    required String newHash,
    required String newSalt,
    required String tempPassword,
    required UserRole requesterRole,
  }) async {
    if (requesterRole != UserRole.admin) {
      throw Exception('Недостаточно прав');
    }
    await updatePassword(
      userId: targetUserId,
      newHash: newHash,
      newSalt: newSalt,
      mustChangePassword: true,
    );
    return tempPassword;
  }

  /// Проверяет, что targetUserId — не последний активный ADMIN
  Future<void> _guardLastAdmin(int targetUserId) async {
    final db = await _db.database;
    final user = await findById(targetUserId);
    if (user?.role != UserRole.admin) return;

    final rows = await db.query(
      'users',
      where: "role = ? AND is_active = 1 AND id != ?",
      whereArgs: [kRoleAdmin, targetUserId],
    );
    if (rows.isEmpty) {
      throw Exception('Нельзя деактивировать последнего активного администратора');
    }
  }
}

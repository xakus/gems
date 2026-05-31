import 'dart:convert';

import '../../core/constants/config.dart';
import '../../core/database/database_helper.dart';
import '../models/audit_log.dart';
import '../models/user.dart';
import 'audit_repository.dart';

/// Репозиторий для работы с таблицей users.
/// Проверки ролей и запись аудита выполняются здесь, не в UI.
class UserRepository {
  final DatabaseHelper _db = DatabaseHelper.instance;
  final AuditRepository _audit = AuditRepository();

  /// Возвращает пользователя по логину (только активный и не удалённый)
  Future<User?> findByUsername(String username) async {
    final db = await _db.database;
    final rows = await db.query(
      'users',
      where: 'username = ? AND is_deleted = 0',
      whereArgs: [username],
    );
    return rows.isNotEmpty ? User.fromMap(rows.first) : null;
  }

  /// Возвращает пользователя по ID (включая удалённых — для внутренних нужд)
  Future<User?> findById(int id) async {
    final db = await _db.database;
    final rows = await db.query('users', where: 'id = ?', whereArgs: [id]);
    return rows.isNotEmpty ? User.fromMap(rows.first) : null;
  }

  /// Возвращает всех не удалённых пользователей
  Future<List<User>> getAll() async {
    final db = await _db.database;
    final rows = await db.query(
      'users',
      where: 'is_deleted = 0',
      orderBy: 'created_at ASC',
    );
    return rows.map(User.fromMap).toList();
  }

  /// Создаёт нового пользователя. Только для ADMIN. Пишет в аудит.
  Future<User> create(
    User user, {
    required int performerId,
    required String performerName,
    required UserRole requesterRole,
  }) async {
    if (requesterRole != UserRole.admin) {
      throw Exception('Недостаточно прав для создания пользователя');
    }
    final db = await _db.database;
    final id = await db.insert('users', user.toMap());
    final created = user.copyWith(id: id);

    await _audit.add(AuditLog(
      action: AuditAction.create,
      performedById: performerId,
      performedByName: performerName,
      targetUserId: id,
      targetUserName: created.fullName,
      changesJson: jsonEncode({
        'first_name': {'to': created.firstName},
        'last_name': {'to': created.lastName},
        'username': {'to': created.username},
        'role': {'to': created.role.toDbString()},
      }),
      createdAt: DateTime.now(),
    ));

    return created;
  }

  /// Обновляет данные пользователя (имя, фамилия, логин, роль). Только для ADMIN.
  Future<void> update({
    required User user,
    required int requesterUserId,
    required String requesterName,
    required UserRole requesterRole,
  }) async {
    if (requesterRole != UserRole.admin) {
      throw Exception('Недостаточно прав');
    }
    final existing = await findById(user.id!);
    if (existing == null) throw Exception('Пользователь не найден');

    // Защита последнего admin при понижении роли
    if (existing.role == UserRole.admin && user.role == UserRole.user) {
      await _guardLastAdmin(user.id!);
    }

    // Собираем только изменённые поля
    final changes = <String, Map<String, String>>{};
    if (existing.firstName != user.firstName) {
      changes['first_name'] = {'from': existing.firstName, 'to': user.firstName};
    }
    if (existing.lastName != user.lastName) {
      changes['last_name'] = {'from': existing.lastName, 'to': user.lastName};
    }
    if (existing.username != user.username) {
      changes['username'] = {'from': existing.username, 'to': user.username};
    }
    if (existing.role != user.role) {
      changes['role'] = {
        'from': existing.role.toDbString(),
        'to': user.role.toDbString(),
      };
    }

    final db = await _db.database;
    await db.update(
      'users',
      {
        'first_name': user.firstName,
        'last_name': user.lastName,
        'username': user.username,
        'role': user.role.toDbString(),
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [user.id],
    );

    if (changes.isNotEmpty) {
      await _audit.add(AuditLog(
        action: AuditAction.update,
        performedById: requesterUserId,
        performedByName: requesterName,
        targetUserId: user.id!,
        targetUserName: user.fullName,
        changesJson: jsonEncode(changes),
        createdAt: DateTime.now(),
      ));
    }
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
    required String requesterName,
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

    final target = await findById(targetUserId);
    final db = await _db.database;
    await db.update(
      'users',
      {
        'is_active': isActive ? 1 : 0,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [targetUserId],
    );

    await _audit.add(AuditLog(
      action: isActive ? AuditAction.activate : AuditAction.deactivate,
      performedById: requesterUserId,
      performedByName: requesterName,
      targetUserId: targetUserId,
      targetUserName: target?.fullName ?? '—',
      changesJson: jsonEncode({
        'is_active': {
          'from': isActive ? '0' : '1',
          'to': isActive ? '1' : '0',
        },
      }),
      createdAt: DateTime.now(),
    ));
  }

  /// Сбрасывает пароль пользователя на временный. Только для ADMIN.
  Future<String> resetPassword({
    required int targetUserId,
    required String newHash,
    required String newSalt,
    required String tempPassword,
    required int requesterUserId,
    required String requesterName,
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

    final target = await findById(targetUserId);
    await _audit.add(AuditLog(
      action: AuditAction.resetPassword,
      performedById: requesterUserId,
      performedByName: requesterName,
      targetUserId: targetUserId,
      targetUserName: target?.fullName ?? '—',
      changesJson: null,
      createdAt: DateTime.now(),
    ));

    return tempPassword;
  }

  /// Мягко удаляет пользователя (is_deleted = 1). Только для ADMIN.
  /// Данные остаются в БД и видны в истории аудита.
  Future<void> delete({
    required int targetUserId,
    required int requesterUserId,
    required String requesterName,
    required UserRole requesterRole,
  }) async {
    if (requesterRole != UserRole.admin) {
      throw Exception('Недостаточно прав');
    }
    if (targetUserId == requesterUserId) {
      throw Exception('Нельзя удалить собственный аккаунт');
    }
    await _guardLastAdmin(targetUserId);

    final target = await findById(targetUserId);
    final now = DateTime.now();

    final db = await _db.database;
    await db.update(
      'users',
      {
        'is_deleted': 1,
        'deleted_at': now.toIso8601String(),
        'is_active': 0,
        'updated_at': now.toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [targetUserId],
    );

    await _audit.add(AuditLog(
      action: AuditAction.delete,
      performedById: requesterUserId,
      performedByName: requesterName,
      targetUserId: targetUserId,
      targetUserName: target?.fullName ?? '—',
      changesJson: null,
      createdAt: now,
    ));
  }

  /// Проверяет, что targetUserId — не последний активный не удалённый ADMIN
  Future<void> _guardLastAdmin(int targetUserId) async {
    final db = await _db.database;
    final user = await findById(targetUserId);
    if (user?.role != UserRole.admin) return;

    final rows = await db.query(
      'users',
      where: 'role = ? AND is_active = 1 AND is_deleted = 0 AND id != ?',
      whereArgs: [kRoleAdmin, targetUserId],
    );
    if (rows.isEmpty) {
      throw Exception('Нельзя удалить/деактивировать последнего активного администратора');
    }
  }
}

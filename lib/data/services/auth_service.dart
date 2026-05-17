import '../../core/utils/password_hasher.dart';
import '../../core/utils/temp_password_generator.dart';
import '../models/session.dart';
import '../models/user.dart';
import '../repositories/user_repository.dart';
import '../repositories/settings_repository.dart';

/// Результат попытки входа
enum LoginResult {
  success,
  invalidCredentials,
  accountDisabled,
}

/// Сервис аутентификации. Вся логика входа/выхода — здесь.
class AuthService {
  final UserRepository _userRepo;
  final SettingsRepository _settingsRepo;

  AuthService({
    UserRepository? userRepo,
    SettingsRepository? settingsRepo,
  })  : _userRepo = userRepo ?? UserRepository(),
        _settingsRepo = settingsRepo ?? SettingsRepository();

  /// Пытается войти. Возвращает пару (результат, сессия или null).
  Future<({LoginResult result, Session? session})> login(
    String username,
    String password,
  ) async {
    final user = await _userRepo.findByUsername(username.trim());
    if (user == null) {
      return (result: LoginResult.invalidCredentials, session: null);
    }
    if (!user.isActive) {
      return (result: LoginResult.accountDisabled, session: null);
    }
    final valid = PasswordHasher.verify(password, user.passwordSalt, user.passwordHash);
    if (!valid) {
      return (result: LoginResult.invalidCredentials, session: null);
    }
    return (
      result: LoginResult.success,
      session: Session(user: user, loginAt: DateTime.now()),
    );
  }

  /// Меняет пароль текущего пользователя.
  Future<void> changePassword({
    required int userId,
    required String newPassword,
  }) async {
    final salt = PasswordHasher.generateSalt();
    final hash = PasswordHasher.hash(newPassword, salt);
    await _userRepo.updatePassword(
      userId: userId,
      newHash: hash,
      newSalt: salt,
      mustChangePassword: false,
    );
  }

  /// Создаёт нового пользователя с временным паролем.
  Future<({User user, String tempPassword})> createUser({
    required String firstName,
    required String lastName,
    required String username,
    required UserRole role,
    required UserRole requesterRole,
    String? tempPassword,
  }) async {
    final pass = tempPassword ?? TempPasswordGenerator.generate();
    final salt = PasswordHasher.generateSalt();
    final hash = PasswordHasher.hash(pass, salt);
    final now = DateTime.now();

    final user = User(
      firstName: firstName.trim(),
      lastName: lastName.trim(),
      username: username.trim().toLowerCase(),
      passwordHash: hash,
      passwordSalt: salt,
      role: role,
      isActive: true,
      mustChangePassword: true,
      createdAt: now,
      updatedAt: now,
    );

    final created = await _userRepo.create(user, requesterRole: requesterRole);
    await _settingsRepo.getByUserId(created.id!); // создаёт дефолтные настройки
    return (user: created, tempPassword: pass);
  }

  /// Сбрасывает пароль пользователя на новый временный.
  Future<String> resetUserPassword({
    required int targetUserId,
    required UserRole requesterRole,
  }) async {
    final tempPass = TempPasswordGenerator.generate();
    final salt = PasswordHasher.generateSalt();
    final hash = PasswordHasher.hash(tempPass, salt);

    await _userRepo.resetPassword(
      targetUserId: targetUserId,
      newHash: hash,
      newSalt: salt,
      tempPassword: tempPass,
      requesterRole: requesterRole,
    );
    return tempPass;
  }
}

import 'package:flutter/material.dart';
import '../../data/models/session.dart';
import '../../data/models/user.dart';
import '../../data/services/auth_service.dart';
import '../../data/repositories/user_repository.dart';

/// Провайдер аутентификации. Хранит текущую сессию в памяти.
class AuthProvider extends ChangeNotifier {
  final AuthService _authService;
  final UserRepository _userRepo;

  Session? _session;
  bool _loading = false;
  String? _error;

  AuthProvider({AuthService? authService, UserRepository? userRepo})
      : _authService = authService ?? AuthService(),
        _userRepo = userRepo ?? UserRepository();

  Session? get session => _session;
  bool get isAuthenticated => _session != null;
  bool get loading => _loading;
  String? get error => _error;

  User? get currentUser => _session?.user;
  bool get isAdmin => _session?.isAdmin ?? false;

  /// Обновляет текущего пользователя из БД (после смены пароля и т.п.)
  Future<void> refreshUser() async {
    if (_session == null) return;
    final updated = await _userRepo.findById(_session!.user.id!);
    if (updated != null) {
      _session = Session(user: updated, loginAt: _session!.loginAt);
      notifyListeners();
    }
  }

  /// Вход. Возвращает LoginResult.
  Future<LoginResult> login(String username, String password) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _authService.login(username, password);
      if (result.result == LoginResult.success) {
        _session = result.session;
      }
      return result.result;
    } catch (e) {
      _error = e.toString();
      return LoginResult.invalidCredentials;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// Смена пароля текущего пользователя
  Future<void> changePassword(String newPassword) async {
    if (_session == null) return;
    await _authService.changePassword(
      userId: _session!.user.id!,
      newPassword: newPassword,
    );
    await refreshUser();
  }

  /// Выход из системы
  void logout() {
    _session = null;
    _error = null;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}

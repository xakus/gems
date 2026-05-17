import 'user.dart';

/// Текущая сессия (хранится только в памяти, сбрасывается при закрытии)
class Session {
  final User user;
  final DateTime loginAt;

  const Session({required this.user, required this.loginAt});

  bool get isAdmin => user.role == UserRole.admin;
}

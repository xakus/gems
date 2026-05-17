import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants/config.dart';
import '../features/auth/change_password_screen.dart';
import '../features/auth/login_screen.dart';
import '../features/home/home_screen.dart';
import '../features/settings/settings_screen.dart';
import '../features/splash/splash_screen.dart';
import '../shared/providers/auth_provider.dart';

/// Генератор маршрутов с guard-ами доступа
Route<dynamic> generateRoute(RouteSettings settings) {
  final name = settings.name;

  // Публичные маршруты — доступны всегда
  switch (name) {
    case kRouteSplash:
      return _fade(const SplashScreen(), settings);
    case kRouteLogin:
      return _fade(const LoginScreen(), settings);
  }

  // Для защищённых маршрутов нужен guard — виджет-обёртка
  return _fade(_AuthGuard(routeName: name ?? kRouteLogin), settings);
}

/// Guard: проверяет авторизацию прямо в дереве виджетов
class _AuthGuard extends StatelessWidget {
  final String routeName;
  const _AuthGuard({required this.routeName});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    if (!auth.isAuthenticated) {
      // Редирект на логин (после первого кадра)
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacementNamed(context, kRouteLogin);
      });
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final user = auth.currentUser!;

    // Экран смены пароля — только если флаг выставлен
    if (routeName == kRouteChangePassword) {
      if (!user.mustChangePassword) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Navigator.pushReplacementNamed(context, kRouteHome);
        });
        return const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        );
      }
      return const ChangePasswordScreen();
    }

    // Если пользователь вошёл, но должен сменить пароль — форсируем
    if (user.mustChangePassword && routeName != kRouteChangePassword) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacementNamed(context, kRouteChangePassword);
      });
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return switch (routeName) {
      kRouteHome => const HomeScreen(),
      kRouteSettings => const SettingsScreen(),
      _ => const Scaffold(body: Center(child: Text('404 — страница не найдена'))),
    };
  }
}

PageRouteBuilder<dynamic> _fade(Widget page, RouteSettings settings) {
  return PageRouteBuilder(
    settings: settings,
    pageBuilder: (_, _, _) => page,
    transitionsBuilder: (_, animation, _, child) {
      return FadeTransition(
        opacity: CurvedAnimation(parent: animation, curve: Curves.easeInOut),
        child: child,
      );
    },
    transitionDuration: const Duration(milliseconds: 250),
  );
}

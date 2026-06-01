import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants/config.dart';
import '../features/auth/change_password_screen.dart';
import '../features/auth/login_screen.dart';
import '../features/home/home_screen.dart';
import '../features/settings/settings_screen.dart';
import '../features/splash/splash_screen.dart';
import '../features/stands/stand_1_screen.dart';
import '../features/stands/stand_2_screen.dart';
import '../features/stands/stand_3_screen.dart';
import '../features/stands/stand_4_screen.dart';
import '../features/stands/stand_5_screen.dart';
import '../features/stands/stand_test_screen.dart';
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
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final navigator = Navigator.of(context);
        // Получаем имя текущего верхнего маршрута через navigator
        navigator.popUntil((route) {
          if (route.settings.name == kRouteLogin) return true;
          if (route.settings.name != null &&
              route.settings.name != kRouteLogin) {
            navigator.pushReplacementNamed(kRouteLogin);
          }
          return true;
        });
      });
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final user = auth.currentUser!;

    // Экран смены пароля — только если флаг выставлен
    if (routeName == kRouteChangePassword) {
      if (!user.mustChangePassword) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Navigator.pushReplacementNamed(context, kRouteHome);
        });
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      }
      return const ChangePasswordScreen();
    }

    // Если пользователь вошёл, но должен сменить пароль — форсируем
    if (user.mustChangePassword && routeName != kRouteChangePassword) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacementNamed(context, kRouteChangePassword);
      });
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return switch (routeName) {
      kRouteHome => const HomeScreen(),
      kRouteSettings => const SettingsScreen(),
      kRouteStand1 => const Stand1Screen(),
      kRouteStand2 => const Stand2Screen(),
      kRouteStand3 => const Stand3Screen(),
      kRouteStand4 => const Stand4Screen(),
      kRouteStand5 => const Stand5Screen(),
      kRouteStand1Loaded   => const StandTestScreen(standTitleKey: 'stand_1_title', testTypeKey: 'stand_test_loaded'),
      kRouteStand1Unloaded => const StandTestScreen(standTitleKey: 'stand_1_title', testTypeKey: 'stand_test_unloaded'),
      kRouteStand2Loaded   => const StandTestScreen(standTitleKey: 'stand_2_title', testTypeKey: 'stand_test_loaded'),
      kRouteStand2Unloaded => const StandTestScreen(standTitleKey: 'stand_2_title', testTypeKey: 'stand_test_unloaded'),
      kRouteStand3Loaded   => const StandTestScreen(standTitleKey: 'stand_3_title', testTypeKey: 'stand_test_loaded'),
      kRouteStand3Unloaded => const StandTestScreen(standTitleKey: 'stand_3_title', testTypeKey: 'stand_test_unloaded'),
      _ => const Scaffold(
        body: Center(child: Text('404 — страница не найдена')),
      ),
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

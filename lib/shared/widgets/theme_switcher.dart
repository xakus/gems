import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../providers/theme_provider.dart';

/// Кнопка-иконка переключения светлой/тёмной темы
class ThemeSwitcher extends StatelessWidget {
  const ThemeSwitcher({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDark;
    return IconButton(
      tooltip: isDark ? 'Светлая тема' : 'Тёмная тема',
      icon: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        transitionBuilder: (child, animation) => RotationTransition(
          turns: animation,
          child: FadeTransition(opacity: animation, child: child),
        ),
        child: Icon(
          isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
          key: ValueKey(isDark),
          color: isDark ? AppColors.accent : AppColors.primary,
        ),
      ),
      onPressed: () => context.read<ThemeProvider>().toggle(),
    );
  }
}

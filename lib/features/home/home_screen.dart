import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/providers/theme_provider.dart';
import '../../shared/widgets/app_header.dart';

/// Главный экран — центр пока заглушка
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppHeader(),
      body: const _HomeBody(),
    );
  }
}

class _HomeBody extends StatelessWidget {
  const _HomeBody();

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDark;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Иконка модуля
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primary.withValues(alpha: 0.1),
                  AppColors.accent.withValues(alpha: 0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.2),
                width: 1.5,
              ),
            ),
            child: const Icon(
              Icons.electric_bolt_rounded,
              size: 48,
              color: AppColors.primary,
            ),
          )
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .shimmer(
                duration: 2500.ms,
                color: AppColors.accent.withValues(alpha: 0.3),
              ),

          const SizedBox(height: 24),

          Text(
            AppLocalizations.of(context).tr('home_placeholder'),
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: isDark
                      ? AppColors.darkSecondaryText
                      : AppColors.lightSecondaryText,
                ),
          ).animate().fadeIn(delay: 200.ms),

          const SizedBox(height: 8),

          Text(
            AppLocalizations.of(context).tr('home_placeholder_sub'),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: (isDark
                          ? AppColors.darkSecondaryText
                          : AppColors.lightSecondaryText)
                      .withValues(alpha: 0.7),
                ),
          ).animate().fadeIn(delay: 300.ms),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/theme/app_colors.dart';

/// Общая заглушка для всех экранов стендов
class StandPlaceholder extends StatelessWidget {
  final String image;
  final String titleKey;
  final String subtitleKey;

  const StandPlaceholder({
    super.key,
    required this.image,
    required this.titleKey,
    required this.subtitleKey,
  });

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(
            image,
            width: 160,
            height: 160,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) => Icon(
              Icons.electric_bolt_rounded,
              size: 72,
              color: AppColors.primary,
            ),
          ).animate().fadeIn(duration: 400.ms).scale(begin: const Offset(0.85, 0.85)),

          const SizedBox(height: 24),

          Text(
            loc.tr(titleKey),
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
          ).animate().fadeIn(delay: 150.ms),

          const SizedBox(height: 8),

          Text(
            loc.tr(subtitleKey),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                ),
          ).animate().fadeIn(delay: 200.ms),

          const SizedBox(height: 32),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
            ),
            child: Text(
              loc.tr('stand_coming_soon'),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.primary,
                  ),
            ),
          ).animate().fadeIn(delay: 300.ms),
        ],
      ),
    );
  }
}

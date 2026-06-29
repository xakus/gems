import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../core/constants/config.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';

/// Карточка фазы 1 (омметры) — показывается по центру экрана.
/// Живые показания мегаомметра (изоляция) и микроомметра (обмотки).
class OmmeterPhaseCard extends StatelessWidget {
  final double? insulationMohm;
  final double? windingResistance;

  const OmmeterPhaseCard({
    super.key,
    required this.insulationMohm,
    required this.windingResistance,
  });

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = AppColors.primary;

    return Container(
          width: 460,
          padding: const EdgeInsets.all(kPaddingLarge * 1.5),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
            borderRadius: BorderRadius.circular(kCardRadius + 4),
            border: Border.all(color: primary.withValues(alpha: 0.18)),
            boxShadow: [
              BoxShadow(
                color: primary.withValues(alpha: 0.12),
                blurRadius: 40,
                offset: const Offset(0, 14),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Заголовок фазы + индикатор процесса
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      color: primary,
                    ),
                  ),
                  const SizedBox(width: kPadding),
                  Text(
                    loc.tr('test_phase1_title'),
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: kPaddingLarge),

              _Reading(
                label: loc.tr('metric_insulation'),
                value: insulationMohm,
                unit: loc.tr('unit_mohm'),
              ),
              const SizedBox(height: kPadding),
              _Reading(
                label: loc.tr('metric_winding'),
                value: windingResistance,
                unit: loc.tr('unit_ohm'),
              ),
            ],
          ),
        )
        .animate()
        .fadeIn(duration: 350.ms)
        .scale(
          begin: const Offset(0.7, 0.7),
          end: const Offset(1.0, 1.0),
          duration: 420.ms,
          curve: Curves.easeOutBack,
        );
  }
}

/// Строка одного показания омметра (мигает «…», пока значение не пришло)
class _Reading extends StatelessWidget {
  final String label;
  final double? value;
  final String unit;

  const _Reading({
    required this.label,
    required this.value,
    required this.unit,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ready = value != null;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: isDark
                ? AppColors.darkSecondaryText
                : AppColors.lightSecondaryText,
          ),
        ),
        Text(
          ready ? '${value!.toStringAsFixed(2)}  $unit' : '…',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
      ],
    );
  }
}

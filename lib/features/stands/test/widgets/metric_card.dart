import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../core/constants/config.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';

/// Карточка рабочего показателя (фаза 2): заголовок, текущее значение с единицей
/// и live-график. Появляется с анимацией «от маленького к большому».
class MetricCard extends StatelessWidget {
  final String titleKey;
  final String unitKey;
  final double value;
  final List<double> series;
  final Color accent;

  const MetricCard({
    super.key,
    required this.titleKey,
    required this.unitKey,
    required this.value,
    required this.series,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
          width: 280,
          padding: const EdgeInsets.all(kPaddingLarge),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
            borderRadius: BorderRadius.circular(kCardRadius),
            border: Border.all(color: accent.withValues(alpha: 0.25)),
            boxShadow: [
              BoxShadow(
                color: accent.withValues(alpha: 0.10),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Заголовок метрики
              Text(
                loc.tr(titleKey),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: isDark
                      ? AppColors.darkSecondaryText
                      : AppColors.lightSecondaryText,
                ),
              ),
              const SizedBox(height: kPaddingSmall),

              // Текущее значение + единица
              RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: value.toStringAsFixed(1),
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: accent,
                          ),
                    ),
                    TextSpan(
                      text: '  ${loc.tr(unitKey)}',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: accent.withValues(alpha: 0.7),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: kPadding),

              // Live-график
              SizedBox(
                height: 70,
                child: _Chart(series: series, accent: accent),
              ),
            ],
          ),
        )
        .animate()
        .fadeIn(duration: 350.ms)
        .scale(
          begin: const Offset(0.6, 0.6),
          end: const Offset(1.0, 1.0),
          duration: 400.ms,
          curve: Curves.easeOutBack,
        );
  }
}

/// Мини-график линии по истории значений метрики
class _Chart extends StatelessWidget {
  final List<double> series;
  final Color accent;

  const _Chart({required this.series, required this.accent});

  @override
  Widget build(BuildContext context) {
    if (series.length < 2) {
      return const SizedBox.shrink();
    }

    final spots = <FlSpot>[
      for (var i = 0; i < series.length; i++) FlSpot(i.toDouble(), series[i]),
    ];

    return LineChart(
      LineChartData(
        gridData: const FlGridData(show: false),
        titlesData: const FlTitlesData(show: false),
        borderData: FlBorderData(show: false),
        lineTouchData: const LineTouchData(enabled: false),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            barWidth: 2.5,
            color: accent,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  accent.withValues(alpha: 0.25),
                  accent.withValues(alpha: 0.0),
                ],
              ),
            ),
          ),
        ],
      ),
      duration: const Duration(milliseconds: 250),
    );
  }
}

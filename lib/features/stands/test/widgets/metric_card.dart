import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../core/constants/config.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';

/// Цвета фаз U/V/W (для трёхфазных метрик)
const List<Color> kPhaseColors = [
  AppColors.primary,
  AppColors.accent,
  AppColors.warning,
];

/// Карточка рабочего показателя (фаза 2): заголовок, заданный номинал,
/// текущее значение (одно или по 3 фазам) и live-график.
/// Появляется с анимацией «от маленького к большому». Растягивается под ячейку.
///
/// [hover] — общий индекс наведения (синхронный crosshair по всем карточкам,
/// как в Grafana): при наведении на любой график линия и значения показываются
/// сразу во всех карточках на той же позиции по времени.
class MetricCard extends StatelessWidget {
  final String titleKey;
  final String unitKey;
  final bool isThreePhase;

  /// История значений по фазам: {1,2,3} для трёхфазных, {0} — для однофазных
  final Map<int, List<double>> series;

  /// Текущие значения по фазам
  final Map<int, double> current;

  /// Заданный номинал (горизонтальная линия), null — без линии (нагрев)
  final double? target;

  /// Базовый цвет для однофазной метрики
  final Color accent;

  /// Общий индекс наведения (по шкале 0..kChartWindowPoints-1) или null
  final ValueNotifier<int?> hover;

  const MetricCard({
    super.key,
    required this.titleKey,
    required this.unitKey,
    required this.isThreePhase,
    required this.series,
    required this.current,
    required this.target,
    required this.accent,
    required this.hover,
  });

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final unit = loc.tr(unitKey);

    return Container(
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
            children: [
              // Заголовок + заданный номинал
              Row(
                children: [
                  Expanded(
                    child: Text(
                      loc.tr(titleKey),
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: isDark
                            ? AppColors.darkOnBackground
                            : AppColors.lightOnBackground,
                      ),
                    ),
                  ),
                  if (target != null) _NominalBadge(target: target!, unit: unit),
                ],
              ),
              const SizedBox(height: kPadding),

              // Текущие значения (или значения под курсором при наведении)
              ValueListenableBuilder<int?>(
                valueListenable: hover,
                builder: (context, hoverX, _) {
                  final values = _valuesAt(hoverX);
                  if (isThreePhase) {
                    return _PhaseValues(values: values, unit: unit);
                  }
                  return _SingleValue(
                    value: values[0],
                    unit: unit,
                    accent: accent,
                  );
                },
              ),

              const SizedBox(height: kPadding),

              // Live-график заполняет остаток высоты карточки
              Expanded(
                child: _Chart(
                  series: series,
                  target: target,
                  isThreePhase: isThreePhase,
                  accent: accent,
                  hover: hover,
                ),
              ),
            ],
          ),
        )
        .animate()
        .fadeIn(duration: 450.ms, curve: Curves.easeOut)
        .scale(
          begin: const Offset(0.8, 0.8),
          end: const Offset(1.0, 1.0),
          duration: 500.ms,
          curve: Curves.easeOutCubic,
        );
  }

  /// Значения по фазам в точке наведения (или текущие, если наведения нет).
  /// Возвращает {phase: value}.
  Map<int, double> _valuesAt(int? hoverX) {
    if (hoverX == null) return current;
    final result = <int, double>{};
    series.forEach((phase, values) {
      final i = _indexAt(hoverX, values.length);
      if (i != null) result[phase] = values[i];
    });
    // Если в точке нет данных — показываем текущие, чтобы не было пусто
    return result.isEmpty ? current : result;
  }

  /// Индекс точки в окне [len] для общей X-координаты [hoverX]
  /// (данные выровнены по правому краю шкалы kChartWindowPoints).
  static int? _indexAt(int hoverX, int len) {
    if (len == 0) return null;
    final window = len > kChartWindowPoints ? kChartWindowPoints : len;
    final i = window - 1 - ((kChartWindowPoints - 1) - hoverX);
    if (i < 0 || i >= window) return null;
    return len - window + i; // абсолютный индекс в исходном списке
  }
}

/// Бейдж «задано: X ед.»
class _NominalBadge extends StatelessWidget {
  final double target;
  final String unit;

  const _NominalBadge({required this.target, required this.unit});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.info.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.info.withValues(alpha: 0.30)),
      ),
      child: Text(
        '${loc.tr('test_nominal_label')}: ${_fmt(target)} $unit',
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          color: AppColors.info,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

/// Одно крупное значение (однофазные метрики)
class _SingleValue extends StatelessWidget {
  final double? value;
  final String unit;
  final Color accent;

  const _SingleValue({
    required this.value,
    required this.unit,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerLeft,
      child: RichText(
        text: TextSpan(
          children: [
            TextSpan(
              text: value != null ? _fmt(value!) : '—',
              style: Theme.of(context).textTheme.displaySmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: accent,
              ),
            ),
            TextSpan(
              text: '  $unit',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: accent.withValues(alpha: 0.7),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Три значения по фазам U/V/W
class _PhaseValues extends StatelessWidget {
  final Map<int, double> values;
  final String unit;

  const _PhaseValues({required this.values, required this.unit});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var ph = 1; ph <= kMotorPhaseCount; ph++) ...[
          Expanded(
            child: _PhaseChip(
              label: kPhaseLabels[ph - 1],
              value: values[ph],
              unit: unit,
              color: kPhaseColors[ph - 1],
            ),
          ),
          if (ph < kMotorPhaseCount) const SizedBox(width: kPaddingSmall),
        ],
      ],
    );
  }
}

class _PhaseChip extends StatelessWidget {
  final String label;
  final double? value;
  final String unit;
  final Color color;

  const _PhaseChip({
    required this.label,
    required this.value,
    required this.unit,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value != null ? _fmt(value!) : '—',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// График: одна или несколько линий (по фазам), горизонтальная линия номинала
/// и синхронный вертикальный crosshair (общий [hover] на все карточки).
class _Chart extends StatelessWidget {
  final Map<int, List<double>> series;
  final double? target;
  final bool isThreePhase;
  final Color accent;
  final ValueNotifier<int?> hover;

  const _Chart({
    required this.series,
    required this.target,
    required this.isThreePhase,
    required this.accent,
    required this.hover,
  });

  /// Берёт последние kChartWindowPoints значений (скользящее окно)
  List<double> _window(List<double> v) => v.length > kChartWindowPoints
      ? v.sublist(v.length - kChartWindowPoints)
      : v;

  @override
  Widget build(BuildContext context) {
    // Скользящие окна по фазам
    final windows = {for (final e in series.entries) e.key: _window(e.value)};
    final allValues = [for (final list in windows.values) ...list, ?target];
    if (allValues.length < 2) {
      return const SizedBox.shrink();
    }

    // Стабильная ось Y — линия плавно растёт, а не «прыгает» каждый кадр
    final (minY, maxY) = _axisRange(allValues);
    // Фиксированная шкала X (данные выровнены по правому краю — «сейчас» справа)
    final maxX = (kChartWindowPoints - 1).toDouble();

    final bars = <LineChartBarData>[];
    for (final entry in windows.entries) {
      final phase = entry.key;
      final values = entry.value;
      if (values.length < 2) continue;
      final color = isThreePhase ? kPhaseColors[phase - 1] : accent;
      final offset = (kChartWindowPoints - values.length).toDouble();
      bars.add(
        LineChartBarData(
          spots: [
            for (var i = 0; i < values.length; i++)
              FlSpot(offset + i, values[i]),
          ],
          isCurved: true,
          curveSmoothness: 0.25,
          preventCurveOverShooting: true,
          barWidth: 2.5,
          color: color,
          dotData: const FlDotData(show: false),
          belowBarData: BarAreaData(
            show: !isThreePhase,
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                color.withValues(alpha: 0.22),
                color.withValues(alpha: 0.0),
              ],
            ),
          ),
        ),
      );
    }

    return ValueListenableBuilder<int?>(
      valueListenable: hover,
      builder: (context, hoverX, _) {
        final vLines = <VerticalLine>[
          if (hoverX != null)
            VerticalLine(
              x: hoverX.toDouble(),
              color: AppColors.info.withValues(alpha: 0.6),
              strokeWidth: 1.4,
              dashArray: [4, 4],
            ),
        ];
        final hLines = <HorizontalLine>[
          if (target != null)
            HorizontalLine(
              y: target!,
              color: AppColors.info.withValues(alpha: 0.7),
              strokeWidth: 1.6,
              dashArray: [7, 5],
            ),
        ];

        return LineChart(
          LineChartData(
            minX: 0,
            maxX: maxX,
            minY: minY,
            maxY: maxY,
            clipData: const FlClipData.all(),
            gridData: const FlGridData(show: false),
            titlesData: const FlTitlesData(show: false),
            borderData: FlBorderData(show: false),
            lineBarsData: bars,
            extraLinesData: ExtraLinesData(
              horizontalLines: hLines,
              verticalLines: vLines,
            ),
            // Наведение мышью → обновляем общий индекс crosshair
            lineTouchData: LineTouchData(
              enabled: true,
              handleBuiltInTouches: false,
              touchCallback: (event, response) {
                if (!event.isInterestedForInteractions ||
                    response == null ||
                    response.lineBarSpots == null ||
                    response.lineBarSpots!.isEmpty) {
                  hover.value = null;
                  return;
                }
                hover.value = response.lineBarSpots!.first.x.round();
              },
            ),
          ),
          duration: const Duration(milliseconds: 320),
          curve: Curves.easeInOut,
        );
      },
    );
  }

  /// Стабильный диапазон оси Y. Привязан к номиналу, если он есть, иначе —
  /// к данным с запасом (чтобы шкала не дёргалась каждый кадр).
  (double, double) _axisRange(List<double> values) {
    final dataMax = values.reduce((a, b) => a > b ? a : b);
    final dataMin = values.reduce((a, b) => a < b ? a : b);

    if (target != null && target! > 0) {
      // 0..номинал с запасом — линия растёт снизу вверх к уставке
      final top = (target! * 1.35) > dataMax ? target! * 1.35 : dataMax * 1.1;
      return (0, top);
    }
    // Нет номинала (нагрев): границы по данным с запасом
    final span = (dataMax - dataMin).abs();
    final pad = span * 0.25 + 2;
    return (dataMin - pad, dataMax + pad);
  }
}

/// Форматирует значение: целое без дробной части, иначе 1 знак
String _fmt(double v) =>
    v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(1);

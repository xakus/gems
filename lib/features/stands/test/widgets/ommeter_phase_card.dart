import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../core/constants/config.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';

/// Список проверок фазы 1 (ключи локализации) — для чеклиста процесса.
const List<String> _phase1Checks = [
  'test_check_interturn', // межвитковое замыкание
  'test_check_break', // обрыв обмотки
  'test_check_hv', // пробой изоляции (ВН)
  'test_check_ground', // замыкание на корпус
];

/// Карточка фазы 1 (омметры) — показывается по центру экрана.
/// Живые показания мегаомметра (изоляция) и микроомметра (обмотки),
/// прогресс измерения и чеклист проверок, отмечаемый по мере прохождения.
class OmmeterPhaseCard extends StatefulWidget {
  final double? insulationMohm;
  final double? windingResistance;

  const OmmeterPhaseCard({
    super.key,
    required this.insulationMohm,
    required this.windingResistance,
  });

  @override
  State<OmmeterPhaseCard> createState() => _OmmeterPhaseCardState();
}

class _OmmeterPhaseCardState extends State<OmmeterPhaseCard> {
  Timer? _timer;
  double _progress = 0;

  @override
  void initState() {
    super.initState();
    // Прогресс фазы 1 по времени (отметка проверок поочерёдно).
    // Реальная ПЛС позднее будет слать статусы проверок напрямую.
    final start = DateTime.now();
    _timer = Timer.periodic(const Duration(milliseconds: 80), (t) {
      final elapsed = DateTime.now().difference(start).inMilliseconds;
      final p = (elapsed / kMockPhase1DurationMs).clamp(0.0, 1.0);
      if (mounted) setState(() => _progress = p);
      if (p >= 1.0) t.cancel();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = AppColors.primary;
    // Сколько проверок уже пройдено (по прогрессу)
    final done = (_progress * _phase1Checks.length).floor();

    return Container(
          width: 560,
          padding: const EdgeInsets.all(kPaddingLarge * 1.6),
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
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.6,
                      color: primary,
                    ),
                  ),
                  const SizedBox(width: kPadding),
                  Text(
                    loc.tr('test_phase1_title'),
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: kPaddingLarge),

              // Прогресс измерения
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: _progress == 0 ? null : _progress,
                  minHeight: 8,
                  backgroundColor: primary.withValues(alpha: 0.12),
                  valueColor: AlwaysStoppedAnimation(primary),
                ),
              ),
              const SizedBox(height: kPaddingLarge),

              // Крупные показания омметров
              _Reading(
                label: loc.tr('metric_insulation'),
                value: widget.insulationMohm,
                unit: loc.tr('unit_mohm'),
              ),
              const SizedBox(height: kPadding),
              _Reading(
                label: loc.tr('metric_winding'),
                value: widget.windingResistance,
                unit: loc.tr('unit_ohm'),
              ),

              const SizedBox(height: kPaddingLarge),
              Divider(color: primary.withValues(alpha: 0.15), height: 1),
              const SizedBox(height: kPadding),

              // Чеклист проверок
              for (var i = 0; i < _phase1Checks.length; i++)
                _CheckRow(label: loc.tr(_phase1Checks[i]), done: i < done),
            ],
          ),
        )
        .animate()
        .fadeIn(duration: 400.ms, curve: Curves.easeOut)
        .scale(
          begin: const Offset(0.85, 0.85),
          end: const Offset(1.0, 1.0),
          duration: 450.ms,
          curve: Curves.easeOutCubic,
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
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: isDark
                ? AppColors.darkSecondaryText
                : AppColors.lightSecondaryText,
          ),
        ),
        Text(
          ready ? '${value!.toStringAsFixed(2)}  $unit' : '…',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
      ],
    );
  }
}

/// Строка чеклиста проверки: крутилка пока идёт, зелёная галочка по завершении
class _CheckRow extends StatelessWidget {
  final String label;
  final bool done;

  const _CheckRow({required this.label, required this.done});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          if (done)
            const Icon(
              Icons.check_circle_rounded,
              size: 22,
              color: AppColors.success,
            )
          else
            SizedBox(
              width: 22,
              height: 22,
              child: Padding(
                padding: const EdgeInsets.all(3),
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.primary.withValues(alpha: 0.5),
                ),
              ),
            ),
          const SizedBox(width: kPadding),
          Text(
            label,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: done
                  ? AppColors.success
                  : Theme.of(context).textTheme.titleMedium?.color,
              fontWeight: done ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}

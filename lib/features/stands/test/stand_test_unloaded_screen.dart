import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/config.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/motor_params.dart';
import '../../../data/models/test_measurement.dart';
import '../../../data/models/test_run.dart';
import '../../../data/repositories/test_repository.dart';
import '../../../data/services/plc/mock_plc_data_source.dart';
import '../../../shared/providers/auth_provider.dart';
import '../../../shared/widgets/app_header.dart';
import 'test_controller.dart';
import 'widgets/metric_card.dart';
import 'widgets/ommeter_phase_card.dart';
import 'widgets/test_error_overlay.dart';

/// Экран процесса теста двигателя «Без нагрузки».
/// Получает [MotorParams] и [standId] через аргументы маршрута.
class StandTestUnloadedScreen extends StatefulWidget {
  final MotorParams params;
  final int standId;

  /// Отладка: если задан failed_*-статус, мок-ПЛС смоделирует аварию фазы 1
  /// (для проверки ветки ошибок). В обычном запуске — null.
  final TestStatus? simulateFailure;

  const StandTestUnloadedScreen({
    super.key,
    required this.params,
    required this.standId,
    this.simulateFailure,
  });

  @override
  State<StandTestUnloadedScreen> createState() =>
      _StandTestUnloadedScreenState();
}

class _StandTestUnloadedScreenState extends State<StandTestUnloadedScreen> {
  late final TestController _controller;

  /// Общий индекс наведения для синхронного crosshair по всем графикам
  final ValueNotifier<int?> _hover = ValueNotifier(null);

  @override
  void initState() {
    super.initState();
    final auth = context.read<AuthProvider>();
    final user = auth.currentUser!;
    _controller = TestController(
      plc: MockPlcDataSource(simulateFailure: widget.simulateFailure),
      repo: TestRepository(),
      params: widget.params,
      standId: widget.standId,
      startedById: user.id!,
      startedByName: user.fullName,
    );
    _controller.start();
  }

  @override
  void dispose() {
    _hover.dispose();
    _controller.dispose();
    super.dispose();
  }

  /// Подтверждение экстренного завершения
  Future<void> _confirmEmergencyStop() async {
    final loc = AppLocalizations.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(loc.tr('test_emergency_confirm_title')),
        content: Text(loc.tr('test_emergency_confirm_msg')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(loc.tr('btn_cancel')),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: Text(loc.tr('test_emergency_stop')),
          ),
        ],
      ),
    );
    if (ok == true) await _controller.emergencyStop();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        // Пока тест идёт — выход «назад» заблокирован (п.6 ТЗ)
        return PopScope(
          canPop: !_controller.isRunning,
          child: Scaffold(appBar: const AppHeader(), body: _buildBody(context)),
        );
      },
    );
  }

  Widget _buildBody(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final c = _controller;

    return Padding(
      padding: const EdgeInsets.all(kPaddingLarge),
      child: Column(
        children: [
          // Заголовок: «N Стенд — Без нагрузки»
          Text(
            '${loc.tr('stand_${widget.standId}_title')} — ${loc.tr('stand_test_unloaded')}',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: kPadding),

          // Омметры, прошедшие фазу 1 — строки с зелёными галочками наверху
          if (c.phase != TestPhase.phase1 && c.phase != TestPhase.failed)
            _OmmetersDoneBar(
              insulation: c.insulationMohm,
              winding: c.windingResistance,
            ),

          Expanded(child: _buildCenter(context)),

          _buildBottomBar(context),
        ],
      ),
    );
  }

  Widget _buildCenter(BuildContext context) {
    final c = _controller;

    return switch (c.phase) {
      // Фаза 1 — карточка омметров по центру
      TestPhase.phase1 => Center(
        child: OmmeterPhaseCard(
          insulationMohm: c.insulationMohm,
          windingResistance: c.windingResistance,
        ),
      ),
      // Авария — крупная ошибка по центру
      TestPhase.failed => TestErrorOverlay(
        status: c.status,
        onFinish: () => Navigator.pop(context),
      ),
      // Фаза 2 / завершение — сетка карточек метрик
      _ => _buildMetrics(context),
    };
  }

  Widget _buildMetrics(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final c = _controller;

    if (c.activeMetrics.isEmpty) {
      // Омметры прошли, метрики ещё не пришли — короткое ожидание
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: kPadding),
            Text(loc.tr('test_phase2_waiting')),
          ],
        ),
      );
    }

    // Адаптивная сетка: заполняет экран без пустот; на узких/низких — прокрутка
    return LayoutBuilder(
      builder: (context, constraints) {
        final count = c.activeMetrics.length;
        const spacing = kPaddingLarge;

        // Колонки по ширине: до 3 на широком мониторе (1920), меньше — на узких
        var cols = (constraints.maxWidth / kMetricCardMinWidth).floor();
        cols = cols.clamp(1, 3);
        if (cols > count) cols = count;
        final rows = (count / cols).ceil();

        final cardW = (constraints.maxWidth - spacing * (cols - 1)) / cols;
        final fitH = (constraints.maxHeight - spacing * (rows - 1)) / rows;
        // Если по высоте влезает — растягиваем (без пустот), иначе фикс + скролл
        final fill = fitH >= kMetricCardMinHeight;
        final cardH = fill ? fitH : kMetricCardMinHeight;

        final grid = Wrap(
          spacing: spacing,
          runSpacing: spacing,
          alignment: WrapAlignment.center,
          children: [
            for (final metric in c.activeMetrics)
              SizedBox(
                width: cardW,
                height: cardH,
                child: MetricCard(
                  key: ValueKey(metric),
                  titleKey: metric.titleKey,
                  unitKey: metric.unitKey,
                  isThreePhase: metric.isThreePhase,
                  series: c.series[metric] ?? const {},
                  current: c.current[metric] ?? const {},
                  target: c.targets[metric],
                  accent: _metricColor(metric),
                  hover: _hover,
                ),
              ),
          ],
        );

        return fill ? Center(child: grid) : SingleChildScrollView(child: grid);
      },
    );
  }

  Widget _buildBottomBar(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final c = _controller;

    // Тест идёт — кнопка экстренного завершения
    if (c.isRunning) {
      return Padding(
        padding: const EdgeInsets.only(top: kPadding),
        child: ElevatedButton.icon(
          onPressed: _confirmEmergencyStop,
          icon: const Icon(Icons.power_settings_new_rounded),
          label: Text(loc.tr('test_emergency_stop')),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.error,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(
              horizontal: kPaddingLarge * 1.5,
              vertical: kPadding,
            ),
          ),
        ),
      );
    }

    // Авария показывает свою кнопку внутри overlay — здесь не дублируем
    if (c.phase == TestPhase.failed) return const SizedBox.shrink();

    // Завершено / остановлено — статус + кнопка выхода
    final aborted = c.phase == TestPhase.aborted;
    return Padding(
      padding: const EdgeInsets.only(top: kPadding),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                aborted ? Icons.cancel_rounded : Icons.check_circle_rounded,
                color: aborted ? AppColors.warning : AppColors.success,
              ),
              const SizedBox(width: kPaddingSmall),
              Text(
                loc.tr(aborted ? 'test_status_aborted' : 'test_status_passed'),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: aborted ? AppColors.warning : AppColors.success,
                ),
              ),
            ],
          ).animate().fadeIn(duration: 300.ms),
          const SizedBox(height: kPadding),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(
                horizontal: kPaddingLarge * 1.5,
                vertical: kPadding,
              ),
            ),
            child: Text(loc.tr('test_finish')),
          ),
        ],
      ),
    );
  }

  /// Цвет акцента карточки по метрике
  Color _metricColor(MetricType metric) => switch (metric) {
    MetricType.voltage => AppColors.primary,
    MetricType.current => AppColors.accent,
    MetricType.power => AppColors.info,
    MetricType.speed => AppColors.success,
    MetricType.temperature => AppColors.warning,
    MetricType.frequency => AppColors.accentDark,
    _ => AppColors.primary,
  };
}

/// Верхняя полоса с пройденными омметрами (фаза 1 завершена успешно)
class _OmmetersDoneBar extends StatelessWidget {
  final double? insulation;
  final double? winding;

  const _OmmetersDoneBar({required this.insulation, required this.winding});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: kPadding),
      child: Wrap(
        spacing: kPaddingLarge,
        runSpacing: kPaddingSmall,
        alignment: WrapAlignment.center,
        children: [
          _DoneItem(
            label: loc.tr('metric_insulation'),
            text: insulation != null
                ? '${insulation!.toStringAsFixed(2)} ${loc.tr('unit_mohm')}'
                : '—',
          ),
          _DoneItem(
            label: loc.tr('metric_winding'),
            text: winding != null
                ? '${winding!.toStringAsFixed(2)} ${loc.tr('unit_ohm')}'
                : '—',
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms).slideY(begin: -0.4, end: 0);
  }
}

class _DoneItem extends StatelessWidget {
  final String label;
  final String text;

  const _DoneItem({required this.label, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: kPadding, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.success.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.success.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.check_circle_rounded,
            size: 18,
            color: AppColors.success,
          ),
          const SizedBox(width: 6),
          Text(
            '$label: $text',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

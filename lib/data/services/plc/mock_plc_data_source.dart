import 'dart:async';
import 'dart:math';

import '../../../core/constants/config.dart';
import '../../models/motor_params.dart';
import '../../models/test_measurement.dart';
import '../../models/test_run.dart';
import 'plc_data_source.dart';
import 'plc_models.dart';

/// Мок-источник данных ПЛС.
///
/// Имитирует реальную работу стенда: данные приходят не разом, а постепенно и
/// параллельно по течению времени. Омметры (фаза 1) приходят раньше остальных;
/// после успешной фазы 1 «оживают» рабочие показатели (фаза 2).
///
/// [simulateFailure] — для проверки ветки аварии: если задан failed_*-статус,
/// фаза 1 завершится этой проблемой и фаза 2 не начнётся.
class MockPlcDataSource implements PlcDataSource {
  final TestStatus? simulateFailure;
  final Random _rnd = Random();

  final StreamController<PlcEvent> _controller =
      StreamController<PlcEvent>.broadcast();

  /// Активные таймеры — чтобы корректно отменить при стопе/dispose
  final List<Timer> _timers = [];
  bool _stopped = false;

  MockPlcDataSource({this.simulateFailure});

  @override
  Stream<PlcEvent> get events => _controller.stream;

  @override
  Future<void> start(MotorParams params) async {
    _runPhase1(params);
  }

  // ── Фаза 1: омметры ────────────────────────────────────────────────────────

  void _runPhase1(MotorParams params) {
    // Целевые итоги омметров (мок): изоляция ~ сотни МОм, обмотки — доли Ома
    final targetInsulation = 200 + _rnd.nextDouble() * 600; // 200..800 МОм
    final targetWinding = 0.2 + _rnd.nextDouble() * 1.8; // 0.2..2.0 Ом

    // «Капли» показаний омметров во время измерения
    _addPeriodic(
      delay: kMockOmmeterStartDelayMs,
      period: kMockOmmeterTickMs,
      until: kMockPhase1DurationMs,
      onTick: (progress) {
        _emit(
          PlcReading(
            metric: MetricType.insulation,
            value: targetInsulation * (0.6 + 0.4 * progress) + _noise(8),
            at: DateTime.now(),
          ),
        );
        _emit(
          PlcReading(
            metric: MetricType.winding,
            value: targetWinding * (0.6 + 0.4 * progress) + _noise(0.03),
            at: DateTime.now(),
          ),
        );
      },
    );

    // Итог фазы 1 — после её завершения
    _addOnce(kMockPhase1DurationMs, () {
      _emit(
        PlcPhase1Result(
          insulationMohm: targetInsulation,
          windingResistance: targetWinding,
          errorStatus: simulateFailure,
          at: DateTime.now(),
        ),
      );

      if (simulateFailure == null) {
        _runPhase2(params);
      }
    });
  }

  // ── Фаза 2: рабочие показатели ──────────────────────────────────────────────

  void _runPhase2(MotorParams params) {
    // Целевые значения метрик и их «появление» с разной задержкой
    final metrics = <MetricType, double>{
      MetricType.voltage: params.voltageV,
      MetricType.current: params.currentA,
      MetricType.power: params.powerKwt,
      MetricType.speed: params.speedRpm,
      MetricType.temperature: 60, // нагрев растёт от комнатной до ~60 °C
    };

    var stagger = kMockPhase2StartDelayMs;
    for (final entry in metrics.entries) {
      final metric = entry.key;
      final target = entry.value;
      // Каждая метрика начинает обновляться со своей задержкой (параллельно, но не разом)
      _addPeriodic(
        delay: stagger,
        period: kMockPhase2TickMs,
        until: kMockPhase2DurationMs,
        onTick: (progress) {
          _emit(
            PlcReading(
              metric: metric,
              value: _approach(metric, target, progress),
              at: DateTime.now(),
            ),
          );
        },
      );
      stagger += kMockMetricStaggerMs;
    }

    // Завершение теста
    _addOnce(kMockPhase2DurationMs + kMockPhase2StartDelayMs, () {
      _emit(PlcTestFinished(at: DateTime.now()));
    });
  }

  /// Значение метрики при заданном прогрессе (0..1): плавный выход на целевое + шум.
  double _approach(MetricType metric, double target, double progress) {
    // Температура стартует с комнатной, остальное — с нуля и выходит на номинал
    final base = metric == MetricType.temperature ? 25.0 : 0.0;
    final value = base + (target - base) * _ease(progress);
    final noiseAmp = target.abs() * 0.02 + 0.01;
    return value + _noise(noiseAmp);
  }

  // ── Помощники таймеров ───────────────────────────────────────────────────────

  /// Однократное действие через [delayMs]
  void _addOnce(int delayMs, void Function() action) {
    _timers.add(
      Timer(Duration(milliseconds: delayMs), () {
        if (!_stopped) action();
      }),
    );
  }

  /// Периодический тик: стартует через [delay], тикает каждые [period],
  /// останавливается через [until] (от старта). [onTick] получает прогресс 0..1.
  void _addPeriodic({
    required int delay,
    required int period,
    required int until,
    required void Function(double progress) onTick,
  }) {
    _addOnce(delay, () {
      final started = DateTime.now();
      _timers.add(
        Timer.periodic(Duration(milliseconds: period), (timer) {
          if (_stopped) {
            timer.cancel();
            return;
          }
          final elapsed = DateTime.now().difference(started).inMilliseconds;
          final progress = (elapsed / until).clamp(0.0, 1.0);
          onTick(progress);
          if (elapsed >= until) timer.cancel();
        }),
      );
    });
  }

  void _emit(PlcEvent e) {
    if (!_stopped && !_controller.isClosed) _controller.add(e);
  }

  /// Сглаживающая кривая (ease-out) для плавного выхода на номинал
  double _ease(double t) => 1 - pow(1 - t, 3).toDouble();

  /// Симметричный шум амплитуды [amp]
  double _noise(double amp) => (_rnd.nextDouble() * 2 - 1) * amp;

  void _cancelAll() {
    for (final t in _timers) {
      t.cancel();
    }
    _timers.clear();
  }

  @override
  Future<void> stop() async {
    _stopped = true;
    _cancelAll();
  }

  @override
  Future<void> emergencyStop() async {
    _stopped = true;
    _cancelAll();
  }

  @override
  void dispose() {
    _stopped = true;
    _cancelAll();
    if (!_controller.isClosed) _controller.close();
  }
}

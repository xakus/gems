import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../data/models/motor_params.dart';
import '../../../data/models/test_event.dart';
import '../../../data/models/test_measurement.dart';
import '../../../data/models/test_run.dart';
import '../../../data/repositories/test_repository.dart';
import '../../../data/services/plc/plc_data_source.dart';
import '../../../data/services/plc/plc_models.dart';

/// Фаза прохождения теста (управляет тем, что показывает экран).
enum TestPhase {
  phase1, // идут измерения омметров (карточка в центре)
  phase1Done, // омметры пройдены (уехали наверх), ждём/идёт фаза 2
  phase2, // идут рабочие показатели
  finished, // тест успешно завершён
  failed, // авария фазы 1 (КЗ/обрыв/пробой/КЗ на корпус)
  aborted, // экстренный стоп оператором
}

/// Контроллер процесса теста двигателя «Без нагрузки».
///
/// Подписывается на [PlcDataSource], агрегирует состояние для UI и пишет
/// запуск, измерения и события в [TestRepository].
class TestController extends ChangeNotifier {
  final PlcDataSource _plc;
  final TestRepository _repo;
  final MotorParams params;
  final int standId;
  final int startedById;
  final String startedByName;

  TestController({
    required PlcDataSource plc,
    required TestRepository repo,
    required this.params,
    required this.standId,
    required this.startedById,
    required this.startedByName,
  }) : _plc = plc,
       _repo = repo;

  StreamSubscription<PlcEvent>? _sub;
  int? _runId;

  // ── Состояние для UI ─────────────────────────────────────────────────────
  TestPhase _phase = TestPhase.phase1;
  TestPhase get phase => _phase;

  /// Текущие показания омметров (null — ещё не пришло)
  double? insulationMohm;
  double? windingResistance;

  /// Итоговый статус (после завершения/аварии)
  TestStatus _status = TestStatus.running;
  TestStatus get status => _status;
  String? errorCode;

  /// Последние значения метрик фазы 2
  final Map<MetricType, double> current = {};

  /// История значений для графиков (по метрикам)
  final Map<MetricType, List<double>> series = {};

  /// Порядок появления метрик — для поочерёдной анимации карточек
  final List<MetricType> activeMetrics = [];

  /// Тест ещё идёт → выход назад заблокирован (п.6 ТЗ)
  bool get isRunning =>
      _phase == TestPhase.phase1 ||
      _phase == TestPhase.phase1Done ||
      _phase == TestPhase.phase2;

  // ── Жизненный цикл ───────────────────────────────────────────────────────

  /// Создаёт запись запуска в БД и стартует ПЛС.
  Future<void> start() async {
    final run = await _repo.createRun(
      TestRun(
        standId: standId,
        mode: TestMode.unloaded,
        params: params,
        status: TestStatus.running,
        startedById: startedById,
        startedByName: startedByName,
        startedAt: DateTime.now(),
      ),
    );
    _runId = run.id;

    _sub = _plc.events.listen(_onEvent);
    await _plc.start(params);
  }

  void _onEvent(PlcEvent event) {
    switch (event) {
      case PlcReading():
        _onReading(event);
      case PlcPhase1Result():
        _onPhase1Result(event);
      case PlcTestFinished():
        _onFinished(event);
    }
  }

  void _onReading(PlcReading r) {
    final metric = r.metric;

    if (metric == MetricType.insulation) {
      insulationMohm = r.value;
    } else if (metric == MetricType.winding) {
      windingResistance = r.value;
    } else {
      // Метрика фазы 2: фиксируем появление и историю для графика
      if (!activeMetrics.contains(metric)) {
        activeMetrics.add(metric);
        if (_phase == TestPhase.phase1Done) _phase = TestPhase.phase2;
      }
      current[metric] = r.value;
      (series[metric] ??= []).add(r.value);
    }

    _record(metric, r.value, r.at);
    notifyListeners();
  }

  void _onPhase1Result(PlcPhase1Result res) {
    insulationMohm = res.insulationMohm;
    windingResistance = res.windingResistance;

    if (res.isOk) {
      _phase = TestPhase.phase1Done;
      _addEvent(TestEventType.phase1Ok);
    } else {
      // Авария: статус failed_*, запись в БД, выход разблокирован
      _status = res.errorStatus!;
      errorCode = _status.toDbString();
      _phase = TestPhase.failed;
      _finish(_status, TestEventType.error);
    }
    notifyListeners();
  }

  void _onFinished(PlcTestFinished _) {
    _status = TestStatus.passed;
    _phase = TestPhase.finished;
    _finish(TestStatus.passed, TestEventType.finish);
    notifyListeners();
  }

  /// Экстренное завершение оператором (кнопка)
  Future<void> emergencyStop() async {
    if (!isRunning) return;
    await _plc.emergencyStop();
    _status = TestStatus.aborted;
    _phase = TestPhase.aborted;
    _finish(TestStatus.aborted, TestEventType.emergencyStop);
    notifyListeners();
  }

  // ── Запись в БД ──────────────────────────────────────────────────────────

  void _record(MetricType metric, double value, DateTime at) {
    final runId = _runId;
    if (runId == null) return;
    _repo.addMeasurement(
      TestMeasurement(
        runId: runId,
        metric: metric,
        value: value,
        unit: metric.unitKey,
        recordedAt: at,
      ),
    );
  }

  void _addEvent(TestEventType type, [String? message]) {
    final runId = _runId;
    if (runId == null) return;
    _repo.addEvent(
      TestEvent(
        runId: runId,
        type: type,
        message: message,
        createdAt: DateTime.now(),
      ),
    );
  }

  void _finish(TestStatus status, TestEventType eventType) {
    final runId = _runId;
    if (runId == null) return;
    _repo.finishRun(
      runId: runId,
      status: status,
      eventType: eventType,
      errorCode: errorCode,
      insulationMohm: insulationMohm,
      windingResistance: windingResistance,
    );
  }

  @override
  void dispose() {
    _sub?.cancel();
    _plc.dispose();
    super.dispose();
  }
}

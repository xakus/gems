import '../../core/constants/config.dart';
import 'motor_params.dart';

/// Режим теста двигателя
enum TestMode {
  unloaded;

  String toDbString() => switch (this) {
    TestMode.unloaded => kTestModeUnloaded,
  };

  static TestMode fromString(String s) => switch (s) {
    kTestModeUnloaded => TestMode.unloaded,
    _ => TestMode.unloaded,
  };
}

/// Статус запуска теста.
/// failed_* — провал фазы 1 (омметры), aborted — экстренный стоп.
enum TestStatus {
  running,
  passed,
  aborted,
  failedInterturn,
  failedBreak,
  failedHvBreakdown,
  failedGround;

  String toDbString() => switch (this) {
    TestStatus.running => kTestStatusRunning,
    TestStatus.passed => kTestStatusPassed,
    TestStatus.aborted => kTestStatusAborted,
    TestStatus.failedInterturn => kTestStatusFailedInterturn,
    TestStatus.failedBreak => kTestStatusFailedBreak,
    TestStatus.failedHvBreakdown => kTestStatusFailedHvBreakdown,
    TestStatus.failedGround => kTestStatusFailedGround,
  };

  static TestStatus fromString(String s) => switch (s) {
    kTestStatusRunning => TestStatus.running,
    kTestStatusPassed => TestStatus.passed,
    kTestStatusAborted => TestStatus.aborted,
    kTestStatusFailedInterturn => TestStatus.failedInterturn,
    kTestStatusFailedBreak => TestStatus.failedBreak,
    kTestStatusFailedHvBreakdown => TestStatus.failedHvBreakdown,
    kTestStatusFailedGround => TestStatus.failedGround,
    _ => TestStatus.running,
  };

  /// true — тест провален аппаратной проверкой фазы 1
  bool get isFailure =>
      this == TestStatus.failedInterturn ||
      this == TestStatus.failedBreak ||
      this == TestStatus.failedHvBreakdown ||
      this == TestStatus.failedGround;
}

/// Запуск теста двигателя (таблица test_runs)
class TestRun {
  final int? id;

  /// Номер стенда (1..5)
  final int standId;

  /// Режим теста
  final TestMode mode;

  /// Заданные параметры двигателя
  final MotorParams params;

  /// Текущий статус запуска
  final TestStatus status;

  /// Код ошибки от ПЛС (null, если ошибки нет)
  final String? errorCode;

  /// Итоговое сопротивление изоляции (мегаомметр), МОм — nullable
  final double? insulationMohm;

  /// Итоговое сопротивление обмоток (микроомметр) — nullable
  final double? windingResistance;

  /// Кто запустил тест (снимок на момент запуска)
  final int startedById;
  final String startedByName;

  final DateTime startedAt;
  final DateTime? finishedAt;

  const TestRun({
    this.id,
    required this.standId,
    required this.mode,
    required this.params,
    required this.status,
    this.errorCode,
    this.insulationMohm,
    this.windingResistance,
    required this.startedById,
    required this.startedByName,
    required this.startedAt,
    this.finishedAt,
  });

  factory TestRun.fromMap(Map<String, dynamic> map) {
    return TestRun(
      id: map['id'] as int?,
      standId: map['stand_id'] as int,
      mode: TestMode.fromString(map['test_mode'] as String),
      params: MotorParams(
        powerKwt: (map['power_kwt'] as num).toDouble(),
        voltageV: (map['voltage_v'] as num).toDouble(),
        currentA: (map['current_a'] as num).toDouble(),
        speedRpm: (map['speed_rpm'] as num).toDouble(),
        frequencyHz: (map['frequency_hz'] as num).toDouble(),
      ),
      status: TestStatus.fromString(map['status'] as String),
      errorCode: map['error_code'] as String?,
      insulationMohm: (map['insulation_mohm'] as num?)?.toDouble(),
      windingResistance: (map['winding_resistance'] as num?)?.toDouble(),
      startedById: map['started_by_id'] as int,
      startedByName: map['started_by_name'] as String,
      startedAt: DateTime.parse(map['started_at'] as String),
      finishedAt: map['finished_at'] != null
          ? DateTime.parse(map['finished_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'stand_id': standId,
      'test_mode': mode.toDbString(),
      'power_kwt': params.powerKwt,
      'voltage_v': params.voltageV,
      'current_a': params.currentA,
      'speed_rpm': params.speedRpm,
      'frequency_hz': params.frequencyHz,
      'status': status.toDbString(),
      'error_code': errorCode,
      'insulation_mohm': insulationMohm,
      'winding_resistance': windingResistance,
      'started_by_id': startedById,
      'started_by_name': startedByName,
      'started_at': startedAt.toIso8601String(),
      'finished_at': finishedAt?.toIso8601String(),
    };
  }

  TestRun copyWith({
    int? id,
    TestStatus? status,
    String? errorCode,
    double? insulationMohm,
    double? windingResistance,
    DateTime? finishedAt,
  }) {
    return TestRun(
      id: id ?? this.id,
      standId: standId,
      mode: mode,
      params: params,
      status: status ?? this.status,
      errorCode: errorCode ?? this.errorCode,
      insulationMohm: insulationMohm ?? this.insulationMohm,
      windingResistance: windingResistance ?? this.windingResistance,
      startedById: startedById,
      startedByName: startedByName,
      startedAt: startedAt,
      finishedAt: finishedAt ?? this.finishedAt,
    );
  }
}

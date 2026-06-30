import '../../core/constants/config.dart';

/// Тип измеряемой величины. Каждой метрике соответствует ключ единицы измерения
/// (см. assets/translations) для отображения в UI.
enum MetricType {
  insulation, // мегаомметр — сопротивление изоляции
  winding, // микроомметр — сопротивление обмоток
  voltage, // трёхфазное
  current, // трёхфазное
  power,
  speed,
  temperature,
  frequency;

  String toDbString() => switch (this) {
    MetricType.insulation => kMetricInsulation,
    MetricType.winding => kMetricWinding,
    MetricType.voltage => kMetricVoltage,
    MetricType.current => kMetricCurrent,
    MetricType.power => kMetricPower,
    MetricType.speed => kMetricSpeed,
    MetricType.temperature => kMetricTemperature,
    MetricType.frequency => kMetricFrequency,
  };

  static MetricType fromString(String s) => switch (s) {
    kMetricInsulation => MetricType.insulation,
    kMetricWinding => MetricType.winding,
    kMetricVoltage => MetricType.voltage,
    kMetricCurrent => MetricType.current,
    kMetricPower => MetricType.power,
    kMetricSpeed => MetricType.speed,
    kMetricTemperature => MetricType.temperature,
    kMetricFrequency => MetricType.frequency,
    _ => MetricType.voltage,
  };

  /// Трёхфазная метрика (напряжение/ток) — измеряется по 3 фазам
  bool get isThreePhase =>
      this == MetricType.voltage || this == MetricType.current;

  /// Ключ локализации названия метрики
  String get titleKey => 'metric_$name';

  /// Ключ локализации единицы измерения
  String get unitKey => switch (this) {
    MetricType.insulation => 'unit_mohm',
    MetricType.winding => 'unit_ohm',
    MetricType.voltage => 'unit_v',
    MetricType.current => 'unit_a',
    MetricType.power => 'unit_kwt',
    MetricType.speed => 'unit_rpm',
    MetricType.temperature => 'unit_celsius',
    MetricType.frequency => 'unit_hz',
  };
}

/// Одно измерение тайм-серии (таблица test_measurements)
class TestMeasurement {
  final int? id;
  final int runId;
  final MetricType metric;

  /// Фаза: 1/2/3 для трёхфазных метрик, 0 — однофазные
  final int phase;
  final double value;

  /// Снимок единицы измерения на момент записи
  final String unit;
  final DateTime recordedAt;

  const TestMeasurement({
    this.id,
    required this.runId,
    required this.metric,
    this.phase = 0,
    required this.value,
    required this.unit,
    required this.recordedAt,
  });

  factory TestMeasurement.fromMap(Map<String, dynamic> map) {
    return TestMeasurement(
      id: map['id'] as int?,
      runId: map['run_id'] as int,
      metric: MetricType.fromString(map['metric'] as String),
      phase: (map['phase'] as int?) ?? 0,
      value: (map['value'] as num).toDouble(),
      unit: map['unit'] as String,
      recordedAt: DateTime.parse(map['recorded_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'run_id': runId,
      'metric': metric.toDbString(),
      'phase': phase,
      'value': value,
      'unit': unit,
      'recorded_at': recordedAt.toIso8601String(),
    };
  }
}

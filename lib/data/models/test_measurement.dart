import '../../core/constants/config.dart';

/// Тип измеряемой величины. Каждой метрике соответствует ключ единицы измерения
/// (см. assets/translations) для отображения в UI.
enum MetricType {
  insulation, // мегаомметр — сопротивление изоляции
  winding, // микроомметр — сопротивление обмоток
  voltage,
  current,
  power,
  speed,
  temperature;

  String toDbString() => switch (this) {
    MetricType.insulation => kMetricInsulation,
    MetricType.winding => kMetricWinding,
    MetricType.voltage => kMetricVoltage,
    MetricType.current => kMetricCurrent,
    MetricType.power => kMetricPower,
    MetricType.speed => kMetricSpeed,
    MetricType.temperature => kMetricTemperature,
  };

  static MetricType fromString(String s) => switch (s) {
    kMetricInsulation => MetricType.insulation,
    kMetricWinding => MetricType.winding,
    kMetricVoltage => MetricType.voltage,
    kMetricCurrent => MetricType.current,
    kMetricPower => MetricType.power,
    kMetricSpeed => MetricType.speed,
    kMetricTemperature => MetricType.temperature,
    _ => MetricType.voltage,
  };

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
  };
}

/// Одно измерение тайм-серии (таблица test_measurements)
class TestMeasurement {
  final int? id;
  final int runId;
  final MetricType metric;
  final double value;

  /// Снимок единицы измерения на момент записи
  final String unit;
  final DateTime recordedAt;

  const TestMeasurement({
    this.id,
    required this.runId,
    required this.metric,
    required this.value,
    required this.unit,
    required this.recordedAt,
  });

  factory TestMeasurement.fromMap(Map<String, dynamic> map) {
    return TestMeasurement(
      id: map['id'] as int?,
      runId: map['run_id'] as int,
      metric: MetricType.fromString(map['metric'] as String),
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
      'value': value,
      'unit': unit,
      'recorded_at': recordedAt.toIso8601String(),
    };
  }
}

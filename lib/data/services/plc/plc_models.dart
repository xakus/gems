import '../../models/test_measurement.dart';
import '../../models/test_run.dart';

/// События, приходящие от ПЛС (реальной или мок).
/// Все события несут момент времени [at] — фиксируется по приходу данных.
sealed class PlcEvent {
  final DateTime at;
  const PlcEvent(this.at);
}

/// Очередное показание измерителя (омметры фазы 1 или метрики фазы 2).
class PlcReading extends PlcEvent {
  final MetricType metric;
  final double value;

  const PlcReading({
    required this.metric,
    required this.value,
    required DateTime at,
  }) : super(at);
}

/// Результат фазы 1 (омметры): прошли проверки или авария.
/// [errorStatus] != null → обнаружена проблема (КЗ/обрыв/пробой/КЗ на корпус).
class PlcPhase1Result extends PlcEvent {
  /// Итог мегаомметра (сопротивление изоляции), МОм
  final double insulationMohm;

  /// Итог микроомметра (сопротивление обмоток)
  final double windingResistance;

  /// null — всё хорошо; иначе соответствующий failed_*-статус
  final TestStatus? errorStatus;

  const PlcPhase1Result({
    required this.insulationMohm,
    required this.windingResistance,
    this.errorStatus,
    required DateTime at,
  }) : super(at);

  bool get isOk => errorStatus == null;
}

/// Тест успешно завершён ПЛС (все измерения фазы 2 сняты).
class PlcTestFinished extends PlcEvent {
  const PlcTestFinished({required DateTime at}) : super(at);
}

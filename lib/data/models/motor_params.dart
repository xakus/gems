/// Параметры испытуемого двигателя (value-object).
/// Заполняются в форме «Без нагрузки» и передаются в экран теста.
class MotorParams {
  /// Мощность, кВт
  final double powerKwt;

  /// Напряжение, В
  final double voltageV;

  /// Ток, А
  final double currentA;

  /// Скорость вращения, об/мин
  final double speedRpm;

  /// Частота, Гц
  final double frequencyHz;

  const MotorParams({
    required this.powerKwt,
    required this.voltageV,
    required this.currentA,
    required this.speedRpm,
    required this.frequencyHz,
  });
}

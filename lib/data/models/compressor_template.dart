/// Шаблон настроек теста компрессора (таблица compressor_templates)
class CompressorTemplate {
  final int? id;

  /// Название шаблона (отображается в выпадающем списке)
  final String name;

  /// Название компрессора
  final String compressorName;

  /// Мощность, кВт
  final double powerKwt;

  /// Напряжение, В
  final double voltageV;

  /// Ток, А
  final double currentA;

  /// Максимальные обороты, об/мин
  final double speedRpm;

  /// Частота, Гц
  final double frequencyHz;

  /// Производительность, лит/мин
  final double productivityLMin;

  /// Заданное давление, Бар
  final double pressureBar;

  /// Время удержания, мин (0 = без удержания)
  final double holdTimeMin;

  /// Объём ресивера, л
  final double receiverVolumeL;

  final DateTime createdAt;
  final DateTime updatedAt;

  const CompressorTemplate({
    this.id,
    required this.name,
    required this.compressorName,
    required this.powerKwt,
    required this.voltageV,
    required this.currentA,
    required this.speedRpm,
    required this.frequencyHz,
    required this.productivityLMin,
    required this.pressureBar,
    required this.holdTimeMin,
    required this.receiverVolumeL,
    required this.createdAt,
    required this.updatedAt,
  });

  factory CompressorTemplate.fromMap(Map<String, dynamic> map) {
    return CompressorTemplate(
      id: map['id'] as int?,
      name: map['name'] as String,
      compressorName: map['compressor_name'] as String,
      powerKwt: (map['power_kwt'] as num).toDouble(),
      voltageV: (map['voltage_v'] as num).toDouble(),
      currentA: (map['current_a'] as num).toDouble(),
      speedRpm: (map['speed_rpm'] as num).toDouble(),
      frequencyHz: (map['frequency_hz'] as num).toDouble(),
      productivityLMin: (map['productivity_l_min'] as num).toDouble(),
      pressureBar: (map['pressure_bar'] as num).toDouble(),
      holdTimeMin: (map['hold_time_min'] as num).toDouble(),
      receiverVolumeL: (map['receiver_volume_l'] as num).toDouble(),
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'compressor_name': compressorName,
      'power_kwt': powerKwt,
      'voltage_v': voltageV,
      'current_a': currentA,
      'speed_rpm': speedRpm,
      'frequency_hz': frequencyHz,
      'productivity_l_min': productivityLMin,
      'pressure_bar': pressureBar,
      'hold_time_min': holdTimeMin,
      'receiver_volume_l': receiverVolumeL,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  CompressorTemplate copyWith({
    int? id,
    String? name,
    String? compressorName,
    double? powerKwt,
    double? voltageV,
    double? currentA,
    double? speedRpm,
    double? frequencyHz,
    double? productivityLMin,
    double? pressureBar,
    double? holdTimeMin,
    double? receiverVolumeL,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CompressorTemplate(
      id: id ?? this.id,
      name: name ?? this.name,
      compressorName: compressorName ?? this.compressorName,
      powerKwt: powerKwt ?? this.powerKwt,
      voltageV: voltageV ?? this.voltageV,
      currentA: currentA ?? this.currentA,
      speedRpm: speedRpm ?? this.speedRpm,
      frequencyHz: frequencyHz ?? this.frequencyHz,
      productivityLMin: productivityLMin ?? this.productivityLMin,
      pressureBar: pressureBar ?? this.pressureBar,
      holdTimeMin: holdTimeMin ?? this.holdTimeMin,
      receiverVolumeL: receiverVolumeL ?? this.receiverVolumeL,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

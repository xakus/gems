import '../../core/constants/config.dart';

/// Тип события в журнале теста
enum TestEventType {
  start, // тест запущен
  phase1Ok, // фаза 1 (омметры) пройдена
  measurement, // зафиксированы показания (метка для отчёта)
  error, // ошибка от ПЛС (КЗ/обрыв/пробой/КЗ на корпус)
  emergencyStop, // экстренное завершение оператором
  finish; // тест завершён

  String toDbString() => switch (this) {
    TestEventType.start => kTestEventStart,
    TestEventType.phase1Ok => kTestEventPhase1Ok,
    TestEventType.measurement => kTestEventMeasurement,
    TestEventType.error => kTestEventError,
    TestEventType.emergencyStop => kTestEventEmergencyStop,
    TestEventType.finish => kTestEventFinish,
  };

  static TestEventType fromString(String s) => switch (s) {
    kTestEventStart => TestEventType.start,
    kTestEventPhase1Ok => TestEventType.phase1Ok,
    kTestEventMeasurement => TestEventType.measurement,
    kTestEventError => TestEventType.error,
    kTestEventEmergencyStop => TestEventType.emergencyStop,
    kTestEventFinish => TestEventType.finish,
    _ => TestEventType.measurement,
  };
}

/// Событие журнала теста (таблица test_events) — для архива и отчётов
class TestEvent {
  final int? id;
  final int runId;
  final TestEventType type;

  /// Доп. описание (например код ошибки) — опционально
  final String? message;
  final DateTime createdAt;

  const TestEvent({
    this.id,
    required this.runId,
    required this.type,
    this.message,
    required this.createdAt,
  });

  factory TestEvent.fromMap(Map<String, dynamic> map) {
    return TestEvent(
      id: map['id'] as int?,
      runId: map['run_id'] as int,
      type: TestEventType.fromString(map['event_type'] as String),
      message: map['message'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'run_id': runId,
      'event_type': type.toDbString(),
      'message': message,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

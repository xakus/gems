import '../../core/database/database_helper.dart';
import '../models/test_event.dart';
import '../models/test_measurement.dart';
import '../models/test_run.dart';

/// Репозиторий модуля тестирования двигателей.
/// Пишет запуски, тайм-серию измерений и журнал событий теста.
class TestRepository {
  final DatabaseHelper _db = DatabaseHelper.instance;

  /// Создаёт запись запуска теста (status=running) и событие «старт».
  /// Возвращает [TestRun] с присвоенным id.
  Future<TestRun> createRun(TestRun run) async {
    final db = await _db.database;
    final id = await db.insert('test_runs', run.toMap());
    final created = run.copyWith(id: id);

    await addEvent(
      TestEvent(
        runId: id,
        type: TestEventType.start,
        createdAt: DateTime.now(),
      ),
    );

    return created;
  }

  /// Добавляет одно измерение
  Future<void> addMeasurement(TestMeasurement m) async {
    final db = await _db.database;
    await db.insert('test_measurements', m.toMap());
  }

  /// Добавляет пачку измерений одной транзакцией
  Future<void> addMeasurementsBatch(List<TestMeasurement> items) async {
    if (items.isEmpty) return;
    final db = await _db.database;
    final batch = db.batch();
    for (final m in items) {
      batch.insert('test_measurements', m.toMap());
    }
    await batch.commit(noResult: true);
  }

  /// Добавляет событие в журнал теста
  Future<void> addEvent(TestEvent e) async {
    final db = await _db.database;
    await db.insert('test_events', e.toMap());
  }

  /// Завершает тест: обновляет статус/итоги и пишет событие финиша.
  /// [eventType] — finish (успех), error (авария), emergency_stop (стоп оператора).
  Future<void> finishRun({
    required int runId,
    required TestStatus status,
    required TestEventType eventType,
    String? errorCode,
    double? insulationMohm,
    double? windingResistance,
  }) async {
    final db = await _db.database;
    final now = DateTime.now();

    await db.update(
      'test_runs',
      {
        'status': status.toDbString(),
        'error_code': errorCode,
        'insulation_mohm': insulationMohm,
        'winding_resistance': windingResistance,
        'finished_at': now.toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [runId],
    );

    await addEvent(
      TestEvent(
        runId: runId,
        type: eventType,
        message: errorCode,
        createdAt: now,
      ),
    );
  }

  /// Все запуски по стенду (новые сверху) — для архива/отчётов
  Future<List<TestRun>> getRunsByStand(int standId) async {
    final db = await _db.database;
    final rows = await db.query(
      'test_runs',
      where: 'stand_id = ?',
      whereArgs: [standId],
      orderBy: 'started_at DESC',
    );
    return rows.map(TestRun.fromMap).toList();
  }

  /// Тайм-серия измерений запуска (по возрастанию времени) — для графиков/отчётов
  Future<List<TestMeasurement>> getMeasurements(int runId) async {
    final db = await _db.database;
    final rows = await db.query(
      'test_measurements',
      where: 'run_id = ?',
      whereArgs: [runId],
      orderBy: 'recorded_at ASC',
    );
    return rows.map(TestMeasurement.fromMap).toList();
  }
}

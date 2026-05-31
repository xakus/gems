import '../../core/database/database_helper.dart';
import '../models/audit_log.dart';

/// Репозиторий для работы с таблицей audit_log.
/// Записи только добавляются и читаются — удаление не предусмотрено.
class AuditRepository {
  final DatabaseHelper _db = DatabaseHelper.instance;

  /// Добавляет запись в журнал аудита
  Future<void> add(AuditLog entry) async {
    final db = await _db.database;
    await db.insert('audit_log', entry.toMap());
  }

  /// Возвращает все записи аудита (от новых к старым)
  Future<List<AuditLog>> getAll() async {
    final db = await _db.database;
    final rows = await db.query('audit_log', orderBy: 'created_at DESC');
    return rows.map(AuditLog.fromMap).toList();
  }
}

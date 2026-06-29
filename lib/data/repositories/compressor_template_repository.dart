import 'dart:convert';
import '../../core/database/database_helper.dart';
import '../models/audit_log.dart';
import '../models/compressor_template.dart';
import 'audit_repository.dart';

/// CRUD-репозиторий для шаблонов настроек компрессора.
/// Все мутирующие операции записывают запись в журнал аудита.
class CompressorTemplateRepository {
  final DatabaseHelper _db = DatabaseHelper.instance;
  final AuditRepository _audit = AuditRepository();

  /// Возвращает все шаблоны (по алфавиту)
  Future<List<CompressorTemplate>> getAll() async {
    final db = await _db.database;
    final rows = await db.query('compressor_templates', orderBy: 'name ASC');
    return rows.map(CompressorTemplate.fromMap).toList();
  }

  /// Создаёт новый шаблон и пишет аудит
  Future<CompressorTemplate> create({
    required CompressorTemplate template,
    required int performedById,
    required String performedByName,
  }) async {
    final db = await _db.database;
    final now = DateTime.now();
    final toInsert = template.copyWith(createdAt: now, updatedAt: now);
    final id = await db.insert('compressor_templates', toInsert.toMap());
    final created = toInsert.copyWith(id: id);

    await _audit.add(
      AuditLog(
        action: AuditAction.templateCreate,
        performedById: performedById,
        performedByName: performedByName,
        targetUserId: id,
        targetUserName: created.name,
        changesJson: jsonEncode(_templateToChanges(created)),
        createdAt: now,
      ),
    );

    return created;
  }

  /// Обновляет шаблон и пишет аудит (только изменённые поля)
  Future<void> update({
    required CompressorTemplate oldTemplate,
    required CompressorTemplate newTemplate,
    required int performedById,
    required String performedByName,
  }) async {
    final db = await _db.database;
    final now = DateTime.now();
    final updated = newTemplate.copyWith(
      id: oldTemplate.id,
      createdAt: oldTemplate.createdAt,
      updatedAt: now,
    );
    await db.update(
      'compressor_templates',
      updated.toMap(),
      where: 'id = ?',
      whereArgs: [oldTemplate.id],
    );

    final diff = _diffTemplates(oldTemplate, updated);
    await _audit.add(
      AuditLog(
        action: AuditAction.templateUpdate,
        performedById: performedById,
        performedByName: performedByName,
        targetUserId: oldTemplate.id!,
        targetUserName: updated.name,
        changesJson: diff.isNotEmpty ? jsonEncode(diff) : null,
        createdAt: now,
      ),
    );
  }

  /// Удаляет шаблон и пишет аудит
  Future<void> delete({
    required CompressorTemplate template,
    required int performedById,
    required String performedByName,
  }) async {
    final db = await _db.database;
    await db.delete(
      'compressor_templates',
      where: 'id = ?',
      whereArgs: [template.id],
    );

    await _audit.add(
      AuditLog(
        action: AuditAction.templateDelete,
        performedById: performedById,
        performedByName: performedByName,
        targetUserId: template.id!,
        targetUserName: template.name,
        changesJson: null,
        createdAt: DateTime.now(),
      ),
    );
  }

  /// Формирует changes-map для CREATE (все поля → to)
  Map<String, Map<String, String>> _templateToChanges(CompressorTemplate t) {
    return {
      'name': {'to': t.name},
      'compressor_name': {'to': t.compressorName},
      'power_kwt': {'to': t.powerKwt.toString()},
      'voltage_v': {'to': t.voltageV.toString()},
      'current_a': {'to': t.currentA.toString()},
      'speed_rpm': {'to': t.speedRpm.toString()},
      'frequency_hz': {'to': t.frequencyHz.toString()},
      'productivity_l_min': {'to': t.productivityLMin.toString()},
      'pressure_bar': {'to': t.pressureBar.toString()},
      'hold_time_min': {'to': t.holdTimeMin.toString()},
      'receiver_volume_l': {'to': t.receiverVolumeL.toString()},
    };
  }

  /// Формирует diff только изменённых полей для UPDATE
  Map<String, Map<String, String>> _diffTemplates(
    CompressorTemplate old,
    CompressorTemplate updated,
  ) {
    final diff = <String, Map<String, String>>{};

    void check(String key, String oldVal, String newVal) {
      if (oldVal != newVal) {
        diff[key] = {'from': oldVal, 'to': newVal};
      }
    }

    check('name', old.name, updated.name);
    check('compressor_name', old.compressorName, updated.compressorName);
    check('power_kwt', old.powerKwt.toString(), updated.powerKwt.toString());
    check('voltage_v', old.voltageV.toString(), updated.voltageV.toString());
    check('current_a', old.currentA.toString(), updated.currentA.toString());
    check('speed_rpm', old.speedRpm.toString(), updated.speedRpm.toString());
    check(
      'frequency_hz',
      old.frequencyHz.toString(),
      updated.frequencyHz.toString(),
    );
    check(
      'productivity_l_min',
      old.productivityLMin.toString(),
      updated.productivityLMin.toString(),
    );
    check(
      'pressure_bar',
      old.pressureBar.toString(),
      updated.pressureBar.toString(),
    );
    check(
      'hold_time_min',
      old.holdTimeMin.toString(),
      updated.holdTimeMin.toString(),
    );
    check(
      'receiver_volume_l',
      old.receiverVolumeL.toString(),
      updated.receiverVolumeL.toString(),
    );

    return diff;
  }
}

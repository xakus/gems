import 'dart:convert';

/// Тип действия в журнале аудита
enum AuditAction {
  create,
  update,
  activate,
  deactivate,
  resetPassword,
  delete;

  String toDbString() => switch (this) {
    AuditAction.create => 'CREATE',
    AuditAction.update => 'UPDATE',
    AuditAction.activate => 'ACTIVATE',
    AuditAction.deactivate => 'DEACTIVATE',
    AuditAction.resetPassword => 'RESET_PASSWORD',
    AuditAction.delete => 'DELETE',
  };

  static AuditAction fromString(String s) => switch (s) {
    'CREATE' => AuditAction.create,
    'UPDATE' => AuditAction.update,
    'ACTIVATE' => AuditAction.activate,
    'DEACTIVATE' => AuditAction.deactivate,
    'RESET_PASSWORD' => AuditAction.resetPassword,
    'DELETE' => AuditAction.delete,
    _ => AuditAction.update,
  };
}

/// Запись журнала аудита (таблица audit_log)
class AuditLog {
  final int? id;
  final AuditAction action;
  final int performedById;

  /// Снимок имени исполнителя на момент действия
  final String performedByName;
  final int targetUserId;

  /// Снимок имени целевого пользователя на момент действия
  final String targetUserName;

  /// JSON: {"field": {"from": "...", "to": "..."}} — только изменённые поля.
  /// Для CREATE содержит только ключ "to". Для DELETE/RESET — null.
  final String? changesJson;
  final DateTime createdAt;

  const AuditLog({
    this.id,
    required this.action,
    required this.performedById,
    required this.performedByName,
    required this.targetUserId,
    required this.targetUserName,
    this.changesJson,
    required this.createdAt,
  });

  /// Декодированные изменения: поле → {from?, to?}
  Map<String, Map<String, String>>? get changes {
    if (changesJson == null) return null;
    final decoded = jsonDecode(changesJson!) as Map<String, dynamic>;
    return decoded.map(
      (k, v) => MapEntry(k, Map<String, String>.from(v as Map)),
    );
  }

  factory AuditLog.fromMap(Map<String, dynamic> map) {
    return AuditLog(
      id: map['id'] as int?,
      action: AuditAction.fromString(map['action'] as String),
      performedById: map['performed_by_id'] as int,
      performedByName: map['performed_by_name'] as String,
      targetUserId: map['target_user_id'] as int,
      targetUserName: map['target_user_name'] as String,
      changesJson: map['changes'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'action': action.toDbString(),
      'performed_by_id': performedById,
      'performed_by_name': performedByName,
      'target_user_id': targetUserId,
      'target_user_name': targetUserName,
      'changes': changesJson,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

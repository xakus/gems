import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/constants/config.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/audit_log.dart';
import '../../data/repositories/audit_repository.dart';

/// Раздел журнала аудита — только для ADMIN.
/// Показывает все действия с пользователями: кто, что, когда и над кем.
class AuditLogSection extends StatefulWidget {
  const AuditLogSection({super.key});

  @override
  State<AuditLogSection> createState() => _AuditLogSectionState();
}

class _AuditLogSectionState extends State<AuditLogSection> {
  final AuditRepository _repo = AuditRepository();
  List<AuditLog> _logs = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadLogs();
  }

  Future<void> _loadLogs() async {
    setState(() => _loading = true);
    try {
      _logs = await _repo.getAll();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final hPad = ((constraints.maxWidth - kUsersMaxWidth) / 2)
            .clamp(kPaddingLarge, double.infinity);

        return Padding(
          padding: EdgeInsets.fromLTRB(hPad, kPaddingLarge, hPad, kPaddingLarge),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      l10n.tr('audit_title'),
                      style: Theme.of(context).textTheme.headlineSmall,
                      overflow: TextOverflow.ellipsis,
                    ).animate().fadeIn(),
                  ),
                  IconButton(
                    tooltip: l10n.tr('audit_refresh'),
                    icon: const Icon(Icons.refresh_rounded),
                    onPressed: _loadLogs,
                  ).animate(delay: 100.ms).fadeIn(),
                ],
              ),

              const SizedBox(height: 20),

              if (_loading)
                const Center(child: CircularProgressIndicator())
              else if (_logs.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 48),
                    child: Column(
                      children: [
                        Icon(
                          Icons.history_rounded,
                          size: 48,
                          color: Theme.of(context).colorScheme.outlineVariant,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          l10n.tr('audit_no_logs'),
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: Theme.of(context).colorScheme.outlineVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                Row(
                  children: [
                    Expanded(
                      child: _AuditTable(logs: _logs),
                    ),
                  ],
                ),
            ],
          ),
        );
      },
    );
  }
}

/// Таблица записей аудита
class _AuditTable extends StatelessWidget {
  final List<AuditLog> logs;

  const _AuditTable({required this.logs});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Card(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: SingleChildScrollView(
          child: DataTable(
            headingRowColor: WidgetStateProperty.all(
              Theme.of(context).colorScheme.surfaceContainerHighest,
            ),
            columnSpacing: 20,
            columns: [
              DataColumn(label: Text(l10n.tr('audit_date'))),
              DataColumn(label: Text(l10n.tr('audit_action'))),
              DataColumn(label: Text(l10n.tr('audit_performed_by'))),
              DataColumn(label: Text(l10n.tr('audit_target_user'))),
              DataColumn(label: Text(l10n.tr('audit_changes'))),
            ],
            rows: logs.map((log) => _buildRow(context, log)).toList(),
          ),
        ),
      ),
    );
  }

  DataRow _buildRow(BuildContext context, AuditLog log) {
    final dateStr = _formatDateTime(log.createdAt);
    final changesText = _formatChanges(context, log);

    return DataRow(
      cells: [
        DataCell(
          Text(
            dateStr,
            style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
          ),
        ),
        DataCell(_ActionBadge(action: log.action)),
        DataCell(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.admin_panel_settings_rounded,
                  size: 14, color: AppColors.accent),
              const SizedBox(width: 6),
              Text(log.performedByName,
                  style: const TextStyle(fontWeight: FontWeight.w500)),
            ],
          ),
        ),
        DataCell(
          Text(
            log.targetUserName,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
        ),
        DataCell(
          Tooltip(
            message: changesText,
            child: Text(
              changesText,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ),
      ],
    );
  }

  String _formatDateTime(DateTime dt) {
    final d = dt.day.toString().padLeft(2, '0');
    final mo = dt.month.toString().padLeft(2, '0');
    final y = dt.year;
    final h = dt.hour.toString().padLeft(2, '0');
    final mi = dt.minute.toString().padLeft(2, '0');
    return '$d.$mo.$y $h:$mi';
  }

  String _formatChanges(BuildContext context, AuditLog log) {
    final l10n = AppLocalizations.of(context);
    final ch = log.changes;

    if (ch == null || ch.isEmpty) return '—';

    final fieldLabels = {
      'first_name': l10n.tr('audit_field_first_name'),
      'last_name': l10n.tr('audit_field_last_name'),
      'username': l10n.tr('audit_field_username'),
      'role': l10n.tr('audit_field_role'),
      'is_active': l10n.tr('audit_field_is_active'),
    };

    return ch.entries.map((e) {
      final field = fieldLabels[e.key] ?? e.key;
      final from = e.value['from'];
      final to = e.value['to'] ?? '';
      if (from == null || from.isEmpty) {
        return '$field: $to';
      }
      return '$field: $from → $to';
    }).join('  |  ');
  }
}

/// Цветной бейдж для типа действия
class _ActionBadge extends StatelessWidget {
  final AuditAction action;

  const _ActionBadge({required this.action});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    final (label, color) = switch (action) {
      AuditAction.create => (l10n.tr('audit_action_create'), AppColors.success),
      AuditAction.update => (l10n.tr('audit_action_update'), AppColors.info),
      AuditAction.activate => (l10n.tr('audit_action_activate'), AppColors.success),
      AuditAction.deactivate => (l10n.tr('audit_action_deactivate'), AppColors.warning),
      AuditAction.resetPassword => (l10n.tr('audit_action_reset_password'), AppColors.warning),
      AuditAction.delete => (l10n.tr('audit_action_delete'), AppColors.error),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.3,
          color: color,
        ),
      ),
    );
  }
}

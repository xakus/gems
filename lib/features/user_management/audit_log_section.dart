import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../core/constants/config.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/audit_log.dart';
import '../../data/repositories/audit_repository.dart';

// Фиксированные ширины колонок таблицы
const _kDateW  = 108.0;
const _kBadgeW = 140.0;
const _kRowH   = 50.0;

// ─────────────────────────────────────────────────────────────────────────────
// Основной виджет
// ─────────────────────────────────────────────────────────────────────────────

/// Журнал аудита: фильтрация, кликабельные строки с деталями, экспорт в PDF
class AuditLogSection extends StatefulWidget {
  const AuditLogSection({super.key});

  @override
  State<AuditLogSection> createState() => _AuditLogSectionState();
}

class _AuditLogSectionState extends State<AuditLogSection> {
  final _repo       = AuditRepository();
  final _searchCtrl = TextEditingController();

  List<AuditLog> _allLogs  = [];
  List<AuditLog> _filtered = [];
  AuditAction?   _actionFilter;
  bool _loading  = true;
  bool _exporting = false;

  @override
  void initState() {
    super.initState();
    _loadLogs();
    _searchCtrl.addListener(_applyFilter);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  // ── Загрузка и фильтрация ────────────────────────────────────────────────

  Future<void> _loadLogs() async {
    setState(() => _loading = true);
    try {
      _allLogs = await _repo.getAll();
      _applyFilter();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _applyFilter() {
    final q = _searchCtrl.text.trim().toLowerCase();
    setState(() {
      _filtered = _allLogs.where((log) {
        if (_actionFilter != null && log.action != _actionFilter) return false;
        if (q.isNotEmpty) {
          return log.performedByName.toLowerCase().contains(q) ||
              log.targetUserName.toLowerCase().contains(q);
        }
        return true;
      }).toList();
    });
  }

  void _setActionFilter(AuditAction? action) {
    _actionFilter = action;
    _applyFilter();
  }

  // ── PDF экспорт ───────────────────────────────────────────────────────────

  Future<void> _exportPdf() async {
    final l10n   = AppLocalizations.of(context);
    final logs   = List<AuditLog>.from(_filtered);
    final labels = _fieldLabels(l10n);
    setState(() => _exporting = true);
    try {
      await Printing.layoutPdf(
        name: 'audit_log.pdf',
        onLayout: (fmt) => _buildPdfBytes(logs, l10n, labels, fmt),
      );
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  static Future<Uint8List> _buildPdfBytes(
    List<AuditLog>      logs,
    AppLocalizations     l10n,
    Map<String, String> fieldLabels,
    PdfPageFormat       format,
  ) async {
    final doc = pw.Document();

    final baseData = await rootBundle.load('assets/fonts/NotoSans-Regular.ttf');
    final boldData = await rootBundle.load('assets/fonts/NotoSans-Bold.ttf');
    final font     = pw.Font.ttf(baseData);
    final boldFont = pw.Font.ttf(boldData);

    doc.addPage(
      pw.MultiPage(
        pageFormat: format,
        theme: pw.ThemeData.withFont(base: font, bold: boldFont),
        margin: const pw.EdgeInsets.all(32),
        header: (_) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  l10n.tr('audit_pdf_title'),
                  style: pw.TextStyle(
                    font: boldFont, fontSize: 15, color: PdfColors.blue800,
                  ),
                ),
                pw.Text(
                  _fmtDt(DateTime.now()),
                  style: pw.TextStyle(font: font, fontSize: 9, color: PdfColors.grey600),
                ),
              ],
            ),
            pw.SizedBox(height: 3),
            pw.Divider(color: PdfColors.grey300),
            pw.SizedBox(height: 6),
          ],
        ),
        build: (_) => [
          pw.TableHelper.fromTextArray(
            headers: [
              l10n.tr('audit_date'),
              l10n.tr('audit_action'),
              l10n.tr('audit_performed_by'),
              l10n.tr('audit_target_user'),
              l10n.tr('audit_changes'),
            ],
            data: logs.map((log) => [
              _fmtDt(log.createdAt),
              _actionStr(log.action, l10n),
              log.performedByName,
              log.targetUserName,
              _changesFlat(log.changes, fieldLabels),
            ]).toList(),
            headerStyle: pw.TextStyle(
              font: boldFont, fontSize: 9, color: PdfColors.white,
            ),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.blue800),
            cellStyle: pw.TextStyle(font: font, fontSize: 8),
            oddRowDecoration: const pw.BoxDecoration(color: PdfColors.grey50),
            cellPadding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
            columnWidths: {
              0: const pw.FixedColumnWidth(68),
              1: const pw.FixedColumnWidth(96),
              2: const pw.FixedColumnWidth(80),
              3: const pw.FixedColumnWidth(80),
              4: const pw.FlexColumnWidth(),
            },
            cellAlignments: {
              0: pw.Alignment.centerLeft,
              1: pw.Alignment.center,
              2: pw.Alignment.centerLeft,
              3: pw.Alignment.centerLeft,
              4: pw.Alignment.centerLeft,
            },
          ),
        ],
      ),
    );

    return doc.save();
  }

  // ── Вспомогательные (статические) ────────────────────────────────────────

  static Map<String, String> _fieldLabels(AppLocalizations l10n) => {
    'first_name':         l10n.tr('audit_field_first_name'),
    'last_name':          l10n.tr('audit_field_last_name'),
    'username':           l10n.tr('audit_field_username'),
    'role':               l10n.tr('audit_field_role'),
    'is_active':          l10n.tr('audit_field_is_active'),
    'name':               l10n.tr('audit_field_name'),
    'compressor_name':    l10n.tr('audit_field_compressor_name'),
    'power_kwt':          l10n.tr('audit_field_power_kwt'),
    'voltage_v':          l10n.tr('audit_field_voltage_v'),
    'current_a':          l10n.tr('audit_field_current_a'),
    'speed_rpm':          l10n.tr('audit_field_speed_rpm'),
    'frequency_hz':       l10n.tr('audit_field_frequency_hz'),
    'productivity_l_min': l10n.tr('audit_field_productivity_l_min'),
    'pressure_bar':       l10n.tr('audit_field_pressure_bar'),
    'hold_time_min':      l10n.tr('audit_field_hold_time_min'),
    'receiver_volume_l':  l10n.tr('audit_field_receiver_volume_l'),
  };

  static String _fmtDt(DateTime dt) {
    final d  = dt.day.toString().padLeft(2, '0');
    final mo = dt.month.toString().padLeft(2, '0');
    final h  = dt.hour.toString().padLeft(2, '0');
    final mi = dt.minute.toString().padLeft(2, '0');
    return '$d.$mo.${dt.year} $h:$mi';
  }

  static String _actionStr(AuditAction a, AppLocalizations l) => switch (a) {
    AuditAction.create         => l.tr('audit_action_create'),
    AuditAction.update         => l.tr('audit_action_update'),
    AuditAction.activate       => l.tr('audit_action_activate'),
    AuditAction.deactivate     => l.tr('audit_action_deactivate'),
    AuditAction.resetPassword  => l.tr('audit_action_reset_password'),
    AuditAction.delete         => l.tr('audit_action_delete'),
    AuditAction.templateCreate => l.tr('audit_action_template_create'),
    AuditAction.templateUpdate => l.tr('audit_action_template_update'),
    AuditAction.templateDelete => l.tr('audit_action_template_delete'),
  };

  static String _changesFlat(
    Map<String, Map<String, String>>? ch,
    Map<String, String> fieldLabels,
  ) {
    if (ch == null || ch.isEmpty) return '—';
    return ch.entries.map((e) {
      final f    = fieldLabels[e.key] ?? e.key;
      final from = e.value['from'];
      final to   = e.value['to'] ?? '';
      return (from == null || from.isEmpty) ? '$f: $to' : '$f: $from → $to';
    }).join('  |  ');
  }

  // ── Детальный диалог ──────────────────────────────────────────────────────

  void _openDetail(AuditLog log) {
    final l10n = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (_) => _LogDetailDialog(
        log: log,
        fieldLabels: _fieldLabels(l10n),
        l10n: l10n,
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final l10n  = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(kPaddingLarge),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          // Шапка ─────────────────────────────────────────────────────────
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n.tr('audit_title'),
                  style: theme.textTheme.headlineSmall,
                  overflow: TextOverflow.ellipsis,
                ).animate().fadeIn(),
              ),
              const SizedBox(width: 12),

              // Поиск
              SizedBox(
                width: 220,
                height: 38,
                child: TextField(
                  controller: _searchCtrl,
                  decoration: InputDecoration(
                    hintText: l10n.tr('audit_search_hint'),
                    prefixIcon: const Icon(Icons.search_rounded, size: 17),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 8),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    suffixIcon: _searchCtrl.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded, size: 15),
                            onPressed: () => _searchCtrl.clear(),
                            padding: EdgeInsets.zero,
                            constraints:
                                const BoxConstraints(minWidth: 32, minHeight: 32),
                          )
                        : null,
                  ),
                ),
              ).animate(delay: 50.ms).fadeIn(),
              const SizedBox(width: 8),

              // Кнопка PDF
              FilledButton.icon(
                icon: _exporting
                    ? const SizedBox(
                        width: 14, height: 14,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.picture_as_pdf_rounded, size: 16),
                label: Text(l10n.tr('audit_download_pdf')),
                style: FilledButton.styleFrom(backgroundColor: AppColors.error),
                onPressed: (_exporting || _filtered.isEmpty) ? null : _exportPdf,
              ).animate(delay: 100.ms).fadeIn(),
              const SizedBox(width: 8),

              // Обновить
              IconButton(
                tooltip: l10n.tr('audit_refresh'),
                icon: const Icon(Icons.refresh_rounded),
                onPressed: _loading ? null : _loadLogs,
              ).animate(delay: 150.ms).fadeIn(),
            ],
          ),

          const SizedBox(height: 12),

          // Фильтр-чипы ────────────────────────────────────────────────────
          _FilterBar(
            selected: _actionFilter,
            onSelect: _setActionFilter,
          ).animate(delay: 50.ms).fadeIn(),

          const SizedBox(height: 12),

          // Контент ────────────────────────────────────────────────────────
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _filtered.isEmpty
                    ? _EmptyState(
                        text: _allLogs.isEmpty
                            ? l10n.tr('audit_no_logs')
                            : l10n.tr('audit_no_match'),
                      )
                    : _LogTable(logs: _filtered, onRowTap: _openDetail),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Filter bar
// ─────────────────────────────────────────────────────────────────────────────

class _FilterBar extends StatelessWidget {
  final AuditAction?              selected;
  final ValueChanged<AuditAction?> onSelect;

  const _FilterBar({required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cs   = Theme.of(context).colorScheme;

    final chips = [
      (null as AuditAction?,       l10n.tr('audit_filter_all'),           cs.primary),
      (AuditAction.create,         l10n.tr('audit_action_create'),        AppColors.success),
      (AuditAction.update,         l10n.tr('audit_action_update'),        AppColors.info),
      (AuditAction.activate,       l10n.tr('audit_action_activate'),      AppColors.success),
      (AuditAction.deactivate,     l10n.tr('audit_action_deactivate'),    AppColors.warning),
      (AuditAction.resetPassword,  l10n.tr('audit_action_reset_password'),AppColors.warning),
      (AuditAction.delete,         l10n.tr('audit_action_delete'),        AppColors.error),
      (AuditAction.templateCreate, l10n.tr('audit_action_template_create'), AppColors.success),
      (AuditAction.templateUpdate, l10n.tr('audit_action_template_update'), AppColors.info),
      (AuditAction.templateDelete, l10n.tr('audit_action_template_delete'), AppColors.error),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: chips.map((chip) {
          final (action, label, color) = chip;
          final isSel = selected == action;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: InkWell(
              onTap: () => onSelect(action),
              borderRadius: BorderRadius.circular(20),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: isSel
                      ? color.withValues(alpha: 0.14)
                      : cs.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSel ? color : Colors.transparent,
                    width: 1.5,
                  ),
                ),
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isSel ? FontWeight.w700 : FontWeight.w400,
                    color: isSel ? color : cs.onSurfaceVariant,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Log table — кастомный layout вместо DataTable (нет overflow)
// ─────────────────────────────────────────────────────────────────────────────

class _LogTable extends StatelessWidget {
  final List<AuditLog>       logs;
  final ValueChanged<AuditLog> onRowTap;

  const _LogTable({required this.logs, required this.onRowTap});

  @override
  Widget build(BuildContext context) {
    final l10n   = AppLocalizations.of(context);
    final cs     = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    const headerStyle = TextStyle(
      fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 0.2,
    );

    return Card(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          children: [
            // Строка заголовков
            Container(
              color: cs.surfaceContainerHighest,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: _RowLayout(
                date:    Text(l10n.tr('audit_date'),         style: headerStyle),
                action:  Text(l10n.tr('audit_action'),       style: headerStyle),
                by:      Text(l10n.tr('audit_performed_by'), style: headerStyle,
                              overflow: TextOverflow.ellipsis),
                target:  Text(l10n.tr('audit_target_user'),  style: headerStyle,
                              overflow: TextOverflow.ellipsis),
                changes: Text(l10n.tr('audit_changes'),      style: headerStyle,
                              overflow: TextOverflow.ellipsis),
              ),
            ),

            // Строки данных
            Expanded(
              child: ListView.separated(
                itemCount: logs.length,
                separatorBuilder: (_, _) => Divider(
                  height: 1,
                  color: cs.outlineVariant.withValues(alpha: 0.35),
                ),
                itemBuilder: (ctx, i) {
                  final log = logs[i];
                  return Material(
                    color: i.isEven
                        ? Colors.transparent
                        : (isDark
                            ? Colors.white.withValues(alpha: 0.02)
                            : Colors.black.withValues(alpha: 0.015)),
                    child: InkWell(
                      onTap: () => onRowTap(log),
                      child: SizedBox(
                        height: _kRowH,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: _LogRowContent(log: log),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Единый layout строки (заголовок + данные)
// ─────────────────────────────────────────────────────────────────────────────

class _RowLayout extends StatelessWidget {
  final Widget  date;
  final Widget  action;
  final Widget  by;
  final Widget  target;
  final Widget  changes;
  final Widget? trailing;

  const _RowLayout({
    required this.date,
    required this.action,
    required this.by,
    required this.target,
    required this.changes,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(width: _kDateW, child: date),
        const SizedBox(width: 8),
        SizedBox(width: _kBadgeW, child: action),
        const SizedBox(width: 8),
        Expanded(flex: 1, child: by),
        const SizedBox(width: 8),
        Expanded(flex: 1, child: target),
        const SizedBox(width: 8),
        Expanded(flex: 2, child: changes),
        if (trailing != null) ...[const SizedBox(width: 4), trailing!],
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Содержимое одной строки данных
// ─────────────────────────────────────────────────────────────────────────────

class _LogRowContent extends StatelessWidget {
  final AuditLog log;

  const _LogRowContent({required this.log});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final dt = log.createdAt;

    final dateStr = '${dt.day.toString().padLeft(2, '0')}.'
        '${dt.month.toString().padLeft(2, '0')}.'
        '${dt.year}\n'
        '${dt.hour.toString().padLeft(2, '0')}:'
        '${dt.minute.toString().padLeft(2, '0')}';

    // Превью изменений — только значения через разделитель
    final ch = log.changes;
    final preview = ch == null || ch.isEmpty
        ? '—'
        : ch.entries.map((e) {
            final from = e.value['from'];
            final to   = e.value['to'] ?? '';
            return (from == null || from.isEmpty) ? to : '$from → $to';
          }).join('  |  ');

    return _RowLayout(
      date: Text(
        dateStr,
        style: const TextStyle(fontSize: 11, height: 1.35),
      ),
      action: _ActionBadge(action: log.action),
      by: Row(
        children: [
          const Icon(
            Icons.admin_panel_settings_rounded,
            size: 13, color: AppColors.accent,
          ),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              log.performedByName,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
      target: Text(
        log.targetUserName,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
      ),
      changes: Text(
        preview,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
      ),
      trailing: Icon(
        Icons.chevron_right_rounded,
        size: 18,
        color: cs.outlineVariant,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Empty state
// ─────────────────────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final String text;

  const _EmptyState({required this.text});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.history_rounded,
            size: 48,
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
          const SizedBox(height: 12),
          Text(
            text,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).colorScheme.outlineVariant,
                ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Детальный диалог
// ─────────────────────────────────────────────────────────────────────────────

class _LogDetailDialog extends StatelessWidget {
  final AuditLog           log;
  final Map<String, String> fieldLabels;
  final AppLocalizations   l10n;

  const _LogDetailDialog({
    required this.log,
    required this.fieldLabels,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    final dt = log.createdAt;
    final dateStr = '${dt.day.toString().padLeft(2, '0')}.'
        '${dt.month.toString().padLeft(2, '0')}.'
        '${dt.year}  '
        '${dt.hour.toString().padLeft(2, '0')}:'
        '${dt.minute.toString().padLeft(2, '0')}';

    final changes = log.changes;

    return AlertDialog(
      title: Row(
        children: [
          _ActionBadge(action: log.action),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              dateStr,
              style: const TextStyle(fontSize: 14, fontFamily: 'monospace'),
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 540,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 4),
              _DetailInfoRow(
                icon:  Icons.admin_panel_settings_rounded,
                label: l10n.tr('audit_performed_by'),
                value: log.performedByName,
              ),
              const SizedBox(height: 8),
              _DetailInfoRow(
                icon:  Icons.person_outline_rounded,
                label: l10n.tr('audit_target_user'),
                value: log.targetUserName,
              ),

              if (changes != null && changes.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(
                  l10n.tr('audit_changes'),
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 8),
                _ChangesTable(
                  changes:     changes,
                  fieldLabels: fieldLabels,
                  hasFrom: changes.values.any(
                    (v) => (v['from'] ?? '').isNotEmpty,
                  ),
                  l10n: l10n,
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        FilledButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.tr('btn_close')),
        ),
      ],
    );
  }
}

class _DetailInfoRow extends StatelessWidget {
  final IconData icon;
  final String   label;
  final String   value;

  const _DetailInfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(icon, size: 16, color: AppColors.primary),
        const SizedBox(width: 8),
        Text('$label: ', style: const TextStyle(fontWeight: FontWeight.w600)),
        Flexible(child: Text(value, overflow: TextOverflow.ellipsis)),
      ],
    );
  }
}

class _ChangesTable extends StatelessWidget {
  final Map<String, Map<String, String>> changes;
  final Map<String, String>              fieldLabels;
  final bool                             hasFrom;
  final AppLocalizations                 l10n;

  const _ChangesTable({
    required this.changes,
    required this.fieldLabels,
    required this.hasFrom,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Table(
      border: TableBorder.all(
        color: cs.outlineVariant.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      columnWidths: hasFrom
          ? const {
              0: FlexColumnWidth(2),
              1: FlexColumnWidth(2),
              2: FlexColumnWidth(2),
            }
          : const {
              0: FlexColumnWidth(2),
              1: FlexColumnWidth(3),
            },
      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
      children: [
        // Заголовок
        TableRow(
          decoration: BoxDecoration(color: cs.surfaceContainerHighest),
          children: [
            _TCell(l10n.tr('audit_detail_field'), bold: true),
            if (hasFrom) _TCell(l10n.tr('audit_detail_from'), bold: true),
            _TCell(l10n.tr('audit_detail_to'), bold: true),
          ],
        ),
        // Данные
        ...changes.entries.map((e) {
          final field = fieldLabels[e.key] ?? e.key;
          final from  = e.value['from'] ?? '';
          final to    = e.value['to']   ?? '';
          return TableRow(
            children: [
              _TCell(field, bold: true),
              if (hasFrom)
                _TCell(
                  from,
                  color: from.isNotEmpty
                      ? AppColors.error.withValues(alpha: 0.75)
                      : null,
                ),
              _TCell(
                to,
                color: (to.isNotEmpty && from.isNotEmpty)
                    ? AppColors.success.withValues(alpha: 0.85)
                    : null,
              ),
            ],
          );
        }),
      ],
    );
  }
}

class _TCell extends StatelessWidget {
  final String text;
  final bool   bold;
  final Color? color;

  const _TCell(this.text, {this.bold = false, this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 13,
          fontWeight: bold ? FontWeight.w600 : FontWeight.w400,
          color: color,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Action badge
// ─────────────────────────────────────────────────────────────────────────────

class _ActionBadge extends StatelessWidget {
  final AuditAction action;

  const _ActionBadge({required this.action});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    final (label, color) = switch (action) {
      AuditAction.create         => (l10n.tr('audit_action_create'),          AppColors.success),
      AuditAction.update         => (l10n.tr('audit_action_update'),          AppColors.info),
      AuditAction.activate       => (l10n.tr('audit_action_activate'),        AppColors.success),
      AuditAction.deactivate     => (l10n.tr('audit_action_deactivate'),      AppColors.warning),
      AuditAction.resetPassword  => (l10n.tr('audit_action_reset_password'),  AppColors.warning),
      AuditAction.delete         => (l10n.tr('audit_action_delete'),          AppColors.error),
      AuditAction.templateCreate => (l10n.tr('audit_action_template_create'), AppColors.success),
      AuditAction.templateUpdate => (l10n.tr('audit_action_template_update'), AppColors.info),
      AuditAction.templateDelete => (l10n.tr('audit_action_template_delete'), AppColors.error),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.2,
          color: color,
        ),
      ),
    );
  }
}

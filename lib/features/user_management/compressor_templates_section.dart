import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../core/constants/config.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/compressor_template.dart';
import '../../data/repositories/compressor_template_repository.dart';
import '../../shared/providers/auth_provider.dart';

/// Раздел управления шаблонами компрессора — только для ADMIN.
class CompressorTemplatesSection extends StatefulWidget {
  const CompressorTemplatesSection({super.key});

  @override
  State<CompressorTemplatesSection> createState() =>
      _CompressorTemplatesSectionState();
}

class _CompressorTemplatesSectionState
    extends State<CompressorTemplatesSection> {
  final _repo = CompressorTemplateRepository();
  List<CompressorTemplate> _templates = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      _templates = await _repo.getAll();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);

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
                      loc.tr('compressor_templates_title'),
                      style: Theme.of(context).textTheme.headlineSmall,
                      overflow: TextOverflow.ellipsis,
                    ).animate().fadeIn(),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: Text(loc.tr('compressor_templates_create')),
                    onPressed: () => _showEditDialog(context, null),
                  ).animate(delay: 100.ms).fadeIn(),
                ],
              ),

              const SizedBox(height: 20),

              if (_loading)
                const Center(child: CircularProgressIndicator())
              else if (_templates.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 48),
                    child: Column(
                      children: [
                        Icon(
                          Icons.layers_outlined,
                          size: 48,
                          color: Theme.of(context).colorScheme.outlineVariant,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          loc.tr('compressor_templates_no_templates'),
                          style:
                              Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .outlineVariant,
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
                      child: _TemplatesTable(
                        templates: _templates,
                        onEdit: (t) => _showEditDialog(context, t),
                        onDelete: (t) => _confirmDelete(context, t),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _showEditDialog(
    BuildContext context,
    CompressorTemplate? existing,
  ) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _TemplateDialog(
        template: existing,
        onSave: (draft) => _save(draft, existing),
      ),
    );
    if (result == true) _load();
  }

  Future<void> _save(
    CompressorTemplate draft,
    CompressorTemplate? existing,
  ) async {
    final auth = context.read<AuthProvider>();
    final user = auth.currentUser!;

    if (existing == null) {
      await _repo.create(
        template: draft,
        performedById: user.id!,
        performedByName: user.fullName,
      );
    } else {
      await _repo.update(
        oldTemplate: existing,
        newTemplate: draft,
        performedById: user.id!,
        performedByName: user.fullName,
      );
    }
  }

  Future<void> _confirmDelete(
    BuildContext context,
    CompressorTemplate template,
  ) async {
    final loc = AppLocalizations.of(context);
    // Читаем данные пользователя ДО async-разрыва
    final auth = context.read<AuthProvider>();
    final user = auth.currentUser!;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(loc.tr('compressor_templates_delete_confirm')),
        content: Text(
          loc
              .tr('compressor_templates_delete_msg')
              .replaceAll('{name}', template.name),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(loc.tr('compressor_templates_cancel')),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: Text(loc.tr('compressor_templates_delete')),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    await _repo.delete(
      template: template,
      performedById: user.id!,
      performedByName: user.fullName,
    );

    if (mounted) {
      ScaffoldMessenger.of(this.context).showSnackBar(
        SnackBar(
          content: Text(loc.tr('compressor_templates_deleted')),
          backgroundColor: AppColors.success,
        ),
      );
      _load();
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Таблица шаблонов
// ─────────────────────────────────────────────────────────────────────────────

class _TemplatesTable extends StatelessWidget {
  final List<CompressorTemplate> templates;
  final void Function(CompressorTemplate) onEdit;
  final void Function(CompressorTemplate) onDelete;

  const _TemplatesTable({
    required this.templates,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);

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
              DataColumn(label: Text(loc.tr('compressor_templates_name'))),
              DataColumn(label: Text(loc.tr('compressor_name'))),
              DataColumn(label: Text(loc.tr('compressor_power'))),
              DataColumn(label: Text(loc.tr('compressor_pressure'))),
              DataColumn(label: Text(loc.tr('compressor_productivity'))),
              const DataColumn(label: Text('')),
            ],
            rows: templates
                .map((t) => _buildRow(context, t))
                .toList(),
          ),
        ),
      ),
    );
  }

  DataRow _buildRow(BuildContext context, CompressorTemplate t) {
    final loc = AppLocalizations.of(context);

    return DataRow(
      cells: [
        DataCell(Text(t.name, style: const TextStyle(fontWeight: FontWeight.w600))),
        DataCell(Text(t.compressorName)),
        DataCell(Text('${_fmt(t.powerKwt)} ${loc.tr('unit_kwt')}')),
        DataCell(Text('${_fmt(t.pressureBar)} ${loc.tr('unit_bar')}')),
        DataCell(Text('${_fmt(t.productivityLMin)} ${loc.tr('unit_l_min')}')),
        DataCell(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                tooltip: loc.tr('compressor_templates_edit'),
                icon: const Icon(Icons.edit_rounded, size: 18),
                color: AppColors.primary,
                onPressed: () => onEdit(t),
              ),
              IconButton(
                tooltip: loc.tr('compressor_templates_delete'),
                icon: const Icon(Icons.delete_outline_rounded, size: 18),
                color: AppColors.error,
                onPressed: () => onDelete(t),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _fmt(double v) {
    if (v == v.truncateToDouble()) return v.toInt().toString();
    return v.toStringAsFixed(2);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Диалог создания / редактирования шаблона
// ─────────────────────────────────────────────────────────────────────────────

class _TemplateDialog extends StatefulWidget {
  final CompressorTemplate? template;
  final Future<void> Function(CompressorTemplate) onSave;

  const _TemplateDialog({required this.onSave, this.template});

  @override
  State<_TemplateDialog> createState() => _TemplateDialogState();
}

class _TemplateDialogState extends State<_TemplateDialog> {
  final _formKey = GlobalKey<FormState>();
  bool _saving = false;

  late final TextEditingController _tplNameCtrl;
  late final TextEditingController _nameCtrl;
  late final TextEditingController _powerCtrl;
  late final TextEditingController _voltageCtrl;
  late final TextEditingController _currentCtrl;
  late final TextEditingController _speedCtrl;
  late final TextEditingController _freqCtrl;
  late final TextEditingController _productivityCtrl;
  late final TextEditingController _pressureCtrl;
  late final TextEditingController _holdTimeCtrl;
  late final TextEditingController _receiverCtrl;

  @override
  void initState() {
    super.initState();
    final t = widget.template;
    _tplNameCtrl     = TextEditingController(text: t?.name ?? '');
    _nameCtrl        = TextEditingController(text: t?.compressorName ?? '');
    _powerCtrl       = TextEditingController(text: t != null ? _fmt(t.powerKwt) : '');
    _voltageCtrl     = TextEditingController(text: t != null ? _fmt(t.voltageV) : '');
    _currentCtrl     = TextEditingController(text: t != null ? _fmt(t.currentA) : '');
    _speedCtrl       = TextEditingController(text: t != null ? _fmt(t.speedRpm) : '');
    _freqCtrl        = TextEditingController(text: t != null ? _fmt(t.frequencyHz) : '');
    _productivityCtrl = TextEditingController(text: t != null ? _fmt(t.productivityLMin) : '');
    _pressureCtrl    = TextEditingController(text: t != null ? _fmt(t.pressureBar) : '');
    _holdTimeCtrl    = TextEditingController(
        text: t != null && t.holdTimeMin > 0 ? _fmt(t.holdTimeMin) : '');
    _receiverCtrl    = TextEditingController(text: t != null ? _fmt(t.receiverVolumeL) : '');
  }

  @override
  void dispose() {
    _tplNameCtrl.dispose();
    _nameCtrl.dispose();
    _powerCtrl.dispose();
    _voltageCtrl.dispose();
    _currentCtrl.dispose();
    _speedCtrl.dispose();
    _freqCtrl.dispose();
    _productivityCtrl.dispose();
    _pressureCtrl.dispose();
    _holdTimeCtrl.dispose();
    _receiverCtrl.dispose();
    super.dispose();
  }

  String _fmt(double v) {
    if (v == v.truncateToDouble()) return v.toInt().toString();
    return v.toString();
  }

  double? _parsePositive(String v) {
    final d = double.tryParse(v.trim().replaceAll(',', '.'));
    return (d != null && d > 0) ? d : null;
  }

  double _parseHoldTime(String v) {
    if (v.trim().isEmpty) return 0;
    return double.tryParse(v.trim().replaceAll(',', '.')) ?? 0;
  }

  String? _reqPositive(String? v, AppLocalizations loc) {
    if (v == null || v.trim().isEmpty) return loc.tr('compressor_params_required');
    if (_parsePositive(v) == null) return loc.tr('compressor_params_negative_error');
    return null;
  }

  String? _reqNonNeg(String? v, AppLocalizations loc) {
    if (v == null || v.trim().isEmpty) return null;
    final d = double.tryParse(v.trim().replaceAll(',', '.'));
    if (d == null || d < 0) return loc.tr('compressor_params_negative_error');
    return null;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final now = DateTime.now();
    final draft = CompressorTemplate(
      name: _tplNameCtrl.text.trim(),
      compressorName: _nameCtrl.text.trim(),
      powerKwt: _parsePositive(_powerCtrl.text)!,
      voltageV: _parsePositive(_voltageCtrl.text)!,
      currentA: _parsePositive(_currentCtrl.text)!,
      speedRpm: _parsePositive(_speedCtrl.text)!,
      frequencyHz: _parsePositive(_freqCtrl.text)!,
      productivityLMin: _parsePositive(_productivityCtrl.text)!,
      pressureBar: _parsePositive(_pressureCtrl.text)!,
      holdTimeMin: _parseHoldTime(_holdTimeCtrl.text),
      receiverVolumeL: _parsePositive(_receiverCtrl.text)!,
      createdAt: now,
      updatedAt: now,
    );

    try {
      await widget.onSave(draft);
      if (mounted) {
        final loc = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.template == null
                  ? loc.tr('compressor_templates_created')
                  : loc.tr('compressor_templates_updated'),
            ),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc   = AppLocalizations.of(context);
    final isNew = widget.template == null;

    return AlertDialog(
      title: Text(
        isNew
            ? loc.tr('compressor_templates_create')
            : loc.tr('compressor_templates_edit'),
      ),
      content: SizedBox(
        width: 520,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _DialogField(
                  label: loc.tr('compressor_templates_name'),
                  controller: _tplNameCtrl,
                  maxLength: 100,
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? loc.tr('compressor_params_required')
                      : null,
                ),
                _gap,
                _DialogField(
                  label: loc.tr('compressor_name'),
                  controller: _nameCtrl,
                  maxLength: 200,
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? loc.tr('compressor_params_required')
                      : null,
                ),
                _gap,
                Row(
                  children: [
                    Expanded(
                      child: _NumField(
                        label: '${loc.tr('compressor_power')} (${loc.tr('unit_kwt')})',
                        controller: _powerCtrl,
                        validator: (v) => _reqPositive(v, loc),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _NumField(
                        label: '${loc.tr('compressor_voltage')} (${loc.tr('unit_v')})',
                        controller: _voltageCtrl,
                        validator: (v) => _reqPositive(v, loc),
                      ),
                    ),
                  ],
                ),
                _gap,
                Row(
                  children: [
                    Expanded(
                      child: _NumField(
                        label: '${loc.tr('compressor_current')} (${loc.tr('unit_a')})',
                        controller: _currentCtrl,
                        validator: (v) => _reqPositive(v, loc),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _NumField(
                        label: '${loc.tr('compressor_speed')} (${loc.tr('unit_rpm')})',
                        controller: _speedCtrl,
                        validator: (v) => _reqPositive(v, loc),
                      ),
                    ),
                  ],
                ),
                _gap,
                _NumField(
                  label: '${loc.tr('compressor_frequency')} (${loc.tr('unit_hz')})',
                  controller: _freqCtrl,
                  validator: (v) => _reqPositive(v, loc),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Divider(),
                ),
                Row(
                  children: [
                    Expanded(
                      child: _NumField(
                        label:
                            '${loc.tr('compressor_productivity')} (${loc.tr('unit_l_min')})',
                        controller: _productivityCtrl,
                        validator: (v) => _reqPositive(v, loc),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _NumField(
                        label:
                            '${loc.tr('compressor_pressure')} (${loc.tr('unit_bar')})',
                        controller: _pressureCtrl,
                        validator: (v) => _reqPositive(v, loc),
                      ),
                    ),
                  ],
                ),
                _gap,
                Row(
                  children: [
                    Expanded(
                      child: _NumField(
                        label:
                            '${loc.tr('compressor_hold_time')} (${loc.tr('unit_min')})',
                        controller: _holdTimeCtrl,
                        hintText: '0',
                        validator: (v) => _reqNonNeg(v, loc),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _NumField(
                        label:
                            '${loc.tr('compressor_receiver_volume')} (${loc.tr('unit_l')})',
                        controller: _receiverCtrl,
                        validator: (v) => _reqPositive(v, loc),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context, false),
          child: Text(loc.tr('compressor_templates_cancel')),
        ),
        FilledButton(
          onPressed: _saving ? null : _submit,
          child: _saving
              ? const SizedBox(
                  height: 16,
                  width: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Text(loc.tr('compressor_templates_save')),
        ),
      ],
    );
  }

  static const _gap = SizedBox(height: 12);
}

// ─────────────────────────────────────────────────────────────────────────────
//  Вспомогательные виджеты диалога
// ─────────────────────────────────────────────────────────────────────────────

class _DialogField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final int? maxLength;
  final String? Function(String?)? validator;

  const _DialogField({
    required this.label,
    required this.controller,
    this.maxLength,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      maxLength: maxLength,
      decoration: InputDecoration(
        labelText: label,
        counterText: '',
      ),
      validator: validator,
    );
  }
}

class _NumField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String? Function(String?)? validator;
  final String? hintText;

  const _NumField({
    required this.label,
    required this.controller,
    this.validator,
    this.hintText,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(
        decimal: true,
        signed: false,
      ),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
      ],
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText,
      ),
      validator: validator,
    );
  }
}

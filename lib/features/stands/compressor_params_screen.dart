import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/constants/config.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/compressor_template.dart';
import '../../data/repositories/compressor_template_repository.dart';
import '../../shared/widgets/app_header.dart';

/// Экран ввода параметров теста компрессора — Стенд 5.
class CompressorParamsScreen extends StatefulWidget {
  const CompressorParamsScreen({super.key});

  @override
  State<CompressorParamsScreen> createState() => _CompressorParamsScreenState();
}

class _CompressorParamsScreenState extends State<CompressorParamsScreen> {
  final _repo = CompressorTemplateRepository();

  List<CompressorTemplate> _templates = [];
  bool _loadingTemplates = true;

  /// ID выбранного шаблона; null = «Без шаблона»
  int? _selectedTemplateId;

  final _nameCtrl         = TextEditingController();
  final _powerCtrl        = TextEditingController();
  final _voltageCtrl      = TextEditingController();
  final _currentCtrl      = TextEditingController();
  final _speedCtrl        = TextEditingController();
  final _freqCtrl         = TextEditingController();
  final _productivityCtrl = TextEditingController();
  final _pressureCtrl     = TextEditingController();
  final _holdTimeCtrl     = TextEditingController();
  final _receiverCtrl     = TextEditingController();

  String? _nameError;
  String? _powerError;
  String? _voltageError;
  String? _currentError;
  String? _speedError;
  String? _freqError;
  String? _productivityError;
  String? _pressureError;
  String? _holdTimeError;
  String? _receiverError;

  @override
  void initState() {
    super.initState();
    _loadTemplates();
  }

  @override
  void dispose() {
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

  Future<void> _loadTemplates() async {
    setState(() => _loadingTemplates = true);
    try {
      _templates = await _repo.getAll();
    } finally {
      if (mounted) setState(() => _loadingTemplates = false);
    }
  }

  // ── Парсинг и валидация ─────────────────────────────────────────────────

  double? _parsePositive(String value) {
    final v = double.tryParse(value.replaceAll(',', '.'));
    return (v != null && v > 0) ? v : null;
  }

  double? _parseNonNegative(String value) {
    if (value.trim().isEmpty) return 0;
    final v = double.tryParse(value.replaceAll(',', '.'));
    return (v != null && v >= 0) ? v : null;
  }

  String? _validatePositive(String value) {
    if (value.isEmpty) return null;
    return _parsePositive(value) == null ? 'negative' : null;
  }

  String? _validateNonNegative(String value) {
    if (value.isEmpty) return null;
    final v = double.tryParse(value.replaceAll(',', '.'));
    return (v == null || v < 0) ? 'negative' : null;
  }

  bool _fieldOk(String value) => _parsePositive(value) != null;
  bool _holdOk(String value) => _parseNonNegative(value) != null;

  bool get _isFormValid {
    final nameOk = _nameCtrl.text.trim().isNotEmpty &&
        _nameCtrl.text.trim().length <= 200 &&
        _nameError == null;
    return nameOk &&
        _powerError == null && _fieldOk(_powerCtrl.text) &&
        _voltageError == null && _fieldOk(_voltageCtrl.text) &&
        _currentError == null && _fieldOk(_currentCtrl.text) &&
        _speedError == null && _fieldOk(_speedCtrl.text) &&
        _freqError == null && _fieldOk(_freqCtrl.text) &&
        _productivityError == null && _fieldOk(_productivityCtrl.text) &&
        _pressureError == null && _fieldOk(_pressureCtrl.text) &&
        _holdTimeError == null && _holdOk(_holdTimeCtrl.text) &&
        _receiverError == null && _fieldOk(_receiverCtrl.text);
  }

  String _errorText(String? code, AppLocalizations loc) {
    return switch (code) {
      'negative' => loc.tr('compressor_params_negative_error'),
      'required' => loc.tr('compressor_params_required'),
      'too_long' => loc.tr('compressor_params_name_too_long'),
      _ => loc.tr('compressor_params_required'),
    };
  }

  // ── Смена шаблона ───────────────────────────────────────────────────────

  void _onTemplateChanged(int? templateId) {
    if (templateId == null) {
      setState(() => _selectedTemplateId = null);
      return;
    }
    final t = _templates.firstWhere((t) => t.id == templateId);
    setState(() {
      _selectedTemplateId = templateId;
      _nameCtrl.text = t.compressorName;
      _powerCtrl.text = _fmt(t.powerKwt);
      _voltageCtrl.text = _fmt(t.voltageV);
      _currentCtrl.text = _fmt(t.currentA);
      _speedCtrl.text = _fmt(t.speedRpm);
      _freqCtrl.text = _fmt(t.frequencyHz);
      _productivityCtrl.text = _fmt(t.productivityLMin);
      _pressureCtrl.text = _fmt(t.pressureBar);
      _holdTimeCtrl.text = t.holdTimeMin == 0 ? '' : _fmt(t.holdTimeMin);
      _receiverCtrl.text = _fmt(t.receiverVolumeL);
      // Сбрасываем ошибки после заполнения из шаблона
      _nameError = null;
      _powerError = null;
      _voltageError = null;
      _currentError = null;
      _speedError = null;
      _freqError = null;
      _productivityError = null;
      _pressureError = null;
      _holdTimeError = null;
      _receiverError = null;
    });
  }

  /// Вызывается при любом ручном изменении поля — сбрасывает выбор шаблона
  void _deselectTemplate() {
    if (_selectedTemplateId != null) {
      setState(() => _selectedTemplateId = null);
    }
  }

  String _fmt(double v) {
    if (v == v.truncateToDouble()) return v.toInt().toString();
    return v.toString();
  }

  // ── Пуск теста ──────────────────────────────────────────────────────────

  void _onStart() {
    // TODO: запустить тест компрессора (модуль в разработке)
    final loc = AppLocalizations.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(loc.tr('stand_coming_soon')),
        backgroundColor: AppColors.primary,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc    = AppLocalizations.of(context);
    final primary = AppColors.primary;
    final isDark  = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: const AppHeader(showBackButton: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(
          horizontal: kPaddingLarge * 2,
          vertical: kPaddingLarge,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // ── Заголовок ──────────────────────────────────────────────
            Text(
              loc.tr('compressor_test_title'),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 44,
                  ),
            )
                .animate()
                .fadeIn(duration: 300.ms)
                .slideY(begin: -0.12, end: 0),

            const SizedBox(height: kPaddingLarge * 2),

            // ── Карточка формы ─────────────────────────────────────────
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: _FormCard(
                  isDark: isDark,
                  primary: primary,
                  child: _loadingTemplates
                      ? const Center(
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 48),
                            child: CircularProgressIndicator(),
                          ),
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Выбор шаблона
                            _TemplateDropdown(
                              templates: _templates,
                              selectedId: _selectedTemplateId,
                              onChanged: _onTemplateChanged,
                              label: loc.tr('compressor_template'),
                              noTemplateName: loc.tr('compressor_no_template'),
                              animDelay: 80,
                            ),

                            const SizedBox(height: kPadding * 1.5),

                            // Название компрессора
                            _NameField(
                              label: loc.tr('compressor_name'),
                              controller: _nameCtrl,
                              errorText: _nameError != null
                                  ? _errorText(_nameError, loc)
                                  : null,
                              onChanged: (v) {
                                _deselectTemplate();
                                setState(() {
                                  if (v.trim().isEmpty) {
                                    _nameError = 'required';
                                  } else if (v.trim().length > 200) {
                                    _nameError = 'too_long';
                                  } else {
                                    _nameError = null;
                                  }
                                });
                              },
                              animDelay: 150,
                            ),

                            const SizedBox(height: kPadding * 1.5),

                            _ParamField(
                              label: loc.tr('compressor_power'),
                              unit: loc.tr('unit_kwt'),
                              controller: _powerCtrl,
                              errorText: _powerError != null
                                  ? _errorText(_powerError, loc)
                                  : null,
                              onChanged: (v) {
                                _deselectTemplate();
                                setState(() => _powerError = _validatePositive(v));
                              },
                              animDelay: 220,
                            ),

                            const SizedBox(height: kPadding * 1.5),

                            _ParamField(
                              label: loc.tr('compressor_voltage'),
                              unit: loc.tr('unit_v'),
                              controller: _voltageCtrl,
                              errorText: _voltageError != null
                                  ? _errorText(_voltageError, loc)
                                  : null,
                              onChanged: (v) {
                                _deselectTemplate();
                                setState(() => _voltageError = _validatePositive(v));
                              },
                              animDelay: 290,
                            ),

                            const SizedBox(height: kPadding * 1.5),

                            _ParamField(
                              label: loc.tr('compressor_current'),
                              unit: loc.tr('unit_a'),
                              controller: _currentCtrl,
                              errorText: _currentError != null
                                  ? _errorText(_currentError, loc)
                                  : null,
                              onChanged: (v) {
                                _deselectTemplate();
                                setState(() => _currentError = _validatePositive(v));
                              },
                              animDelay: 360,
                            ),

                            const SizedBox(height: kPadding * 1.5),

                            _ParamField(
                              label: loc.tr('compressor_speed'),
                              unit: loc.tr('unit_rpm'),
                              controller: _speedCtrl,
                              errorText: _speedError != null
                                  ? _errorText(_speedError, loc)
                                  : null,
                              onChanged: (v) {
                                _deselectTemplate();
                                setState(() => _speedError = _validatePositive(v));
                              },
                              animDelay: 430,
                            ),

                            const SizedBox(height: kPadding * 1.5),

                            _ParamField(
                              label: loc.tr('compressor_frequency'),
                              unit: loc.tr('unit_hz'),
                              controller: _freqCtrl,
                              errorText: _freqError != null
                                  ? _errorText(_freqError, loc)
                                  : null,
                              onChanged: (v) {
                                _deselectTemplate();
                                setState(() => _freqError = _validatePositive(v));
                              },
                              animDelay: 500,
                            ),

                            const SizedBox(height: kPaddingLarge),

                            // Разделитель между блоками
                            _FieldDivider(primary: primary, animDelay: 560),

                            const SizedBox(height: kPaddingLarge),

                            _ParamField(
                              label: loc.tr('compressor_productivity'),
                              unit: loc.tr('unit_l_min'),
                              controller: _productivityCtrl,
                              errorText: _productivityError != null
                                  ? _errorText(_productivityError, loc)
                                  : null,
                              onChanged: (v) {
                                _deselectTemplate();
                                setState(() => _productivityError = _validatePositive(v));
                              },
                              animDelay: 580,
                            ),

                            const SizedBox(height: kPadding * 1.5),

                            _ParamField(
                              label: loc.tr('compressor_pressure'),
                              unit: loc.tr('unit_bar'),
                              controller: _pressureCtrl,
                              errorText: _pressureError != null
                                  ? _errorText(_pressureError, loc)
                                  : null,
                              onChanged: (v) {
                                _deselectTemplate();
                                setState(() => _pressureError = _validatePositive(v));
                              },
                              animDelay: 640,
                            ),

                            const SizedBox(height: kPadding * 1.5),

                            _ParamField(
                              label: loc.tr('compressor_hold_time'),
                              unit: loc.tr('unit_min'),
                              controller: _holdTimeCtrl,
                              errorText: _holdTimeError != null
                                  ? _errorText(_holdTimeError, loc)
                                  : null,
                              onChanged: (v) {
                                _deselectTemplate();
                                setState(() => _holdTimeError = _validateNonNegative(v));
                              },
                              animDelay: 700,
                              isOptional: true,
                            ),

                            const SizedBox(height: kPadding * 1.5),

                            _ParamField(
                              label: loc.tr('compressor_receiver_volume'),
                              unit: loc.tr('unit_l'),
                              controller: _receiverCtrl,
                              errorText: _receiverError != null
                                  ? _errorText(_receiverError, loc)
                                  : null,
                              onChanged: (v) {
                                _deselectTemplate();
                                setState(() => _receiverError = _validatePositive(v));
                              },
                              animDelay: 760,
                            ),

                            const SizedBox(height: kPaddingLarge * 1.5),

                            // ── Кнопка «Пуск» ──────────────────────────
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 250),
                              child: ElevatedButton(
                                onPressed: _isFormValid ? _onStart : null,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: primary,
                                  foregroundColor: Colors.white,
                                  disabledBackgroundColor:
                                      primary.withValues(alpha: 0.25),
                                  disabledForegroundColor:
                                      Colors.white.withValues(alpha: 0.45),
                                  elevation: _isFormValid ? 6 : 0,
                                  shadowColor: primary.withValues(alpha: 0.45),
                                  padding: const EdgeInsets.symmetric(vertical: 18),
                                  shape: RoundedRectangleBorder(
                                    borderRadius:
                                        BorderRadius.circular(kButtonRadius),
                                  ),
                                ),
                                child: Text(
                                  loc.tr('compressor_start'),
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                              ),
                            )
                                .animate()
                                .fadeIn(delay: 820.ms, duration: 350.ms)
                                .slideY(begin: 0.12, end: 0),
                          ],
                        ),
                )
                    .animate()
                    .fadeIn(delay: 80.ms, duration: 400.ms)
                    .scale(
                      begin: const Offset(0.97, 0.97),
                      end: const Offset(1.0, 1.0),
                      delay: 80.ms,
                      duration: 400.ms,
                      curve: Curves.easeOut,
                    ),
              ),
            ),

            const SizedBox(height: kPaddingLarge * 2),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Выпадающий список шаблонов
// ─────────────────────────────────────────────────────────────────────────────

class _TemplateDropdown extends StatelessWidget {
  final List<CompressorTemplate> templates;
  final int? selectedId;
  final ValueChanged<int?> onChanged;
  final String label;
  final String noTemplateName;
  final int animDelay;

  const _TemplateDropdown({
    required this.templates,
    required this.selectedId,
    required this.onChanged,
    required this.label,
    required this.noTemplateName,
    required this.animDelay,
  });

  @override
  Widget build(BuildContext context) {
    final primary = AppColors.primary;
    final isDark  = Theme.of(context).brightness == Brightness.dark;
    final labelColor = isDark ? Colors.white70 : AppColors.lightOnBackground;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: labelColor,
              ),
        ),
        const SizedBox(height: 6),
        DropdownButtonFormField<int?>(
          // ignore: deprecated_member_use
          value: selectedId,
          isExpanded: true,
          dropdownColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
          decoration: InputDecoration(
            filled: true,
            fillColor: isDark
                ? Colors.white.withValues(alpha: 0.04)
                : Colors.black.withValues(alpha: 0.02),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: _border(primary, 0.2),
            enabledBorder: _border(primary, 0.22),
            focusedBorder: _border(primary, 1.0, width: 1.5),
          ),
          items: [
            DropdownMenuItem<int?>(
              value: null,
              child: Text(
                noTemplateName,
                style: TextStyle(
                  color: isDark
                      ? Colors.white54
                      : AppColors.lightOnBackground.withValues(alpha: 0.5),
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
            ...templates.map(
              (t) => DropdownMenuItem<int?>(
                value: t.id,
                child: Text(
                  t.name,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
          onChanged: onChanged,
        ),
      ],
    )
        .animate()
        .fadeIn(
          delay: Duration(milliseconds: animDelay),
          duration: 350.ms,
        )
        .slideY(begin: 0.1, end: 0, curve: Curves.easeOut);
  }

  OutlineInputBorder _border(Color color, double alpha, {double width = 1.0}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(
        color: color.withValues(alpha: alpha),
        width: width,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Текстовое поле (название компрессора)
// ─────────────────────────────────────────────────────────────────────────────

class _NameField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String? errorText;
  final void Function(String) onChanged;
  final int animDelay;

  const _NameField({
    required this.label,
    required this.controller,
    required this.onChanged,
    required this.animDelay,
    this.errorText,
  });

  @override
  Widget build(BuildContext context) {
    final primary  = AppColors.primary;
    final isDark   = Theme.of(context).brightness == Brightness.dark;
    final hasError = errorText != null && errorText!.isNotEmpty;

    final labelColor = isDark
        ? (hasError ? AppColors.error : Colors.white70)
        : (hasError ? AppColors.error : AppColors.lightOnBackground);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: labelColor,
              ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          onChanged: onChanged,
          maxLength: 200,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontSize: 16,
                color: isDark
                    ? AppColors.darkOnBackground
                    : AppColors.lightOnBackground,
              ),
          decoration: InputDecoration(
            filled: true,
            fillColor: isDark
                ? Colors.white.withValues(alpha: 0.04)
                : Colors.black.withValues(alpha: 0.02),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            counterText: '',
            border: _border(hasError ? AppColors.error : primary, 0.2),
            enabledBorder:
                _border(hasError ? AppColors.error : primary, 0.22),
            focusedBorder: _border(
              hasError ? AppColors.error : primary,
              hasError ? 0.8 : 1.0,
              width: 1.5,
            ),
          ),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          child: hasError
              ? Padding(
                  padding: const EdgeInsets.only(top: 5, left: 2),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline_rounded,
                          size: 14, color: AppColors.error),
                      const SizedBox(width: 4),
                      Text(errorText!,
                          style: const TextStyle(
                              color: AppColors.error,
                              fontSize: 12,
                              fontWeight: FontWeight.w500)),
                    ],
                  ),
                )
              : const SizedBox.shrink(),
        ),
      ],
    )
        .animate()
        .fadeIn(
          delay: Duration(milliseconds: animDelay),
          duration: 350.ms,
        )
        .slideY(begin: 0.1, end: 0, curve: Curves.easeOut);
  }

  OutlineInputBorder _border(Color color, double alpha, {double width = 1.0}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(
        color: color.withValues(alpha: alpha),
        width: width,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Числовое поле параметра
// ─────────────────────────────────────────────────────────────────────────────

class _ParamField extends StatelessWidget {
  final String label;
  final String unit;
  final TextEditingController controller;
  final String? errorText;
  final void Function(String) onChanged;
  final int animDelay;

  /// true — поле не обязательно (пустое = 0); отображается hint
  final bool isOptional;

  const _ParamField({
    required this.label,
    required this.unit,
    required this.controller,
    required this.onChanged,
    required this.animDelay,
    this.errorText,
    this.isOptional = false,
  });

  @override
  Widget build(BuildContext context) {
    final primary  = AppColors.primary;
    final isDark   = Theme.of(context).brightness == Brightness.dark;
    final hasError = errorText != null && errorText!.isNotEmpty;

    final labelColor = isDark
        ? (hasError ? AppColors.error : Colors.white70)
        : (hasError ? AppColors.error : AppColors.lightOnBackground);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: labelColor,
                ),
            children: [
              TextSpan(text: label),
              TextSpan(
                text: '  $unit',
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: labelColor.withValues(alpha: hasError ? 1.0 : 0.65),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          onChanged: onChanged,
          keyboardType: const TextInputType.numberWithOptions(
            decimal: true,
            signed: false,
          ),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
          ],
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontSize: 16,
                color: isDark
                    ? AppColors.darkOnBackground
                    : AppColors.lightOnBackground,
              ),
          decoration: InputDecoration(
            filled: true,
            fillColor: isDark
                ? Colors.white.withValues(alpha: 0.04)
                : Colors.black.withValues(alpha: 0.02),
            hintText: isOptional ? '0' : null,
            hintStyle: TextStyle(
              color: isDark ? Colors.white24 : Colors.black26,
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: _border(hasError ? AppColors.error : primary, 0.2),
            enabledBorder:
                _border(hasError ? AppColors.error : primary, 0.22),
            focusedBorder: _border(
              hasError ? AppColors.error : primary,
              hasError ? 0.8 : 1.0,
              width: 1.5,
            ),
          ),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          child: hasError
              ? Padding(
                  padding: const EdgeInsets.only(top: 5, left: 2),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline_rounded,
                          size: 14, color: AppColors.error),
                      const SizedBox(width: 4),
                      Text(errorText!,
                          style: const TextStyle(
                              color: AppColors.error,
                              fontSize: 12,
                              fontWeight: FontWeight.w500)),
                    ],
                  ),
                )
              : const SizedBox.shrink(),
        ),
      ],
    )
        .animate()
        .fadeIn(
          delay: Duration(milliseconds: animDelay),
          duration: 350.ms,
        )
        .slideY(begin: 0.1, end: 0, curve: Curves.easeOut);
  }

  OutlineInputBorder _border(Color color, double alpha, {double width = 1.0}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(
        color: color.withValues(alpha: alpha),
        width: width,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Разделительная линия между блоками полей
// ─────────────────────────────────────────────────────────────────────────────

class _FieldDivider extends StatelessWidget {
  final Color primary;
  final int animDelay;

  const _FieldDivider({required this.primary, required this.animDelay});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 1,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.transparent,
            primary.withValues(alpha: 0.35),
            Colors.transparent,
          ],
        ),
      ),
    )
        .animate()
        .fadeIn(delay: Duration(milliseconds: animDelay), duration: 400.ms);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Карточка-обёртка формы
// ─────────────────────────────────────────────────────────────────────────────

class _FormCard extends StatelessWidget {
  final bool isDark;
  final Color primary;
  final Widget child;

  const _FormCard({
    required this.isDark,
    required this.primary,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(kCardRadius + 4),
        border: Border.all(color: primary.withValues(alpha: 0.12)),
        boxShadow: [
          BoxShadow(
            color: primary.withValues(alpha: 0.08),
            blurRadius: 40,
            offset: const Offset(0, 12),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(kPaddingLarge * 1.5),
      child: child,
    );
  }
}

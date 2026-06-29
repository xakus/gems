import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/theme/app_colors.dart';
import '../../core/constants/config.dart';
import '../../data/models/motor_params.dart';
import '../../data/models/test_run.dart';
import '../../shared/widgets/app_header.dart';

/// Экран ввода параметров двигателя — режим «Без нагрузки».
/// [standId] — номер стенда (для записи запуска теста).
/// [maxPowerKwt] — максимально допустимая мощность конкретного стенда.
/// [standTitleKey] — ключ локализации названия стенда.
class MotorParamsUnloadedScreen extends StatefulWidget {
  final int standId;
  final double maxPowerKwt;
  final String standTitleKey;

  const MotorParamsUnloadedScreen({
    super.key,
    required this.standId,
    required this.maxPowerKwt,
    required this.standTitleKey,
  });

  @override
  State<MotorParamsUnloadedScreen> createState() =>
      _MotorParamsUnloadedScreenState();
}

class _MotorParamsUnloadedScreenState extends State<MotorParamsUnloadedScreen> {
  final _powerCtrl = TextEditingController();
  final _voltageCtrl = TextEditingController();
  final _currentCtrl = TextEditingController();
  final _speedCtrl = TextEditingController();
  final _freqCtrl = TextEditingController();

  String? _powerError;
  String? _voltageError;
  String? _currentError;
  String? _speedError;
  String? _freqError;

  @override
  void dispose() {
    _powerCtrl.dispose();
    _voltageCtrl.dispose();
    _currentCtrl.dispose();
    _speedCtrl.dispose();
    _freqCtrl.dispose();
    super.dispose();
  }

  // Парсит строку в double > 0, возвращает null если невалидно
  double? _parsePositive(String value) {
    final v = double.tryParse(value.replaceAll(',', '.'));
    return (v != null && v > 0) ? v : null;
  }

  // Базовая валидация: только если непустое и некорректное — возвращает код ошибки
  String? _validatePositive(String value) {
    if (value.isEmpty) return null;
    return _parsePositive(value) == null ? 'negative' : null;
  }

  void _onPowerChanged(String value) {
    String? err = _validatePositive(value);
    if (err == null && value.isNotEmpty) {
      final v = _parsePositive(value)!;
      if (v > widget.maxPowerKwt) err = 'exceeded';
    }
    setState(() => _powerError = err);
  }

  bool _fieldOk(String value) => _parsePositive(value) != null;

  bool get _isFormValid =>
      _powerError == null &&
      _fieldOk(_powerCtrl.text) &&
      _voltageError == null &&
      _fieldOk(_voltageCtrl.text) &&
      _currentError == null &&
      _fieldOk(_currentCtrl.text) &&
      _speedError == null &&
      _fieldOk(_speedCtrl.text) &&
      _freqError == null &&
      _fieldOk(_freqCtrl.text);

  // Запускает тест: собирает параметры и переходит в окно тестирования.
  // [simulateFailure] — отладочная авария фазы 1 (спрятанный режим проверки).
  void _startTest({TestStatus? simulateFailure}) {
    final params = MotorParams(
      powerKwt: _parsePositive(_powerCtrl.text)!,
      voltageV: _parsePositive(_voltageCtrl.text)!,
      currentA: _parsePositive(_currentCtrl.text)!,
      speedRpm: _parsePositive(_speedCtrl.text)!,
      frequencyHz: _parsePositive(_freqCtrl.text)!,
    );
    Navigator.pushNamed(
      context,
      kRouteStandUnloadedTest,
      arguments: {
        'params': params,
        'standId': widget.standId,
        'simulateFailure': ?simulateFailure,
      },
    );
  }

  // Спрятанный режим проверки аварий: долгое нажатие на «Старт» запускает тест
  // со случайной неисправностью фазы 1 (КЗ/обрыв/пробой/КЗ на корпус).
  void _startFailureTest() {
    if (!_isFormValid) return;
    const failures = [
      TestStatus.failedInterturn,
      TestStatus.failedBreak,
      TestStatus.failedHvBreakdown,
      TestStatus.failedGround,
    ];
    final failure = failures[Random().nextInt(failures.length)];
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          AppLocalizations.of(context).tr('test_debug_failure_mode'),
        ),
        duration: const Duration(seconds: 1),
      ),
    );
    _startTest(simulateFailure: failure);
  }

  String _errorText(String? code, AppLocalizations loc, {double? max}) {
    return switch (code) {
      'exceeded' =>
        loc
            .tr('motor_params_power_exceeded')
            .replaceAll(
              '{max}',
              (max ?? widget.maxPowerKwt).toStringAsFixed(0),
            ),
      'negative' => loc.tr('motor_params_negative_error'),
      _ => loc.tr('motor_params_required'),
    };
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final primary = AppColors.primary;
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
            // ── Заголовок ────────────────────────────────────────
            Text(
              '${loc.tr(widget.standTitleKey)} — ${loc.tr('stand_test_unloaded')}',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: primary,
                fontWeight: FontWeight.bold,
                fontSize: 48,
              ),
            ).animate().fadeIn(duration: 300.ms).slideY(begin: -0.12, end: 0),

            const SizedBox(height: kPaddingLarge * 2),

            // ── Карточка с формой ────────────────────────────────
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child:
                    _FormCard(
                          isDark: isDark,
                          primary: primary,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Мощность кВт
                              _ParamField(
                                label: loc.tr('motor_params_power'),
                                unit: loc.tr('unit_kwt'),
                                controller: _powerCtrl,
                                errorText: _powerError != null
                                    ? _errorText(
                                        _powerError,
                                        loc,
                                        max: widget.maxPowerKwt,
                                      )
                                    : null,
                                onChanged: _onPowerChanged,
                                animDelay: 150,
                              ),

                              const SizedBox(height: kPadding * 1.5),

                              // Напряжение В
                              _ParamField(
                                label: loc.tr('motor_params_voltage'),
                                unit: loc.tr('unit_v'),
                                controller: _voltageCtrl,
                                errorText: _voltageError != null
                                    ? _errorText(_voltageError, loc)
                                    : null,
                                onChanged: (v) => setState(() {
                                  _voltageError = _validatePositive(v);
                                }),
                                animDelay: 250,
                              ),

                              const SizedBox(height: kPadding * 1.5),

                              // Ток А
                              _ParamField(
                                label: loc.tr('motor_params_current'),
                                unit: loc.tr('unit_a'),
                                controller: _currentCtrl,
                                errorText: _currentError != null
                                    ? _errorText(_currentError, loc)
                                    : null,
                                onChanged: (v) => setState(() {
                                  _currentError = _validatePositive(v);
                                }),
                                animDelay: 350,
                              ),

                              const SizedBox(height: kPadding * 1.5),

                              // Скорость вращения об/мин
                              _ParamField(
                                label: loc.tr('motor_params_speed'),
                                unit: loc.tr('unit_rpm'),
                                controller: _speedCtrl,
                                errorText: _speedError != null
                                    ? _errorText(_speedError, loc)
                                    : null,
                                onChanged: (v) => setState(() {
                                  _speedError = _validatePositive(v);
                                }),
                                animDelay: 450,
                              ),

                              const SizedBox(height: kPadding * 1.5),

                              // Частота Гц
                              _ParamField(
                                label: loc.tr('motor_params_frequency'),
                                unit: loc.tr('unit_hz'),
                                controller: _freqCtrl,
                                errorText: _freqError != null
                                    ? _errorText(_freqError, loc)
                                    : null,
                                onChanged: (v) => setState(() {
                                  _freqError = _validatePositive(v);
                                }),
                                animDelay: 550,
                              ),

                              const SizedBox(height: kPaddingLarge * 1.5),

                              // ── Кнопка «Старт» ──────────────────────────
                              // Долгое нажатие — спрятанный режим проверки аварий
                              AnimatedContainer(
                                    duration: const Duration(milliseconds: 250),
                                    child: GestureDetector(
                                      onLongPress: _isFormValid
                                          ? _startFailureTest
                                          : null,
                                      child: ElevatedButton(
                                        onPressed: _isFormValid
                                            ? () => _startTest()
                                            : null,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: primary,
                                          foregroundColor: Colors.white,
                                          disabledBackgroundColor: primary
                                              .withValues(alpha: 0.25),
                                          disabledForegroundColor: Colors.white
                                              .withValues(alpha: 0.45),
                                          elevation: _isFormValid ? 6 : 0,
                                          shadowColor: primary.withValues(
                                            alpha: 0.45,
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 16,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              kButtonRadius,
                                            ),
                                          ),
                                        ),
                                        child: Text(
                                          loc.tr('motor_params_start'),
                                          style: const TextStyle(
                                            fontSize: 17,
                                            fontWeight: FontWeight.w700,
                                            letterSpacing: 0.8,
                                          ),
                                        ),
                                      ),
                                    ),
                                  )
                                  .animate()
                                  .fadeIn(delay: 650.ms, duration: 350.ms)
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
//  Карточка-обёртка для формы
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

// ─────────────────────────────────────────────────────────────────────────────
//  Поле ввода параметра
// ─────────────────────────────────────────────────────────────────────────────

/// Поле ввода с меткой, единицей измерения и анимацией появления.
class _ParamField extends StatelessWidget {
  final String label;
  final String unit;
  final TextEditingController controller;
  final String? errorText;
  final void Function(String) onChanged;
  final int animDelay;

  const _ParamField({
    required this.label,
    required this.unit,
    required this.controller,
    required this.onChanged,
    required this.animDelay,
    this.errorText,
  });

  @override
  Widget build(BuildContext context) {
    final primary = AppColors.primary;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hasError = errorText != null && errorText!.isNotEmpty;

    final labelColor = isDark
        ? (hasError ? AppColors.error : Colors.white70)
        : (hasError ? AppColors.error : AppColors.lightOnBackground);

    return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Метка: «Мощность» + единица «кВт» — единый стиль, одинаковый размер
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
                      color: labelColor.withValues(
                        alpha: hasError ? 1.0 : 0.65,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 6),

            // Поле ввода (только числа > 0)
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
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                border: _border(hasError ? AppColors.error : primary, 0.2),
                enabledBorder: _border(
                  hasError ? AppColors.error : primary,
                  0.22,
                ),
                focusedBorder: _border(
                  hasError ? AppColors.error : primary,
                  hasError ? 0.8 : 1.0,
                  width: 1.5,
                ),
              ),
            ),

            // Сообщение об ошибке с анимацией
            AnimatedSize(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
              child: hasError
                  ? Padding(
                      padding: const EdgeInsets.only(top: 5, left: 2),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.error_outline_rounded,
                            size: 14,
                            color: AppColors.error,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            errorText!,
                            style: const TextStyle(
                              color: AppColors.error,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
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

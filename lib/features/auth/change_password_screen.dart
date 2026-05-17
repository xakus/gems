import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../core/constants/config.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/validators.dart';
import '../../shared/providers/auth_provider.dart';
import '../../shared/providers/theme_provider.dart';

/// Экран принудительной смены пароля (после первого входа)
class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _newPasswordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _newVisible = false;
  bool _confirmVisible = false;
  bool _loading = false;

  @override
  void dispose() {
    _newPasswordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    try {
      await context.read<AuthProvider>().changePassword(_newPasswordCtrl.text);
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, kRouteHome);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDark;
    final gradient =
        isDark ? AppColors.splashGradientDark : AppColors.splashGradientLight;

    final l10n = AppLocalizations.of(context);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: gradient),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: kFormMaxWidth),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(kPaddingLarge),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Иконка
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      gradient: AppColors.logoGradient,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.3),
                          blurRadius: 20,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.lock_reset_rounded,
                      color: Colors.white,
                      size: 36,
                    ),
                  ).animate().fadeIn(duration: 500.ms).scale(
                        begin: const Offset(0.7, 0.7),
                        curve: Curves.elasticOut,
                      ),

                  const SizedBox(height: 24),

                  Text(
                    l10n.tr('change_password_title'),
                    style: Theme.of(context).textTheme.headlineSmall,
                  ).animate(delay: 100.ms).fadeIn(),

                  const SizedBox(height: 8),

                  Text(
                    l10n.tr('change_password_subtitle'),
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: isDark
                              ? AppColors.darkSecondaryText
                              : AppColors.lightSecondaryText,
                        ),
                  ).animate(delay: 150.ms).fadeIn(),

                  const SizedBox(height: 32),

                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(kPaddingLarge),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Новый пароль
                            TextFormField(
                              controller: _newPasswordCtrl,
                              obscureText: !_newVisible,
                              decoration: InputDecoration(
                                labelText: l10n.tr('change_password_new'),
                                prefixIcon: const Icon(Icons.lock_outline),
                                suffixIcon: IconButton(
                                  icon: Icon(_newVisible
                                      ? Icons.visibility_off
                                      : Icons.visibility),
                                  onPressed: () =>
                                      setState(() => _newVisible = !_newVisible),
                                ),
                              ),
                              textInputAction: TextInputAction.next,
                              validator: Validators.password,
                              onChanged: (_) => setState(() {}),
                            ),

                            // Индикатор надёжности
                            if (_newPasswordCtrl.text.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              _PasswordStrengthBar(password: _newPasswordCtrl.text),
                            ],

                            const SizedBox(height: 16),

                            // Подтверждение
                            TextFormField(
                              controller: _confirmCtrl,
                              obscureText: !_confirmVisible,
                              decoration: InputDecoration(
                                labelText: l10n.tr('change_password_confirm'),
                                prefixIcon: const Icon(Icons.lock_outline),
                                suffixIcon: IconButton(
                                  icon: Icon(_confirmVisible
                                      ? Icons.visibility_off
                                      : Icons.visibility),
                                  onPressed: () => setState(
                                      () => _confirmVisible = !_confirmVisible),
                                ),
                              ),
                              textInputAction: TextInputAction.done,
                              validator: (v) => Validators.passwordConfirm(
                                  v, _newPasswordCtrl.text),
                              onFieldSubmitted: (_) => _submit(),
                            ),

                            const SizedBox(height: 12),

                            // Требования
                            _PasswordRequirements(
                              password: _newPasswordCtrl.text,
                            ),

                            const SizedBox(height: 24),

                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: _loading ? null : _submit,
                                child: _loading
                                    ? const SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : Text(l10n.tr('change_password_button')),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                      .animate(delay: 200.ms)
                      .fadeIn(duration: 400.ms)
                      .slideY(begin: 0.1, end: 0),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Индикатор надёжности пароля
class _PasswordStrengthBar extends StatelessWidget {
  final String password;
  const _PasswordStrengthBar({required this.password});

  int _strength() {
    int score = 0;
    if (password.length >= kPasswordMinLength) score++;
    if (password.length >= 12) score++;
    if (password.contains(RegExp(r'\d'))) score++;
    if (password.contains(RegExp(r'[A-Z]'))) score++;
    if (password.contains(RegExp(r'[!@#$%^&*]'))) score++;
    return score;
  }

  @override
  Widget build(BuildContext context) {
    final s = _strength();
    final color = s <= 1
        ? AppColors.error
        : s <= 2
            ? AppColors.warning
            : s <= 3
                ? AppColors.info
                : AppColors.success;
    final l10n = AppLocalizations.of(context);
    final label = s <= 1
        ? l10n.tr('password_strength_weak')
        : s <= 2
            ? l10n.tr('password_strength_fair')
            : s <= 3
                ? l10n.tr('password_strength_good')
                : l10n.tr('password_strength_strong');

    return Row(
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: s / 5,
              backgroundColor: Theme.of(context).dividerColor,
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 5,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(label, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600)),
      ],
    );
  }
}

/// Чеклист требований к паролю
class _PasswordRequirements extends StatelessWidget {
  final String password;
  const _PasswordRequirements({required this.password});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final hasLength = password.length >= kPasswordMinLength;
    final hasDigit = password.contains(RegExp(r'\d'));

    return Column(
      children: [
        _Req(
          met: hasLength,
          text: l10n.tr('validation_min_length', args: {'min': '$kPasswordMinLength'}),
        ),
        const SizedBox(height: 4),
        _Req(met: hasDigit, text: l10n.tr('validation_password_digit')),
      ],
    );
  }
}

class _Req extends StatelessWidget {
  final bool met;
  final String text;
  const _Req({required this.met, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          met ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
          size: 16,
          color: met ? AppColors.success : AppColors.lightSecondaryText,
        ),
        const SizedBox(width: 6),
        Text(
          text,
          style: TextStyle(
            fontSize: 12,
            color: met ? AppColors.success : AppColors.lightSecondaryText,
          ),
        ),
      ],
    );
  }
}

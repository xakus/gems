import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../core/constants/config.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/validators.dart';
import '../../data/services/auth_service.dart';
import '../../shared/providers/auth_provider.dart';
import '../../shared/providers/theme_provider.dart';
import '../../shared/widgets/language_switcher.dart';
import '../../shared/widgets/theme_switcher.dart';
import '../../shared/widgets/amotes_logo.dart';

/// Экран входа в систему
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _usernameCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _passwordVisible = false;
  bool _submitting = false;
  String? _errorMessage;

  late final AnimationController _shakeController;
  late final Animation<double> _shakeAnimation;

  Timer? _errorTimer;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 480),
      vsync: this,
    );
    // Серия сдвигов: имитация macOS shake — амплитуда затухает
    _shakeAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: -14.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -14.0, end: 14.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 14.0, end: -10.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -10.0, end: 10.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 10.0, end: -6.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -6.0, end: 6.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 6.0, end: 0.0), weight: 1),
    ]).animate(CurvedAnimation(parent: _shakeController, curve: Curves.linear));
  }

  @override
  void dispose() {
    _errorTimer?.cancel();
    _shakeController.dispose();
    _usernameCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  void _triggerShake() {
    _shakeController.forward(from: 0);
  }

  void _showError(String message) {
    _errorTimer?.cancel();
    setState(() => _errorMessage = message);
    _triggerShake();
    _errorTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) setState(() => _errorMessage = null);
    });
  }

  Future<void> _submit() async {
    if (_submitting) return;
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _submitting = true;
      _errorMessage = null;
    });

    final auth = context.read<AuthProvider>();
    final result = await auth.login(
      _usernameCtrl.text.trim(),
      _passwordCtrl.text,
    );

    if (!mounted) return;

    final l10n = AppLocalizations.of(context);

    switch (result) {
      case LoginResult.success:
        final user = auth.currentUser!;
        await context.read<ThemeProvider>().loadForUser(user.id!);
        if (!mounted) return;
        Navigator.pushReplacementNamed(
          context,
          user.mustChangePassword ? kRouteChangePassword : kRouteHome,
        );

      case LoginResult.invalidCredentials:
        setState(() => _submitting = false);
        _showError(l10n.tr('login_error_invalid'));

      case LoginResult.accountDisabled:
        setState(() => _submitting = false);
        _showError(l10n.tr('login_error_disabled'));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDark;
    final l10n = AppLocalizations.of(context);
    final gradient = isDark
        ? AppColors.splashGradientDark
        : AppColors.splashGradientLight;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: gradient),
        child: Stack(
          children: [
            _buildDecorCircle(
              top: -80,
              right: -80,
              size: 300,
              color: AppColors.primary.withValues(alpha: isDark ? 0.08 : 0.06),
            ),
            _buildDecorCircle(
              bottom: -60,
              left: -60,
              size: 200,
              color: AppColors.accent.withValues(alpha: isDark ? 0.06 : 0.05),
            ),

            // Переключатели в углу
            Positioned(
              top: kPaddingLarge,
              right: kPaddingLarge,
              child: const Row(
                children: [
                  LanguageSwitcher(),
                  SizedBox(width: 4),
                  ThemeSwitcher(),
                ],
              ),
            ),

            Column(
              children: [
                // Лого + AMOTES + подзаголовок (сверху, фиксированно)
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    kPaddingLarge,
                    kPaddingLarge,
                    kPaddingLarge,
                    0,
                  ),
                  child: Center(
                    child: Column(
                      children: [
                        Hero(tag: 'amotes_logo', child: AmotesLogo(size: 180)),
                        const SizedBox(height: 5),
                        Hero(
                          tag: 'amotes_title',
                          child: Material(
                            color: Colors.transparent,
                            child: Text(
                              kAppName,
                              style: TextStyle(
                                fontSize: 90,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 6,
                                foreground: Paint()
                                  ..shader = AppColors.logoGradient
                                      .createShader(
                                        const Rect.fromLTWH(0, 0, 220, 70),
                                      ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          l10n.tr('app_full_name'),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 18,
                            letterSpacing: 0.4,
                            color: isDark
                                ? AppColors.darkSecondaryText
                                : AppColors.lightSecondaryText,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // "Вход в систему" + форма — прижаты ближе к заголовку
                Expanded(
                  child: Align(
                    alignment: const Alignment(0, -0.2),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(
                        horizontal: kPaddingLarge,
                        vertical: kPaddingSmall,
                      ),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(
                          maxWidth: kFormMaxWidth,
                        ),
                        child: AnimatedBuilder(
                          animation: _shakeAnimation,
                          builder: (context, child) => Transform.translate(
                            offset: Offset(_shakeAnimation.value, 0),
                            child: child,
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                l10n.tr('login_title'),
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(
                                      color: isDark
                                          ? AppColors.darkSecondaryText
                                          : AppColors.lightSecondaryText,
                                    ),
                              ).animate(delay: 150.ms).fadeIn(),
                              const SizedBox(height: 16),
                              Card(
                                child: Padding(
                                  padding: const EdgeInsets.all(kPaddingLarge),
                                  child: Form(
                                    key: _formKey,
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      children: [
                                        TextFormField(
                                          controller: _usernameCtrl,
                                          decoration: InputDecoration(
                                            labelText: l10n.tr(
                                              'login_username',
                                            ),
                                            prefixIcon: const Icon(
                                              Icons.person_outline,
                                            ),
                                          ),
                                          textInputAction: TextInputAction.next,
                                          validator: Validators.username,
                                          onFieldSubmitted: (_) =>
                                              FocusScope.of(
                                                context,
                                              ).nextFocus(),
                                        ),

                                        const SizedBox(height: 16),

                                        TextFormField(
                                          controller: _passwordCtrl,
                                          obscureText: !_passwordVisible,
                                          decoration: InputDecoration(
                                            labelText: l10n.tr(
                                              'login_password',
                                            ),
                                            prefixIcon: const Icon(
                                              Icons.lock_outline,
                                            ),
                                            suffixIcon: IconButton(
                                              icon: Icon(
                                                _passwordVisible
                                                    ? Icons.visibility_off
                                                    : Icons.visibility,
                                              ),
                                              onPressed: () => setState(
                                                () => _passwordVisible =
                                                    !_passwordVisible,
                                              ),
                                            ),
                                          ),
                                          textInputAction: TextInputAction.done,
                                          validator: (v) =>
                                              (v == null || v.isEmpty)
                                              ? l10n.tr('validation_required')
                                              : null,
                                          onFieldSubmitted: (_) => _submit(),
                                        ),

                                        const SizedBox(height: 12),

                                        SizedBox(
                                          width: double.infinity,
                                          child: ElevatedButton(
                                            onPressed: _submitting
                                                ? null
                                                : _submit,
                                            child: _submitting
                                                ? const SizedBox(
                                                    height: 20,
                                                    width: 20,
                                                    child:
                                                        CircularProgressIndicator(
                                                          strokeWidth: 2,
                                                          color: Colors.white,
                                                        ),
                                                  )
                                                : Text(l10n.tr('login_button')),
                                          ),
                                        ),

                                        if (_errorMessage != null)
                                          Padding(
                                            padding: const EdgeInsets.only(
                                              top: 12,
                                            ),
                                            child: Row(
                                              children: [
                                                const Icon(
                                                  Icons.error_outline,
                                                  size: 16,
                                                  color: Colors.redAccent,
                                                ),
                                                const SizedBox(width: 6),
                                                Expanded(
                                                  child: Text(
                                                    _errorMessage!,
                                                    style: Theme.of(context)
                                                        .textTheme
                                                        .bodySmall
                                                        ?.copyWith(
                                                          color:
                                                              Colors.redAccent,
                                                        ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Декоративный круг в углу экрана
  Widget _buildDecorCircle({
    double? top,
    double? bottom,
    double? left,
    double? right,
    required double size,
    required Color color,
  }) {
    return Positioned(
      top: top,
      bottom: bottom,
      left: left,
      right: right,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(shape: BoxShape.circle, color: color),
      ),
    );
  }
}

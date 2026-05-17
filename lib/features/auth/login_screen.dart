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
import '../../shared/widgets/gems_logo.dart';

/// Экран входа в систему
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _passwordVisible = false;
  String? _errorMessage;

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _errorMessage = null);

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
        if (user.mustChangePassword) {
          Navigator.pushReplacementNamed(context, kRouteChangePassword);
        } else {
          Navigator.pushReplacementNamed(context, kRouteHome);
        }
      case LoginResult.accountDisabled:
        setState(() => _errorMessage = l10n.tr('login_error_disabled'));
      case LoginResult.invalidCredentials:
        setState(() => _errorMessage = l10n.tr('login_error_invalid'));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDark;
    final isLoading = context.watch<AuthProvider>().loading;
    final gradient =
        isDark ? AppColors.splashGradientDark : AppColors.splashGradientLight;

    final l10n = AppLocalizations.of(context);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: gradient),
        child: Stack(
          children: [
            // Декоративный круг в углу
            Positioned(
              top: -80,
              right: -80,
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primary.withValues(alpha: isDark ? 0.08 : 0.06),
                ),
              ),
            ),
            Positioned(
              bottom: -60,
              left: -60,
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.accent.withValues(alpha: isDark ? 0.06 : 0.05),
                ),
              ),
            ),

            // Переключатели в углу
            Positioned(
              top: kPaddingLarge,
              right: kPaddingLarge,
              child: Row(
                children: const [
                  LanguageSwitcher(),
                  SizedBox(width: 4),
                  ThemeSwitcher(),
                ],
              ),
            ),

            // Форма входа
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: kFormMaxWidth),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(kPaddingLarge),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Логотип
                      Hero(
                        tag: 'gems_logo',
                        child: GemsLogo(size: 72),
                      ).animate().fadeIn(duration: 500.ms).scale(
                            begin: const Offset(0.8, 0.8),
                            curve: Curves.easeOut,
                          ),

                      const SizedBox(height: 20),

                      // Заголовок
                      Hero(
                        tag: 'gems_title',
                        child: Material(
                          color: Colors.transparent,
                          child: Text(
                            kAppName,
                            style: TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 5,
                              foreground: Paint()
                                ..shader = AppColors.logoGradient
                                    .createShader(
                                      const Rect.fromLTWH(0, 0, 140, 50),
                                    ),
                            ),
                          ),
                        ),
                      ).animate(delay: 100.ms).fadeIn(),

                      const SizedBox(height: 8),

                      Text(
                        l10n.tr('login_title'),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: isDark
                                  ? AppColors.darkSecondaryText
                                  : AppColors.lightSecondaryText,
                            ),
                      ).animate(delay: 150.ms).fadeIn(),

                      const SizedBox(height: 36),

                      // Карточка формы
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(kPaddingLarge),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // Поле логина
                                TextFormField(
                                  controller: _usernameCtrl,
                                  decoration: InputDecoration(
                                    labelText: l10n.tr('login_username'),
                                    prefixIcon: const Icon(Icons.person_outline),
                                  ),
                                  textInputAction: TextInputAction.next,
                                  validator: Validators.username,
                                  onFieldSubmitted: (_) =>
                                      FocusScope.of(context).nextFocus(),
                                ),

                                const SizedBox(height: 16),

                                // Поле пароля
                                TextFormField(
                                  controller: _passwordCtrl,
                                  obscureText: !_passwordVisible,
                                  decoration: InputDecoration(
                                    labelText: l10n.tr('login_password'),
                                    prefixIcon: const Icon(Icons.lock_outline),
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
                                  validator: (v) => v == null || v.isEmpty
                                      ? l10n.tr('validation_required')
                                      : null,
                                  onFieldSubmitted: (_) => _submit(),
                                ),

                                // Сообщение об ошибке
                                if (_errorMessage != null) ...[
                                  const SizedBox(height: 12),
                                  _ErrorBanner(message: _errorMessage!),
                                ],

                                const SizedBox(height: 24),

                                // Кнопка входа
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    onPressed: isLoading ? null : _submit,
                                    child: isLoading
                                        ? const SizedBox(
                                            height: 20,
                                            width: 20,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Colors.white,
                                            ),
                                          )
                                        : Text(l10n.tr('login_button')),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      )
                          .animate(delay: 200.ms)
                          .fadeIn(duration: 400.ms)
                          .slideY(begin: 0.15, end: 0),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String message;
  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppColors.error, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: AppColors.error, fontSize: 13),
            ),
          ),
        ],
      ),
    ).animate().shake(duration: 300.ms, hz: 3);
  }
}

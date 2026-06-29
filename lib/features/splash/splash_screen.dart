import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../core/constants/config.dart';
import '../../core/database/database_helper.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/providers/theme_provider.dart';
import '../../shared/providers/locale_provider.dart';
import '../../shared/widgets/amotes_logo.dart';

/// Splash-экран с staggered-анимацией и параллельной инициализацией БД
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  String? _adminTempPassword;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    // Параллельная инициализация
    await Future.wait([
      _initDb(),
      context.read<ThemeProvider>().loadFromPrefs(),
      context.read<LocaleProvider>().loadFromPrefs(),
      Future.delayed(Duration(seconds: kSplashDurationSeconds)),
    ]);

    if (!mounted) return;

    if (_adminTempPassword != null) {
      _showAdminDialog(_adminTempPassword!);
    } else {
      Navigator.pushReplacementNamed(context, kRouteLogin);
    }
  }

  Future<void> _initDb() async {
    await DatabaseHelper.instance.database;
    final pass = await DatabaseHelper.instance.getAdminTempPassword();
    if (pass != null) {
      _adminTempPassword = pass;
    }
  }

  void _showAdminDialog(String password) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _AdminFirstRunDialog(
        password: password,
        onDismiss: () async {
          await DatabaseHelper.instance.clearAdminTempPassword();
          if (mounted) Navigator.pushReplacementNamed(context, kRouteLogin);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDark;
    final gradient = isDark
        ? AppColors.splashGradientDark
        : AppColors.splashGradientLight;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: gradient),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Логотип: .animate() внутри Hero — не мешает Hero flight
              Hero(
                tag: 'amotes_logo',
                child: AmotesLogo(size: 96)
                    .animate()
                    .fadeIn(
                      duration: Duration(
                        milliseconds: kSplashLogoFadeDurationMs,
                      ),
                      curve: Curves.easeOut,
                    )
                    .scale(
                      begin: const Offset(0.6, 0.6),
                      end: const Offset(1.0, 1.0),
                      duration: Duration(
                        milliseconds: kSplashLogoFadeDurationMs,
                      ),
                      curve: Curves.elasticOut,
                    ),
              ),

              const SizedBox(height: 28),

              // Название AMOTES: .animate() внутри Hero
              Hero(
                tag: 'amotes_title',
                child:
                    Material(
                          color: Colors.transparent,
                          child: Text(
                            kAppName,
                            style: Theme.of(context).textTheme.headlineLarge
                                ?.copyWith(
                                  fontSize: 52,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 6,
                                  foreground: Paint()
                                    ..shader =
                                        const LinearGradient(
                                          colors: [
                                            AppColors.primary,
                                            AppColors.accent,
                                          ],
                                        ).createShader(
                                          const Rect.fromLTWH(0, 0, 200, 60),
                                        ),
                                ),
                          ),
                        )
                        .animate(
                          delay: Duration(milliseconds: kSplashTitleDelayMs),
                        )
                        .fadeIn(
                          duration: Duration(
                            milliseconds: kSplashLogoFadeDurationMs,
                          ),
                          curve: Curves.easeOut,
                        )
                        .slideY(begin: 0.3, end: 0),
              ),

              const SizedBox(height: 12),

              // Подзаголовок (всегда на AZ)
              Text(
                    kAppFullName,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: isDark
                          ? AppColors.darkSecondaryText
                          : AppColors.lightSecondaryText,
                      letterSpacing: 0.3,
                    ),
                  )
                  .animate(
                    delay: Duration(milliseconds: kSplashSubtitleDelayMs),
                  )
                  .fadeIn(
                    duration: Duration(milliseconds: kSplashLogoFadeDurationMs),
                    curve: Curves.easeOut,
                  )
                  .slideY(begin: 0.3, end: 0),

              const SizedBox(height: 60),

              // Индикатор загрузки
              SizedBox(
                    width: 40,
                    height: 3,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(2),
                      child: LinearProgressIndicator(
                        backgroundColor:
                            (isDark
                                    ? AppColors.darkDivider
                                    : AppColors.lightDivider)
                                .withValues(alpha: 0.4),
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          AppColors.accent,
                        ),
                      ),
                    ),
                  )
                  .animate(
                    delay: Duration(milliseconds: kSplashSubtitleDelayMs + 200),
                  )
                  .fadeIn(duration: 400.ms),
            ],
          ),
        ),
      ),
    );
  }
}

/// Диалог первого запуска с временным паролем ADMIN
class _AdminFirstRunDialog extends StatelessWidget {
  final String password;
  final VoidCallback onDismiss;

  const _AdminFirstRunDialog({required this.password, required this.onDismiss});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          const Icon(Icons.admin_panel_settings, color: AppColors.primary),
          const SizedBox(width: 10),
          const Expanded(child: Text('Добро пожаловать в AMOTES')),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Создана учётная запись администратора.'),
          const SizedBox(height: 16),
          const Text('Логин:', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          _PasswordBox(text: kDefaultAdminUsername),
          const SizedBox(height: 12),
          const Text(
            'Временный пароль:',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          _PasswordBox(text: password),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.warning.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: AppColors.warning.withValues(alpha: 0.4),
              ),
            ),
            child: Row(
              children: const [
                Icon(
                  Icons.warning_amber_rounded,
                  color: AppColors.warning,
                  size: 18,
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Сохраните пароль — он больше не будет показан.',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        ElevatedButton(
          onPressed: onDismiss,
          child: const Text('Сохранил, продолжить'),
        ),
      ],
    );
  }
}

class _PasswordBox extends StatelessWidget {
  final String text;
  const _PasswordBox({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Row(
        children: [
          Expanded(
            child: SelectableText(
              text,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.copy, size: 18),
            onPressed: () {},
            tooltip: 'Скопировать',
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }
}

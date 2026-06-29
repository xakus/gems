import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/theme/app_colors.dart';
import '../../core/constants/config.dart';
import '../../shared/widgets/app_header.dart';

/// Экран стенда 1 — выбор режима тестирования (с нагрузкой / без нагрузки)
class Stand1Screen extends StatelessWidget {
  const Stand1Screen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      appBar: AppHeader(showBackButton: true),
      body: _Stand1Body(),
    );
  }
}

class _Stand1Body extends StatelessWidget {
  const _Stand1Body();

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final primary = AppColors.primary;

    return Padding(
      padding: const EdgeInsets.all(kPaddingLarge * 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Заголовок стенда
          Text(
            loc.tr('stand_1_title'),
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: primary,
              fontWeight: FontWeight.bold,
              fontSize: 56,
            ),
          ).animate().fadeIn(duration: 300.ms).slideY(begin: -0.1, end: 0),

          const SizedBox(height: kPaddingLarge * 2),

          // Две карточки режима теста (половина доступного пространства)
          Expanded(
            child: Center(
              child: FractionallySizedBox(
                widthFactor: 0.5,
                heightFactor: 0.5,
                child: Row(
                  children: [
                    Expanded(
                      child: _TestTypeCard(
                        image:
                            'assets/engin_test_type_image/small_engin_power.png',
                        label: loc.tr('stand_test_loaded'),
                        delay: 0,
                        onTap: () =>
                            Navigator.pushNamed(context, kRouteStand1Loaded),
                      ),
                    ),
                    const SizedBox(width: kPaddingLarge),
                    Expanded(
                      child: _TestTypeCard(
                        image:
                            'assets/engin_test_type_image/small_engin_free.png',
                        label: loc.tr('stand_test_unloaded'),
                        delay: 120,
                        onTap: () =>
                            Navigator.pushNamed(context, kRouteStand1Unloaded),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: kPaddingLarge * 2),
        ],
      ),
    );
  }
}

/// Карточка выбора типа теста
class _TestTypeCard extends StatefulWidget {
  final String image;
  final String label;
  final int delay;
  final VoidCallback onTap;

  const _TestTypeCard({
    required this.image,
    required this.label,
    required this.delay,
    required this.onTap,
  });

  @override
  State<_TestTypeCard> createState() => _TestTypeCardState();
}

class _TestTypeCardState extends State<_TestTypeCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = AppColors.primary;
    final cardColor = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final shadowColor = primary.withValues(alpha: _hovered ? 0.25 : 0.08);

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child:
          GestureDetector(
                onTap: widget.onTap,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOut,
                  transform: Matrix4.translationValues(
                    0,
                    _hovered ? -6.0 : 0.0,
                    0,
                  ),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(kCardRadius),
                    border: Border.all(
                      color: _hovered
                          ? primary.withValues(alpha: 0.5)
                          : primary.withValues(alpha: 0.12),
                      width: _hovered ? 1.5 : 1.0,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: shadowColor,
                        blurRadius: _hovered ? 20 : 8,
                        offset: Offset(0, _hovered ? 8 : 3),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(kPaddingLarge),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Изображение
                        Expanded(
                          flex: 4,
                          child: AnimatedScale(
                            scale: _hovered ? 1.05 : 1.0,
                            duration: const Duration(milliseconds: 200),
                            child: Image.asset(
                              widget.image,
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) =>
                                  Icon(
                                    Icons.electric_bolt_rounded,
                                    size: 48,
                                    color: primary,
                                  ),
                            ),
                          ),
                        ),

                        const SizedBox(height: kPaddingLarge),

                        // Разделитель
                        Container(
                          height: 1,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.transparent,
                                primary.withValues(alpha: 0.3),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: kPaddingLarge),

                        // Подпись
                        Expanded(
                          flex: 1,
                          child: Text(
                            widget.label,
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(
                                  fontSize: 17,
                                  color: primary,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              )
              .animate()
              .fadeIn(
                delay: Duration(milliseconds: widget.delay),
                duration: 350.ms,
              )
              .slideY(begin: 0.08, end: 0),
    );
  }
}

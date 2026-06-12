import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/constants/config.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/widgets/app_header.dart';

/// Главный экран с четырьмя стендами
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppHeader(),
      body: const _HomeBody(),
    );
  }
}

class _HomeBody extends StatelessWidget {
  const _HomeBody();

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);

    final stands = [
      _StandConfig(
        titleKey: 'stand_1_title',
        subtitleKey: 'stand_1_subtitle',
        image: 'assets/menu_image/small_engin.png',
        route: kRouteStand1,
      ),
      _StandConfig(
        titleKey: 'stand_2_title',
        subtitleKey: 'stand_2_subtitle',
        image: 'assets/menu_image/middle_engin.png',
        route: kRouteStand2,
      ),
      _StandConfig(
        titleKey: 'stand_3_title',
        subtitleKey: 'stand_3_subtitle',
        image: 'assets/menu_image/middle_engin.png',
        route: kRouteStand3,
      ),
      _StandConfig(
        titleKey: 'stand_4_title',
        subtitleKey: 'stand_4_subtitle',
        image: 'assets/menu_image/big_engin.png',
        route: kRouteStand4,
      ),
      _StandConfig(
        titleKey: 'stand_5_title',
        subtitleKey: 'stand_5_subtitle',
        image: 'assets/menu_image/kompressor.png',
        route: kRouteStand5Compressor,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = kPaddingLarge;
        const outerPad = kPaddingLarge * 2;

        final cardHeight = (constraints.maxHeight - outerPad * 2) / 2;

        return Padding(
          padding: const EdgeInsets.all(outerPad),
          child: Align(
            alignment: Alignment.center,
            child: SizedBox(
              height: cardHeight,
              child: Row(
            children: [
              Expanded(child: _StandCard(config: stands[0], title: loc.tr(stands[0].titleKey), subtitle: loc.tr(stands[0].subtitleKey), delay: 0)),
              const SizedBox(width: gap),
              Expanded(child: _StandCard(config: stands[1], title: loc.tr(stands[1].titleKey), subtitle: loc.tr(stands[1].subtitleKey), delay: 80)),
              const SizedBox(width: gap),
              Expanded(child: _StandCard(config: stands[2], title: loc.tr(stands[2].titleKey), subtitle: loc.tr(stands[2].subtitleKey), delay: 160)),
              const SizedBox(width: gap),
              Expanded(child: _StandCard(config: stands[3], title: loc.tr(stands[3].titleKey), subtitle: loc.tr(stands[3].subtitleKey), delay: 240)),
              const SizedBox(width: gap),
              Expanded(child: _StandCard(config: stands[4], title: loc.tr(stands[4].titleKey), subtitle: loc.tr(stands[4].subtitleKey), delay: 320)),
            ],
          ),
            ),
          ),
        );
      },
    );
  }
}

/// Данные одного стенда
class _StandConfig {
  final String titleKey;
  final String subtitleKey;
  final String image;
  final String route;

  const _StandConfig({
    required this.titleKey,
    required this.subtitleKey,
    required this.image,
    required this.route,
  });
}

/// Карточка-кнопка стенда
class _StandCard extends StatefulWidget {
  final _StandConfig config;
  final String title;
  final String subtitle;
  final int delay;

  const _StandCard({
    required this.config,
    required this.title,
    required this.subtitle,
    required this.delay,
  });

  @override
  State<_StandCard> createState() => _StandCardState();
}

class _StandCardState extends State<_StandCard> {
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
      child: GestureDetector(
        onTap: () => Navigator.pushNamed(context, widget.config.route),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          transform: Matrix4.translationValues(0.0, _hovered ? -6.0 : 0.0, 0.0),
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
                // Название стенда (вверху)
                Text(
                  widget.title,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontSize: 30,
                        color: primary,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                ),

                const SizedBox(height: kPadding),

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

                const SizedBox(height: kPadding),

                // Изображение двигателя
                Expanded(
                  flex: 3,
                  child: AnimatedScale(
                    scale: _hovered ? 1.06 : 1.0,
                    duration: const Duration(milliseconds: 200),
                    child: Image.asset(
                      widget.config.image,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) => Icon(
                        Icons.electric_bolt_rounded,
                        size: 72,
                        color: primary,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: kPadding),

                // Описание
                Expanded(
                  flex: 1,
                  child: Text(
                    widget.subtitle,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontSize: 20,
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.6),
                          height: 1.4,
                        ),
                  ),
                ),
              ],
            ),
          ),
        ),
      )
          .animate()
          .fadeIn(delay: Duration(milliseconds: widget.delay), duration: 350.ms)
          .slideY(begin: 0.08, end: 0),
    );
  }
}

import 'package:flutter/material.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/theme/app_colors.dart';
import '../../core/constants/config.dart';
import '../../shared/widgets/app_header.dart';

/// Пустой экран теста — заглушка для будущего функционала.
/// Показывает заголовок: название стенда + тип теста.
class StandTestScreen extends StatelessWidget {
  final String standTitleKey;
  final String testTypeKey;

  const StandTestScreen({
    super.key,
    required this.standTitleKey,
    required this.testTypeKey,
  });

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final primary = AppColors.primary;

    return Scaffold(
      appBar: const AppHeader(showBackButton: true),
      body: Padding(
        padding: const EdgeInsets.all(kPaddingLarge * 2),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Заголовок: "1 Стенд — С нагрузкой"
            Text(
              '${loc.tr(standTitleKey)} — ${loc.tr(testTypeKey)}',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 48,
                  ),
            ),

            const Expanded(child: SizedBox()),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../core/constants/config.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../data/models/test_run.dart';

/// Крупное сообщение об аварии фазы 1 — показывается по центру экрана.
/// Текст подбирается по статусу-провалу (КЗ/обрыв/пробой/КЗ на корпус).
class TestErrorOverlay extends StatelessWidget {
  final TestStatus status;
  final VoidCallback onFinish;

  const TestErrorOverlay({
    super.key,
    required this.status,
    required this.onFinish,
  });

  /// Ключ локализации текста ошибки по статусу
  String get _messageKey => switch (status) {
    TestStatus.failedInterturn => 'test_error_interturn',
    TestStatus.failedBreak => 'test_error_break',
    TestStatus.failedHvBreakdown => 'test_error_hv_breakdown',
    TestStatus.failedGround => 'test_error_ground',
    _ => 'test_error_unknown',
  };

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);

    return Center(
      child:
          Container(
                width: 520,
                padding: const EdgeInsets.all(kPaddingLarge * 1.5),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(kCardRadius + 4),
                  border: Border.all(
                    color: AppColors.error.withValues(alpha: 0.4),
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.error_rounded, size: 72, color: AppColors.error)
                        .animate(onPlay: (c) => c.repeat(reverse: true))
                        .scale(
                          begin: const Offset(1, 1),
                          end: const Offset(1.12, 1.12),
                          duration: 700.ms,
                          curve: Curves.easeInOut,
                        ),
                    const SizedBox(height: kPaddingLarge),
                    Text(
                      loc.tr('test_error_title'),
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            color: AppColors.error,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: kPadding),
                    Text(
                      loc.tr(_messageKey),
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: kPaddingLarge * 1.5),
                    ElevatedButton(
                      onPressed: onFinish,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.error,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: kPaddingLarge * 1.5,
                          vertical: kPadding,
                        ),
                      ),
                      child: Text(loc.tr('test_finish')),
                    ),
                  ],
                ),
              )
              .animate()
              .fadeIn(duration: 300.ms)
              .scale(begin: const Offset(0.85, 0.85), end: const Offset(1, 1)),
    );
  }
}

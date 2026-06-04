import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/widgets/app_header.dart';

/// Заглушка экрана результатов теста «Без нагрузки» — будет реализована позже.
class StandUnloadedResultScreen extends StatelessWidget {
  const StandUnloadedResultScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppHeader(showBackButton: true),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.construction_rounded,
              size: 72,
              color: AppColors.primary.withValues(alpha: 0.4),
            )
                .animate()
                .fadeIn(duration: 400.ms)
                .scale(begin: const Offset(0.7, 0.7)),

            const SizedBox(height: 24),

            Text(
              'Модуль в разработке',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppColors.primary.withValues(alpha: 0.6),
                    fontWeight: FontWeight.w600,
                  ),
            ).animate().fadeIn(delay: 200.ms),
          ],
        ),
      ),
    );
  }
}

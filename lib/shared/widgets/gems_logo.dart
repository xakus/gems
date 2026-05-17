import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

/// Логотип GEMS — стилизованная буква G с градиентом и молнией.
/// Используется на Splash, в AppHeader (через Hero).
class GemsLogo extends StatelessWidget {
  final double size;
  final bool showGlow;

  const GemsLogo({super.key, this.size = 64, this.showGlow = true});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: AppColors.logoGradient,
        borderRadius: BorderRadius.circular(size * 0.22),
        boxShadow: showGlow
            ? [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.35),
                  blurRadius: size * 0.4,
                  spreadRadius: size * 0.04,
                ),
                BoxShadow(
                  color: AppColors.accent.withValues(alpha: 0.2),
                  blurRadius: size * 0.6,
                  spreadRadius: size * 0.02,
                ),
              ]
            : null,
      ),
      child: CustomPaint(
        painter: _LogoPainter(size: size),
      ),
    );
  }
}

/// Рисует букву G + символ молнии поверх градиентного фона
class _LogoPainter extends CustomPainter {
  final double size;
  const _LogoPainter({required this.size});

  @override
  void paint(Canvas canvas, Size canvasSize) {
    final cx = canvasSize.width / 2;
    final cy = canvasSize.height / 2;
    final r = size * 0.32;

    final paintWhite = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = size * 0.08
      ..strokeCap = StrokeCap.round;

    // Дуга буквы G (270° от правого, против часовой)
    final arcRect = Rect.fromCircle(center: Offset(cx, cy), radius: r);
    canvas.drawArc(arcRect, 0.35, 5.0, false, paintWhite);

    // Горизонтальная черта буквы G
    final barPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = size * 0.08
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(cx, cy),
      Offset(cx + r, cy),
      barPaint,
    );

    // Молния (акцентный цвет) — правый нижний угол
    final boltPaint = Paint()
      ..color = AppColors.accent
      ..style = PaintingStyle.fill;

    final bx = cx + r * 0.3;
    final by = cy + r * 0.3;
    final bs = size * 0.14;

    final boltPath = Path()
      ..moveTo(bx, by - bs)
      ..lineTo(bx - bs * 0.55, by + bs * 0.1)
      ..lineTo(bx - bs * 0.1, by + bs * 0.1)
      ..lineTo(bx - bs * 0.4, by + bs)
      ..lineTo(bx + bs * 0.55, by - bs * 0.15)
      ..lineTo(bx + bs * 0.1, by - bs * 0.15)
      ..close();

    canvas.drawPath(boltPath, boltPaint);
  }

  @override
  bool shouldRepaint(covariant _LogoPainter old) => old.size != size;
}

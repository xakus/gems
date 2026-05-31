import 'package:flutter/material.dart';

/// Логотип AMOTES из файла assets/icons/logo.jpeg.
/// Используется на Splash, Login и в AppHeader (через Hero).
class AmotesLogo extends StatelessWidget {
  final double size;

  const AmotesLogo({super.key, this.size = 64});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Image.asset(
        'assets/icons/logo.png',
        width: size,
        height: size,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.high,
      ),
    );
  }
}

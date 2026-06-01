import 'package:flutter/material.dart';
import '../../shared/widgets/app_header.dart';
import 'stand_placeholder.dart';

/// Экран стенда 5 — компрессор
class Stand5Screen extends StatelessWidget {
  const Stand5Screen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      appBar: AppHeader(showBackButton: true),
      body: StandPlaceholder(
        image: 'assets/menu_image/kompressor.png',
        titleKey: 'stand_5_title',
        subtitleKey: 'stand_5_subtitle',
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../../shared/widgets/app_header.dart';
import 'stand_placeholder.dart';

/// Экран стенда 4 — большой двигатель до мощности 1000 кВт
class Stand4Screen extends StatelessWidget {
  const Stand4Screen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      appBar: AppHeader(showBackButton: true),
      body: StandPlaceholder(
        image: 'assets/menu_image/big_engin.png',
        titleKey: 'stand_4_title',
        subtitleKey: 'stand_4_subtitle',
      ),
    );
  }
}

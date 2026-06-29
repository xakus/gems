import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/config.dart';
import '../../core/theme/app_colors.dart';
import '../providers/locale_provider.dart';

/// Компактный переключатель языка EN / AZ / RU
class LanguageSwitcher extends StatelessWidget {
  const LanguageSwitcher({super.key});

  @override
  Widget build(BuildContext context) {
    final locale = context.watch<LocaleProvider>().languageCode;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: kSupportedLocales.map((code) {
        final selected = code == locale;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: _LangChip(
            code: code.toUpperCase(),
            selected: selected,
            onTap: () => context.read<LocaleProvider>().setLocale(code),
          ),
        );
      }).toList(),
    );
  }
}

class _LangChip extends StatelessWidget {
  final String code;
  final bool selected;
  final VoidCallback onTap;

  const _LangChip({
    required this.code,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      child: Material(
        color: selected
            ? AppColors.primary
            : (isDark
                  ? AppColors.darkSurfaceRaised
                  : AppColors.lightBackground),
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            child: Text(
              code,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: selected
                    ? Colors.white
                    : (isDark
                          ? AppColors.darkSecondaryText
                          : AppColors.lightSecondaryText),
                letterSpacing: 0.5,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

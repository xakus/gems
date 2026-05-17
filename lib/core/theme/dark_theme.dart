import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Тёмная тема GEMS
ThemeData buildDarkTheme() {
  const colorScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: AppColors.accent,
    onPrimary: Color(0xFF003B5C),
    primaryContainer: Color(0xFF004A77),
    onPrimaryContainer: AppColors.accent,
    secondary: AppColors.primaryLight,
    onSecondary: Colors.white,
    secondaryContainer: Color(0xFF003B82),
    onSecondaryContainer: Color(0xFF90CAF9),
    error: Color(0xFFFF6B6B),
    onError: Color(0xFF600000),
    surface: AppColors.darkSurface,
    onSurface: AppColors.darkOnBackground,
    surfaceContainerHighest: AppColors.darkSurfaceRaised,
    outline: AppColors.darkDivider,
    shadow: Colors.black,
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: AppColors.darkBackground,
    fontFamily: 'NotoSans',

    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.darkHeader,
      foregroundColor: AppColors.darkOnBackground,
      elevation: 0,
      shadowColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
    ),

    cardTheme: CardThemeData(
      color: AppColors.darkSurface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.darkDivider),
      ),
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.accent,
        foregroundColor: const Color(0xFF003B5C),
        elevation: 0,
        minimumSize: const Size(88, 52),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, letterSpacing: 0.3),
      ),
    ),

    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.accent,
        side: const BorderSide(color: AppColors.accent, width: 1.5),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
      ),
    ),

    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.accent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    ),

    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.darkSurfaceRaised,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.darkDivider),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.darkDivider),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.accent, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFFF6B6B)),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFFF6B6B), width: 2),
      ),
      labelStyle: const TextStyle(color: AppColors.darkSecondaryText),
      hintStyle: TextStyle(color: AppColors.darkSecondaryText.withValues(alpha: 0.7)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),

    dividerTheme: const DividerThemeData(
      color: AppColors.darkDivider,
      thickness: 1,
      space: 1,
    ),

    iconTheme: const IconThemeData(color: AppColors.darkOnBackground),

    textTheme: const TextTheme(
      headlineLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.w700, color: AppColors.darkOnBackground),
      headlineMedium: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: AppColors.darkOnBackground),
      headlineSmall: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: AppColors.darkOnBackground),
      titleLarge: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.darkOnBackground),
      titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: AppColors.darkOnBackground),
      bodyLarge: TextStyle(fontSize: 15, color: AppColors.darkOnBackground),
      bodyMedium: TextStyle(fontSize: 14, color: AppColors.darkOnBackground),
      bodySmall: TextStyle(fontSize: 12, color: AppColors.darkSecondaryText),
    ),

    chipTheme: ChipThemeData(
      backgroundColor: AppColors.darkSurfaceRaised,
      selectedColor: AppColors.accent.withValues(alpha: 0.2),
      labelStyle: const TextStyle(fontSize: 13, color: AppColors.darkOnBackground),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ),

    dialogTheme: DialogThemeData(
      backgroundColor: AppColors.darkSurface,
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),

    snackBarTheme: SnackBarThemeData(
      backgroundColor: AppColors.darkSurfaceRaised,
      contentTextStyle: const TextStyle(color: AppColors.darkOnBackground),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      behavior: SnackBarBehavior.floating,
    ),

    tooltipTheme: TooltipThemeData(
      decoration: BoxDecoration(
        color: AppColors.darkSurfaceRaised,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.darkDivider),
      ),
      textStyle: const TextStyle(color: AppColors.darkOnBackground, fontSize: 12),
    ),
  );
}

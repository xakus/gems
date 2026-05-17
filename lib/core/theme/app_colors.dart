import 'package:flutter/material.dart';

/// Фирменная палитра GEMS.
/// Основная тема: электрический синий + циан-акцент.
abstract final class AppColors {
  // ── Основные бренд-цвета ──────────────────────────────────────────
  /// Основной синий (электрика, надёжность)
  static const Color primary = Color(0xFF1565C0);

  /// Насыщенный синий для hover/press
  static const Color primaryDark = Color(0xFF0D47A1);

  /// Светлый вариант primary для фонов
  static const Color primaryLight = Color(0xFF1976D2);

  /// Акцентный электрик-циан (энергия, ток)
  static const Color accent = Color(0xFF00B0FF);

  /// Насыщенный акцент
  static const Color accentDark = Color(0xFF0091EA);

  // ── Светлая тема ─────────────────────────────────────────────────
  /// Фон страниц
  static const Color lightBackground = Color(0xFFF4F6F9);

  /// Поверхность карточек
  static const Color lightSurface = Color(0xFFFFFFFF);

  /// Поверхность AppHeader (светлая)
  static const Color lightHeader = Color(0xFFFFFFFF);

  /// Основной текст
  static const Color lightOnBackground = Color(0xFF1A1A2E);

  /// Вторичный текст
  static const Color lightSecondaryText = Color(0xFF6B7280);

  /// Граница / разделители
  static const Color lightDivider = Color(0xFFE5E7EB);

  /// Тень карточек
  static const Color lightShadow = Color(0x1A000000);

  // ── Тёмная тема ──────────────────────────────────────────────────
  /// Фон страниц (промышленный dark)
  static const Color darkBackground = Color(0xFF0D1117);

  /// Поверхность карточек
  static const Color darkSurface = Color(0xFF161B22);

  /// Поверхность AppHeader (тёмная)
  static const Color darkHeader = Color(0xFF161B22);

  /// Raised surface (модалки, дропдауны)
  static const Color darkSurfaceRaised = Color(0xFF21262D);

  /// Основной текст
  static const Color darkOnBackground = Color(0xFFE6EDF3);

  /// Вторичный текст
  static const Color darkSecondaryText = Color(0xFF8B949E);

  /// Граница / разделители
  static const Color darkDivider = Color(0xFF30363D);

  // ── Семантические цвета (одинаковы в обеих темах) ────────────────
  /// Успех (активен, создан)
  static const Color success = Color(0xFF2DA44E);

  /// Предупреждение
  static const Color warning = Color(0xFFD29922);

  /// Ошибка / деактивирован
  static const Color error = Color(0xFFCF222E);

  /// Информация
  static const Color info = Color(0xFF0969DA);

  // ── Специальные ──────────────────────────────────────────────────
  /// Стекло/overlay для модалок
  static const Color overlayLight = Color(0x80FFFFFF);
  static const Color overlayDark = Color(0x800D1117);

  /// Gradient для splash-экрана (светлая тема)
  static const LinearGradient splashGradientLight = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFE3F2FD), Color(0xFFF4F6F9), Color(0xFFE8F4FD)],
  );

  /// Gradient для splash-экрана (тёмная тема)
  static const LinearGradient splashGradientDark = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF0D1117), Color(0xFF161B22), Color(0xFF0D1117)],
  );

  /// Gradient для логотипа
  static const LinearGradient logoGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1565C0), Color(0xFF00B0FF)],
  );
}

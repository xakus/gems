import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/config.dart';
import '../../data/repositories/settings_repository.dart';

/// Провайдер темы. Применяется мгновенно, сохраняется в SharedPreferences
/// (до логина) и в таблице settings (после логина).
class ThemeProvider extends ChangeNotifier {
  final SettingsRepository _settingsRepo;
  ThemeMode _themeMode = ThemeMode.light;
  int? _currentUserId;

  ThemeProvider({SettingsRepository? settingsRepo})
      : _settingsRepo = settingsRepo ?? SettingsRepository();

  ThemeMode get themeMode => _themeMode;
  bool get isDark => _themeMode == ThemeMode.dark;

  /// Загружает тему из SharedPreferences при старте (до логина)
  Future<void> loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(kPrefsThemeKey) ?? kDefaultTheme;
    _themeMode = saved == 'dark' ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
  }

  /// Загружает тему пользователя из БД после входа
  Future<void> loadForUser(int userId) async {
    _currentUserId = userId;
    final settings = await _settingsRepo.getByUserId(userId);
    _themeMode = settings.theme == 'dark' ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
  }

  /// Переключает тему и сохраняет
  Future<void> toggle() async {
    _themeMode = isDark ? ThemeMode.light : ThemeMode.dark;
    notifyListeners();
    await _persist();
  }

  /// Устанавливает конкретную тему
  Future<void> setTheme(String theme) async {
    _themeMode = theme == 'dark' ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
    await _persist();
  }

  /// Сбрасывает при выходе (возвращает к загрузке из prefs)
  void onLogout() {
    _currentUserId = null;
    loadFromPrefs();
  }

  Future<void> _persist() async {
    final themeStr = isDark ? 'dark' : 'light';
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(kPrefsThemeKey, themeStr);
    if (_currentUserId != null) {
      await _settingsRepo.updateTheme(_currentUserId!, themeStr);
    }
  }
}

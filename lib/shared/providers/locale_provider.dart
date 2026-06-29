import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/config.dart';
import '../../data/repositories/settings_repository.dart';

/// Провайдер языка интерфейса
class LocaleProvider extends ChangeNotifier {
  final SettingsRepository _settingsRepo;
  Locale _locale = const Locale(kDefaultLocale);
  int? _currentUserId;

  LocaleProvider({SettingsRepository? settingsRepo})
    : _settingsRepo = settingsRepo ?? SettingsRepository();

  Locale get locale => _locale;
  String get languageCode => _locale.languageCode;

  /// Загружает язык из SharedPreferences при старте
  Future<void> loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(kPrefsLocaleKey) ?? kDefaultLocale;
    _locale = Locale(_resolveCode(saved));
    notifyListeners();
  }

  /// Загружает язык пользователя из БД после входа
  Future<void> loadForUser(int userId) async {
    _currentUserId = userId;
    final settings = await _settingsRepo.getByUserId(userId);
    _locale = Locale(_resolveCode(settings.language));
    notifyListeners();
  }

  /// Меняет язык и сохраняет
  Future<void> setLocale(String langCode) async {
    final code = _resolveCode(langCode);
    _locale = Locale(code);
    notifyListeners();
    await _persist(code);
  }

  /// Сбрасывает при выходе
  void onLogout() {
    _currentUserId = null;
    loadFromPrefs();
  }

  String _resolveCode(String code) =>
      kSupportedLocales.contains(code) ? code : kDefaultLocale;

  Future<void> _persist(String code) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(kPrefsLocaleKey, code);
    if (_currentUserId != null) {
      await _settingsRepo.updateLanguage(_currentUserId!, code);
    }
  }
}

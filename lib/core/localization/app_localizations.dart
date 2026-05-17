import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../constants/config.dart';

/// Загрузчик переводов из JSON-файлов в assets/translations/
class AppLocalizations {
  final Locale locale;
  late Map<String, String> _strings;

  AppLocalizations(this.locale);

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  Future<bool> load() async {
    final langCode = _resolveCode(locale.languageCode);
    final jsonString = await rootBundle.loadString(
      '$kTranslationsPath/$langCode.json',
    );
    final Map<String, dynamic> jsonMap = json.decode(jsonString);
    _strings = jsonMap.map((key, value) => MapEntry(key, value.toString()));
    return true;
  }

  /// Возвращает перевод по ключу. Если не найден — возвращает ключ.
  String tr(String key, {Map<String, String>? args}) {
    String text = _strings[key] ?? key;
    if (args != null) {
      args.forEach((k, v) => text = text.replaceAll('{$k}', v));
    }
    return text;
  }

  /// Приводит код языка к поддерживаемому
  String _resolveCode(String code) {
    if (kSupportedLocales.contains(code)) return code;
    return kDefaultLocale;
  }
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) =>
      kSupportedLocales.contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async {
    final loc = AppLocalizations(locale);
    await loc.load();
    return loc;
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

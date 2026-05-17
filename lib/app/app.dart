import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import '../core/constants/config.dart';
import '../core/localization/app_localizations.dart';
import '../core/theme/dark_theme.dart';
import '../core/theme/light_theme.dart';
import '../shared/providers/auth_provider.dart';
import '../shared/providers/locale_provider.dart';
import '../shared/providers/theme_provider.dart';
import 'router.dart';

/// Корневой виджет приложения — MaterialApp с темами, локализацией и провайдерами
class GemsApp extends StatelessWidget {
  const GemsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => LocaleProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
      ],
      child: const _AppRoot(),
    );
  }
}

class _AppRoot extends StatelessWidget {
  const _AppRoot();

  @override
  Widget build(BuildContext context) {
    final themeMode = context.watch<ThemeProvider>().themeMode;
    final locale = context.watch<LocaleProvider>().locale;

    return MaterialApp(
      title: kAppName,
      debugShowCheckedModeBanner: false,

      // Темы
      theme: buildLightTheme(),
      darkTheme: buildDarkTheme(),
      themeMode: themeMode,

      // Локализация
      locale: locale,
      supportedLocales: kSupportedLocales.map(Locale.new).toList(),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],

      // Маршрутизация
      initialRoute: kRouteSplash,
      onGenerateRoute: generateRoute,
    );
  }
}

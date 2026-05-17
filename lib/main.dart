import 'dart:io';
import 'package:flutter/material.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:window_manager/window_manager.dart';
import 'app/app.dart';
import 'core/constants/config.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Инициализация SQLite FFI для desktop платформ
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  // Настройка окна приложения
  await windowManager.ensureInitialized();
  await windowManager.waitUntilReadyToShow(
    const WindowOptions(
      title: kAppName,
      minimumSize: Size(kWindowMinWidth, kWindowMinHeight),
      size: Size(kWindowInitialWidth, kWindowInitialHeight),
      center: true,
      backgroundColor: Colors.transparent,
      titleBarStyle: TitleBarStyle.normal,
    ),
    () async {
      await windowManager.show();
      await windowManager.focus();
    },
  );

  runApp(const GemsApp());
}

import 'dart:math';
import '../constants/config.dart';

/// Генератор временных паролей для новых пользователей
class TempPasswordGenerator {
  static final Random _random = Random.secure();

  static const String _letters =
      'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ';
  static const String _digits = '0123456789';
  static const String _all = _letters + _digits;

  /// Генерирует пароль заданной длины (гарантированно содержит цифру)
  static String generate([int length = kTempPasswordLength]) {
    final buffer = StringBuffer();
    // Минимум 2 цифры для надёжности
    buffer.write(_digits[_random.nextInt(_digits.length)]);
    buffer.write(_digits[_random.nextInt(_digits.length)]);
    for (int i = 2; i < length; i++) {
      buffer.write(_all[_random.nextInt(_all.length)]);
    }
    // Перемешиваем символы
    final chars = buffer.toString().split('');
    chars.shuffle(_random);
    return chars.join();
  }
}

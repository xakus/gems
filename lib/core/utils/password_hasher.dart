import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import '../constants/config.dart';

/// Утилита для хеширования и проверки паролей (SHA-256 + случайная соль)
class PasswordHasher {
  static final Random _random = Random.secure();

  /// Генерирует случайную соль в виде hex-строки
  static String generateSalt() {
    final bytes = List<int>.generate(
      kPasswordSaltLength,
      (_) => _random.nextInt(256),
    );
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }

  /// Хеширует пароль с заданной солью
  static String hash(String password, String salt) {
    final input = utf8.encode('$salt$password');
    return sha256.convert(input).toString();
  }

  /// Проверяет пароль против сохранённого хеша и соли
  static bool verify(String password, String salt, String storedHash) {
    return hash(password, salt) == storedHash;
  }
}

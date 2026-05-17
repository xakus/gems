import '../constants/config.dart';

/// Валидаторы форм
class Validators {
  Validators._();

  /// Проверяет, что поле не пустое
  static String? required(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName обязательно для заполнения';
    }
    return null;
  }

  /// Валидация пароля: минимум 8 символов + хотя бы одна цифра
  static String? password(String? value) {
    if (value == null || value.isEmpty) return 'Введите пароль';
    if (value.length < kPasswordMinLength) {
      return 'Минимум $kPasswordMinLength символов';
    }
    if (!value.contains(RegExp(r'\d'))) {
      return 'Пароль должен содержать хотя бы одну цифру';
    }
    return null;
  }

  /// Проверяет совпадение двух паролей
  static String? passwordConfirm(String? value, String? original) {
    if (value == null || value.isEmpty) return 'Повторите пароль';
    if (value != original) return 'Пароли не совпадают';
    return null;
  }

  /// Валидация логина: только латиница, цифры и подчёркивание
  static String? username(String? value) {
    if (value == null || value.trim().isEmpty) return 'Введите логин';
    if (value.length < 3) return 'Минимум 3 символа';
    if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(value)) {
      return 'Только латиница, цифры и _';
    }
    return null;
  }

  /// Валидация имени/фамилии
  static String? name(String? value, String label) {
    if (value == null || value.trim().isEmpty) return '$label обязательно';
    if (value.trim().length < 2) return 'Минимум 2 символа';
    return null;
  }
}

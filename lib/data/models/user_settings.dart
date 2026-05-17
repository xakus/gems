/// Настройки конкретного пользователя (таблица settings)
class UserSettings {
  final int userId;
  final String theme;
  final String language;

  const UserSettings({
    required this.userId,
    this.theme = 'light',
    this.language = 'en',
  });

  factory UserSettings.fromMap(Map<String, dynamic> map) {
    return UserSettings(
      userId: map['user_id'] as int,
      theme: map['theme'] as String,
      language: map['language'] as String,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'user_id': userId,
      'theme': theme,
      'language': language,
    };
  }

  UserSettings copyWith({String? theme, String? language}) {
    return UserSettings(
      userId: userId,
      theme: theme ?? this.theme,
      language: language ?? this.language,
    );
  }
}

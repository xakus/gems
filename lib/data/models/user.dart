import '../../core/constants/config.dart';

/// Роль пользователя в системе
enum UserRole {
  user,
  admin;

  /// Преобразует строку из БД в enum
  static UserRole fromString(String value) {
    return value.toUpperCase() == kRoleAdmin ? UserRole.admin : UserRole.user;
  }

  /// Строка для сохранения в БД
  String toDbString() => this == UserRole.admin ? kRoleAdmin : kRoleUser;
}

/// Модель пользователя (соответствует таблице users)
class User {
  final int? id;
  final String firstName;
  final String lastName;
  final String username;
  final String passwordHash;
  final String passwordSalt;
  final UserRole role;
  final bool isActive;
  final bool mustChangePassword;

  /// true — пользователь мягко удалён и не отображается в системе
  final bool isDeleted;

  /// Дата мягкого удаления (null если не удалён)
  final DateTime? deletedAt;

  final DateTime createdAt;
  final DateTime updatedAt;

  const User({
    this.id,
    required this.firstName,
    required this.lastName,
    required this.username,
    required this.passwordHash,
    required this.passwordSalt,
    required this.role,
    this.isActive = true,
    this.mustChangePassword = true,
    this.isDeleted = false,
    this.deletedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Полное имя пользователя
  String get fullName => '$firstName $lastName';

  /// Создаёт из Map (результат запроса к БД)
  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'] as int?,
      firstName: map['first_name'] as String,
      lastName: map['last_name'] as String,
      username: map['username'] as String,
      passwordHash: map['password_hash'] as String,
      passwordSalt: map['password_salt'] as String,
      role: UserRole.fromString(map['role'] as String),
      isActive: (map['is_active'] as int) == 1,
      mustChangePassword: (map['must_change_password'] as int) == 1,
      isDeleted: (map['is_deleted'] as int? ?? 0) == 1,
      deletedAt: map['deleted_at'] != null
          ? DateTime.parse(map['deleted_at'] as String)
          : null,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  /// Преобразует в Map для сохранения в БД
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'first_name': firstName,
      'last_name': lastName,
      'username': username,
      'password_hash': passwordHash,
      'password_salt': passwordSalt,
      'role': role.toDbString(),
      'is_active': isActive ? 1 : 0,
      'must_change_password': mustChangePassword ? 1 : 0,
      'is_deleted': isDeleted ? 1 : 0,
      'deleted_at': deletedAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Копирует объект с изменёнными полями
  User copyWith({
    int? id,
    String? firstName,
    String? lastName,
    String? username,
    String? passwordHash,
    String? passwordSalt,
    UserRole? role,
    bool? isActive,
    bool? mustChangePassword,
    bool? isDeleted,
    DateTime? deletedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return User(
      id: id ?? this.id,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      username: username ?? this.username,
      passwordHash: passwordHash ?? this.passwordHash,
      passwordSalt: passwordSalt ?? this.passwordSalt,
      role: role ?? this.role,
      isActive: isActive ?? this.isActive,
      mustChangePassword: mustChangePassword ?? this.mustChangePassword,
      isDeleted: isDeleted ?? this.isDeleted,
      deletedAt: deletedAt ?? this.deletedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

// Центральный файл конфигурации AMOTES.
// Все настройки приложения — здесь. Не хардкодить нигде в коде.

// ─────────────────────────────────────────────
//  Мета-информация приложения
// ─────────────────────────────────────────────

/// Короткое название
const String kAppName = 'AMOTES';

/// Полное название (азербайджанский, часть бренда — не переводить)
const String kAppFullName = 'Güclü Elektromühərriklərin Monitorinqi və Sınağı';

/// Версия приложения
const String kAppVersion = '1.0.0';

/// Имя файла базы данных
const String kDatabaseFileName = 'amotes.db';

/// Текущая версия схемы БД (для миграций)
const int kDatabaseVersion = 2;

// ─────────────────────────────────────────────
//  Окно приложения
// ─────────────────────────────────────────────

/// Минимальная ширина окна
const double kWindowMinWidth = 900;

/// Минимальная высота окна
const double kWindowMinHeight = 800;

/// Начальная ширина окна
const double kWindowInitialWidth = 1280;

/// Начальная высота окна
const double kWindowInitialHeight = 800;

// ─────────────────────────────────────────────
//  Splash Screen
// ─────────────────────────────────────────────

/// Длительность splash-экрана в секундах
const int kSplashDurationSeconds = 2;

/// Длительность анимации fade-in логотипа (мс)
const int kSplashLogoFadeDurationMs = 600;

/// Задержка перед анимацией названия (мс)
const int kSplashTitleDelayMs = 400;

/// Задержка перед анимацией подзаголовка (мс)
const int kSplashSubtitleDelayMs = 800;

// ─────────────────────────────────────────────
//  Аутентификация
// ─────────────────────────────────────────────

/// Имя пользователя дефолтного администратора
const String kDefaultAdminUsername = 'admin';

/// Длина автогенерируемого временного пароля
const int kTempPasswordLength = 12;

/// Минимальная длина пароля
const int kPasswordMinLength = 8;

/// Длина соли для хеширования (в байтах)
const int kPasswordSaltLength = 32;

// ─────────────────────────────────────────────
//  Локализация
// ─────────────────────────────────────────────

/// Дефолтный язык
const String kDefaultLocale = 'en';

/// Поддерживаемые языки
const List<String> kSupportedLocales = ['en', 'az', 'ru'];

/// Пути к файлам переводов
const String kTranslationsPath = 'assets/translations';

// ─────────────────────────────────────────────
//  Темы
// ─────────────────────────────────────────────

/// Дефолтная тема
const String kDefaultTheme = 'light';

// ─────────────────────────────────────────────
//  Ключи SharedPreferences
// ─────────────────────────────────────────────

/// Ключ темы в SharedPreferences (до логина)
const String kPrefsThemeKey = 'amotes_theme';

/// Ключ языка в SharedPreferences (до логина)
const String kPrefsLocaleKey = 'amotes_locale';

// ─────────────────────────────────────────────
//  Ключи таблицы app_meta
// ─────────────────────────────────────────────

/// Версия схемы БД
const String kMetaDbVersion = 'db_version';

/// Флаг первого запуска
const String kMetaFirstRun = 'first_run';

// ─────────────────────────────────────────────
//  Роли пользователей
// ─────────────────────────────────────────────

/// Строковое представление роли USER в БД
const String kRoleUser = 'USER';

/// Строковое представление роли ADMIN в БД
const String kRoleAdmin = 'ADMIN';

// ─────────────────────────────────────────────
//  UI константы
// ─────────────────────────────────────────────

/// Максимальная ширина форм (логин, смена пароля)
const double kFormMaxWidth = 460;

/// Максимальная ширина области управления пользователями
const double kUsersMaxWidth = 1100;

/// Радиус скругления карточек
const double kCardRadius = 16;

/// Радиус скругления кнопок
const double kButtonRadius = 12;

/// Высота AppHeader
const double kHeaderHeight = 100;

/// Стандартный внутренний отступ
const double kPadding = 16;

/// Увеличенный отступ
const double kPaddingLarge = 24;

/// Маленький отступ
const double kPaddingSmall = 8;

/// Стандартная длительность анимации (мс)
const int kAnimationDurationMs = 300;

/// Медленная анимация (мс)
const int kAnimationDurationSlowMs = 600;

// ─────────────────────────────────────────────
//  Маршруты
// ─────────────────────────────────────────────

/// Маршрут splash
const String kRouteSplash = '/splash';

/// Маршрут логина
const String kRouteLogin = '/login';

/// Маршрут принудительной смены пароля
const String kRouteChangePassword = '/change-password';

/// Маршрут главного экрана
const String kRouteHome = '/home';

/// Маршрут настроек
const String kRouteSettings = '/settings';

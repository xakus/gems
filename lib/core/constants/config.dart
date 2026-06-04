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

/// Маршрут стенда 1 — малый двигатель до 75 кВт
const String kRouteStand1 = '/stand-1';

/// Маршрут стенда 2 — средний двигатель до 315 кВт
const String kRouteStand2 = '/stand-2';

/// Маршрут стенда 3 — большой двигатель до 1000 кВт
const String kRouteStand3 = '/stand-3';

/// Маршрут стенда 4 — компрессор
const String kRouteStand4 = '/stand-4';

/// Маршрут стенда 5 — средний двигатель (копия стенда 2)
const String kRouteStand5 = '/stand-5';

/// Маршруты экранов тестирования стенда 1
const String kRouteStand1Loaded   = '/stand-1/loaded';
const String kRouteStand1Unloaded = '/stand-1/unloaded';

/// Маршруты экранов тестирования стенда 2
const String kRouteStand2Loaded   = '/stand-2/loaded';
const String kRouteStand2Unloaded = '/stand-2/unloaded';

/// Маршруты экранов тестирования стенда 3
const String kRouteStand3Loaded   = '/stand-3/loaded';
const String kRouteStand3Unloaded = '/stand-3/unloaded';

/// Маршрут экрана результатов после ввода параметров (режим «Без нагрузки»)
const String kRouteStandUnloadedResult = '/stand/unloaded/result';

// ─────────────────────────────────────────────
//  Максимальная мощность стендов (кВт)
// ─────────────────────────────────────────────

/// Стенд 1 — двигатели до 22 кВт
const double kStand1MaxPowerKwt = 22.0;

/// Стенд 2 — двигатели до 170 кВт
const double kStand2MaxPowerKwt = 170.0;

/// Стенд 3 — двигатели до 170 кВт
const double kStand3MaxPowerKwt = 170.0;

# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

---

## Что это

**AMOTES** (полное азербайджанское название — *Güclü Elektromühərriklərin Monitorinqi və Sınağı*, «Мониторинг и тестирование мощных электродвигателей») — **desktop-приложение на Flutter** для тестирования мощных синхронных электродвигателей.

- Только desktop: **Windows, Linux, macOS**. Mobile/web не поддерживаются.
- **Офлайн-first**: никаких сетевых запросов, вся персистентность — в локальной SQLite.
- Язык комментариев в коде — **русский**.

---

## Команды

```bash
flutter run -d linux          # запуск (или -d windows / -d macos)
flutter analyze               # статический анализ (линтер — flutter_lints, см. analysis_options.yaml)
dart format lib/ test/        # форматирование
flutter test                  # все тесты
flutter test test/widget_test.dart   # один файл тестов
flutter build linux --release # release-сборка (или windows / macos)
flutter clean && flutter pub get     # полная очистка зависимостей
```

> ⚠️ Тесты сейчас почти пустые (`test/widget_test.dart` — дефолтная заглушка). Перед тем как полагаться на `flutter test`, проверь, что там есть реальные тесты.

---

## Архитектура (big picture)

Слоистая структура `lib/` — features → providers → repositories → DatabaseHelper. Понимание этих сквозных механизмов важнее, чем список файлов:

### 1. Точка входа и окно
`main.dart` инициализирует **sqflite FFI** (обязательно для desktop — без этого SQLite не работает) и `window_manager` (мин. размер, разворачивает окно на весь экран), затем запускает `AmotesApp`.

### 2. Корень приложения
`app/app.dart` — `MaterialApp` обёрнут в `MultiProvider` с тремя `ChangeNotifierProvider`:
- **`ThemeProvider`** — светлая/тёмная тема, `themeMode`.
- **`LocaleProvider`** — текущая локаль (en/az/ru).
- **`AuthProvider`** — текущая сессия в памяти.

`MaterialApp` использует стабильный `navigatorKey` (`GlobalKey<NavigatorState>`), чтобы Navigator не пересоздавался при rebuild темы/локали.

### 3. Маршрутизация и guard — `app/router.dart`
Это **нестандартный** паттерн, не перепутай:
- Маршруты строятся через `onGenerateRoute: generateRoute` (НЕ через таблицу `routes:`).
- Публичные маршруты (`/splash`, `/login`) возвращаются напрямую.
- **Все защищённые маршруты оборачиваются в виджет `_AuthGuard`**, который проверяет авторизацию *прямо в дереве виджетов* (через `context.watch<AuthProvider>()`), а не в роутере. Если не авторизован — `popUntil` до `/login`. Если `mustChangePassword` — форсирует `/change-password`.
- Сам маппинг имени маршрута на экран — внутри `_AuthGuard.build` через `switch (routeName)`.
- Переходы — кастомный fade (`_fade`).

### 4. Доступ к данным
`features/*` (экраны) → `shared/providers/*` (состояние) → `data/repositories/*` (CRUD) → `core/database/database_helper.dart`.

- **`DatabaseHelper`** — синглтон (`DatabaseHelper.instance`), ленивая инициализация БД, схема в `_onCreate`, миграции в `_onUpgrade`. БД-файл (`amotes.db`) лежит в `getApplicationSupportDirectory()`.
- Репозитории (`UserRepository`, `SettingsRepository`, `AuditRepository`, `CompressorTemplateRepository`) получают `await _db.database` и работают сырыми запросами sqflite. **Проверка роли дублируется на уровне репозитория**, а не только в UI.
- `AuthService` — логин и смена пароля; UI никогда не лезет в БД напрямую за аутентификацией.

### 5. Локализация — `core/localization/app_localizations.dart`
**Своя реализация, не `intl`/`gen-l10n`.** Плоские JSON-словари `assets/translations/{en,az,ru}.json`. Использование: `AppLocalizations.of(context).tr('key')`. Интерполяция через `{arg}`: `tr('key', args: {'name': 'Murad'})` заменяет `{name}` в строке. Если ключ не найден — возвращается сам ключ.
- **Никогда не хардкодь строки в UI** — всё через `tr()`. При добавлении строки добавляй ключ во **все три** JSON.
- Подзаголовок-бренд `Güclü Elektromühərriklərin Monitorinqi və Sınağı` не переводится.

### 6. Темы — `core/theme/`
`app_colors.dart` (`AppColors.primary` и пр.), `light_theme.dart`, `dark_theme.dart` (фабрики `buildLightTheme()` / `buildDarkTheme()`). **Не хардкодь цвета** — бери из `Theme.of(context)` или `AppColors`. Шрифт — `NotoSans` (важно: AZ-символы `ə`, `ü`, `ğ` и т.п.).

### 7. Конфигурация — `core/constants/config.dart`
**Единственный источник констант.** Все `kRoute*`, размеры окна, длины паролей, ключи `app_meta`/`SharedPreferences`, имена ролей (`kRoleAdmin`/`kRoleUser`), макс. мощности стендов (`kStand1MaxPowerKwt` и т.д.), UI-отступы/радиусы. **Не хардкодь эти значения по месту** — добавляй/бери отсюда.

---

## Схема БД (SQLite, версия = 3)

Версия в `kDatabaseVersion` (config.dart). При изменении схемы — **поднимай версию и пиши миграцию в `_onUpgrade`**, не правь только `_onCreate` (иначе у существующих пользователей схема не обновится).

- **`users`** — пользователи. Роль `USER`/`ADMIN`, `is_active`, `must_change_password`, **мягкое удаление** через `is_deleted`/`deleted_at` (записи не удаляются физически).
- **`settings`** — тема/язык на пользователя (FK → users, `ON DELETE CASCADE`).
- **`app_meta`** — key-value мета: версия схемы, флаг первого запуска, временный пароль admin.
- **`audit_log`** — журнал действий над пользователями (только append + чтение, без удаления).
- **`compressor_templates`** — сохранённые наборы параметров компрессора для стенда 5.

История миграций: v1→v2 добавила мягкое удаление + audit_log; v2→v3 добавила compressor_templates.

### Первый запуск
`_seedAdmin` создаёт ADMIN: `username=admin`, временный пароль = тоже `admin` (хранится в `app_meta.admin_temp_password` для показа), `must_change_password=1`. Пароли — **SHA-256 + соль на пользователя** (`core/utils/password_hasher.dart`), никогда не в открытом виде.

---

## Модуль стендов (`features/stands/`) — активная разработка

Это **главный экран и текущая основная работа** (вопреки более старым заметкам о «пустом центре» — центр давно заполнен стендами).

`home_screen.dart` показывает 5 карточек-стендов в ряд:

| Стенд | Назначение | Маршрут карточки |
|---|---|---|
| 1 | малый двигатель (`kStand1MaxPowerKwt = 22 кВт`) | `/stand-1` |
| 2 | средний двигатель (`kStand2MaxPowerKwt = 170 кВт`) | `/stand-2` |
| 3 | средний двигатель (`kStand3MaxPowerKwt = 170 кВт`) | `/stand-3` |
| 4 | большой двигатель | `/stand-4` |
| 5 | компрессор | `/stand-5/compressor` |

Поток: карточка стенда → экран выбора режима (`stand_N_screen.dart`) → выбор **«С нагрузкой»** (`/stand-N/loaded` → `StandTestScreen`) или **«Без нагрузки»** (`/stand-N/unloaded` → `MotorParamsUnloadedScreen` → форма параметров → `StandUnloadedResultScreen`). Стенд 5 (компрессор) ведёт на `CompressorParamsScreen` с шаблонами из `compressor_templates`.

`StandTestScreen` пока заглушка (только заголовок) — сюда придёт реальная логика тестирования. PDF-экспорт результатов планируется через пакеты `pdf` + `printing` (уже в зависимостях).

---

## Конвенции

- Файлы — `snake_case.dart`, классы — `PascalCase`, приватное — с `_`.
- Один переиспользуемый/крупный (>~100 строк) виджет — один файл.
- RBAC: раздел «Пользователи» в настройках виден только ADMIN; проверка роли — и в UI, и в репозитории. Нельзя деактивировать себя или последнего активного ADMIN.
- Сессия живёт только в памяти (`AuthProvider`), при закрытии приложения сбрасывается. Никакого автологина/«запомнить меня».
- Тема/язык до логина хранятся в `SharedPreferences` (ключи `kPrefs*`), после логина — в таблице `settings`.

---

## Чего НЕ делать

- Не добавлять mobile/web платформы, сетевые API, облачные сервисы, аналитику.
- Не возвращать «сырые» Map из репозиториев в UI там, где есть модель (`data/models/`) — используй модели.
- Не менять схему БД без поднятия `kDatabaseVersion` и миграции.
- Не хардкодить строки (→ локализация), цвета (→ тема), магические значения (→ `config.dart`).
- Не физически удалять пользователей — только мягкое удаление (`is_deleted`).

# План: Окно теста двигателя до 22 кВт «Без нагрузки» (Стенд 1)

> Статус: **черновик, ожидает реализации**
> Дата создания: 2026-06-29
> Связано: `lib/features/stands/`, `docs/SPECIFICATION.md` (раздел 8)

Этот файл — точка возврата. Если разработка прервётся — открыть его, свериться с чеклистом
в конце (раздел 12) и продолжить с первого незакрытого пункта.

---

## 0. Решения, согласованные с заказчиком (Мурад)

| Вопрос | Решение |
|---|---|
| Показатели фазы 2 (напряжение/ток/мощность/обороты/нагрев) | **Сразу live-графики** (пакет `fl_chart`) |
| Хранение измерений в БД | **Отдельная таблица тайм-серии** (`test_measurements`) |
| Авария (КЗ/обрыв/пробой/КЗ на корпус) и экстренный стоп | **Стоп + статус в БД + разблокировать выход** |
| Мок ПЛС | **Абстракция `PlcDataSource` + мок-реализация `MockPlcDataSource`** |

Открытый вопрос (решить по ходу/уточнить): делать ли экран теста сразу переиспользуемым
для стендов 2 и 3 (у них тоже есть режим «Без нагрузки»). **План написан переиспользуемо**
(экран принимает `standId` + `maxPowerKwt`), подключение стендов 2/3 — отдельным маленьким шагом.

---

## 1. Поток (big picture)

```
Stand1Screen → «Без нагрузки»
   → MotorParamsUnloadedScreen (форма 5 полей)
   → кнопка «СТАРТ» (валидно)
   → пишем test_runs(status=running) + параметры в БД
   → StandTestUnloadedScreen:
        Фаза 1 (омметры, приходят раньше) → центр, анимация «от маленького к большому»
           ├─ OK   → карточка уезжает наверх строкой с зелёной галочкой ✓
           └─ авария (КЗ межвитковое / обрыв / пробой по ВН / КЗ на корпус)
                    → крупная ошибка в центре, status=failed_*, запись в БД, выход разблокирован
        Фаза 2 (параллельно во времени) → карточки метрик появляются по приходу данных,
           внутри live-график (fl_chart) + текущее число
        Кнопка «Экстренное завершение» (красная, всегда видна) → подтверждение → status=aborted
        Завершение → выход разблокирован, кнопка «Завершить»
```

Требования из ТЗ (docs/текст), к которым привязан план:
- (1) на «Старт» — переход в тест + параллельная запись запуска и параметров в БД; измерения пишутся для графиков/отчётов.
- (2) данные из ПЛС с текущим временем; ПЛС не готова → мок; данные приходят постепенно и параллельно, омметры — раньше остальных.
- (3) сначала мегаомметр/микроомметр и их результат; после, если нет КЗ/обрыва/пробоя/КЗ на корпус — остальные окна (напряжение/ток/мощность/обороты/нагрев).
- (4) показатели появляются в момент начала измерений; плавные анимации появления окон (от маленького к большому).
- (5) фаза 1 — в центре с анимацией; после успеха омметров уезжают наверх как текст с зелёными галочками; проблема — в центре + запись в БД; ошибки приходят из ПЛС.
- (6) пока тест не завершён — назад нельзя.
- (7) кнопка экстренного завершения.
- (8) все действия — в БД для архива и отчёта.

---

## 2. База данных (схема v3 → v4)

`config.dart`: `kDatabaseVersion = 4`. Миграция в `database_helper.dart::_onUpgrade` (`if (oldVersion < 4)`),
а также добавить создание таблиц в `_onCreate` (вынести в `_createTestTables(db)` и вызвать из обоих мест).

### `test_runs`
```
id              INTEGER PK AUTOINCREMENT
stand_id        INTEGER NOT NULL
test_mode       TEXT    NOT NULL          -- 'unloaded'
power_kwt       REAL    NOT NULL
voltage_v       REAL    NOT NULL
current_a       REAL    NOT NULL
speed_rpm       REAL    NOT NULL
frequency_hz    REAL    NOT NULL
status          TEXT    NOT NULL          -- running|passed|failed_interturn|failed_break|failed_hv_breakdown|failed_ground|aborted
error_code      TEXT                      -- nullable
insulation_mohm REAL                      -- итог мегаомметра, nullable
winding_resistance REAL                   -- итог микроомметра, nullable
started_by_id   INTEGER NOT NULL
started_by_name TEXT    NOT NULL
started_at      TEXT    NOT NULL
finished_at     TEXT                      -- nullable
```

### `test_measurements`
```
id          INTEGER PK AUTOINCREMENT
run_id      INTEGER NOT NULL REFERENCES test_runs(id) ON DELETE CASCADE
metric      TEXT    NOT NULL  -- voltage|current|power|speed|temperature|insulation|winding
value       REAL    NOT NULL
unit        TEXT    NOT NULL
recorded_at TEXT    NOT NULL
```
Индекс: `CREATE INDEX idx_measurements_run_metric ON test_measurements(run_id, metric)`.

### `test_events`
```
id         INTEGER PK AUTOINCREMENT
run_id     INTEGER NOT NULL REFERENCES test_runs(id) ON DELETE CASCADE
event_type TEXT    NOT NULL  -- start|phase1_ok|measurement|error|emergency_stop|finish
message    TEXT
created_at TEXT    NOT NULL
```

---

## 3. Модели (`lib/data/models/`)

- `motor_params.dart` — `MotorParams` (power/voltage/current/speed/frequency), value-object для передачи формы → тест.
- `test_run.dart` — `TestRun` + `enum TestStatus`, `enum TestMode`. `fromMap/toMap/copyWith`.
- `test_measurement.dart` — `TestMeasurement` + `enum MetricType` (с unit'ами).
- `test_event.dart` — `TestEvent` + `enum TestEventType`.

Конвенция: enum'ы сериализуются в строковые значения колонок (как роли пользователей в проекте).

---

## 4. Репозиторий (`lib/data/repositories/test_repository.dart`)

- `Future<TestRun> createRun({required TestRun run})` — insert + `test_events(start)`.
- `Future<void> addMeasurement(TestMeasurement m)` / `addMeasurementsBatch(List)`.
- `Future<void> addEvent(TestEvent e)`.
- `Future<void> finishRun({required int runId, required TestStatus status, String? errorCode, double? insulation, double? winding})` — update + `test_events(finish|error|emergency_stop)`.
- На будущее (отчёты): `getRunsByStand(standId)`, `getMeasurements(runId)`.

---

## 5. Источник данных ПЛС (`lib/data/services/plc/`)

- `plc_models.dart` — `PlcReading` (metric, value, unit, ts), `PlcEvent` (sealed/типы: `OmmeterReading`, `Phase1Result{ok,errorCode}`, `MetricReading`, `TestFinished`).
- `plc_data_source.dart` — абстрактный интерфейс:
  ```
  abstract class PlcDataSource {
    Stream<PlcEvent> get events;
    Future<void> start(MotorParams params);
    Future<void> stop();           // штатное завершение
    Future<void> emergencyStop();  // экстренный стоп
    void dispose();
  }
  ```
- `mock_plc_data_source.dart` — реализация на таймерах:
  - сначала эмитит показания омметров (раньше всего), затем `Phase1Result`;
  - при ok — параллельно «оживляет» voltage/current/power/speed/temperature и плавно меняет их со временем (тренд + лёгкий рандом);
  - тайминги/диапазоны — из `config.dart`;
  - по умолчанию успешный сценарий; есть флаг/режим для моделирования аварии (проверка ветки ошибок).

Реальная ПЛС позднее = новая реализация `PlcDataSource`, UI не меняется.

---

## 6. Контроллер состояния (`lib/features/stands/test/test_controller.dart`)

`TestController extends ChangeNotifier`:
- принимает `PlcDataSource` + `TestRepository` + `MotorParams` + `standId` + текущего пользователя;
- `start()` создаёт запись запуска, подписывается на `events`, агрегирует состояние (фаза, map текущих метрик, история точек для графиков, статус, errorCode);
- пишет измерения/события в репозиторий;
- `emergencyStop()`; `dispose()` отписывается и закрывает источник.

Создаётся локально на экране (`ChangeNotifierProvider` в дереве экрана), не в глобальном `MultiProvider`.

---

## 7. UI (`lib/features/stands/test/`)

- `stand_test_unloaded_screen.dart` — экран теста:
  - параметры (`MotorParams`, `standId`) из `RouteSettings.arguments`;
  - `PopScope(canPop: false ...)` пока тест идёт (п.6); `AppHeader` без кнопки «назад»;
  - фаза 1 по центру; после успеха омметры → строки с ✓ наверху; ошибка → overlay в центре;
  - фаза 2 — сетка карточек метрик, появление с анимацией scale (от маленького к большому);
  - красная кнопка «Экстренное завершение» с диалогом подтверждения;
  - по завершении — кнопка «Завершить» (Navigator.pop).
- `widgets/ommeter_phase_card.dart` — карточка фазы 1 (живые показания + переход в строку с ✓).
- `widgets/metric_card.dart` — карточка метрики: заголовок, текущее число + единица, **live-график fl_chart**.
- `widgets/test_error_overlay.dart` — крупная ошибка в центре (текст из локализации по `errorCode`).

Анимации — на уже подключённом `flutter_animate` (fadeIn + scale begin 0.x). Цвета статусов — `AppColors.success/error/warning`. Никаких хардкодов строк/цветов/чисел.

---

## 8. Навигация и конфиг (`config.dart`, `router.dart`, форма)

- `config.dart`: `kRouteStandUnloadedTest = '/stand/unloaded/test'`; тайминги мока (`kMockPhase1DelayMs`, интервал тиков, и т.п.); имена метрик/единицы (если нужны константы).
- `motor_params_unloaded_screen.dart`: подпись кнопки → «Старт» (ключ `motor_params_start`); передавать `MotorParams` + `standId` через `Navigator.pushNamed(context, kRouteStandUnloadedTest, arguments: {...})`.
- `router.dart`: в `_AuthGuard` достать `settings.arguments` (прокинуть через конструктор guard) и построить `StandTestUnloadedScreen`.
- `StandUnloadedResultScreen` (заглушка «Модуль в разработке») — удалить/заменить новым экраном; убрать `kRouteStandUnloadedResult` или перенаправить.

---

## 9. Локализация (`assets/translations/{en,az,ru}.json`)

Добавить во **все три** файла ключи: метрики (voltage/current/power/speed/temperature/insulation/winding),
единицы (если нет), фазы, статусы, тексты ошибок (КЗ межвитковое, обрыв, пробой по ВН, КЗ на корпус),
кнопки (старт, экстренное завершение, завершить), подтверждение выхода/стопа.

---

## 10. Зависимости (`pubspec.yaml`)

- Добавить `fl_chart` (последняя стабильная). `flutter pub get`.

---

## 11. Документация (обязательно — «все изменения в документ»)

- `docs/SPECIFICATION.md` — раздел 8: описать новый поток, экран теста, фазы, мок ПЛС; добавить новые таблицы БД в раздел схемы; снять отметку «заглушка» со `StandUnloadedResultScreen`.
- `CLAUDE.md` — обновить схему БД (v4 + 3 таблицы), описать модуль теста и `fl_chart`, поправить таблицу маршрутов.
- Обновить этот файл (`PLAN.md`) — отмечать выполненные пункты в чеклисте.

---

## 12. Чеклист выполнения (отмечать по ходу)

- [x] 2. БД: `kDatabaseVersion=4`, `_createTestTables`, миграция `_onUpgrade`
- [x] 3. Модели: MotorParams, TestRun(+enums), TestMeasurement(+enum), TestEvent(+enum)
- [x] 4. `TestRepository` (create/addMeasurement/addEvent/finish/getters)
- [x] 5. ПЛС: `plc_models`, `PlcDataSource`, `MockPlcDataSource`
- [x] 6. `TestController`
- [x] 7. UI: экран теста + ommeter_phase_card + metric_card(график) + error_overlay
- [x] 8. Навигация/конфиг: маршрут, передача аргументов, кнопка «Старт», router
- [x] 9. Локализация en/az/ru
- [x] 10. `fl_chart` в pubspec + pub get
- [x] 11. Документация: SPECIFICATION.md, CLAUDE.md, этот PLAN.md
- [~] 12. Проверка: `flutter analyze` чисто ✅, `dart format` ✅, сборка `flutter build linux` —
        ⏳ ручной прогон (успех / авария / экстренный стоп) за оператором

---

## 13. Критерии готовности (Verify)

1. `flutter analyze` — без ошибок/ворнингов по новому коду.
2. На «Старт» появляется запись в `test_runs(status=running)` с параметрами.
3. Омметры приходят раньше, рисуются в центре с анимацией, при успехе уезжают наверх с ✓.
4. Метрики фазы 2 появляются по приходу данных с анимацией «от маленького к большому», графики живые.
5. Авария → ошибка в центре + `status=failed_*` + `error_code` в БД; выход разблокирован.
6. Экстренный стоп → `status=aborted` + событие в БД; выход разблокирован.
7. Пока тест идёт — «назад» заблокирован.
8. Измерения лежат в `test_measurements`, события — в `test_events`.

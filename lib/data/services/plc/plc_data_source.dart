import '../../models/motor_params.dart';
import 'plc_models.dart';

/// Абстракция источника данных ПЛС.
///
/// Сейчас реализована моком ([MockPlcDataSource]); когда появится реальная ПЛС —
/// добавим её реализацию этого же интерфейса, не трогая UI и контроллер.
abstract class PlcDataSource {
  /// Поток событий теста (показания, результат фазы 1, финиш).
  Stream<PlcEvent> get events;

  /// Запускает тест с заданными параметрами двигателя.
  Future<void> start(MotorParams params);

  /// Штатная остановка (по завершении теста).
  Future<void> stop();

  /// Экстренная остановка по команде оператора.
  Future<void> emergencyStop();

  /// Освобождает ресурсы (таймеры, подписки, контроллер потока).
  void dispose();
}

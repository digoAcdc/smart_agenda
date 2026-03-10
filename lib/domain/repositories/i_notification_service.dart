import '../../core/result/result.dart';
import '../entities/agenda_item.dart';

abstract class INotificationService {
  Future<Result<void>> init({
    Future<void> Function(String? payload)? onNotificationTap,
  });
  Future<Result<bool>> ensurePermissions();
  Future<Result<void>> scheduleForItem(AgendaItem item);
  Future<Result<void>> cancelForItem(AgendaItem item);
  Future<Result<void>> scheduleDailySummary();
  /// Exibe notificação push imediata (ex: FCM em foreground).
  Future<Result<void>> showPush(String title, String body, {String? payload});
}

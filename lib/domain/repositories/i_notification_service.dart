import '../../core/result/result.dart';
import '../entities/agenda_item.dart';

abstract class INotificationService {
  Future<Result<void>> init();
  Future<Result<bool>> ensurePermissions();
  Future<Result<void>> scheduleForItem(AgendaItem item);
  Future<Result<void>> cancelForItem(AgendaItem item);
  Future<Result<void>> scheduleDailySummary();
}

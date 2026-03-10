import '../../domain/entities/class_schedule_slot.dart';
import '../../domain/repositories/i_class_schedule_datasource.dart';
import '../../domain/repositories/i_sync_service.dart';

/// Sempre usa local (offline-first); sync envia para nuvem quando premium.
class ClassScheduleDataSourceOrchestrator implements IClassScheduleDataSource {
  ClassScheduleDataSourceOrchestrator(this._local, this._syncService);

  final IClassScheduleDataSource _local;
  final ISyncService _syncService;

  void _scheduleSync() => _syncService.syncNow();

  @override
  Future<List<ClassScheduleSlot>> getSlots() => _local.getSlots();

  @override
  Future<String?> addTimeRange(int start, int end) async {
    final result = await _local.addTimeRange(start, end);
    if (result == null) _scheduleSync();
    return result;
  }

  @override
  Future<void> updateSlotDetails(
    String id, {
    String? subject,
    String? professorName,
    String? professorEmail,
    String? professorPhone,
  }) async {
    await _local.updateSlotDetails(
      id,
      subject: subject,
      professorName: professorName,
      professorEmail: professorEmail,
      professorPhone: professorPhone,
    );
    _scheduleSync();
  }

  @override
  Future<void> removeTimeRange(int start, int end) async {
    await _local.removeTimeRange(start, end);
    _scheduleSync();
  }
}

import '../../domain/entities/class_schedule_slot.dart';
import '../../domain/repositories/i_class_schedule_datasource.dart';
import '../../domain/repositories/i_sync_service.dart';

/// Sempre usa local (offline-first); o sync envia a grade pessoal (Pro)
/// e as grades dos filhos (Familia).
class ClassScheduleDataSourceOrchestrator implements IClassScheduleDataSource {
  ClassScheduleDataSourceOrchestrator(this._local, this._syncService);

  final IClassScheduleDataSource _local;
  final ISyncService _syncService;

  void _scheduleSync() => _syncService.syncNow();

  @override
  Future<List<ClassScheduleSlot>> getSlots(ScheduleOwner owner) =>
      _local.getSlots(owner);

  @override
  Future<List<ClassScheduleSlot>> getAllSlots() => _local.getAllSlots();

  @override
  Future<String?> addTimeRange(ScheduleOwner owner, int start, int end) async {
    final result = await _local.addTimeRange(owner, start, end);
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
  Future<String?> updateTimeRange(
    ScheduleOwner owner,
    int oldStart,
    int oldEnd,
    int newStart,
    int newEnd,
  ) async {
    final result =
        await _local.updateTimeRange(owner, oldStart, oldEnd, newStart, newEnd);
    if (result == null) _scheduleSync();
    return result;
  }

  @override
  Future<void> removeTimeRange(ScheduleOwner owner, int start, int end) async {
    await _local.removeTimeRange(owner, start, end);
    _scheduleSync();
  }
}

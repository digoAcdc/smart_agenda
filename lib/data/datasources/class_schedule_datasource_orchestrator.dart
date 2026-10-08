import '../../domain/entities/class_schedule_slot.dart';
import '../../domain/repositories/i_class_schedule_datasource.dart';
import '../../domain/repositories/i_sync_service.dart';

/// Sempre usa local (offline-first); o sync envia as grades pessoais (Pro)
/// e as grades dos filhos (Familia).
class ClassScheduleDataSourceOrchestrator implements IClassScheduleDataSource {
  ClassScheduleDataSourceOrchestrator(this._local, this._syncService);

  final IClassScheduleDataSource _local;
  final ISyncService _syncService;

  void _scheduleSync() => _syncService.syncNow();

  Future<T> _thenSync<T>(Future<T> action) async {
    final result = await action;
    _scheduleSync();
    return result;
  }

  @override
  Future<List<ClassSchedule>> getSchedules() => _local.getSchedules();

  @override
  Future<ClassSchedule> createSchedule({
    required String name,
    String? familyId,
    String? childId,
  }) =>
      _thenSync(_local.createSchedule(
        name: name,
        familyId: familyId,
        childId: childId,
      ));

  @override
  Future<void> renameSchedule(String id, String name) =>
      _thenSync(_local.renameSchedule(id, name));

  @override
  Future<void> deleteSchedule(ClassSchedule schedule) =>
      _thenSync(_local.deleteSchedule(schedule));

  @override
  Future<List<ClassScheduleSlot>> getSlots(ClassSchedule schedule) =>
      _local.getSlots(schedule);

  @override
  Future<List<ClassScheduleSlot>> getAllSlots() => _local.getAllSlots();

  @override
  Future<String?> addTimeRange(ClassSchedule schedule, int start, int end) =>
      _thenSync(_local.addTimeRange(schedule, start, end));

  @override
  Future<void> updateSlotDetails(
    String id, {
    String? subject,
    String? professorName,
    String? professorEmail,
    String? professorPhone,
  }) =>
      _thenSync(_local.updateSlotDetails(
        id,
        subject: subject,
        professorName: professorName,
        professorEmail: professorEmail,
        professorPhone: professorPhone,
      ));

  @override
  Future<void> removeTimeRange(ClassSchedule schedule, int start, int end) =>
      _thenSync(_local.removeTimeRange(schedule, start, end));

  @override
  Future<String?> updateTimeRange(
    ClassSchedule schedule,
    int oldStart,
    int oldEnd,
    int newStart,
    int newEnd,
  ) =>
      _thenSync(_local.updateTimeRange(schedule, oldStart, oldEnd, newStart, newEnd));
}

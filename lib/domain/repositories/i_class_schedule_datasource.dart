import '../entities/class_schedule_slot.dart';

/// Data source para slots de horario de aula (local ou Supabase).
abstract class IClassScheduleDataSource {
  Future<List<ClassScheduleSlot>> getSlots();

  Future<String?> addTimeRange(int start, int end);

  Future<void> updateSubject(String id, String? subject);

  Future<void> removeTimeRange(int start, int end);
}

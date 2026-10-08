import '../entities/class_schedule_slot.dart';

/// Grades horarias com nome ([ClassSchedule]) e suas aulas.
abstract class IClassScheduleDataSource {
  Future<List<ClassSchedule>> getSchedules();

  /// Com [childId] a grade e da Familia; sem, e pessoal.
  Future<ClassSchedule> createSchedule({
    required String name,
    String? familyId,
    String? childId,
  });

  Future<void> renameSchedule(String id, String name);

  /// Exclui a grade e suas aulas.
  Future<void> deleteSchedule(ClassSchedule schedule);

  Future<List<ClassScheduleSlot>> getSlots(ClassSchedule schedule);

  /// Aulas de todas as grades, para a Home.
  Future<List<ClassScheduleSlot>> getAllSlots();

  Future<String?> addTimeRange(ClassSchedule schedule, int start, int end);

  Future<void> updateSlotDetails(
    String id, {
    String? subject,
    String? professorName,
    String? professorEmail,
    String? professorPhone,
  });

  Future<void> removeTimeRange(ClassSchedule schedule, int start, int end);

  /// Muda o horario de uma linha inteira (todos os dias).
  Future<String?> updateTimeRange(
    ClassSchedule schedule,
    int oldStart,
    int oldEnd,
    int newStart,
    int newEnd,
  );
}

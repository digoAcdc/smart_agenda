import '../entities/class_schedule_slot.dart';

/// Grade horaria: pessoal ou de um filho da Familia ([ScheduleOwner]).
abstract class IClassScheduleDataSource {
  Future<List<ClassScheduleSlot>> getSlots(ScheduleOwner owner);

  /// Todas as grades (pessoal e dos filhos), para a Home.
  Future<List<ClassScheduleSlot>> getAllSlots();

  Future<String?> addTimeRange(ScheduleOwner owner, int start, int end);

  Future<void> updateSlotDetails(
    String id, {
    String? subject,
    String? professorName,
    String? professorEmail,
    String? professorPhone,
  });

  Future<void> removeTimeRange(ScheduleOwner owner, int start, int end);

  /// Muda o horario de uma linha inteira (todos os dias).
  Future<String?> updateTimeRange(
    ScheduleOwner owner,
    int oldStart,
    int oldEnd,
    int newStart,
    int newEnd,
  );
}

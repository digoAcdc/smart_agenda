import 'package:equatable/equatable.dart';

/// De quem e a grade: a propria (pessoal) ou de um filho da Familia.
class ScheduleOwner extends Equatable {
  const ScheduleOwner.mine()
      : familyId = null,
        childId = null;
  const ScheduleOwner.child({required String this.familyId, required String this.childId});

  final String? familyId;
  final String? childId;

  bool get isChild => childId != null;

  @override
  List<Object?> get props => [familyId, childId];
}

/// Slot de horario de aula (domain entity, independente de Drift/Supabase).
class ClassScheduleSlot extends Equatable {
  const ClassScheduleSlot({
    required this.id,
    required this.dayOfWeek,
    required this.startMinutes,
    required this.endMinutes,
    this.subject,
    this.professorName,
    this.professorEmail,
    this.professorPhone,
    this.familyId,
    this.childId,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final int dayOfWeek;
  final int startMinutes;
  final int endMinutes;
  final String? subject;
  final String? professorName;
  final String? professorEmail;
  final String? professorPhone;

  /// Preenchidos quando a grade e de um filho da Familia.
  final String? familyId;
  final String? childId;
  final DateTime createdAt;
  final DateTime updatedAt;

  ScheduleOwner get owner => childId == null
      ? const ScheduleOwner.mine()
      : ScheduleOwner.child(familyId: familyId!, childId: childId!);

  @override
  List<Object?> get props => [
        id,
        dayOfWeek,
        startMinutes,
        endMinutes,
        subject,
        professorName,
        professorEmail,
        professorPhone,
        familyId,
        childId,
        createdAt,
        updatedAt,
      ];
}

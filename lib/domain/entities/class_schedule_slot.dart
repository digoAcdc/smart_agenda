import 'package:equatable/equatable.dart';

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
  final DateTime createdAt;
  final DateTime updatedAt;

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
        createdAt,
        updatedAt,
      ];
}

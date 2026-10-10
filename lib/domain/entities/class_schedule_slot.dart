import 'package:equatable/equatable.dart';

/// Grade com nome. Com filho = da Familia (compartilhada); sem filho = pessoal.
class ClassSchedule extends Equatable {
  const ClassSchedule({
    required this.id,
    required this.name,
    this.familyId,
    this.childId,
    this.bringItems = const {},
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String name;
  final String? familyId;
  final String? childId;

  /// "O que levar" por materia (Mochila de amanha).
  final Map<String, String> bringItems;
  final DateTime createdAt;
  final DateTime updatedAt;

  bool get isFamily => familyId != null;

  @override
  List<Object?> get props => [
    id,
    name,
    familyId,
    childId,
    bringItems,
    createdAt,
    updatedAt,
  ];
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
    this.scheduleId,
    this.familyId,
    this.childId,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String? scheduleId;
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

  @override
  List<Object?> get props => [
    id,
    scheduleId,
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

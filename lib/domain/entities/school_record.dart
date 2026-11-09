import 'package:equatable/equatable.dart';

/// Falta ou nota.
enum SchoolRecordKind { absence, grade }

/// Um lancamento de Notas e faltas de uma materia da grade.
class SchoolRecord extends Equatable {
  const SchoolRecord({
    required this.id,
    required this.scheduleId,
    required this.subject,
    required this.kind,
    required this.date,
    this.title,
    this.score,
    this.maxScore,
    this.term,
    this.note,
    this.familyId,
    this.childId,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String scheduleId;
  final String subject;
  final SchoolRecordKind kind;

  /// Dia da falta ou da avaliacao.
  final DateTime date;

  /// Nome da avaliacao ("Prova 1"); so em nota.
  final String? title;
  final double? score;

  /// Nota maxima da avaliacao (padrao 10).
  final double? maxScore;

  /// Bimestre (1 a 4); so em nota.
  final int? term;

  /// Observacao livre.
  final String? note;

  /// Preenchidos quando a grade e da Familia.
  final String? familyId;
  final String? childId;
  final DateTime createdAt;
  final DateTime updatedAt;

  bool get isAbsence => kind == SchoolRecordKind.absence;

  /// Nota na escala 0-10 (nulo se faltar nota ou maximo valido).
  double? get scoreOutOf10 {
    final s = score;
    final max = maxScore ?? 10;
    if (s == null || max <= 0) return null;
    return s / max * 10;
  }

  SchoolRecord copyWith({
    DateTime? date,
    String? title,
    double? score,
    double? maxScore,
    int? term,
    String? note,
  }) => SchoolRecord(
    id: id,
    scheduleId: scheduleId,
    subject: subject,
    kind: kind,
    date: date ?? this.date,
    title: title ?? this.title,
    score: score ?? this.score,
    maxScore: maxScore ?? this.maxScore,
    term: term ?? this.term,
    note: note ?? this.note,
    familyId: familyId,
    childId: childId,
    createdAt: createdAt,
    updatedAt: updatedAt,
  );

  @override
  List<Object?> get props => [
    id,
    scheduleId,
    subject,
    kind,
    date,
    title,
    score,
    maxScore,
    term,
    note,
    familyId,
    childId,
    createdAt,
    updatedAt,
  ];
}

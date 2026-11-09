import '../entities/school_record.dart';

/// Resumo de uma materia na aba Notas e faltas.
class SubjectRecordsSummary {
  const SubjectRecordsSummary({
    required this.subject,
    required this.absences,
    required this.grades,
    required this.average,
  });

  final String subject;

  /// Faltas no ano (faltas nao tem bimestre).
  final int absences;

  /// Notas do filtro (bimestre ou ano), mais recentes primeiro.
  final List<SchoolRecord> grades;

  /// Media 0-10 das notas do filtro; nulo sem nota.
  final double? average;
}

/// Bimestre de uma data no calendario escolar comum: fev-abr = 1o,
/// mai-jul = 2o, ago-set = 3o, out-jan = 4o (janeiro fecha o ano anterior).
int termForDate(DateTime date) => switch (date.month) {
  2 || 3 || 4 => 1,
  5 || 6 || 7 => 2,
  8 || 9 => 3,
  _ => 4,
};

/// Media simples 0-10 (cada nota convertida pela nota maxima dela).
double? averageOf(Iterable<SchoolRecord> grades) {
  final values = [
    for (final g in grades)
      if (!g.isAbsence && g.scoreOutOf10 != null) g.scoreOutOf10!,
  ];
  if (values.isEmpty) return null;
  return values.reduce((a, b) => a + b) / values.length;
}

/// Um resumo por materia, na ordem de [subjects] (as da grade). Lancamentos
/// de materia que saiu da grade ficam no fim, para nao sumirem.
/// [term] nulo = ano todo.
List<SubjectRecordsSummary> summarizeBySubject({
  required List<String> subjects,
  required List<SchoolRecord> records,
  int? term,
}) {
  final ordered = <String>{...subjects, for (final r in records) r.subject};
  return [
    for (final subject in ordered)
      _summarize(subject, records.where((r) => r.subject == subject), term),
  ];
}

SubjectRecordsSummary _summarize(
  String subject,
  Iterable<SchoolRecord> records,
  int? term,
) {
  final grades =
      records
          .where((r) => !r.isAbsence && (term == null || r.term == term))
          .toList()
        ..sort((a, b) => b.date.compareTo(a.date));
  return SubjectRecordsSummary(
    subject: subject,
    absences: records.where((r) => r.isAbsence).length,
    grades: grades,
    average: averageOf(grades),
  );
}

/// "7,5" / "10" (virgula, uma casa so quando precisa).
String formatScore(double value) {
  final rounded = (value * 10).round() / 10;
  final text = rounded == rounded.roundToDouble()
      ? rounded.toStringAsFixed(0)
      : rounded.toStringAsFixed(1);
  return text.replaceAll('.', ',');
}

/// Le "7,5" ou "7.5"; nulo se invalido ou negativo.
double? parseScore(String raw) {
  final value = double.tryParse(raw.trim().replaceAll(',', '.'));
  if (value == null || value < 0) return null;
  return value;
}

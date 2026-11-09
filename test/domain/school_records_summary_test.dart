import 'package:flutter_test/flutter_test.dart';
import 'package:smart_agenda/domain/entities/school_record.dart';
import 'package:smart_agenda/domain/services/school_records_summary.dart';

SchoolRecord _grade(
  String subject,
  double score, {
  double max = 10,
  int term = 1,
  DateTime? date,
}) => SchoolRecord(
  id: '$subject-$score-$term-$max',
  scheduleId: 'g',
  subject: subject,
  kind: SchoolRecordKind.grade,
  date: date ?? DateTime(2026, 3, 10),
  score: score,
  maxScore: max,
  term: term,
  createdAt: DateTime(2026),
  updatedAt: DateTime(2026),
);

SchoolRecord _absence(String subject, DateTime date) => SchoolRecord(
  id: '$subject-falta-$date',
  scheduleId: 'g',
  subject: subject,
  kind: SchoolRecordKind.absence,
  date: date,
  createdAt: DateTime(2026),
  updatedAt: DateTime(2026),
);

void main() {
  test('media converte cada nota pela nota maxima dela', () {
    // 8/10 = 8 e 15/20 = 7,5 -> media 7,75.
    expect(averageOf([_grade('Mat', 8), _grade('Mat', 15, max: 20)]), 7.75);
    expect(averageOf([]), isNull);
    expect(averageOf([_absence('Mat', DateTime(2026, 3, 1))]), isNull);
  });

  test('resumo por materia: ordem da grade, bimestre e faltas do ano', () {
    final records = [
      _grade('Português', 6, term: 1),
      _grade('Português', 10, term: 2),
      _absence('Português', DateTime(2026, 3, 2)),
      _absence('Português', DateTime(2026, 6, 2)),
      _grade('Matemática', 9, term: 1),
    ];
    final first = summarizeBySubject(
      subjects: ['Matemática', 'Português', 'Inglês'],
      records: records,
      term: 1,
    );
    expect(first.map((s) => s.subject), ['Matemática', 'Português', 'Inglês']);
    expect(first[1].average, 6);
    expect(first[1].grades.length, 1);
    expect(first[1].absences, 2); // faltas valem o ano todo
    expect(first[2].average, isNull);
    expect(first[2].absences, 0);

    final year = summarizeBySubject(
      subjects: ['Matemática', 'Português'],
      records: records,
    );
    expect(year[1].average, 8);
    expect(year[1].grades.length, 2);
  });

  test('materia que saiu da grade continua aparecendo (nao perde nota)', () {
    final summaries = summarizeBySubject(
      subjects: ['Matemática'],
      records: [_grade('Artes', 7)],
    );
    expect(summaries.map((s) => s.subject), ['Matemática', 'Artes']);
  });

  test('bimestre pela data', () {
    expect(termForDate(DateTime(2026, 2, 10)), 1);
    expect(termForDate(DateTime(2026, 4, 30)), 1);
    expect(termForDate(DateTime(2026, 5, 2)), 2);
    expect(termForDate(DateTime(2026, 8, 1)), 3);
    expect(termForDate(DateTime(2026, 11, 9)), 4);
    expect(termForDate(DateTime(2027, 1, 15)), 4);
  });

  test('nota com virgula: ler e mostrar', () {
    expect(parseScore('7,5'), 7.5);
    expect(parseScore(' 8.25 '), 8.25);
    expect(parseScore('abc'), isNull);
    expect(parseScore('-1'), isNull);
    expect(formatScore(7.5), '7,5');
    expect(formatScore(10), '10');
    expect(formatScore(7.75), '7,8');
  });
}

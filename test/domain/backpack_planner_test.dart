import 'package:flutter_test/flutter_test.dart';
import 'package:smart_agenda/domain/entities/class_schedule_slot.dart';
import 'package:smart_agenda/domain/services/backpack_planner.dart';

ClassSchedule _schedule(String id, String name, Map<String, String> bring) =>
    ClassSchedule(
      id: id,
      name: name,
      bringItems: bring,
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
    );

ClassScheduleSlot _slot(
  String scheduleId,
  int day,
  int start,
  String subject,
) => ClassScheduleSlot(
  id: '$scheduleId-$day-$start',
  scheduleId: scheduleId,
  dayOfWeek: day,
  startMinutes: start,
  endMinutes: start + 50,
  subject: subject,
  createdAt: DateTime(2026),
  updatedAt: DateTime(2026),
);

void main() {
  // Domingo, 11/10/2026, 10h.
  final now = DateTime(2026, 10, 11, 10);

  test('aviso na noite anterior com o que levar de cada materia do dia', () {
    final plans = buildBackpackPlans(
      schedules: [
        _schedule('a', 'Escola', {
          'Ed. Física': 'tênis e uniforme',
          'Inglês': 'livro',
        }),
      ],
      slots: [
        _slot('a', 1, 420, 'Matemática'), // segunda, sem item
        _slot('a', 1, 470, 'Inglês'),
        _slot('a', 1, 520, 'Ed. Física'),
        _slot('a', 1, 570, 'Inglês'), // repetida: aparece uma vez
        _slot('a', 3, 420, 'Ed. Física'), // quarta
      ],
      now: now,
      ownerLabel: (s) => s.name,
    );
    // Domingo 20h (para segunda) e terca 20h (para quarta).
    expect(plans.map((p) => p.notifyAt).toList(), [
      DateTime(2026, 10, 11, 20),
      DateTime(2026, 10, 13, 20),
    ]);
    expect(plans.first.body, 'livro (Inglês) · tênis e uniforme (Ed. Física)');
    expect(plans[1].body, 'tênis e uniforme (Ed. Física)');
  });

  test('duas grades com itens: prefixa o dono', () {
    final plans = buildBackpackPlans(
      schedules: [
        _schedule('a', 'João', {'Ed. Física': 'tênis'}),
        _schedule('b', 'Maria', {'Artes': 'tinta'}),
      ],
      slots: [_slot('a', 1, 420, 'Ed. Física'), _slot('b', 1, 420, 'Artes')],
      now: now,
      ownerLabel: (s) => s.name,
      days: 1,
    );
    expect(
      plans.single.body,
      'João: tênis (Ed. Física) · Maria: tinta (Artes)',
    );
  });

  test('depois das 20h nao agenda para a noite que ja passou', () {
    final plans = buildBackpackPlans(
      schedules: [
        _schedule('a', 'Escola', {'Inglês': 'livro'}),
      ],
      slots: [_slot('a', 1, 420, 'Inglês'), _slot('a', 2, 420, 'Inglês')],
      now: DateTime(2026, 10, 11, 21),
      ownerLabel: (s) => s.name,
      days: 2,
    );
    expect(plans.map((p) => p.notifyAt).toList(), [DateTime(2026, 10, 12, 20)]);
  });

  test('sem itens cadastrados: nenhum aviso', () {
    final plans = buildBackpackPlans(
      schedules: [_schedule('a', 'Escola', {})],
      slots: [_slot('a', 1, 420, 'Inglês')],
      now: now,
      ownerLabel: (s) => s.name,
    );
    expect(plans, isEmpty);
  });
}

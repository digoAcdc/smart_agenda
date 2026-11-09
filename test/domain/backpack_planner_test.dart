import 'package:flutter_test/flutter_test.dart';
import 'package:smart_agenda/domain/entities/backpack_item.dart';
import 'package:smart_agenda/domain/entities/class_schedule_slot.dart';
import 'package:smart_agenda/domain/services/backpack_planner.dart';

/// Grade com um item "toda semana" por materia ({materia: item}).
ClassSchedule _schedule(String id, String name, Map<String, String> bring) =>
    _scheduleWith(id, name, [
      for (final e in bring.entries)
        BackpackItem(id: '${e.key}-${e.value}', subject: e.key, label: e.value),
    ]);

ClassSchedule _scheduleWith(String id, String name, List<BackpackItem> items) =>
    ClassSchedule(
      id: id,
      name: name,
      backpackItems: items,
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
    );

BackpackItem _weekly(String subject, String label) =>
    BackpackItem(id: '$subject-$label', subject: subject, label: label);

BackpackItem _once(String subject, String label, DateTime due) => BackpackItem(
  id: '$subject-$label-once',
  subject: subject,
  label: label,
  frequency: BackpackFrequency.nextClass,
  dueDate: due,
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

  group('Amanhã leve (agregacao do dia seguinte)', () {
    // Segunda, 12/10/2026: Ed. Física e Inglês (Inglês duas vezes).
    final monday = DateTime(2026, 10, 12);
    final slots = [
      _slot('a', 1, 420, 'Matemática'),
      _slot('a', 1, 470, 'Inglês'),
      _slot('a', 1, 520, 'Ed. Física'),
      _slot('a', 1, 570, 'Inglês'),
      _slot('a', 3, 420, 'Ed. Física'),
    ];

    test('junta os itens por materia, na ordem das aulas, sem repetir', () {
      final groups = backpackForDay(
        schedules: [
          _scheduleWith('a', 'Escola', [
            _weekly('Ed. Física', 'tênis'),
            _weekly('Ed. Física', 'uniforme'),
            _weekly('Inglês', 'livro'),
            _weekly('Artes', 'tinta'), // sem aula na segunda
          ]),
        ],
        slots: slots,
        day: monday,
        ownerLabel: (s) => s.name,
      );
      expect(groups.map((g) => g.subject), ['Inglês', 'Ed. Física']);
      expect(groups[1].items.map((i) => i.label), ['tênis', 'uniforme']);
      expect(groups.every((g) => g.owner == null), isTrue);
      expect(
        backpackSummary(groups),
        'livro (Inglês) · tênis e uniforme (Ed. Física)',
      );
    });

    test('"so na proxima aula" entra so no dia da aula dele', () {
      final schedule = _scheduleWith('a', 'Escola', [
        _once('Ed. Física', 'garrafinha', monday),
        _once('Ed. Física', 'autorização', DateTime(2026, 10, 14)),
      ]);
      final onMonday = backpackForDay(
        schedules: [schedule],
        slots: slots,
        day: monday,
        ownerLabel: (s) => s.name,
      );
      expect(onMonday.single.items.map((i) => i.label), ['garrafinha']);
      final onWednesday = backpackForDay(
        schedules: [schedule],
        slots: slots,
        day: DateTime(2026, 10, 14),
        ownerLabel: (s) => s.name,
      );
      expect(onWednesday.single.items.map((i) => i.label), ['autorização']);
    });

    test('dia sem aula ou sem itens: vazio (o quadro nao aparece)', () {
      final schedule = _scheduleWith('a', 'Escola', [
        _weekly('Inglês', 'livro'),
      ]);
      expect(
        backpackForDay(
          schedules: [schedule],
          slots: slots,
          day: DateTime(2026, 10, 13), // terca: sem aula
          ownerLabel: (s) => s.name,
        ),
        isEmpty,
      );
      expect(
        backpackForDay(
          schedules: [_scheduleWith('a', 'Escola', [])],
          slots: slots,
          day: monday,
          ownerLabel: (s) => s.name,
        ),
        isEmpty,
      );
    });

    test('duas grades com itens no dia: cada grupo leva o dono', () {
      final groups = backpackForDay(
        schedules: [
          _scheduleWith('a', 'Escola', [_weekly('Ed. Física', 'tênis')]),
          _scheduleWith('b', 'Escola', [_weekly('Artes', 'tinta')]),
          _scheduleWith('c', 'Cursinho', [_weekly('Física', 'calculadora')]),
        ],
        slots: [
          ...slots,
          _slot('b', 1, 420, 'Artes'),
          _slot('c', 2, 420, 'Física'), // terca: nao conta
        ],
        day: monday,
        ownerLabel: (s) => s.id == 'a' ? 'João' : 'Maria',
      );
      expect(groups.map((g) => '${g.owner}/${g.subject}'), [
        'João/Ed. Física',
        'Maria/Artes',
      ]);
    });
  });

  group('lembrete por item', () {
    // Segunda, 12/10/2026: Ed. Física e Inglês.
    final monday = DateTime(2026, 10, 12);
    final slots = [
      _slot('a', 1, 420, 'Inglês'),
      _slot('a', 1, 520, 'Ed. Física'),
    ];
    final schedule = _scheduleWith('a', 'Escola', [
      _weekly('Ed. Física', 'tênis'),
      _weekly('Ed. Física', 'uniforme').copyWith(remind: false),
      _weekly('Inglês', 'livro').copyWith(remind: false),
    ]);

    test('o aviso das 20h so leva itens com lembrete ligado', () {
      final plans = buildBackpackPlans(
        schedules: [schedule],
        slots: slots,
        now: now, // domingo 10h: aviso de domingo 20h para segunda
        ownerLabel: (s) => s.name,
      );
      expect(plans.first.notifyAt, DateTime(2026, 10, 11, 20));
      expect(plans.first.body, 'tênis (Ed. Física)');
    });

    test('a checklist "Amanhã leve" mostra todos os itens', () {
      final groups = backpackForDay(
        schedules: [schedule],
        slots: slots,
        day: monday,
        ownerLabel: (s) => s.name,
      );
      expect(groups.expand((g) => g.items).map((i) => i.label), [
        'livro',
        'tênis',
        'uniforme',
      ]);
    });

    test('dia so com itens sem lembrete: nenhum aviso', () {
      final plans = buildBackpackPlans(
        schedules: [
          _scheduleWith('a', 'Escola', [
            _weekly('Inglês', 'livro').copyWith(remind: false),
          ]),
        ],
        slots: slots,
        now: now,
        ownerLabel: (s) => s.name,
      );
      expect(plans, isEmpty);
    });

    test('com duas grades, o dono so aparece se as duas tem aviso', () {
      final groups = backpackForDay(
        schedules: [
          schedule,
          _scheduleWith('b', 'Escola', [
            _weekly('Artes', 'tinta').copyWith(remind: false),
          ]),
        ],
        slots: [...slots, _slot('b', 1, 420, 'Artes')],
        day: monday,
        ownerLabel: (s) => s.id == 'a' ? 'João' : 'Maria',
        onlyReminders: true,
      );
      expect(backpackSummary(groups), 'tênis (Ed. Física)');
    });
  });

  group('proximos dias com aula', () {
    final slots = [
      _slot('a', 1, 420, 'Ed. Física'), // segunda 07:00-07:50
      _slot('a', 3, 420, 'Ed. Física'), // quarta
      _slot('a', 3, 520, 'Ed. Física'), // quarta de novo: um dia so
    ];

    test('lista os proximos dias, sem repetir, pulando aula que acabou', () {
      // Segunda 08h: a aula de hoje ja acabou.
      expect(
        upcomingClassDates('Ed. Física', slots, DateTime(2026, 10, 12, 8)),
        [
          DateTime(2026, 10, 14),
          DateTime(2026, 10, 19),
          DateTime(2026, 10, 21),
          DateTime(2026, 10, 26),
        ],
      );
      expect(
        upcomingClassDates(
          'Ed. Física',
          slots,
          DateTime(2026, 10, 12, 7),
          count: 2,
        ),
        [DateTime(2026, 10, 12), DateTime(2026, 10, 14)],
      );
      expect(upcomingClassDates('Artes', slots, DateTime(2026, 10, 12)), []);
      expect(classWeekdays('Ed. Física', slots), [1, 3]);
    });
  });

  group('so na proxima aula', () {
    final slots = [
      _slot('a', 1, 420, 'Ed. Física'), // segunda 07:00-07:50
      _slot('a', 1, 600, 'Ed. Física'), // segunda 10:00-10:50
      _slot('a', 3, 420, 'Ed. Física'),
    ];
    final item = _once('Ed. Física', 'garrafinha', DateTime(2026, 10, 12));

    test('vale ate acabar a ultima aula da materia no dia', () {
      expect(
        isBackpackItemExpired(item, slots, DateTime(2026, 10, 12, 10, 49)),
        isFalse,
      );
      expect(
        isBackpackItemExpired(item, slots, DateTime(2026, 10, 12, 10, 50)),
        isTrue,
      );
      expect(
        isBackpackItemExpired(item, slots, DateTime(2026, 10, 13)),
        isTrue,
      );
      expect(
        isBackpackItemExpired(
          _weekly('Ed. Física', 'tênis'),
          slots,
          DateTime(2030),
        ),
        isFalse,
      );
    });

    test(
      'proxima aula: hoje se ainda nao acabou, senao o proximo dia com aula',
      () {
        // Segunda 09h: ainda tem a aula das 10h.
        expect(
          nextClassDate('Ed. Física', slots, DateTime(2026, 10, 12, 9)),
          DateTime(2026, 10, 12),
        );
        // Segunda 11h: acabou; proxima e quarta.
        expect(
          nextClassDate('Ed. Física', slots, DateTime(2026, 10, 12, 11)),
          DateTime(2026, 10, 14),
        );
        // Sexta: proxima e segunda que vem.
        expect(
          nextClassDate('Ed. Física', slots, DateTime(2026, 10, 16, 8)),
          DateTime(2026, 10, 19),
        );
        expect(nextClassDate('Artes', slots, DateTime(2026, 10, 12)), isNull);
      },
    );
  });
}

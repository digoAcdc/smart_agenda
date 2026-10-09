import 'package:flutter_test/flutter_test.dart';
import 'package:smart_agenda/domain/entities/agenda_enums.dart';
import 'package:smart_agenda/domain/entities/agenda_item.dart';
import 'package:smart_agenda/domain/entities/recurrence_rule.dart';
import 'package:smart_agenda/domain/services/recurrence_expander.dart';

AgendaItem _item(DateTime start, RecurrenceRule? rule, {DateTime? end}) =>
    AgendaItem(
      id: 'serie',
      title: 'Natação',
      startAt: start,
      endAt: end,
      recurrence: rule,
      createdAt: start,
      updatedAt: start,
    );

List<String> _days(List<AgendaItem> items) => items
    .map(
      (e) =>
          '${e.startAt.day.toString().padLeft(2, '0')}/${e.startAt.month.toString().padLeft(2, '0')}',
    )
    .toList();

void main() {
  // Terca, 06/10/2026, 18:30-19:30.
  final start = DateTime(2026, 10, 6, 18, 30);
  final end = DateTime(2026, 10, 6, 19, 30);

  test('sem regra: so o proprio evento, se estiver no periodo', () {
    final item = _item(start, null);
    expect(
      RecurrenceExpander.expand(
        item,
        DateTime(2026, 10, 1),
        DateTime(2026, 10, 31),
      ),
      [item],
    );
    expect(
      RecurrenceExpander.expand(
        item,
        DateTime(2026, 11, 1),
        DateTime(2026, 11, 30),
      ),
      isEmpty,
    );
  });

  test('toda semana ter e qui: datas, horario e duracao', () {
    final item = _item(
      start,
      const RecurrenceRule(type: RecurrenceType.weekly, byWeekDays: [4, 2]),
      end: end,
    );
    final occ = RecurrenceExpander.expand(
      item,
      DateTime(2026, 10, 1),
      DateTime(2026, 10, 20, 23, 59),
    );
    expect(_days(occ), ['06/10', '08/10', '13/10', '15/10', '20/10']);
    expect(occ.first.startAt.hour, 18);
    expect(occ.first.endAt, DateTime(2026, 10, 6, 19, 30));
    expect(occ[1].endAt, DateTime(2026, 10, 8, 19, 30));
    expect(occ.every((e) => e.id == 'serie' && e.isOccurrence), isTrue);
  });

  test('nao gera dias antes do inicio da serie na primeira semana', () {
    // Inicio numa terca; segunda da mesma semana nao entra.
    final item = _item(
      start,
      const RecurrenceRule(type: RecurrenceType.weekly, byWeekDays: [1, 2]),
    );
    final occ = RecurrenceExpander.expand(
      item,
      DateTime(2026, 10, 1),
      DateTime(2026, 10, 13, 23, 59),
    );
    expect(_days(occ), ['06/10', '12/10', '13/10']);
  });

  test('todo dia a cada 2 dias, ate uma data', () {
    final item = _item(
      start,
      RecurrenceRule(
        type: RecurrenceType.daily,
        interval: 2,
        until: DateTime(2026, 10, 12),
      ),
    );
    final occ = RecurrenceExpander.expand(
      item,
      DateTime(2026, 10, 1),
      DateTime(2026, 12, 31),
    );
    expect(_days(occ), ['06/10', '08/10', '10/10', '12/10']);
  });

  test('quantidade de vezes conta desde o inicio, mesmo fora do periodo', () {
    final item = _item(
      start,
      const RecurrenceRule(type: RecurrenceType.daily, count: 5),
    );
    // Periodo comeca no 3o dia: so restam 3 ocorrencias.
    final occ = RecurrenceExpander.expand(
      item,
      DateTime(2026, 10, 8),
      DateTime(2026, 12, 31),
    );
    expect(_days(occ), ['08/10', '09/10', '10/10']);
  });

  test('todo mes no dia 31 pula meses sem dia 31', () {
    final item = _item(
      DateTime(2026, 10, 31, 9),
      const RecurrenceRule(type: RecurrenceType.monthly),
    );
    final occ = RecurrenceExpander.expand(
      item,
      DateTime(2026, 10, 1),
      DateTime(2027, 3, 31, 23, 59),
    );
    expect(_days(occ), ['31/10', '31/12', '31/01', '31/03']);
  });

  test('concluido por ocorrencia e excluir so este', () {
    var rule = const RecurrenceRule(type: RecurrenceType.daily);
    rule = RecurrenceExpander.withCompleted(
      rule,
      DateTime(2026, 10, 7, 18),
      true,
    );
    rule = RecurrenceExpander.withException(rule, DateTime(2026, 10, 8));
    final occ = RecurrenceExpander.expand(
      _item(start, rule),
      DateTime(2026, 10, 6),
      DateTime(2026, 10, 9, 23, 59),
    );
    expect(_days(occ), ['06/10', '07/10', '09/10']);
    expect(occ.map((e) => e.status).toList(), [
      AgendaStatus.pending,
      AgendaStatus.done,
      AgendaStatus.pending,
    ]);

    rule = RecurrenceExpander.withCompleted(rule, DateTime(2026, 10, 7), false);
    expect(rule.completedDates, isEmpty);
  });

  test('serie cancelada: todas as ocorrencias canceladas', () {
    final item = _item(
      start,
      const RecurrenceRule(type: RecurrenceType.daily),
    ).copyWith(status: AgendaStatus.canceled);
    final occ = RecurrenceExpander.expand(
      item,
      DateTime(2026, 10, 6),
      DateTime(2026, 10, 8, 23, 59),
    );
    expect(occ.every((e) => e.status == AgendaStatus.canceled), isTrue);
  });

  test('regra salva e lida de volta (json) com concluidos', () {
    final rule = RecurrenceRule(
      type: RecurrenceType.weekly,
      byWeekDays: const [2, 4],
      until: DateTime(2026, 12, 20),
      completedDates: [DateTime(2026, 10, 6)],
    );
    expect(RecurrenceRule.fromJson(rule.toJson()), rule);
    expect(rule.shortLabel, 'Toda semana (ter, qui) até 20/12');
  });

  test('regra antiga sem completedDates continua lendo', () {
    final rule = RecurrenceRule.fromJson({'type': 'daily', 'interval': 1});
    expect(rule.completedDates, isEmpty);
    expect(rule.shortLabel, 'Todo dia');
  });
}

import '../entities/agenda_enums.dart';
import '../entities/agenda_item.dart';
import '../entities/recurrence_rule.dart';

/// Gera as ocorrencias de um evento que se repete. O evento e salvo uma vez
/// so, com a regra; as telas recebem uma copia por dia, com o horario do
/// evento original e o status daquele dia.
class RecurrenceExpander {
  RecurrenceExpander._();

  /// Trava de seguranca para regras sem fim.
  static const _maxIterations = 5000;

  static DateTime _day(DateTime d) => DateTime(d.year, d.month, d.day);

  static bool _containsDay(List<DateTime> days, DateTime day) => days.any(
    (d) => d.year == day.year && d.month == day.month && d.day == day.day,
  );

  /// Dias da serie (em ordem), do inicio ate [to], respeitando fim e
  /// quantidade. Inclui dias excluidos ("so este"), que contam para [count].
  static Iterable<DateTime> _seriesDays(
    RecurrenceRule rule,
    DateTime seriesStart,
    DateTime to,
  ) sync* {
    final first = _day(seriesStart);
    final until = rule.until == null ? null : _day(rule.until!);
    final step = rule.interval < 1 ? 1 : rule.interval;
    var emitted = 0;
    var iterations = 0;

    bool done(DateTime day) =>
        day.isAfter(to) ||
        (until != null && day.isAfter(until)) ||
        (rule.count != null && emitted >= rule.count!) ||
        ++iterations > _maxIterations;

    switch (rule.type) {
      case RecurrenceType.none:
      case RecurrenceType.custom:
        if (!first.isAfter(to)) yield first;
        return;
      case RecurrenceType.daily:
        for (var i = 0; ; i += step) {
          final day = DateTime(first.year, first.month, first.day + i);
          if (done(day)) return;
          emitted++;
          yield day;
        }
      case RecurrenceType.weekly:
        final days = (rule.byWeekDays == null || rule.byWeekDays!.isEmpty)
            ? [seriesStart.weekday]
            : ([...rule.byWeekDays!]..sort());
        // Segunda-feira da semana do inicio.
        final monday = DateTime(
          first.year,
          first.month,
          first.day - (first.weekday - 1),
        );
        for (var w = 0; ; w += step) {
          for (final wd in days) {
            final day = DateTime(
              monday.year,
              monday.month,
              monday.day + w * 7 + (wd - 1),
            );
            if (day.isBefore(first)) continue;
            if (done(day)) return;
            emitted++;
            yield day;
          }
        }
      case RecurrenceType.monthly:
        for (var m = 0; ; m += step) {
          final day = DateTime(first.year, first.month + m, first.day);
          // Dia 31 em mes de 30 dias: pula aquele mes.
          if (day.day != first.day) {
            if (++iterations > _maxIterations) return;
            continue;
          }
          if (done(day)) return;
          emitted++;
          yield day;
        }
    }
  }

  /// Ocorrencias de [master] com inicio entre [from] e [to] (inclusive).
  static List<AgendaItem> expand(
    AgendaItem master,
    DateTime from,
    DateTime to,
  ) {
    final rule = master.recurrence;
    if (rule == null || !rule.repeats) {
      final inRange =
          !master.startAt.isBefore(from) && !master.startAt.isAfter(to);
      return inRange ? [master] : const [];
    }
    final duration = master.endAt?.difference(master.startAt);
    final result = <AgendaItem>[];
    for (final day in _seriesDays(rule, master.startAt, to)) {
      if (_containsDay(rule.exceptions, day)) continue;
      final start = DateTime(
        day.year,
        day.month,
        day.day,
        master.startAt.hour,
        master.startAt.minute,
      );
      if (start.isBefore(from) || start.isAfter(to)) continue;
      final status = master.status == AgendaStatus.canceled
          ? AgendaStatus.canceled
          : _containsDay(rule.completedDates, day)
          ? AgendaStatus.done
          : AgendaStatus.pending;
      result.add(
        master.copyWith(
          startAt: start,
          endAt: duration == null ? null : start.add(duration),
          status: status,
          occurrenceDate: day,
        ),
      );
    }
    return result;
  }

  /// Proximas [limit] ocorrencias a partir de [from] (para lembretes).
  static List<AgendaItem> nextOccurrences(
    AgendaItem master,
    DateTime from, {
    int limit = 8,
    Duration horizon = const Duration(days: 400),
  }) {
    return expand(master, from, from.add(horizon)).take(limit).toList();
  }

  /// Regra com o dia marcado/desmarcado como concluido.
  static RecurrenceRule withCompleted(
    RecurrenceRule rule,
    DateTime day,
    bool completed,
  ) {
    final d = _day(day);
    final others = rule.completedDates.where((x) => _day(x) != d).toList();
    return rule.copyWith(completedDates: completed ? [...others, d] : others);
  }

  /// Regra sem aquele dia ("excluir so este").
  static RecurrenceRule withException(RecurrenceRule rule, DateTime day) {
    final d = _day(day);
    if (_containsDay(rule.exceptions, d)) return rule;
    return rule.copyWith(
      exceptions: [...rule.exceptions, d],
      completedDates: rule.completedDates.where((x) => _day(x) != d).toList(),
    );
  }
}

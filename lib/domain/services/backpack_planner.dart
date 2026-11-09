import '../entities/backpack_item.dart';
import '../entities/class_schedule_slot.dart';

/// Um aviso "Mochila de amanha" (sai na noite anterior).
class BackpackPlan {
  const BackpackPlan({required this.notifyAt, required this.body});

  final DateTime notifyAt;
  final String body;
}

/// O que levar para uma materia num dia.
class BackpackSubjectGroup {
  const BackpackSubjectGroup({
    required this.scheduleId,
    required this.subject,
    required this.items,
    this.owner,
  });

  final String scheduleId;
  final String subject;
  final List<BackpackItem> items;

  /// Dono da grade ("João"); so preenchido quando mais de uma grade tem
  /// itens no dia.
  final String? owner;
}

/// "a", "a e b", "a, b e c".
String joinPt(List<String> parts) {
  if (parts.length <= 1) return parts.join();
  return '${parts.sublist(0, parts.length - 1).join(', ')} e ${parts.last}';
}

DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

/// Se [item] vai na mochila para as aulas de [day].
bool backpackItemAppliesTo(BackpackItem item, DateTime day) {
  if (item.isWeekly) return true;
  final due = item.dueDate;
  return due != null && _dateOnly(due) == _dateOnly(day);
}

/// Item "so na proxima aula" cuja aula ja terminou. [slots] sao as aulas da
/// grade do item; sem aula da materia naquele dia, vale ate o fim do dia.
bool isBackpackItemExpired(
  BackpackItem item,
  List<ClassScheduleSlot> slots,
  DateTime now,
) {
  if (item.isWeekly || item.dueDate == null) return false;
  final due = _dateOnly(item.dueDate!);
  var endMinutes = 24 * 60;
  final ends = slots
      .where(
        (s) => s.dayOfWeek == due.weekday && s.subject?.trim() == item.subject,
      )
      .map((s) => s.endMinutes);
  if (ends.isNotEmpty) endMinutes = ends.reduce((a, b) => a > b ? a : b);
  return !now.isBefore(due.add(Duration(minutes: endMinutes)));
}

/// Dia da proxima aula de [subject] (hoje conta se a aula ainda nao acabou).
/// Nulo se a materia nao esta na grade.
DateTime? nextClassDate(
  String subject,
  List<ClassScheduleSlot> slots,
  DateTime now,
) {
  final dates = upcomingClassDates(subject, slots, now, count: 1);
  return dates.isEmpty ? null : dates.first;
}

/// Os proximos [count] dias com aula de [subject] (hoje conta se a aula
/// ainda nao acabou), para escolher "so neste dia". Vazio se a materia nao
/// esta na grade.
List<DateTime> upcomingClassDates(
  String subject,
  List<ClassScheduleSlot> slots,
  DateTime now, {
  int count = 4,
}) {
  final key = subject.trim();
  final weekdays = {
    for (final s in slots)
      if (s.subject?.trim() == key) s.dayOfWeek,
  };
  if (weekdays.isEmpty || count <= 0) return const [];
  final today = _dateOnly(now);
  final nowMinutes = now.hour * 60 + now.minute;
  final dates = <DateTime>[];
  for (var i = 0; dates.length < count && i <= 7 * count; i++) {
    final day = DateTime(today.year, today.month, today.day + i);
    final hasClass = slots.any(
      (s) =>
          s.dayOfWeek == day.weekday &&
          s.subject?.trim() == key &&
          (i > 0 || s.endMinutes > nowMinutes),
    );
    if (hasClass) dates.add(day);
  }
  return dates;
}

/// Dias da semana com aula de [subject], em ordem (1 = segunda).
List<int> classWeekdays(String subject, List<ClassScheduleSlot> slots) {
  final key = subject.trim();
  return {
    for (final s in slots)
      if (s.subject?.trim() == key) s.dayOfWeek,
  }.toList()..sort();
}

/// O que levar em [day]: para cada grade, as materias com aula nesse dia
/// (na ordem das aulas, sem repetir) e seus itens. Com mais de uma grade com
/// itens no dia, cada grupo leva o dono ([ownerLabel]).
///
/// Com [onlyReminders], so os itens com aviso ligado (o aviso das 20h); a
/// checklist "Amanhã leve" mostra todos.
List<BackpackSubjectGroup> backpackForDay({
  required List<ClassSchedule> schedules,
  required List<ClassScheduleSlot> slots,
  required DateTime day,
  required String Function(ClassSchedule schedule) ownerLabel,
  bool onlyReminders = false,
}) {
  final perSchedule = <(ClassSchedule, List<BackpackSubjectGroup>)>[];
  for (final schedule in schedules) {
    if (schedule.backpackItems.isEmpty) continue;
    final daySlots =
        slots
            .where(
              (s) =>
                  s.scheduleId == schedule.id &&
                  s.dayOfWeek == day.weekday &&
                  (s.subject?.trim().isNotEmpty ?? false),
            )
            .toList()
          ..sort((a, b) => a.startMinutes.compareTo(b.startMinutes));
    final seen = <String>{};
    final groups = <BackpackSubjectGroup>[];
    for (final slot in daySlots) {
      final subject = slot.subject!.trim();
      if (!seen.add(subject)) continue;
      final items = [
        for (final i in schedule.backpackItems)
          if (i.subject == subject &&
              backpackItemAppliesTo(i, day) &&
              (!onlyReminders || i.remind))
            i,
      ];
      if (items.isEmpty) continue;
      groups.add(
        BackpackSubjectGroup(
          scheduleId: schedule.id,
          subject: subject,
          items: items,
        ),
      );
    }
    if (groups.isNotEmpty) perSchedule.add((schedule, groups));
  }
  if (perSchedule.length <= 1) {
    return [for (final (_, groups) in perSchedule) ...groups];
  }
  return [
    for (final (schedule, groups) in perSchedule)
      for (final g in groups)
        BackpackSubjectGroup(
          scheduleId: g.scheduleId,
          subject: g.subject,
          items: g.items,
          owner: ownerLabel(schedule),
        ),
  ];
}

/// Texto do aviso: "tênis e uniforme (Ed. Física) · livro (Inglês)"; com
/// mais de uma grade, "João: ... · Maria: ...".
String backpackSummary(List<BackpackSubjectGroup> groups) {
  final parts = <String>[];
  String? lastOwner;
  for (final g in groups) {
    final text = '${joinPt([for (final i in g.items) i.label])} (${g.subject})';
    if (g.owner != null && g.owner != lastOwner) {
      parts.add('${g.owner}: $text');
    } else {
      parts.add(text);
    }
    lastOwner = g.owner;
  }
  return parts.join(' · ');
}

/// Monta os avisos das proximas [days] noites a partir das grades: para o dia
/// seguinte, junta os itens com aviso ligado de cada materia que tem aula.
List<BackpackPlan> buildBackpackPlans({
  required List<ClassSchedule> schedules,
  required List<ClassScheduleSlot> slots,
  required DateTime now,
  required String Function(ClassSchedule schedule) ownerLabel,
  int days = 7,
  int hour = 20,
}) {
  final plans = <BackpackPlan>[];
  for (var i = 0; i < days; i++) {
    final evening = DateTime(now.year, now.month, now.day + i, hour);
    if (!evening.isAfter(now)) continue;
    final groups = backpackForDay(
      schedules: schedules,
      slots: slots,
      day: DateTime(evening.year, evening.month, evening.day + 1),
      ownerLabel: ownerLabel,
      onlyReminders: true,
    );
    if (groups.isEmpty) continue;
    plans.add(BackpackPlan(notifyAt: evening, body: backpackSummary(groups)));
  }
  return plans;
}

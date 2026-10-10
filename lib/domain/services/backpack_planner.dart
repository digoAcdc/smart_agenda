import '../entities/class_schedule_slot.dart';

/// Um aviso "Mochila de amanha" (sai na noite anterior).
class BackpackPlan {
  const BackpackPlan({required this.notifyAt, required this.body});

  final DateTime notifyAt;
  final String body;
}

/// Monta os avisos das proximas [days] noites a partir das grades: para o dia
/// seguinte, junta o "o que levar" de cada materia que tem aula.
/// Ex.: "tênis e uniforme (Ed. Física) · livro (Inglês)". Com mais de uma
/// grade com itens, prefixa o dono: "João: ... · Maria: ...".
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
    final weekday = evening.add(const Duration(days: 1)).weekday;

    final perSchedule = <String>[];
    for (final schedule in schedules) {
      if (schedule.bringItems.isEmpty) continue;
      final daySlots =
          slots
              .where(
                (s) =>
                    s.scheduleId == schedule.id &&
                    s.dayOfWeek == weekday &&
                    (s.subject?.trim().isNotEmpty ?? false),
              )
              .toList()
            ..sort((a, b) => a.startMinutes.compareTo(b.startMinutes));
      final seen = <String>{};
      final parts = <String>[];
      for (final slot in daySlots) {
        final subject = slot.subject!.trim();
        if (!seen.add(subject)) continue;
        final bring = schedule.bringItems[subject]?.trim();
        if (bring == null || bring.isEmpty) continue;
        parts.add('$bring ($subject)');
      }
      if (parts.isNotEmpty) {
        perSchedule.add('${ownerLabel(schedule)}\u0000${parts.join(' · ')}');
      }
    }
    if (perSchedule.isEmpty) continue;

    final body = perSchedule.length == 1
        ? perSchedule.single.split('\u0000').last
        : perSchedule.map((p) => p.replaceFirst('\u0000', ': ')).join(' · ');
    plans.add(BackpackPlan(notifyAt: evening, body: body));
  }
  return plans;
}

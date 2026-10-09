import 'package:uuid/uuid.dart';

import '../../core/result/result.dart';
import '../../domain/entities/agenda_enums.dart';
import '../../domain/entities/agenda_item.dart';
import '../../domain/repositories/i_notification_service.dart';
import '../../domain/repositories/i_personal_to_family_service.dart';
import '../../domain/repositories/i_sync_service.dart';
import '../datasources/agenda_local_datasource.dart';
import '../datasources/class_schedule_local_datasource.dart';
import '../models/mappers.dart';

/// Leva o que a pessoa tinha so para si para a Familia.
/// Itens da Familia nao podem mudar de escopo no servidor, entao cada item
/// vira um novo item da Familia e o pessoal e excluido.
class PersonalToFamilyServiceImpl implements IPersonalToFamilyService {
  PersonalToFamilyServiceImpl(
    this._agenda,
    this._schedules,
    this._sync,
    this._notifications,
    this._currentUserId,
  );

  final AgendaLocalDataSource _agenda;
  final ClassScheduleLocalDataSource _schedules;
  final ISyncService _sync;
  final INotificationService _notifications;
  final String? Function() _currentUserId;

  Future<List<AgendaItem>> _personalItems() async {
    final rows = await _agenda.search('');
    return rows
        .where((r) => r.item.familyId == null)
        .map((r) => itemFromDb(r.item, r.attachments))
        .toList();
  }

  @override
  Future<PersonalDataSummary> summary() async {
    final items = await _personalItems();
    final schedules = (await _schedules.getSchedules()).where(
      (g) => !g.isFamily,
    );
    return PersonalDataSummary(
      items: items.length,
      schedules: schedules.length,
    );
  }

  @override
  Future<Result<PersonalDataSummary>> moveAllToFamily(String familyId) async {
    try {
      final uid = _currentUserId();
      final now = DateTime.now();
      final items = await _personalItems();
      for (final old in items) {
        final newId = const Uuid().v4();
        final moved = AgendaItem(
          id: newId,
          title: old.title,
          description: old.description,
          startAt: old.startAt,
          endAt: old.endAt,
          allDay: old.allDay,
          timezone: old.timezone,
          status: old.status,
          locationText: old.locationText,
          reminder: old.reminder,
          recurrence: old.recurrence,
          attachments: [
            for (final a in old.attachments)
              a.copyWith(id: const Uuid().v4(), itemId: newId),
          ],
          familyId: familyId,
          kind: old.kind,
          subjectType: AgendaSubjectType.family,
          createdBy: uid,
          updatedBy: uid,
          createdAt: old.createdAt,
          updatedAt: now,
        );
        await _agenda.createItem(
          agendaItemToCompanion(moved),
          moved.attachments.map(attachmentToCompanion).toList(),
        );
        await _agenda.deleteItemSoft(old.id, now);
        // Lembrete do celular passa para o item novo.
        await _notifications.cancelForItem(old);
        await _notifications.scheduleForItem(moved);
      }

      final personalSchedules = (await _schedules.getSchedules())
          .where((g) => !g.isFamily)
          .toList();
      for (final g in personalSchedules) {
        await _schedules.moveScheduleToFamily(g, familyId);
      }

      _sync.syncNow();
      return Result.success(
        PersonalDataSummary(
          items: items.length,
          schedules: personalSchedules.length,
        ),
      );
    } catch (e) {
      return Result.failure('Não foi possível levar para a Família: $e');
    }
  }
}

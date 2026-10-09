import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_agenda/core/result/result.dart';
import 'package:smart_agenda/data/datasources/agenda_local_datasource.dart';
import 'package:smart_agenda/data/datasources/class_schedule_local_datasource.dart';
import 'package:smart_agenda/data/local/app_database.dart';
import 'package:smart_agenda/data/models/mappers.dart';
import 'package:smart_agenda/data/services/personal_to_family_service_impl.dart';
import 'package:smart_agenda/domain/entities/agenda_enums.dart';
import 'package:smart_agenda/domain/entities/agenda_item.dart';
import 'package:smart_agenda/domain/repositories/i_notification_service.dart';
import 'package:smart_agenda/domain/repositories/i_sync_service.dart';

class _FakeSync implements ISyncService {
  int calls = 0;
  @override
  Future<Result<void>> syncNow() async {
    calls++;
    return Result.success(null);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeNotifications implements INotificationService {
  final canceled = <String>[];
  final scheduled = <String>[];
  @override
  Future<Result<void>> cancelForItem(AgendaItem item) async {
    canceled.add(item.id);
    return Result.success(null);
  }

  @override
  Future<Result<void>> scheduleForItem(AgendaItem item) async {
    scheduled.add(item.id);
    return Result.success(null);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late AppDatabase db;
  late AgendaLocalDataSource agenda;
  late ClassScheduleLocalDataSource schedules;
  late _FakeSync sync;
  late _FakeNotifications notifications;
  late PersonalToFamilyServiceImpl service;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    db = AppDatabase(NativeDatabase.memory());
    agenda = AgendaLocalDataSource(db);
    schedules = ClassScheduleLocalDataSource(db);
    sync = _FakeSync();
    notifications = _FakeNotifications();
    service = PersonalToFamilyServiceImpl(agenda, schedules, sync, notifications, () => 'me');
  });
  tearDown(() => db.close());

  Future<void> addPersonalItem(String id, {String? familyId}) async {
    final now = DateTime.now();
    final item = AgendaItem(
      id: id,
      title: 'Evento $id',
      startAt: now.add(const Duration(days: 1)),
      familyId: familyId,
      createdAt: now,
      updatedAt: now,
    );
    await agenda.createItem(agendaItemToCompanion(item), const []);
  }

  test('resumo conta so o que e pessoal', () async {
    await addPersonalItem('p1');
    await addPersonalItem('f1', familyId: 'fam');
    await schedules.createSchedule(name: 'Minha grade');
    await schedules.createSchedule(name: 'Escola', familyId: 'fam');

    final s = await service.summary();
    expect(s.items, 1);
    expect(s.schedules, 1);
  });

  test('leva eventos e grades (com aulas) para a Familia', () async {
    await addPersonalItem('p1');
    await addPersonalItem('p2');
    final minha = await schedules.createSchedule(name: 'Minha grade');
    await schedules.addTimeRange(minha, 420, 470);

    final result = await service.moveAllToFamily('fam');

    expect(result.isSuccess, isTrue);
    expect(result.data!.items, 2);
    expect(result.data!.schedules, 1);

    // Eventos agora sao da Familia, com novo id e autoria; os pessoais sairam.
    final all = (await agenda.search('')).map((r) => itemFromDb(r.item, r.attachments)).toList();
    expect(all, hasLength(2));
    expect(all.every((i) => i.familyId == 'fam'), isTrue);
    expect(all.every((i) => i.subjectType == AgendaSubjectType.family), isTrue);
    expect(all.every((i) => i.createdBy == 'me'), isTrue);
    expect(all.map((i) => i.id), isNot(contains('p1')));

    // Grade foi para a Familia com as 5 aulas.
    final gs = await schedules.getSchedules();
    expect(gs.single.name, 'Minha grade');
    expect(gs.single.familyId, 'fam');
    expect((await schedules.getSlots(gs.single)).length, 5);

    // Lembretes passam para os itens novos; sync disparado.
    expect(notifications.canceled, containsAll(['p1', 'p2']));
    expect(notifications.scheduled, hasLength(2));
    expect(sync.calls, 1);
    expect((await service.summary()).isEmpty, isTrue);

    // Nuvem pessoal pode ser limpa (grade levada de proposito).
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool(ClassScheduleLocalDataSource.personalSchedulesClearedKey), isTrue);
  });
}

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_agenda/data/datasources/class_schedule_local_datasource.dart';
import 'package:smart_agenda/data/datasources/school_record_local_datasource.dart';
import 'package:smart_agenda/data/local/app_database.dart';
import 'package:smart_agenda/domain/entities/backpack_item.dart';
import 'package:smart_agenda/domain/entities/class_schedule_slot.dart';
import 'package:smart_agenda/domain/entities/school_record.dart';

SchoolRecord _record(
  String id,
  ClassSchedule g, {
  SchoolRecordKind kind = SchoolRecordKind.grade,
  String subject = 'Matemática',
}) => SchoolRecord(
  id: id,
  scheduleId: g.id,
  subject: subject,
  kind: kind,
  date: DateTime(2026, 3, 10),
  title: kind == SchoolRecordKind.grade ? 'Prova 1' : null,
  score: kind == SchoolRecordKind.grade ? 8 : null,
  maxScore: kind == SchoolRecordKind.grade ? 10 : null,
  term: kind == SchoolRecordKind.grade ? 1 : null,
  note: '  ',
  familyId: g.familyId,
  childId: g.childId,
  createdAt: DateTime(2026, 3, 10),
  updatedAt: DateTime(2026, 3, 10),
);

void main() {
  late AppDatabase db;
  late ClassScheduleLocalDataSource schedules;
  late SchoolRecordLocalDataSource records;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    db = AppDatabase(NativeDatabase.memory());
    schedules = ClassScheduleLocalDataSource(db);
    records = SchoolRecordLocalDataSource(db);
  });
  tearDown(() => db.close());

  test('salva, edita e exclui (logico, pendente para o sync)', () async {
    final g = await schedules.createSchedule(name: 'Minha grade');
    await records.saveRecord(_record('n1', g));
    await records.saveRecord(_record('f1', g, kind: SchoolRecordKind.absence));

    var list = await records.getRecords(g.id);
    expect(list.length, 2);
    final nota = list.firstWhere((r) => r.id == 'n1');
    expect(nota.score, 8);
    expect(nota.note, isNull); // observacao em branco nao e gravada

    await records.saveRecord(nota.copyWith(score: 9.5, note: 'recuperação'));
    list = await records.getRecords(g.id);
    expect(list.firstWhere((r) => r.id == 'n1').score, 9.5);
    expect(list.length, 2);

    await records.deleteRecord('f1');
    expect((await records.getRecords(g.id)).map((r) => r.id), ['n1']);
    // A exclusao fica pendente para apagar tambem na nuvem (Pro).
    final pending = await records.getPending(family: false);
    expect(pending.map((r) => r.id).toSet(), {'n1', 'f1'});
    expect(pending.firstWhere((r) => r.id == 'f1').deletedAt, isNotNull);
  });

  test('pendentes separados: pessoais (Pro) e da Familia', () async {
    final minha = await schedules.createSchedule(name: 'Minha grade');
    final joao = await schedules.createSchedule(
      name: 'Escola',
      familyId: 'fam',
      childId: 'joao',
    );
    await records.saveRecord(_record('p', minha));
    await records.saveRecord(_record('f', joao));
    expect((await records.getPending(family: false)).map((r) => r.id), ['p']);
    expect((await records.getPending(family: true)).map((r) => r.id), ['f']);

    await records.markSynced('f');
    expect(await records.getPending(family: true), isEmpty);
  });

  test('excluir a grade leva junto as notas e faltas dela', () async {
    final a = await schedules.createSchedule(name: 'A');
    final b = await schedules.createSchedule(name: 'B');
    await records.saveRecord(_record('a1', a));
    await records.saveRecord(_record('b1', b));

    await schedules.deleteSchedule(a);

    expect(await records.getRecords(a.id), isEmpty);
    expect((await records.getRecords(b.id)).single.id, 'b1');
  });

  test(
    'levar a grade pessoal para a Familia leva notas, faltas e mochila',
    () async {
      final minha = await schedules.createSchedule(name: 'Minha grade');
      await schedules.addTimeRange(minha, 420, 470);
      await schedules.setBackpackItems(minha.id, const [
        BackpackItem(id: 'm1', subject: 'Matemática', label: 'calculadora'),
      ]);
      await records.saveRecord(_record('n1', minha));
      await records.saveRecord(
        _record('f1', minha, kind: SchoolRecordKind.absence),
      );
      final withItems = (await schedules.getSchedules()).single;

      final moved = await schedules.moveScheduleToFamily(withItems, 'fam');

      final movedRecords = await records.getRecords(moved.id);
      expect(movedRecords.length, 2);
      expect(movedRecords.every((r) => r.familyId == 'fam'), isTrue);
      expect(
        (await records.getPending(family: true)).length,
        2,
        reason: 'sobem para a Familia no proximo sync',
      );
      final family = (await schedules.getSchedules()).single;
      expect(family.backpackItems.single.label, 'calculadora');
      expect(await records.getRecords(minha.id), isEmpty);
    },
  );

  test('saiu da Familia: cache de notas da Familia e limpo', () async {
    final joao = await schedules.createSchedule(
      name: 'Escola',
      familyId: 'fam',
      childId: 'joao',
    );
    final minha = await schedules.createSchedule(name: 'Minha grade');
    await records.saveRecord(_record('f', joao));
    await records.saveRecord(_record('p', minha));

    await schedules.clearFamilySlots();

    expect(await records.getRecords(joao.id), isEmpty);
    expect((await records.getRecords(minha.id)).single.id, 'p');
  });

  test('do servidor: edicao local pendente vence; excluido sai', () async {
    final joao = await schedules.createSchedule(
      name: 'Escola',
      familyId: 'fam',
      childId: 'joao',
    );
    await records.saveRecord(_record('f', joao)); // pendente local
    await records.applyRemoteFamily(
      _remoteRow('f', joao.id, score: 2),
      deleted: false,
    );
    expect((await records.getRecords(joao.id)).single.score, 8);

    await records.markSynced('f');
    await records.applyRemoteFamily(
      _remoteRow('f', joao.id, score: 2),
      deleted: false,
    );
    expect((await records.getRecords(joao.id)).single.score, 2);

    await records.applyRemoteFamily(
      _remoteRow('f', joao.id, score: 2),
      deleted: true,
    );
    expect(await records.getRecords(joao.id), isEmpty);
  });
}

/// Linha como chega do servidor (via sync).
SchoolRecordsTableCompanion _remoteRow(
  String id,
  String scheduleId, {
  required double score,
}) => SchoolRecordsTableCompanion.insert(
  id: id,
  scheduleId: scheduleId,
  subject: 'Matemática',
  kind: 'grade',
  date: DateTime(2026, 3, 10),
  score: Value(score),
  maxScore: const Value(10),
  term: const Value(1),
  familyId: const Value('fam'),
  childId: const Value('joao'),
  createdAt: DateTime(2026, 3, 10),
  updatedAt: DateTime(2026, 3, 11),
);

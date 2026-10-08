import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_agenda/data/datasources/class_schedule_local_datasource.dart';
import 'package:smart_agenda/data/local/app_database.dart';

void main() {
  late AppDatabase db;
  late ClassScheduleLocalDataSource ds;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    ds = ClassScheduleLocalDataSource(db);
  });
  tearDown(() => db.close());

  test('grades com nome sao independentes, inclusive duas do mesmo filho', () async {
    final minha = await ds.createSchedule(name: 'Minha grade');
    final joaoEscola =
        await ds.createSchedule(name: 'Escola', familyId: 'fam', childId: 'joao');
    final joaoIngles =
        await ds.createSchedule(name: 'Ingles', familyId: 'fam', childId: 'joao');
    final cursinho = await ds.createSchedule(name: 'Cursinho');

    await ds.addTimeRange(minha, 420, 470);
    await ds.addTimeRange(joaoEscola, 420, 470);
    await ds.addTimeRange(joaoEscola, 480, 530);
    await ds.addTimeRange(joaoIngles, 900, 960);

    expect((await ds.getSchedules()).map((g) => g.name),
        ['Minha grade', 'Escola', 'Ingles', 'Cursinho']);
    expect((await ds.getSlots(minha)).length, 5);
    expect((await ds.getSlots(joaoEscola)).length, 10);
    expect((await ds.getSlots(joaoIngles)).length, 5);
    expect(await ds.getSlots(cursinho), isEmpty);
    expect((await ds.getSlots(joaoIngles)).every((s) => s.childId == 'joao'), isTrue);
    expect((await ds.getAllSlots()).length, 20);
  });

  test('grade sem filho e pessoal mesmo informando a Familia', () async {
    final g = await ds.createSchedule(name: 'Cursinho', familyId: 'fam');
    expect(g.isFamily, isFalse);
    expect(g.familyId, isNull);
  });

  test('remover horario da grade do filho e logico e nao mexe nas outras', () async {
    final minha = await ds.createSchedule(name: 'Minha grade');
    final joao = await ds.createSchedule(name: 'Escola', familyId: 'fam', childId: 'joao');
    await ds.addTimeRange(minha, 420, 470);
    await ds.addTimeRange(joao, 420, 470);

    await ds.removeTimeRange(joao, 420, 470);

    expect(await ds.getSlots(joao), isEmpty);
    expect((await ds.getSlots(minha)).length, 5);
    final pending = await ds.getPendingFamilySlots();
    expect(pending.where((r) => r.deletedAt != null).length, 5);
  });

  test('excluir grade do filho marca para sincronizar e some do aparelho', () async {
    final joao = await ds.createSchedule(name: 'Escola', familyId: 'fam', childId: 'joao');
    await ds.addTimeRange(joao, 420, 470);

    await ds.deleteSchedule(joao);

    expect(await ds.getSchedules(), isEmpty);
    expect(await ds.getAllSlots(), isEmpty);
    final pending = await ds.getPendingFamilySchedules();
    expect(pending.single.deletedAt, isNotNull);
  });

  test('renomear grade', () async {
    final g = await ds.createSchedule(name: 'Escola');
    await ds.renameSchedule(g.id, 'Escola manha');
    expect((await ds.getSchedules()).single.name, 'Escola manha');
  });

  test('sync pessoal so enxerga grades e aulas pessoais', () async {
    final minha = await ds.createSchedule(name: 'Minha grade');
    final joao = await ds.createSchedule(name: 'Escola', familyId: 'fam', childId: 'joao');
    await ds.addTimeRange(minha, 420, 470);
    await ds.addTimeRange(joao, 420, 470);

    expect((await ds.getAllPersonalSchedules()).map((g) => g.id), [minha.id]);
    expect((await ds.getAllPersonalSlots()).every((r) => r.familyId == null), isTrue);
    expect(await ds.hasPersonalPending(), isTrue);
    await ds.markPersonalSynced();
    expect(await ds.hasPersonalPending(), isFalse);
  });

  test('sair da Familia limpa so as grades dos filhos', () async {
    final minha = await ds.createSchedule(name: 'Minha grade');
    final joao = await ds.createSchedule(name: 'Escola', familyId: 'fam', childId: 'joao');
    await ds.addTimeRange(minha, 420, 470);
    await ds.addTimeRange(joao, 420, 470);

    await ds.clearFamilySlots();

    expect((await ds.getSchedules()).map((g) => g.id), [minha.id]);
    expect((await ds.getSlots(minha)).length, 5);
  });
}

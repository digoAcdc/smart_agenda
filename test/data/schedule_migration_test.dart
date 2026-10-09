import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_agenda/data/datasources/class_schedule_local_datasource.dart';
import 'package:smart_agenda/data/local/app_database.dart';

void main() {
  test('v9: aulas antigas viram "Minha grade" e "Escola" de cada filho', () async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final now = DateTime.now();
    Future<void> slot(String id, {String? familyId, String? childId}) =>
        db.into(db.classScheduleSlotsTable).insert(
              ClassScheduleSlotsTableCompanion.insert(
                id: id,
                dayOfWeek: 1,
                startMinutes: 420,
                endMinutes: 470,
                createdAt: now,
                updatedAt: now,
                subject: const Value('Mat'),
                familyId: Value(familyId),
                childId: Value(childId),
                syncState: const Value('synced'),
              ),
            );
    await slot('p1');
    await slot('p2');
    await slot('j1', familyId: 'fam', childId: 'joao');
    await slot('m1', familyId: 'fam', childId: 'maria');

    await db.migrateSlotsToNamedSchedules();

    final ds = ClassScheduleLocalDataSource(db);
    final schedules = await ds.getSchedules();
    expect(schedules.map((g) => g.id).toSet(),
        {'legacy-personal', 'legacy-joao', 'legacy-maria'});
    final minha = schedules.firstWhere((g) => g.id == 'legacy-personal');
    expect(minha.name, 'Minha grade');
    expect(minha.isFamily, isFalse);
    final joao = schedules.firstWhere((g) => g.id == 'legacy-joao');
    expect(joao.name, 'Escola');
    expect(joao.childId, 'joao');
    expect((await ds.getSlots(minha)).map((s) => s.id).toSet(), {'p1', 'p2'});
    expect((await ds.getSlots(joao)).single.id, 'j1');
    // Tudo marcado para subir com a grade nova.
    expect(await ds.hasPersonalPending(), isTrue);
    expect((await ds.getPendingFamilySchedules()).length, 2);
  });

  test('v9 sem aulas antigas nao cria grade vazia', () async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    await db.migrateSlotsToNamedSchedules();
    expect(await ClassScheduleLocalDataSource(db).getSchedules(), isEmpty);
  });
}

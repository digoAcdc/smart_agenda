import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_agenda/data/datasources/class_schedule_local_datasource.dart';
import 'package:smart_agenda/data/local/app_database.dart';
import 'package:smart_agenda/domain/entities/class_schedule_slot.dart';

void main() {
  late AppDatabase db;
  late ClassScheduleLocalDataSource ds;
  const mine = ScheduleOwner.mine();
  const joao = ScheduleOwner.child(familyId: 'fam', childId: 'joao');
  const maria = ScheduleOwner.child(familyId: 'fam', childId: 'maria');

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    ds = ClassScheduleLocalDataSource(db);
  });
  tearDown(() => db.close());

  test('cada grade (minha, Joao, Maria) e independente', () async {
    await ds.addTimeRange(mine, 420, 470);
    await ds.addTimeRange(joao, 420, 470);
    await ds.addTimeRange(joao, 480, 530);
    await ds.addTimeRange(maria, 600, 650);

    expect((await ds.getSlots(mine)).length, 5);
    expect((await ds.getSlots(joao)).length, 10);
    expect((await ds.getSlots(maria)).length, 5);
    expect((await ds.getSlots(joao)).every((s) => s.childId == 'joao'), isTrue);
    expect((await ds.getAllSlots()).length, 20);
  });

  test('remover horario do Joao nao mexe nas outras grades e e logico (sync)', () async {
    await ds.addTimeRange(mine, 420, 470);
    await ds.addTimeRange(joao, 420, 470);
    await ds.addTimeRange(maria, 420, 470);

    await ds.removeTimeRange(joao, 420, 470);

    expect(await ds.getSlots(joao), isEmpty);
    expect((await ds.getSlots(mine)).length, 5);
    expect((await ds.getSlots(maria)).length, 5);
    // Linhas do Joao continuam como pendentes com deletedAt para o sync propagar.
    final pendingFamily = await ds.getPendingFamilySlots();
    expect(pendingFamily.where((r) => r.childId == 'joao' && r.deletedAt != null).length, 5);
  });

  test('sync da grade pessoal so enxerga a grade pessoal', () async {
    await ds.addTimeRange(mine, 420, 470);
    await ds.addTimeRange(joao, 420, 470);

    final personal = await ds.getAllPersonalSlots();
    expect(personal.length, 5);
    expect(personal.every((r) => r.familyId == null), isTrue);
    expect((await ds.getPendingSlots()).every((r) => r.familyId == null), isTrue);
  });

  test('trocar de Familia limpa so o cache das grades dos filhos', () async {
    await ds.addTimeRange(mine, 420, 470);
    await ds.addTimeRange(joao, 420, 470);

    await ds.clearFamilySlots();

    expect((await ds.getSlots(mine)).length, 5);
    expect(await ds.getSlots(joao), isEmpty);
  });
}

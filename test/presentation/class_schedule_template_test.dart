import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_agenda/data/datasources/class_schedule_local_datasource.dart';
import 'package:smart_agenda/data/local/app_database.dart';
import 'package:smart_agenda/presentation/controllers/class_schedule_controller.dart';

void main() {
  late AppDatabase db;
  late ClassScheduleController controller;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    controller = ClassScheduleController(ClassScheduleLocalDataSource(db));
  });
  tearDown(() => db.close());

  test('nova grade com modelo: 6 aulas x 5 dias com as 6 materias em cada dia', () async {
    await controller.createSchedule(name: 'Escola', familyId: 'fam', childId: 'joao');

    expect(controller.selected.value!.name, 'Escola');
    expect(controller.timeRanges.length, 6);
    expect(controller.slots.length, 30);
    for (final day in ClassScheduleController.weekdays) {
      final subjects =
          controller.slots.where((s) => s.dayOfWeek == day).map((s) => s.subject).toSet();
      expect(subjects, ClassScheduleController.defaultSubjects.toSet());
    }
    expect(controller.getCell(1, 420, 470)!.subject,
        isNot(controller.getCell(2, 420, 470)!.subject));
  });

  test('nova grade sem modelo comeca vazia e modelo nao duplica', () async {
    await controller.createSchedule(name: 'Cursinho', withTemplate: false);
    expect(controller.slots, isEmpty);

    await controller.applyTemplate();
    await controller.applyTemplate();
    expect(controller.slots.length, 30);
  });

  test('trocar de grade mostra as aulas daquela grade', () async {
    await controller.createSchedule(name: 'Escola', familyId: 'fam', childId: 'joao');
    await controller.createSchedule(name: 'Ingles', familyId: 'fam', childId: 'joao',
        withTemplate: false);
    expect(controller.schedules.length, 2);
    expect(controller.slots, isEmpty);

    await controller.select(controller.schedules.first);
    expect(controller.slots.length, 30);
    expect(controller.allSlots.length, 30);
  });

  test('excluir grade seleciona outra', () async {
    await controller.createSchedule(name: 'A', withTemplate: false);
    await controller.createSchedule(name: 'B', withTemplate: false);
    await controller.deleteSelected();
    expect(controller.schedules.map((g) => g.name), ['A']);
    expect(controller.selected.value!.name, 'A');
  });

  test('editar horario de uma linha move todos os dias e bloqueia conflito', () async {
    await controller.createSchedule(name: 'Escola');
    final before = controller.getCell(3, 420, 470)!.subject;

    expect(await controller.updateTimeRange(420, 470, 430, 480), isNull);
    expect(controller.getCell(3, 430, 480)!.subject, before);
    expect(controller.getCell(3, 420, 470), isNull);
    expect(await controller.updateTimeRange(430, 480, 470, 520),
        'Ja existe uma linha com esse horario');
  });

  test('sugestoes incluem as 6 materias principais', () {
    expect(controller.subjectOptions,
        containsAll(ClassScheduleController.defaultSubjects));
  });
}

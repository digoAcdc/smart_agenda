import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_agenda/data/datasources/class_schedule_local_datasource.dart';
import 'package:smart_agenda/data/local/app_database.dart';
import 'package:smart_agenda/domain/entities/class_schedule_slot.dart';
import 'package:smart_agenda/presentation/controllers/class_schedule_controller.dart';

void main() {
  late AppDatabase db;
  late ClassScheduleController controller;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    controller = ClassScheduleController(ClassScheduleLocalDataSource(db));
    await controller.selectOwner(
      const ScheduleOwner.child(familyId: 'fam', childId: 'joao'),
    );
  });
  tearDown(() => db.close());

  test('grade modelo: 6 aulas x 5 dias com as 6 materias em cada dia', () async {
    await controller.applyTemplate();

    expect(controller.timeRanges.length, 6);
    expect(controller.slots.length, 30);
    for (final day in ClassScheduleController.weekdays) {
      final subjects = controller.slots
          .where((s) => s.dayOfWeek == day)
          .map((s) => s.subject)
          .toSet();
      expect(subjects, ClassScheduleController.defaultSubjects.toSet());
    }
    // Ordem muda de um dia para o outro.
    final monday = controller.getCell(1, 420, 470)!.subject;
    final tuesday = controller.getCell(2, 420, 470)!.subject;
    expect(monday, isNot(tuesday));
  });

  test('grade modelo nao duplica se a grade ja tem aulas', () async {
    await controller.applyTemplate();
    await controller.applyTemplate();
    expect(controller.slots.length, 30);
  });

  test('editar horario de uma linha move todos os dias e bloqueia conflito', () async {
    await controller.applyTemplate();
    final subjectBefore = controller.getCell(3, 420, 470)!.subject;

    expect(await controller.updateTimeRange(420, 470, 430, 480), isNull);
    expect(controller.getCell(3, 430, 480)!.subject, subjectBefore);
    expect(controller.getCell(3, 420, 470), isNull);

    expect(await controller.updateTimeRange(430, 480, 470, 520),
        'Ja existe uma linha com esse horario');
    expect(await controller.updateTimeRange(430, 480, 500, 490),
        'Fim deve ser maior que inicio');
  });

  test('sugestoes incluem as 6 materias principais', () {
    expect(controller.subjectOptions, containsAll(ClassScheduleController.defaultSubjects));
  });
}

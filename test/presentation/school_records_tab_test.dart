import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_agenda/core/theme/app_theme.dart';
import 'package:smart_agenda/data/datasources/class_schedule_local_datasource.dart';
import 'package:smart_agenda/data/datasources/school_record_local_datasource.dart';
import 'package:smart_agenda/data/local/app_database.dart';
import 'package:smart_agenda/presentation/controllers/class_schedule_controller.dart';
import 'package:smart_agenda/presentation/controllers/school_records_controller.dart';
import 'package:smart_agenda/presentation/pages/class_schedule_page.dart';

void main() {
  late AppDatabase db;
  late ClassScheduleController schedules;
  late SchoolRecordsController records;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await initializeDateFormatting('pt_BR');
    db = AppDatabase(NativeDatabase.memory());
    schedules = Get.put(
      ClassScheduleController(ClassScheduleLocalDataSource(db)),
    );
    records = Get.put(
      SchoolRecordsController(SchoolRecordLocalDataSource(db), schedules),
    );
  });
  tearDown(() async {
    Get.reset();
    await db.close();
  });

  Future<void> pumpPage(WidgetTester tester) async {
    await tester.pumpWidget(
      GetMaterialApp(
        theme: AppTheme.light(),
        home: const Scaffold(body: ClassSchedulePage()),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('sem materia na grade: a aba Notas e faltas nao aparece', (
    tester,
  ) async {
    await tester.runAsync(
      () => schedules.createSchedule(name: 'Escola', withTemplate: false),
    );
    await pumpPage(tester);
    expect(find.text('Notas e faltas'), findsNothing);
  });

  testWidgets('com materias: aba propria para lancar nota e falta', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.runAsync(() => schedules.createSchedule(name: 'Escola'));
    await pumpPage(tester);

    await tester.tap(find.text('Notas e faltas'));
    await tester.pumpAndSettle();
    // Um cartao por materia da grade, ainda sem media.
    expect(find.text('Ciências'), findsOneWidget);
    expect(find.text('—'), findsWidgets);

    final card = find.ancestor(
      of: find.text('Ciências'),
      matching: find.byType(Card),
    );
    await tester.tap(find.descendant(of: card, matching: find.text('Nota')));
    await tester.pumpAndSettle();
    expect(find.text('Nova nota'), findsOneWidget);

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Avaliação (opcional)'),
      'Prova 1',
    );
    await tester.enterText(find.widgetWithText(TextFormField, 'Nota'), '7,5');
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Observação (opcional)'),
      'recuperação',
    );
    await tester.runAsync(() async {
      await tester.tap(find.text('Salvar nota'));
      await Future<void>.delayed(const Duration(milliseconds: 200));
    });
    await tester.pumpAndSettle();
    expect(find.text('7,5'), findsOneWidget);
    expect(records.records.single.note, 'recuperação');

    await tester.tap(find.descendant(of: card, matching: find.text('Falta')));
    await tester.pumpAndSettle();
    await tester.runAsync(() async {
      await tester.tap(find.text('Salvar falta'));
      await Future<void>.delayed(const Duration(milliseconds: 200));
    });
    await tester.pumpAndSettle();
    expect(
      find.descendant(of: card, matching: find.text('1 falta')),
      findsOneWidget,
    );
  });

  testWidgets(
    'tela estreita (360dp) com fonte grande: aba e formulario cabem',
    (tester) async {
      tester.view.physicalSize = const Size(1080, 2340);
      tester.view.devicePixelRatio = 3; // 360 x 780 dp
      tester.platformDispatcher.textScaleFactorTestValue = 1.6;
      addTearDown(tester.view.reset);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await tester.runAsync(() => schedules.createSchedule(name: 'Escola'));
      await pumpPage(tester);

      await tester.tap(find.text('Notas e faltas'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Nota').first);
      await tester.pumpAndSettle();
      expect(find.text('Nova nota'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}

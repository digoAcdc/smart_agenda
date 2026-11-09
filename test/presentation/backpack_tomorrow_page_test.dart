import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_agenda/data/datasources/class_schedule_local_datasource.dart';
import 'package:smart_agenda/data/local/app_database.dart';
import 'package:smart_agenda/presentation/controllers/class_schedule_controller.dart';
import 'package:smart_agenda/presentation/pages/backpack_tomorrow_page.dart';
import 'package:smart_agenda/presentation/services/backpack_reminder_service.dart';

void main() {
  late AppDatabase db;
  late ClassScheduleController controller;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await initializeDateFormatting('pt_BR');
    db = AppDatabase(NativeDatabase.memory());
    controller = Get.put(
      ClassScheduleController(ClassScheduleLocalDataSource(db)),
    );
    Get.put(BackpackReminderService());
  });
  tearDown(() async {
    Get.reset();
    await db.close();
  });

  Future<void> openPage(WidgetTester tester) async {
    await tester.pumpWidget(
      GetMaterialApp(
        home: const Scaffold(),
        getPages: [GetPage(name: '/m', page: BackpackTomorrowPage.new)],
      ),
    );
    Get.toNamed('/m');
    await tester.pumpAndSettle();
  }

  testWidgets('mochila vazia: da para adicionar daqui escolhendo a materia', (
    tester,
  ) async {
    await tester.runAsync(() => controller.createSchedule(name: 'Escola'));
    await openPage(tester);

    expect(find.text('Nada para levar amanhã'), findsOneWidget);
    await tester.tap(find.text('Adicionar à mochila'));
    await tester.pumpAndSettle();

    expect(find.text('Para qual matéria?'), findsOneWidget);
    await tester.tap(find.widgetWithText(ListTile, 'Inglês'));
    await tester.pumpAndSettle();

    // Abre o mesmo passo a passo da tela da materia.
    expect(find.text('1. O que levar?'), findsOneWidget);
  });

  testWidgets('sem materia na grade: sem botao e explica onde comecar', (
    tester,
  ) async {
    await tester.runAsync(
      () => controller.createSchedule(name: 'Escola', withTemplate: false),
    );
    await openPage(tester);

    expect(find.text('Adicionar à mochila'), findsNothing);
    expect(find.textContaining('Monte a grade em Aulas'), findsOneWidget);
  });
}

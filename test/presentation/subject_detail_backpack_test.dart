import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_agenda/data/datasources/class_schedule_local_datasource.dart';
import 'package:smart_agenda/data/local/app_database.dart';
import 'package:smart_agenda/domain/entities/backpack_item.dart';
import 'package:smart_agenda/presentation/controllers/class_schedule_controller.dart';
import 'package:smart_agenda/presentation/pages/subject_detail_page.dart';
import 'package:smart_agenda/presentation/widgets/add_backpack_sheet.dart';

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
  });
  tearDown(() async {
    Get.reset();
    await db.close();
  });

  Future<void> openDetail(
    WidgetTester tester, {
    bool canEdit = true,
    double textScale = 1,
  }) async {
    late SubjectDetailArgs args;
    await tester.runAsync(() async {
      await controller.createSchedule(name: 'Escola');
      final slot = controller.slots.firstWhere((s) => s.subject == 'Inglês');
      args = SubjectDetailArgs(
        slot: slot,
        dayLabel: 'Segunda',
        canEdit: canEdit,
      );
    });
    await tester.pumpWidget(
      GetMaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
        ),
        home: const Scaffold(),
        getPages: [GetPage(name: '/d', page: SubjectDetailPage.new)],
      ),
    );
    Get.toNamed('/d', arguments: args);
    await tester.pumpAndSettle();
  }

  /// FilledButton.icon e uma subclasse: byType nao acha.
  Finder filled(String text) => find.ancestor(
    of: find.text(text),
    matching: find.byWidgetPredicate((w) => w is FilledButton),
  );

  Future<void> tapAndWait(WidgetTester tester, Finder finder) async {
    await tester.runAsync(() async {
      await tester.tap(finder);
      await Future<void>.delayed(const Duration(milliseconds: 200));
    });
    await tester.pumpAndSettle();
  }

  testWidgets('a Mochila e o conteudo da tela, sem abas vazias', (
    tester,
  ) async {
    await openDetail(tester);
    expect(find.byType(TabBar), findsNothing);
    expect(find.text('Faltas'), findsNothing);
    expect(find.text('O que levar na mochila'), findsOneWidget);
    expect(find.text('Nada na mochila ainda'), findsOneWidget);
    // O adicionar e um botao claro, sempre visivel.
    expect(
      find.widgetWithText(FloatingActionButton, 'Adicionar à mochila'),
      findsOneWidget,
    );
  });

  testWidgets('quem so ve nao tem o botao de adicionar', (tester) async {
    await openDetail(tester, canEdit: false);
    expect(find.text('Adicionar à mochila'), findsNothing);
    expect(find.textContaining('Só quem pode editar'), findsOneWidget);
  });

  testWidgets(
    'adicionar: varios itens, um dia de aula e sem lembrete, de uma vez',
    (tester) async {
      await openDetail(tester);
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();
      expect(find.byType(AddBackpackSheet), findsOneWidget);
      expect(find.text('1. O que levar?'), findsOneWidget);
      // Sem nada escolhido, o botao nao adiciona.
      final save = filled('Escolha o que levar');
      expect(tester.widget<ButtonStyleButton>(save).onPressed, isNull);

      await tester.tap(find.widgetWithText(FilterChip, 'Livro'));
      await tester.pump();
      await tester.enterText(find.byType(TextField), 'Dicionário');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
      // O digitado vira chip marcado.
      expect(
        tester
            .widget<FilterChip>(find.widgetWithText(FilterChip, 'Dicionário'))
            .selected,
        isTrue,
      );

      // Quando: o primeiro dia de aula da lista ("Só ...").
      final days = controller.upcomingClassDatesFor('Inglês');
      expect(days, isNotEmpty);
      final dayChip = find.widgetWithText(
        ChoiceChip,
        'Só ${formatBackpackDay(days.first)}',
      );
      await tester.ensureVisible(dayChip);
      await tester.tap(dayChip);
      await tester.pumpAndSettle();

      final remind = find.byType(SwitchListTile);
      await tester.ensureVisible(remind);
      await tester.tap(remind);
      await tester.pumpAndSettle();
      expect(find.textContaining('Sem aviso'), findsOneWidget);

      await tapAndWait(tester, filled('Adicionar 2 itens'));

      expect(find.byType(AddBackpackSheet), findsNothing);
      final items = controller.backpackFor('Inglês');
      expect(items.map((i) => i.label), ['Livro', 'Dicionário']);
      expect(
        items.every(
          (i) =>
              i.frequency == BackpackFrequency.nextClass &&
              i.dueDate == days.first &&
              !i.remind,
        ),
        isTrue,
      );
      expect(find.widgetWithText(ListTile, 'Livro'), findsOneWidget);
      expect(find.textContaining('sem lembrete'), findsNWidgets(2));

      // Liga o lembrete de um item pelo sininho.
      await tapAndWait(tester, find.byTooltip('Ligar lembrete de Livro'));
      expect(
        controller
            .backpackFor('Inglês')
            .firstWhere((i) => i.label == 'Livro')
            .remind,
        isTrue,
      );
    },
  );

  testWidgets('toda aula e o padrao, e item repetido nao entra de novo', (
    tester,
  ) async {
    await openDetail(tester);
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilterChip, 'Caderno'));
    await tester.pump();
    await tapAndWait(tester, filled('Adicionar 1 item'));
    final item = controller.backpackFor('Inglês').single;
    expect(item.isWeekly, isTrue);
    expect(item.remind, isTrue);
    expect(find.textContaining('Toda aula ·'), findsOneWidget);

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    // Ja esta em toda aula: sai das sugestoes.
    expect(find.widgetWithText(FilterChip, 'Caderno'), findsNothing);
    await tester.enterText(find.byType(TextField), 'caderno');
    await tester.pump();
    await tapAndWait(tester, filled('Adicionar 1 item'));
    expect(find.text('Esses itens já estão na mochila.'), findsOneWidget);
    expect(controller.backpackFor('Inglês').length, 1);
  });

  testWidgets('cabe em 360dp com fonte grande (tela e folha de adicionar)', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 740);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await openDetail(tester, textScale: 1.6);
    expect(tester.takeException(), isNull);
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.tap(find.widgetWithText(FilterChip, 'Uniforme de Ed. Física'));
    await tester.pump();
    await tapAndWait(tester, filled('Adicionar 1 item'));
    expect(tester.takeException(), isNull);
    expect(find.byType(FloatingActionButton), findsOneWidget);
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:smart_agenda/core/result/result.dart';
import 'package:smart_agenda/domain/entities/agenda_enums.dart';
import 'package:smart_agenda/domain/entities/agenda_item.dart';
import 'package:smart_agenda/domain/repositories/i_agenda_repository.dart';
import 'package:smart_agenda/domain/repositories/i_notification_service.dart';
import 'package:smart_agenda/domain/usecases/agenda_usecases.dart';
import 'package:smart_agenda/presentation/controllers/agenda_controller.dart';

class _RangeRepo implements IAgendaRepository {
  _RangeRepo(this.items);
  final List<AgendaItem> items;

  @override
  Future<Result<List<AgendaItem>>> getItemsByRange(DateTime start, DateTime end) async =>
      Result.success(items
          .where((e) => !e.startAt.isBefore(start) && !e.startAt.isAfter(end))
          .toList());

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _NoopNotifications implements INotificationService {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

AgendaItem _item(String id, DateTime start,
    {AgendaStatus status = AgendaStatus.pending, bool allDay = false}) {
  final now = DateTime.now();
  return AgendaItem(
    id: id,
    title: id,
    startAt: start,
    allDay: allDay,
    status: status,
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  test('proximos eventos: futuros em ordem, inclui distantes, ignora passados e cancelados',
      () async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final repo = _RangeRepo([
      _item('daqui-3-meses', now.add(const Duration(days: 90))),
      _item('amanha', today.add(const Duration(days: 1, hours: 9))),
      _item('passado-hoje', now.subtract(const Duration(minutes: 30))),
      _item('dia-todo-hoje', today, allDay: true),
      _item('cancelado', now.add(const Duration(days: 2)), status: AgendaStatus.canceled),
      _item('ontem', today.subtract(const Duration(days: 1))),
    ]);
    final controller = AgendaController(
      createAgendaItem: CreateAgendaItem(repo),
      updateAgendaItem: UpdateAgendaItem(repo),
      deleteAgendaItem: DeleteAgendaItem(repo),
      duplicateAgendaItem: DuplicateAgendaItem(repo, () => 'x'),
      setAgendaStatus: SetAgendaStatus(repo),
      getAgendaItemsByDay: GetAgendaItemsByDay(repo),
      getAgendaItemsByRange: GetAgendaItemsByRange(repo),
      getAgendaMarkersByRange: GetAgendaMarkersByRange(repo),
      searchAgendaItems: SearchAgendaItems(repo),
      notificationService: _NoopNotifications(),
    );

    await controller.loadUpcoming();

    expect(
      controller.upcomingItems.map((e) => e.id).toList(),
      ['dia-todo-hoje', 'amanha', 'daqui-3-meses'],
    );
  });

  test('atualizacao em segundo plano nao mostra esqueleto de carregamento', () async {
    final repo = _RangeRepo([_item('amanha', DateTime.now().add(const Duration(days: 1)))]);
    final controller = AgendaController(
      createAgendaItem: CreateAgendaItem(repo),
      updateAgendaItem: UpdateAgendaItem(repo),
      deleteAgendaItem: DeleteAgendaItem(repo),
      duplicateAgendaItem: DuplicateAgendaItem(repo, () => 'x'),
      setAgendaStatus: SetAgendaStatus(repo),
      getAgendaItemsByDay: GetAgendaItemsByDay(repo),
      getAgendaItemsByRange: GetAgendaItemsByRange(repo),
      getAgendaMarkersByRange: GetAgendaMarkersByRange(repo),
      searchAgendaItems: SearchAgendaItems(repo),
      notificationService: _NoopNotifications(),
    );
    final loadingStates = <bool>[];
    controller.loading.listen(loadingStates.add);

    await controller.refreshCurrentData();
    await Future<void>.delayed(Duration.zero);

    expect(loadingStates, isNot(contains(true)));
    expect(controller.upcomingItems.map((e) => e.id), ['amanha']);
  });
}

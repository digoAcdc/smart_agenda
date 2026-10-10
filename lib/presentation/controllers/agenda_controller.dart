import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:uuid/uuid.dart';

import '../../core/utils/date_utils.dart';
import '../../domain/entities/agenda_enums.dart';
import '../../domain/entities/agenda_item.dart';
import '../../domain/entities/attachment_ref.dart';
import '../../domain/entities/recurrence_rule.dart';
import '../../domain/entities/reminder_config.dart';
import '../../domain/repositories/i_notification_service.dart';
import '../../domain/repositories/i_sync_service.dart';
import '../../domain/usecases/agenda_usecases.dart';
import '../../domain/value_objects/search_filters.dart';

class AgendaController extends GetxController {
  AgendaController({
    required this.createAgendaItem,
    required this.updateAgendaItem,
    required this.deleteAgendaItem,
    required this.duplicateAgendaItem,
    required this.setAgendaStatus,
    required this.getAgendaItemsByDay,
    required this.getAgendaItemsByRange,
    required this.getAgendaMarkersByRange,
    required this.searchAgendaItems,
    required this.notificationService,
    this.syncService,
  });

  final CreateAgendaItem createAgendaItem;
  final UpdateAgendaItem updateAgendaItem;
  final DeleteAgendaItem deleteAgendaItem;
  final DuplicateAgendaItem duplicateAgendaItem;
  final SetAgendaStatus setAgendaStatus;
  final GetAgendaItemsByDay getAgendaItemsByDay;
  final GetAgendaItemsByRange getAgendaItemsByRange;
  final GetAgendaMarkersByRange getAgendaMarkersByRange;
  final SearchAgendaItems searchAgendaItems;
  final INotificationService notificationService;
  final ISyncService? syncService;

  final Rx<DateTime> selectedDate = DateTime.now().obs;
  final RxList<AgendaItem> todayItems = <AgendaItem>[].obs;
  final RxList<AgendaItem> weekItems = <AgendaItem>[].obs;
  final RxList<AgendaItem> monthItems = <AgendaItem>[].obs;
  final RxList<AgendaItem> selectedDayItems = <AgendaItem>[].obs;
  final RxList<AgendaItem> searchResults = <AgendaItem>[].obs;

  /// Proximos eventos a partir de agora, mesmo que distantes.
  final RxList<AgendaItem> upcomingItems = <AgendaItem>[].obs;

  /// Provas e trabalhos pendentes dos proximos 45 dias (bloco da Inicio).
  final RxList<AgendaItem> upcomingSchoolWork = <AgendaItem>[].obs;
  static const _upcomingHorizon = Duration(days: 365);
  static const _upcomingLimit = 15;
  final RxSet<DateTime> monthMarkers = <DateTime>{}.obs;
  final RxBool loading = false.obs;
  final RxnString errorMessage = RxnString();
  int _loadByDayRequestId = 0;
  StreamSubscription<void>? _remoteChangesSub;

  // Periodos que estao na tela: atualizar recarrega estes, nao a semana/mes
  // atual (antes, concluir algo numa semana futura esvaziava a lista).
  (DateTime, DateTime)? _shownWeek;
  (DateTime, DateTime)? _shownMonth;
  (DateTime, DateTime)? _shownMarkers;

  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      loadToday();
      await loadUpcoming();
      await loadUpcomingSchoolWork();
      await _scheduleUpcomingOccurrenceReminders();
    });
    // Alteracoes de outros membros/dispositivos chegam pelo sync.
    _remoteChangesSub = syncService?.onDataChanged.listen(
      (_) => refreshCurrentData(),
    );
  }

  @override
  void onClose() {
    _remoteChangesSub?.cancel();
    super.onClose();
  }

  /// [silent]: atualiza sem trocar a tela pelo esqueleto de carregamento
  /// (sincronizacoes e depois de salvar).
  Future<void> loadToday({bool silent = false}) async {
    if (!silent) loading.value = true;
    errorMessage.value = null;
    final result = await getAgendaItemsByDay(DateTime.now());
    if (result.isSuccess) {
      todayItems.assignAll(result.data ?? []);
    } else {
      errorMessage.value = result.errorMessage;
    }
    loading.value = false;
  }

  Future<void> loadUpcoming() async {
    final now = DateTime.now();
    final today = DateUtilsEx.startOfDay(now);
    final result = await getAgendaItemsByRange(
      today,
      now.add(_upcomingHorizon),
    );
    if (!result.isSuccess) return;
    final items =
        (result.data ?? [])
            .where((e) => e.status != AgendaStatus.canceled)
            .where(
              (e) =>
                  !e.startAt.isBefore(now) ||
                  (e.allDay && DateUtilsEx.startOfDay(e.startAt) == today),
            )
            .toList()
          ..sort((a, b) => a.startAt.compareTo(b.startAt));
    upcomingItems.assignAll(items.take(_upcomingLimit));
  }

  Future<void> loadUpcomingSchoolWork() async {
    final today = DateUtilsEx.startOfDay(DateTime.now());
    final result = await getAgendaItemsByRange(
      today,
      today.add(const Duration(days: 45)),
    );
    if (!result.isSuccess) return;
    upcomingSchoolWork.assignAll(
      (result.data ?? []).where(
        (e) => e.kind.isSchoolWork && e.status == AgendaStatus.pending,
      ),
    );
  }

  Future<void> loadWeek(
    DateTime start,
    DateTime end, {
    bool silent = false,
  }) async {
    if (!silent) loading.value = true;
    _shownWeek = (start, end);
    final result = await getAgendaItemsByRange(start, end);
    if (result.isSuccess) {
      weekItems.assignAll(result.data ?? []);
    } else {
      errorMessage.value = result.errorMessage;
    }
    loading.value = false;
  }

  Future<void> loadMonthItems(
    DateTime start,
    DateTime end, {
    bool silent = false,
  }) async {
    if (!silent) loading.value = true;
    _shownMonth = (start, end);
    final result = await getAgendaItemsByRange(start, end);
    if (result.isSuccess) {
      monthItems.assignAll(result.data ?? []);
    } else {
      errorMessage.value = result.errorMessage;
    }
    loading.value = false;
  }

  Future<void> loadMonth(DateTime start, DateTime end) async {
    _shownMarkers = (start, end);
    final result = await getAgendaMarkersByRange(start, end);
    if (result.isSuccess) {
      monthMarkers.assignAll(result.data ?? {});
    } else {
      errorMessage.value = result.errorMessage;
    }
  }

  Future<void> loadByDay(DateTime date) async {
    final requestId = ++_loadByDayRequestId;
    selectedDate.value = date;
    final result = await getAgendaItemsByDay(date);
    if (requestId != _loadByDayRequestId) return;
    if (result.isSuccess) {
      selectedDayItems.assignAll(result.data ?? []);
    } else {
      errorMessage.value = result.errorMessage;
    }
  }

  Future<bool> createItem(AgendaItem item) async {
    loading.value = true;
    errorMessage.value = null;
    final result = await createAgendaItem(item);
    if (result.isSuccess) {
      final notifyResult = await notificationService.scheduleForItem(item);
      if (!notifyResult.isSuccess) {
        errorMessage.value = notifyResult.errorMessage;
      }
      await refreshCurrentData();
      loading.value = false;
      return true;
    }
    errorMessage.value = result.errorMessage;
    loading.value = false;
    return false;
  }

  Future<bool> updateItem(AgendaItem item) async {
    loading.value = true;
    errorMessage.value = null;
    await notificationService.cancelForItem(item);
    final result = await updateAgendaItem(
      item.copyWith(updatedAt: DateTime.now()),
    );
    if (result.isSuccess) {
      final notifyResult = await notificationService.scheduleForItem(item);
      if (!notifyResult.isSuccess) {
        errorMessage.value = notifyResult.errorMessage;
      }
      await refreshCurrentData();
      loading.value = false;
      return true;
    }
    errorMessage.value = result.errorMessage;
    loading.value = false;
    return false;
  }

  Future<bool> deleteItem(String id) async {
    loading.value = true;
    final existing = await getAgendaItemsByDay(selectedDate.value);
    final target = existing.data?.firstWhereOrNull((e) => e.id == id);
    if (target != null) {
      await notificationService.cancelForItem(target);
    }
    final result = await deleteAgendaItem(id);
    if (result.isSuccess) {
      await refreshCurrentData();
      loading.value = false;
      return true;
    }
    errorMessage.value = result.errorMessage;
    loading.value = false;
    return false;
  }

  Future<bool> duplicateItem(String id) async {
    loading.value = true;
    final result = await duplicateAgendaItem(id);
    if (result.isSuccess) {
      await refreshCurrentData();
      loading.value = false;
      return true;
    }
    errorMessage.value = result.errorMessage;
    loading.value = false;
    return false;
  }

  /// Lembretes das proximas ocorrencias de eventos que se repetem. Rodado ao
  /// abrir o app para a serie continuar avisando depois das ja agendadas.
  Future<void> _scheduleUpcomingOccurrenceReminders() async {
    for (final occ in upcomingItems.where(
      (e) => e.isOccurrence && (e.reminder?.enabled ?? false),
    )) {
      await notificationService.scheduleForItem(occ);
    }
  }

  /// Concluir/reabrir/cancelar. Em evento que se repete, vale so para a
  /// ocorrencia tocada (cancelar = tirar so aquele dia).
  Future<void> toggleItemStatus(AgendaItem item, AgendaStatus status) async {
    if (!item.isOccurrence) return toggleStatus(item.id, status);
    final day = item.occurrenceDate!;
    final result = status == AgendaStatus.canceled
        ? await setAgendaStatus.removeOccurrence(item.id, day)
        : await setAgendaStatus.occurrenceDone(
            item.id,
            day,
            status == AgendaStatus.done,
          );
    if (!result.isSuccess) errorMessage.value = result.errorMessage;
    await refreshCurrentData();
  }

  /// Excluir so uma ocorrencia de um evento que se repete.
  Future<bool> deleteOccurrence(AgendaItem occurrence) async {
    final day = occurrence.occurrenceDate;
    if (day == null) return deleteItem(occurrence.id);
    await notificationService.cancelForItem(occurrence);
    final result = await setAgendaStatus.removeOccurrence(occurrence.id, day);
    if (!result.isSuccess) {
      errorMessage.value = result.errorMessage;
      return false;
    }
    await refreshCurrentData();
    return true;
  }

  Future<void> toggleStatus(String id, AgendaStatus status) async {
    final result = await setAgendaStatus(id, status);
    if (!result.isSuccess) {
      errorMessage.value = result.errorMessage;
    }
    await refreshCurrentData();
  }

  Future<void> runSearch(String query, SearchFilters filters) async {
    final result = await searchAgendaItems(query, filters);
    if (result.isSuccess) {
      searchResults.assignAll(result.data ?? []);
    } else {
      errorMessage.value = result.errorMessage;
    }
  }

  /// Recarrega o que esta na tela sem esqueleto de carregamento.
  Future<void> refreshCurrentData() async {
    final now = DateTime.now();
    await loadToday(silent: true);
    await loadUpcoming();
    await loadUpcomingSchoolWork();
    await loadByDay(selectedDate.value);
    final week =
        _shownWeek ??
        (DateUtilsEx.startOfWeek(now), DateUtilsEx.endOfWeek(now));
    await loadWeek(week.$1, week.$2, silent: true);
    final month =
        _shownMonth ??
        (DateUtilsEx.startOfMonth(now), DateUtilsEx.endOfMonth(now));
    await loadMonthItems(month.$1, month.$2, silent: true);
    final markers = _shownMarkers ?? month;
    await loadMonth(markers.$1, markers.$2);
  }

  AgendaItem buildNewItem({
    required String title,
    String? description,
    required DateTime startAt,
    DateTime? endAt,
    bool allDay = false,
    String? groupId,
    AgendaStatus status = AgendaStatus.pending,
    String? locationText,
    ReminderConfig? reminder,
    RecurrenceRule? recurrence,
    List<AttachmentRef> attachments = const [],
  }) {
    final now = DateTime.now();
    return AgendaItem(
      id: const Uuid().v4(),
      title: title,
      description: description,
      startAt: startAt,
      endAt: endAt,
      allDay: allDay,
      groupId: groupId,
      status: status,
      locationText: locationText,
      reminder: reminder,
      recurrence: recurrence,
      attachments: attachments,
      createdAt: now,
      updatedAt: now,
    );
  }
}

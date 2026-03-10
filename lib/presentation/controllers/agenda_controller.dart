import 'package:get/get.dart';
import 'package:uuid/uuid.dart';

import '../../core/utils/date_utils.dart';
import '../../domain/entities/agenda_enums.dart';
import '../../domain/entities/agenda_item.dart';
import '../../domain/entities/attachment_ref.dart';
import '../../domain/entities/recurrence_rule.dart';
import '../../domain/entities/reminder_config.dart';
import '../../domain/repositories/i_notification_service.dart';
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

  final Rx<DateTime> selectedDate = DateTime.now().obs;
  final RxList<AgendaItem> todayItems = <AgendaItem>[].obs;
  final RxList<AgendaItem> weekItems = <AgendaItem>[].obs;
  final RxList<AgendaItem> monthItems = <AgendaItem>[].obs;
  final RxList<AgendaItem> selectedDayItems = <AgendaItem>[].obs;
  final RxList<AgendaItem> searchResults = <AgendaItem>[].obs;
  final RxSet<DateTime> monthMarkers = <DateTime>{}.obs;
  final RxBool loading = false.obs;
  final RxnString errorMessage = RxnString();
  int _loadByDayRequestId = 0;

  @override
  void onInit() {
    super.onInit();
    loadToday();
  }

  Future<void> loadToday() async {
    loading.value = true;
    errorMessage.value = null;
    final result = await getAgendaItemsByDay(DateTime.now());
    if (result.isSuccess) {
      todayItems.assignAll(result.data ?? []);
    } else {
      errorMessage.value = result.errorMessage;
    }
    loading.value = false;
  }

  Future<void> loadWeek(DateTime start, DateTime end) async {
    loading.value = true;
    final result = await getAgendaItemsByRange(start, end);
    if (result.isSuccess) {
      weekItems.assignAll(result.data ?? []);
    } else {
      errorMessage.value = result.errorMessage;
    }
    loading.value = false;
  }

  Future<void> loadMonthItems(DateTime start, DateTime end) async {
    loading.value = true;
    final result = await getAgendaItemsByRange(start, end);
    if (result.isSuccess) {
      monthItems.assignAll(result.data ?? []);
    } else {
      errorMessage.value = result.errorMessage;
    }
    loading.value = false;
  }

  Future<void> loadMonth(DateTime start, DateTime end) async {
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
    final result =
        await updateAgendaItem(item.copyWith(updatedAt: DateTime.now()));
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

  Future<void> refreshCurrentData() async {
    final now = DateTime.now();
    await loadToday();
    await loadByDay(selectedDate.value);
    await loadWeek(DateUtilsEx.startOfWeek(now), DateUtilsEx.endOfWeek(now));
    await loadMonthItems(
        DateUtilsEx.startOfMonth(now), DateUtilsEx.endOfMonth(now));
    await loadMonth(DateUtilsEx.startOfMonth(now), DateUtilsEx.endOfMonth(now));
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

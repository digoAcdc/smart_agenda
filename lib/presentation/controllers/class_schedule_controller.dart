import 'package:drift/drift.dart';
import 'package:get/get.dart' hide Value;
import 'package:uuid/uuid.dart';

import '../../data/local/app_database.dart';

class TimeRange {
  const TimeRange({required this.start, required this.end});
  final int start;
  final int end;
}

class ClassScheduleController extends GetxController {
  ClassScheduleController(this._db);

  final AppDatabase _db;
  final RxList<ClassScheduleSlotsTableData> slots =
      <ClassScheduleSlotsTableData>[].obs;
  final RxBool loading = false.obs;

  static const weekdays = [1, 2, 3, 4, 5];

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    loading.value = true;
    final data = await (_db.select(_db.classScheduleSlotsTable)
          ..orderBy([
            (t) => OrderingTerm(expression: t.startMinutes),
            (t) => OrderingTerm(expression: t.dayOfWeek),
          ]))
        .get();
    slots.assignAll(data);
    loading.value = false;
  }

  List<TimeRange> get timeRanges {
    final map = <String, TimeRange>{};
    for (final slot in slots) {
      final key = '${slot.startMinutes}_${slot.endMinutes}';
      map[key] = TimeRange(start: slot.startMinutes, end: slot.endMinutes);
    }
    final list = map.values.toList()
      ..sort((a, b) => a.start.compareTo(b.start));
    return list;
  }

  ClassScheduleSlotsTableData? getCell(int dayOfWeek, int start, int end) {
    return slots.firstWhereOrNull((e) =>
        e.dayOfWeek == dayOfWeek &&
        e.startMinutes == start &&
        e.endMinutes == end);
  }

  Future<String?> addTimeRange(int start, int end) async {
    if (end <= start) return 'Fim deve ser maior que inicio';
    loading.value = true;
    final now = DateTime.now();

    for (final day in weekdays) {
      final exists = await (_db.select(_db.classScheduleSlotsTable)
            ..where((t) =>
                t.dayOfWeek.equals(day) &
                t.startMinutes.equals(start) &
                t.endMinutes.equals(end)))
          .getSingleOrNull();
      if (exists == null) {
        await _db.into(_db.classScheduleSlotsTable).insert(
              ClassScheduleSlotsTableCompanion.insert(
                id: const Uuid().v4(),
                dayOfWeek: day,
                startMinutes: start,
                endMinutes: end,
                createdAt: now,
                updatedAt: now,
                subject: const Value(null),
              ),
            );
      }
    }
    await load();
    return null;
  }

  Future<void> updateSubject(String id, String? subject) async {
    await (_db.update(_db.classScheduleSlotsTable)
          ..where((t) => t.id.equals(id)))
        .write(
      ClassScheduleSlotsTableCompanion(
        subject: Value(
            subject == null || subject.trim().isEmpty ? null : subject.trim()),
        updatedAt: Value(DateTime.now()),
      ),
    );
    await load();
  }

  Future<void> removeTimeRange(int start, int end) async {
    await (_db.delete(_db.classScheduleSlotsTable)
          ..where(
              (t) => t.startMinutes.equals(start) & t.endMinutes.equals(end)))
        .go();
    await load();
  }

  String formatMinutes(int minutes) {
    final h = (minutes ~/ 60).toString().padLeft(2, '0');
    final m = (minutes % 60).toString().padLeft(2, '0');
    return '$h:$m';
  }
}

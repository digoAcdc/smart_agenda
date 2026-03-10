import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import '../../domain/entities/class_schedule_slot.dart';
import '../../domain/repositories/i_class_schedule_datasource.dart';

class TimeRange {
  const TimeRange({required this.start, required this.end});
  final int start;
  final int end;
}

class ClassScheduleController extends GetxController {
  ClassScheduleController(this._dataSource);

  final IClassScheduleDataSource _dataSource;
  final RxList<ClassScheduleSlot> slots = <ClassScheduleSlot>[].obs;
  final RxBool loading = false.obs;

  static const weekdays = [1, 2, 3, 4, 5];

  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addPostFrameCallback((_) => load());
  }

  Future<void> load() async {
    loading.value = true;
    final data = await _dataSource.getSlots();
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

  /// Materias ja cadastradas na grade (unicas, ordenadas).
  List<String> get existingSubjects {
    final set = <String>{};
    for (final s in slots) {
      if (s.subject != null && s.subject!.trim().isNotEmpty) {
        set.add(s.subject!.trim());
      }
    }
    return set.toList()..sort();
  }

  /// Retorna o slot de referencia para uma materia (o que tem mais dados preenchidos).
  ClassScheduleSlot? getSlotForSubject(String subject) {
    final trimmed = subject.trim();
    if (trimmed.isEmpty) return null;
    ClassScheduleSlot? best;
    for (final s in slots) {
      if (s.subject?.trim() != trimmed) continue;
      if (best == null) {
        best = s;
        continue;
      }
      final bestScore = _slotDetailScore(best);
      final currScore = _slotDetailScore(s);
      if (currScore > bestScore || (currScore == bestScore && s.updatedAt.isAfter(best.updatedAt))) {
        best = s;
      }
    }
    return best;
  }

  int _slotDetailScore(ClassScheduleSlot s) {
    var n = 0;
    if (s.professorName?.trim().isNotEmpty == true) n++;
    if (s.professorEmail?.trim().isNotEmpty == true) n++;
    if (s.professorPhone?.trim().isNotEmpty == true) n++;
    return n;
  }

  ClassScheduleSlot? getCell(int dayOfWeek, int start, int end) {
    for (final e in slots) {
      if (e.dayOfWeek == dayOfWeek &&
          e.startMinutes == start &&
          e.endMinutes == end) {
        return e;
      }
    }
    return null;
  }

  Future<String?> addTimeRange(int start, int end) async {
    final err = await _dataSource.addTimeRange(start, end);
    if (err != null) return err;
    await load();
    return null;
  }

  Future<void> updateSlotDetails(
    String id, {
    String? subject,
    String? professorName,
    String? professorEmail,
    String? professorPhone,
  }) async {
    await _dataSource.updateSlotDetails(
      id,
      subject: subject,
      professorName: professorName,
      professorEmail: professorEmail,
      professorPhone: professorPhone,
    );
    await load();
  }

  Future<void> removeTimeRange(int start, int end) async {
    await _dataSource.removeTimeRange(start, end);
    await load();
  }

  String formatMinutes(int minutes) {
    final h = (minutes ~/ 60).toString().padLeft(2, '0');
    final m = (minutes % 60).toString().padLeft(2, '0');
    return '$h:$m';
  }
}

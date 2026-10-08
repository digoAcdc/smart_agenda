import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import '../../domain/entities/class_schedule_slot.dart';
import '../../domain/repositories/i_class_schedule_datasource.dart';
import '../../domain/repositories/i_sync_service.dart';

class TimeRange {
  const TimeRange({required this.start, required this.end});
  final int start;
  final int end;
}

class ClassScheduleController extends GetxController {
  ClassScheduleController(this._dataSource, {ISyncService? syncService})
    : _syncService = syncService;

  final IClassScheduleDataSource _dataSource;
  final ISyncService? _syncService;
  StreamSubscription<void>? _remoteChangesSub;

  /// Grade exibida na tela (pessoal ou de um filho).
  final Rx<ScheduleOwner> owner = const ScheduleOwner.mine().obs;
  final RxList<ClassScheduleSlot> slots = <ClassScheduleSlot>[].obs;

  /// Todas as grades (pessoal e dos filhos), usadas na Home.
  final RxList<ClassScheduleSlot> allSlots = <ClassScheduleSlot>[].obs;
  final RxBool loading = false.obs;

  static const weekdays = [1, 2, 3, 4, 5];

  /// Materias sugeridas e usadas na grade modelo.
  static const defaultSubjects = [
    'Matemática',
    'Português',
    'Ciências',
    'História',
    'Geografia',
    'Inglês',
  ];

  /// Horarios da grade modelo (aulas de 50 min, intervalo de 20 apos a 3a).
  static const defaultTimes = [
    (420, 470),
    (470, 520),
    (520, 570),
    (590, 640),
    (640, 690),
    (690, 740),
  ];

  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addPostFrameCallback((_) => load());
    // Grades dos filhos editadas por outros membros chegam pelo sync.
    _remoteChangesSub = _syncService?.onDataChanged.listen(
      (_) => load(silent: true),
    );
  }

  @override
  void onClose() {
    _remoteChangesSub?.cancel();
    super.onClose();
  }

  Future<void> load({bool silent = false}) async {
    if (!silent) loading.value = true;
    final current = owner.value;
    final data = await _dataSource.getSlots(current);
    if (owner.value == current) slots.assignAll(data);
    allSlots.assignAll(await _dataSource.getAllSlots());
    loading.value = false;
  }

  Future<void> selectOwner(ScheduleOwner value) async {
    if (owner.value == value) return;
    owner.value = value;
    slots.clear();
    await load();
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

  /// Materias para escolher: as da grade + as principais sugeridas.
  List<String> get subjectOptions {
    final existing = existingSubjects;
    return [
      ...existing,
      ...defaultSubjects.where((s) => !existing.contains(s)),
    ];
  }

  /// Cria a grade modelo: 6 aulas por dia, de segunda a sexta, com as
  /// materias principais em ordem diferente a cada dia. So em grade vazia.
  Future<void> applyTemplate() async {
    if (slots.isNotEmpty) return;
    final current = owner.value;
    for (final (start, end) in defaultTimes) {
      await _dataSource.addTimeRange(current, start, end);
    }
    final created = await _dataSource.getSlots(current);
    for (final slot in created) {
      final row = defaultTimes.indexWhere(
        (t) => t.$1 == slot.startMinutes && t.$2 == slot.endMinutes,
      );
      if (row < 0) continue;
      final subject =
          defaultSubjects[(row + slot.dayOfWeek - 1) % defaultSubjects.length];
      await _dataSource.updateSlotDetails(slot.id, subject: subject);
    }
    await load();
  }

  Future<String?> updateTimeRange(
    int oldStart,
    int oldEnd,
    int newStart,
    int newEnd,
  ) async {
    final err = await _dataSource.updateTimeRange(
      owner.value,
      oldStart,
      oldEnd,
      newStart,
      newEnd,
    );
    if (err != null) return err;
    await load();
    return null;
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
      if (currScore > bestScore ||
          (currScore == bestScore && s.updatedAt.isAfter(best.updatedAt))) {
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
    final err = await _dataSource.addTimeRange(owner.value, start, end);
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
    await _dataSource.removeTimeRange(owner.value, start, end);
    await load();
  }

  String formatMinutes(int minutes) {
    final h = (minutes ~/ 60).toString().padLeft(2, '0');
    final m = (minutes % 60).toString().padLeft(2, '0');
    return '$h:$m';
  }
}

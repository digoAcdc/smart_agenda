import 'dart:async';

import 'package:get/get.dart';
import 'package:uuid/uuid.dart';

import '../../domain/entities/school_record.dart';
import '../../domain/repositories/i_school_record_datasource.dart';
import '../../domain/repositories/i_sync_service.dart';
import '../../domain/services/school_records_summary.dart';
import 'class_schedule_controller.dart';

/// Aba "Notas e faltas" da tela Aulas: lancamentos da grade aberta.
class SchoolRecordsController extends GetxController {
  SchoolRecordsController(
    this._dataSource,
    this._schedules, {
    ISyncService? syncService,
  }) : _syncService = syncService;

  final ISchoolRecordDataSource _dataSource;
  final ClassScheduleController _schedules;
  final ISyncService? _syncService;
  StreamSubscription<void>? _remoteChangesSub;
  Worker? _scheduleWorker;

  final RxList<SchoolRecord> records = <SchoolRecord>[].obs;

  /// Bimestre mostrado nas notas (nulo = ano todo). Abre no bimestre atual.
  final RxnInt term = RxnInt(termForDate(DateTime.now()));

  @override
  void onInit() {
    super.onInit();
    // Trocou de grade (ex.: outro filho): carrega os lancamentos dela.
    _scheduleWorker = ever(_schedules.selected, (_) => load());
    _remoteChangesSub = _syncService?.onDataChanged.listen((_) => load());
    load();
  }

  @override
  void onClose() {
    _scheduleWorker?.dispose();
    _remoteChangesSub?.cancel();
    super.onClose();
  }

  Future<void> load() async {
    final schedule = _schedules.selected.value;
    if (schedule == null) {
      records.clear();
      return;
    }
    final list = await _dataSource.getRecords(schedule.id);
    // A grade pode ter mudado enquanto carregava.
    if (_schedules.selected.value?.id == schedule.id) records.assignAll(list);
  }

  /// Um resumo por materia da grade (e de materias que sairam dela mas
  /// ainda tem lancamentos).
  List<SubjectRecordsSummary> get summaries => summarizeBySubject(
    subjects: _schedules.existingSubjects,
    records: records.toList(),
    term: term.value,
  );

  /// Lancamentos de [subject], mais recentes primeiro.
  List<SchoolRecord> recordsFor(String subject) =>
      records.where((r) => r.subject == subject).toList();

  Future<void> addAbsence(
    String subject, {
    required DateTime date,
    String? note,
  }) =>
      _create(subject, kind: SchoolRecordKind.absence, date: date, note: note);

  Future<void> addGrade(
    String subject, {
    required double score,
    double maxScore = 10,
    required int term,
    required DateTime date,
    String? title,
    String? note,
  }) => _create(
    subject,
    kind: SchoolRecordKind.grade,
    date: date,
    score: score,
    maxScore: maxScore,
    term: term,
    title: title,
    note: note,
  );

  Future<void> _create(
    String subject, {
    required SchoolRecordKind kind,
    required DateTime date,
    double? score,
    double? maxScore,
    int? term,
    String? title,
    String? note,
  }) async {
    final schedule = _schedules.selected.value;
    if (schedule == null || subject.trim().isEmpty) return;
    final now = DateTime.now();
    await _dataSource.saveRecord(
      SchoolRecord(
        id: const Uuid().v4(),
        scheduleId: schedule.id,
        subject: subject.trim(),
        kind: kind,
        date: DateTime(date.year, date.month, date.day),
        title: title,
        score: score,
        maxScore: maxScore,
        term: term,
        note: note,
        familyId: schedule.familyId,
        childId: schedule.childId,
        createdAt: now,
        updatedAt: now,
      ),
    );
    await load();
  }

  Future<void> updateRecord(SchoolRecord record) async {
    await _dataSource.saveRecord(record);
    await load();
  }

  Future<void> deleteRecord(String id) async {
    await _dataSource.deleteRecord(id);
    await load();
  }
}

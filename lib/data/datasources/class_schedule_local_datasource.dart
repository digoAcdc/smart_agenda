import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../domain/entities/class_schedule_slot.dart';
import '../../domain/repositories/i_class_schedule_datasource.dart';
import '../local/app_database.dart';

/// Data source local para slots de horario (Drift).
class ClassScheduleLocalDataSource implements IClassScheduleDataSource {
  ClassScheduleLocalDataSource(this._db);

  final AppDatabase _db;

  static const _weekdays = [1, 2, 3, 4, 5];

  @override
  Future<List<ClassScheduleSlot>> getSlots() async {
    final rows = await (_db.select(_db.classScheduleSlotsTable)
          ..orderBy([
            (t) => OrderingTerm(expression: t.startMinutes),
            (t) => OrderingTerm(expression: t.dayOfWeek),
          ]))
        .get();
    return rows.map(_toSlot).toList();
  }

  @override
  Future<String?> addTimeRange(int start, int end) async {
    if (end <= start) return 'Fim deve ser maior que inicio';

    final now = DateTime.now();
    for (final day in _weekdays) {
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
                syncState: const Value('pending'),
              ),
            );
      }
    }
    return null;
  }

  @override
  Future<void> updateSlotDetails(
    String id, {
    String? subject,
    String? professorName,
    String? professorEmail,
    String? professorPhone,
  }) async {
    String? trimOrNull(String? v) =>
        v == null || v.trim().isEmpty ? null : v.trim();

    await (_db.update(_db.classScheduleSlotsTable)
          ..where((t) => t.id.equals(id)))
        .write(
      ClassScheduleSlotsTableCompanion(
        subject: Value(trimOrNull(subject)),
        professorName: Value(trimOrNull(professorName)),
        professorEmail: Value(trimOrNull(professorEmail)),
        professorPhone: Value(trimOrNull(professorPhone)),
        updatedAt: Value(DateTime.now()),
        syncState: const Value('pending'),
      ),
    );
  }

  @override
  Future<void> removeTimeRange(int start, int end) async {
    await (_db.delete(_db.classScheduleSlotsTable)
          ..where(
              (t) => t.startMinutes.equals(start) & t.endMinutes.equals(end)))
        .go();
    await _markAllPending();
  }

  Future<void> _markAllPending() async {
    await (_db.update(_db.classScheduleSlotsTable))
        .write(const ClassScheduleSlotsTableCompanion(syncState: Value('pending')));
  }

  Future<List<ClassScheduleSlotsTableData>> getPendingSlots() async {
    return (_db.select(_db.classScheduleSlotsTable)
          ..where((t) => t.syncState.equals('pending'))
          ..orderBy([
            (t) => OrderingTerm(expression: t.startMinutes),
            (t) => OrderingTerm(expression: t.dayOfWeek),
          ]))
        .get();
  }

  Future<List<ClassScheduleSlotsTableData>> getAllSlots() async {
    return (_db.select(_db.classScheduleSlotsTable)
          ..orderBy([
            (t) => OrderingTerm(expression: t.startMinutes),
            (t) => OrderingTerm(expression: t.dayOfWeek),
          ]))
        .get();
  }

  Future<void> markSlotsSynced() async {
    await (_db.update(_db.classScheduleSlotsTable)
          ..where((t) => t.syncState.equals('pending')))
        .write(const ClassScheduleSlotsTableCompanion(syncState: Value('synced')));
  }

  ClassScheduleSlot _toSlot(ClassScheduleSlotsTableData row) {
    return ClassScheduleSlot(
      id: row.id,
      dayOfWeek: row.dayOfWeek,
      startMinutes: row.startMinutes,
      endMinutes: row.endMinutes,
      subject: row.subject,
      professorName: row.professorName,
      professorEmail: row.professorEmail,
      professorPhone: row.professorPhone,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
    );
  }
}

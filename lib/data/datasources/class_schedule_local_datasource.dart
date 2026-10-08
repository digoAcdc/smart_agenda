import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../domain/entities/class_schedule_slot.dart';
import '../../domain/repositories/i_class_schedule_datasource.dart';
import '../local/app_database.dart';

/// Data source local para slots de horario (Drift).
/// Grade pessoal: familyId/childId nulos. Grade de filho: cache da Familia,
/// com exclusao logica para propagar aos outros membros.
class ClassScheduleLocalDataSource implements IClassScheduleDataSource {
  ClassScheduleLocalDataSource(this._db);

  final AppDatabase _db;

  static const _weekdays = [1, 2, 3, 4, 5];

  Expression<bool> _ofOwner($ClassScheduleSlotsTableTable t, ScheduleOwner owner) {
    if (!owner.isChild) return t.childId.isNull() & t.familyId.isNull();
    return t.familyId.equals(owner.familyId!) & t.childId.equals(owner.childId!);
  }

  List<OrderingTerm Function($ClassScheduleSlotsTableTable)> get _order => [
        (t) => OrderingTerm(expression: t.startMinutes),
        (t) => OrderingTerm(expression: t.dayOfWeek),
      ];

  @override
  Future<List<ClassScheduleSlot>> getSlots(ScheduleOwner owner) async {
    final rows = await (_db.select(_db.classScheduleSlotsTable)
          ..where((t) => _ofOwner(t, owner) & t.deletedAt.isNull())
          ..orderBy(_order))
        .get();
    return rows.map(_toSlot).toList();
  }

  @override
  Future<List<ClassScheduleSlot>> getAllSlots() async {
    final rows = await (_db.select(_db.classScheduleSlotsTable)
          ..where((t) => t.deletedAt.isNull())
          ..orderBy(_order))
        .get();
    return rows.map(_toSlot).toList();
  }

  @override
  Future<String?> addTimeRange(ScheduleOwner owner, int start, int end) async {
    if (end <= start) return 'Fim deve ser maior que inicio';

    final now = DateTime.now();
    for (final day in _weekdays) {
      final exists = await (_db.select(_db.classScheduleSlotsTable)
            ..where((t) =>
                _ofOwner(t, owner) &
                t.deletedAt.isNull() &
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
                familyId: Value(owner.familyId),
                childId: Value(owner.childId),
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
  Future<void> removeTimeRange(ScheduleOwner owner, int start, int end) async {
    Expression<bool> sameRange($ClassScheduleSlotsTableTable t) =>
        _ofOwner(t, owner) & t.startMinutes.equals(start) & t.endMinutes.equals(end);
    if (owner.isChild) {
      final now = DateTime.now();
      await (_db.update(_db.classScheduleSlotsTable)..where(sameRange)).write(
        ClassScheduleSlotsTableCompanion(
          deletedAt: Value(now),
          updatedAt: Value(now),
          syncState: const Value('pending'),
        ),
      );
      return;
    }
    await (_db.delete(_db.classScheduleSlotsTable)..where(sameRange)).go();
    await _markAllPersonalPending();
  }

  // ---------------------------------------------------------------------------
  // Sincronizacao
  // ---------------------------------------------------------------------------

  Future<void> _markAllPersonalPending() async {
    await (_db.update(_db.classScheduleSlotsTable)
          ..where((t) => t.familyId.isNull()))
        .write(const ClassScheduleSlotsTableCompanion(syncState: Value('pending')));
  }

  Future<List<ClassScheduleSlotsTableData>> getPendingSlots() async {
    return (_db.select(_db.classScheduleSlotsTable)
          ..where((t) => t.familyId.isNull() & t.syncState.equals('pending'))
          ..orderBy(_order))
        .get();
  }

  /// Grade pessoal completa (sincronizada por substituicao).
  Future<List<ClassScheduleSlotsTableData>> getAllPersonalSlots() async {
    return (_db.select(_db.classScheduleSlotsTable)
          ..where((t) => t.familyId.isNull())
          ..orderBy(_order))
        .get();
  }

  Future<void> markSlotsSynced() async {
    await (_db.update(_db.classScheduleSlotsTable)
          ..where((t) => t.familyId.isNull() & t.syncState.equals('pending')))
        .write(const ClassScheduleSlotsTableCompanion(syncState: Value('synced')));
  }

  Future<List<ClassScheduleSlotsTableData>> getPendingFamilySlots() async {
    return (_db.select(_db.classScheduleSlotsTable)
          ..where((t) => t.familyId.isNotNull() & t.syncState.equals('pending')))
        .get();
  }

  Future<void> markSlotSynced(String id) async {
    await (_db.update(_db.classScheduleSlotsTable)..where((t) => t.id.equals(id)))
        .write(const ClassScheduleSlotsTableCompanion(syncState: Value('synced')));
  }

  Future<void> deleteLocalSlot(String id) async {
    await (_db.delete(_db.classScheduleSlotsTable)..where((t) => t.id.equals(id))).go();
  }

  /// Aplica slot da Familia vindo do servidor (edicao local pendente tem prioridade).
  Future<void> applyRemoteFamilySlot(
    ClassScheduleSlotsTableCompanion slot, {
    required bool deleted,
  }) async {
    final id = slot.id.value;
    final local = await (_db.select(_db.classScheduleSlotsTable)
          ..where((t) => t.id.equals(id)))
        .getSingleOrNull();
    if (local != null && local.syncState == 'pending') return;
    if (deleted) {
      await deleteLocalSlot(id);
      return;
    }
    await _db.into(_db.classScheduleSlotsTable).insertOnConflictUpdate(
          slot.copyWith(syncState: const Value('synced')),
        );
  }

  Future<void> clearFamilySlots({String? keepFamilyId}) async {
    await (_db.delete(_db.classScheduleSlotsTable)
          ..where((t) {
            final isFamily = t.familyId.isNotNull();
            return keepFamilyId == null
                ? isFamily
                : isFamily & t.familyId.equals(keepFamilyId).not();
          }))
        .go();
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
      familyId: row.familyId,
      childId: row.childId,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
    );
  }
}

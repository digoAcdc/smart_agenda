import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../../domain/entities/class_schedule_slot.dart';
import '../../domain/repositories/i_class_schedule_datasource.dart';
import '../local/app_database.dart';

/// Grades e aulas no banco local (Drift).
/// Pessoais: sem familyId (sincronizadas por substituicao no Pro).
/// Da Familia: cache com exclusao logica para propagar aos outros membros.
class ClassScheduleLocalDataSource implements IClassScheduleDataSource {
  ClassScheduleLocalDataSource(this._db);

  final AppDatabase _db;

  static const _weekdays = [1, 2, 3, 4, 5];

  List<OrderingTerm Function($ClassScheduleSlotsTableTable)> get _order => [
    (t) => OrderingTerm(expression: t.startMinutes),
    (t) => OrderingTerm(expression: t.dayOfWeek),
  ];

  Expression<bool> _ofSchedule(
    $ClassScheduleSlotsTableTable t,
    ClassSchedule s,
  ) => t.scheduleId.equals(s.id) & t.deletedAt.isNull();

  // ---------------------------------------------------------------------------
  // Grades
  // ---------------------------------------------------------------------------

  @override
  Future<List<ClassSchedule>> getSchedules() async {
    final rows =
        await (_db.select(_db.classSchedulesTable)
              ..where((t) => t.deletedAt.isNull())
              ..orderBy([(t) => OrderingTerm(expression: t.createdAt)]))
            .get();
    return rows.map(_toSchedule).toList();
  }

  @override
  Future<ClassSchedule> createSchedule({
    required String name,
    String? familyId,
    String? childId,
  }) async {
    final now = DateTime.now();
    final row = ClassSchedulesTableCompanion.insert(
      id: const Uuid().v4(),
      name: name.trim(),
      familyId: Value(familyId),
      childId: Value(childId),
      createdAt: now,
      updatedAt: now,
    );
    await _db.into(_db.classSchedulesTable).insert(row);
    return ClassSchedule(
      id: row.id.value,
      name: row.name.value,
      familyId: row.familyId.value,
      childId: row.childId.value,
      createdAt: now,
      updatedAt: now,
    );
  }

  @override
  Future<void> setBringItems(
    String scheduleId,
    Map<String, String> items,
  ) async {
    final clean = {
      for (final e in items.entries)
        if (e.key.trim().isNotEmpty && e.value.trim().isNotEmpty)
          e.key.trim(): e.value.trim(),
    };
    await (_db.update(
      _db.classSchedulesTable,
    )..where((t) => t.id.equals(scheduleId))).write(
      ClassSchedulesTableCompanion(
        bringJson: Value(clean.isEmpty ? null : jsonEncode(clean)),
        updatedAt: Value(DateTime.now()),
        syncState: const Value('pending'),
      ),
    );
  }

  @override
  Future<void> renameSchedule(String id, String name) async {
    await (_db.update(
      _db.classSchedulesTable,
    )..where((t) => t.id.equals(id))).write(
      ClassSchedulesTableCompanion(
        name: Value(name.trim()),
        updatedAt: Value(DateTime.now()),
        syncState: const Value('pending'),
      ),
    );
  }

  @override
  Future<void> deleteSchedule(ClassSchedule schedule) async {
    final now = DateTime.now();
    await _db.transaction(() async {
      if (schedule.isFamily) {
        await (_db.update(
          _db.classSchedulesTable,
        )..where((t) => t.id.equals(schedule.id))).write(
          ClassSchedulesTableCompanion(
            deletedAt: Value(now),
            updatedAt: Value(now),
            syncState: const Value('pending'),
          ),
        );
        // Aulas saem no servidor em cascata; no aparelho, removemos ja.
        await (_db.delete(
          _db.classScheduleSlotsTable,
        )..where((t) => t.scheduleId.equals(schedule.id))).go();
        return;
      }
      await (_db.delete(
        _db.classScheduleSlotsTable,
      )..where((t) => t.scheduleId.equals(schedule.id))).go();
      await (_db.delete(
        _db.classSchedulesTable,
      )..where((t) => t.id.equals(schedule.id))).go();
      await _markAllPersonalPending();
    });
    // Ultima grade pessoal removida de proposito: a nuvem pode ser limpa.
    if (!schedule.isFamily && (await getAllPersonalSchedules()).isEmpty) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(personalSchedulesClearedKey, true);
    }
  }

  /// Marca que o usuario removeu todas as grades pessoais (diferente de um
  /// aparelho novo sem dados, que nunca pode apagar a nuvem).
  static const personalSchedulesClearedKey = 'personal_schedules_cleared';

  /// Copia uma grade pessoal (com as aulas) para a Familia e remove a pessoal.
  Future<ClassSchedule> moveScheduleToFamily(
    ClassSchedule personal,
    String familyId,
  ) async {
    final family = await createSchedule(
      name: personal.name,
      familyId: familyId,
    );
    final now = DateTime.now();
    final slots = await getSlots(personal);
    await _db.batch((batch) {
      batch.insertAll(_db.classScheduleSlotsTable, [
        for (final s in slots)
          ClassScheduleSlotsTableCompanion.insert(
            id: const Uuid().v4(),
            dayOfWeek: s.dayOfWeek,
            startMinutes: s.startMinutes,
            endMinutes: s.endMinutes,
            createdAt: now,
            updatedAt: now,
            subject: Value(s.subject),
            professorName: Value(s.professorName),
            professorEmail: Value(s.professorEmail),
            professorPhone: Value(s.professorPhone),
            scheduleId: Value(family.id),
            familyId: Value(familyId),
            syncState: const Value('pending'),
          ),
      ]);
    });
    await deleteSchedule(personal);
    return family;
  }

  // ---------------------------------------------------------------------------
  // Aulas
  // ---------------------------------------------------------------------------

  @override
  Future<List<ClassScheduleSlot>> getSlots(ClassSchedule schedule) async {
    final rows =
        await (_db.select(_db.classScheduleSlotsTable)
              ..where((t) => _ofSchedule(t, schedule))
              ..orderBy(_order))
            .get();
    return rows.map(_toSlot).toList();
  }

  @override
  Future<List<ClassScheduleSlot>> getAllSlots() async {
    final rows =
        await (_db.select(_db.classScheduleSlotsTable)
              ..where((t) => t.deletedAt.isNull() & t.scheduleId.isNotNull())
              ..orderBy(_order))
            .get();
    return rows.map(_toSlot).toList();
  }

  @override
  Future<String?> addTimeRange(
    ClassSchedule schedule,
    int start,
    int end,
  ) async {
    if (end <= start) return 'Fim deve ser maior que início';

    final now = DateTime.now();
    for (final day in _weekdays) {
      final exists =
          await (_db.select(_db.classScheduleSlotsTable)..where(
                (t) =>
                    _ofSchedule(t, schedule) &
                    t.dayOfWeek.equals(day) &
                    t.startMinutes.equals(start) &
                    t.endMinutes.equals(end),
              ))
              .getSingleOrNull();
      if (exists == null) {
        await _db
            .into(_db.classScheduleSlotsTable)
            .insert(
              ClassScheduleSlotsTableCompanion.insert(
                id: const Uuid().v4(),
                dayOfWeek: day,
                startMinutes: start,
                endMinutes: end,
                createdAt: now,
                updatedAt: now,
                subject: const Value(null),
                scheduleId: Value(schedule.id),
                familyId: Value(schedule.familyId),
                childId: Value(schedule.childId),
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

    await (_db.update(
      _db.classScheduleSlotsTable,
    )..where((t) => t.id.equals(id))).write(
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
  Future<void> removeTimeRange(
    ClassSchedule schedule,
    int start,
    int end,
  ) async {
    Expression<bool> sameRange($ClassScheduleSlotsTableTable t) =>
        _ofSchedule(t, schedule) &
        t.startMinutes.equals(start) &
        t.endMinutes.equals(end);
    if (schedule.isFamily) {
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

  @override
  Future<String?> updateTimeRange(
    ClassSchedule schedule,
    int oldStart,
    int oldEnd,
    int newStart,
    int newEnd,
  ) async {
    if (newEnd <= newStart) return 'Fim deve ser maior que início';
    if (oldStart == newStart && oldEnd == newEnd) return null;
    final clash =
        await (_db.select(_db.classScheduleSlotsTable)
              ..where(
                (t) =>
                    _ofSchedule(t, schedule) &
                    t.startMinutes.equals(newStart) &
                    t.endMinutes.equals(newEnd),
              )
              ..limit(1))
            .getSingleOrNull();
    if (clash != null) return 'Já existe uma linha com esse horário';

    await (_db.update(_db.classScheduleSlotsTable)..where(
          (t) =>
              _ofSchedule(t, schedule) &
              t.startMinutes.equals(oldStart) &
              t.endMinutes.equals(oldEnd),
        ))
        .write(
          ClassScheduleSlotsTableCompanion(
            startMinutes: Value(newStart),
            endMinutes: Value(newEnd),
            updatedAt: Value(DateTime.now()),
            syncState: const Value('pending'),
          ),
        );
    if (!schedule.isFamily) await _markAllPersonalPending();
    return null;
  }

  // ---------------------------------------------------------------------------
  // Sincronizacao: grades pessoais (substituicao completa)
  // ---------------------------------------------------------------------------

  Future<void> _markAllPersonalPending() async {
    await (_db.update(
      _db.classScheduleSlotsTable,
    )..where((t) => t.familyId.isNull())).write(
      const ClassScheduleSlotsTableCompanion(syncState: Value('pending')),
    );
    await (_db.update(_db.classSchedulesTable)
          ..where((t) => t.familyId.isNull()))
        .write(const ClassSchedulesTableCompanion(syncState: Value('pending')));
  }

  Future<bool> hasPersonalPending() async {
    final slot =
        await (_db.select(_db.classScheduleSlotsTable)
              ..where(
                (t) => t.familyId.isNull() & t.syncState.equals('pending'),
              )
              ..limit(1))
            .getSingleOrNull();
    if (slot != null) return true;
    final schedule =
        await (_db.select(_db.classSchedulesTable)
              ..where(
                (t) => t.familyId.isNull() & t.syncState.equals('pending'),
              )
              ..limit(1))
            .getSingleOrNull();
    return schedule != null;
  }

  Future<List<ClassSchedulesTableData>> getAllPersonalSchedules() {
    return (_db.select(
      _db.classSchedulesTable,
    )..where((t) => t.familyId.isNull() & t.deletedAt.isNull())).get();
  }

  /// Aulas pessoais que pertencem a uma grade.
  Future<List<ClassScheduleSlotsTableData>> getAllPersonalSlots() async {
    return (_db.select(_db.classScheduleSlotsTable)
          ..where((t) => t.familyId.isNull() & t.scheduleId.isNotNull())
          ..orderBy(_order))
        .get();
  }

  Future<List<ClassScheduleSlotsTableData>> getPendingSlots() async {
    return (_db.select(_db.classScheduleSlotsTable)
          ..where((t) => t.familyId.isNull() & t.syncState.equals('pending'))
          ..orderBy(_order))
        .get();
  }

  Future<void> markPersonalSynced() async {
    await (_db.update(
      _db.classScheduleSlotsTable,
    )..where((t) => t.familyId.isNull() & t.syncState.equals('pending'))).write(
      const ClassScheduleSlotsTableCompanion(syncState: Value('synced')),
    );
    await (_db.update(_db.classSchedulesTable)
          ..where((t) => t.familyId.isNull() & t.syncState.equals('pending')))
        .write(const ClassSchedulesTableCompanion(syncState: Value('synced')));
  }

  // ---------------------------------------------------------------------------
  // Sincronizacao: grades da Familia (incremental)
  // ---------------------------------------------------------------------------

  Future<List<ClassSchedulesTableData>> getPendingFamilySchedules() {
    return (_db.select(
          _db.classSchedulesTable,
        )..where((t) => t.familyId.isNotNull() & t.syncState.equals('pending')))
        .get();
  }

  Future<List<ClassScheduleSlotsTableData>> getPendingFamilySlots() async {
    return (_db.select(
          _db.classScheduleSlotsTable,
        )..where((t) => t.familyId.isNotNull() & t.syncState.equals('pending')))
        .get();
  }

  Future<void> markScheduleSynced(String id) async {
    await (_db.update(_db.classSchedulesTable)..where((t) => t.id.equals(id)))
        .write(const ClassSchedulesTableCompanion(syncState: Value('synced')));
  }

  Future<void> markSlotSynced(String id) async {
    await (_db.update(
      _db.classScheduleSlotsTable,
    )..where((t) => t.id.equals(id))).write(
      const ClassScheduleSlotsTableCompanion(syncState: Value('synced')),
    );
  }

  Future<void> deleteLocalSchedule(String id) async {
    await (_db.delete(
      _db.classScheduleSlotsTable,
    )..where((t) => t.scheduleId.equals(id))).go();
    await (_db.delete(
      _db.classSchedulesTable,
    )..where((t) => t.id.equals(id))).go();
  }

  Future<void> deleteLocalSlot(String id) async {
    await (_db.delete(
      _db.classScheduleSlotsTable,
    )..where((t) => t.id.equals(id))).go();
  }

  Future<void> applyRemoteFamilySchedule(
    ClassSchedulesTableCompanion schedule, {
    required bool deleted,
  }) async {
    final id = schedule.id.value;
    final local = await (_db.select(
      _db.classSchedulesTable,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
    if (local != null && local.syncState == 'pending') return;
    if (deleted) {
      await deleteLocalSchedule(id);
      return;
    }
    await _db
        .into(_db.classSchedulesTable)
        .insertOnConflictUpdate(
          schedule.copyWith(syncState: const Value('synced')),
        );
  }

  /// Aplica aula da Familia vinda do servidor (edicao local pendente tem prioridade).
  Future<void> applyRemoteFamilySlot(
    ClassScheduleSlotsTableCompanion slot, {
    required bool deleted,
  }) async {
    final id = slot.id.value;
    final local = await (_db.select(
      _db.classScheduleSlotsTable,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
    if (local != null && local.syncState == 'pending') return;
    if (deleted) {
      await deleteLocalSlot(id);
      return;
    }
    await _db
        .into(_db.classScheduleSlotsTable)
        .insertOnConflictUpdate(
          slot.copyWith(syncState: const Value('synced')),
        );
  }

  Future<void> clearFamilySlots({String? keepFamilyId}) async {
    Expression<bool> stale(GeneratedColumn<String> familyId) {
      final isFamily = familyId.isNotNull();
      return keepFamilyId == null
          ? isFamily
          : isFamily & familyId.equals(keepFamilyId).not();
    }

    await (_db.delete(
      _db.classScheduleSlotsTable,
    )..where((t) => stale(t.familyId))).go();
    await (_db.delete(
      _db.classSchedulesTable,
    )..where((t) => stale(t.familyId))).go();
  }

  ClassSchedule _toSchedule(ClassSchedulesTableData row) => ClassSchedule(
    id: row.id,
    name: row.name,
    familyId: row.familyId,
    childId: row.childId,
    bringItems: decodeBringItems(row.bringJson),
    createdAt: row.createdAt,
    updatedAt: row.updatedAt,
  );

  ClassScheduleSlot _toSlot(ClassScheduleSlotsTableData row) {
    return ClassScheduleSlot(
      id: row.id,
      scheduleId: row.scheduleId,
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

/// bring_json -> mapa materia -> o que levar (ignora JSON invalido).
Map<String, String> decodeBringItems(String? json) {
  if (json == null || json.isEmpty) return const {};
  try {
    final raw = jsonDecode(json);
    if (raw is! Map) return const {};
    return {
      for (final e in raw.entries)
        if (e.value is String) e.key.toString(): e.value as String,
    };
  } catch (_) {
    return const {};
  }
}

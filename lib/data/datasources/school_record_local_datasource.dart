import 'package:drift/drift.dart';

import '../../domain/entities/school_record.dart';
import '../../domain/repositories/i_school_record_datasource.dart';
import '../local/app_database.dart';

/// Notas e faltas no banco local (Drift). Exclusao sempre logica: o sync
/// leva o deleted_at para a nuvem (Pro e Familia). No Free fica so aqui.
class SchoolRecordLocalDataSource implements ISchoolRecordDataSource {
  SchoolRecordLocalDataSource(this._db);

  final AppDatabase _db;

  @override
  Future<List<SchoolRecord>> getRecords(String scheduleId) async {
    final rows =
        await (_db.select(_db.schoolRecordsTable)
              ..where(
                (t) => t.scheduleId.equals(scheduleId) & t.deletedAt.isNull(),
              )
              ..orderBy([
                (t) => OrderingTerm.desc(t.date),
                (t) => OrderingTerm.desc(t.createdAt),
              ]))
            .get();
    return rows.map(_toRecord).toList();
  }

  @override
  Future<void> saveRecord(SchoolRecord record) async {
    await _db
        .into(_db.schoolRecordsTable)
        .insertOnConflictUpdate(
          SchoolRecordsTableCompanion.insert(
            id: record.id,
            scheduleId: record.scheduleId,
            subject: record.subject.trim(),
            kind: record.kind.name,
            date: record.date,
            title: Value(_clean(record.title)),
            score: Value(record.score),
            maxScore: Value(record.maxScore),
            term: Value(record.term),
            note: Value(_clean(record.note)),
            familyId: Value(record.familyId),
            childId: Value(record.childId),
            syncState: const Value('pending'),
            createdAt: record.createdAt,
            updatedAt: DateTime.now(),
          ),
        );
  }

  @override
  Future<void> deleteRecord(String id) async {
    final now = DateTime.now();
    await (_db.update(
      _db.schoolRecordsTable,
    )..where((t) => t.id.equals(id))).write(
      SchoolRecordsTableCompanion(
        deletedAt: Value(now),
        updatedAt: Value(now),
        syncState: const Value('pending'),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Sincronizacao
  // ---------------------------------------------------------------------------

  /// Pendentes pessoais (Pro) ou da Familia ([family] true).
  Future<List<SchoolRecordsTableData>> getPending({required bool family}) {
    return (_db.select(_db.schoolRecordsTable)..where(
          (t) =>
              (family ? t.familyId.isNotNull() : t.familyId.isNull()) &
              t.syncState.equals('pending'),
        ))
        .get();
  }

  Future<void> markSynced(String id) async {
    await (_db.update(_db.schoolRecordsTable)..where((t) => t.id.equals(id)))
        .write(const SchoolRecordsTableCompanion(syncState: Value('synced')));
  }

  Future<void> deleteLocal(String id) async {
    await (_db.delete(
      _db.schoolRecordsTable,
    )..where((t) => t.id.equals(id))).go();
  }

  /// Lancamento da Familia vindo do servidor (edicao local pendente vence).
  Future<void> applyRemoteFamily(
    SchoolRecordsTableCompanion record, {
    required bool deleted,
  }) async {
    final id = record.id.value;
    final local = await (_db.select(
      _db.schoolRecordsTable,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
    if (local != null && local.syncState == 'pending') return;
    if (deleted) {
      await deleteLocal(id);
      return;
    }
    await _db
        .into(_db.schoolRecordsTable)
        .insertOnConflictUpdate(
          record.copyWith(syncState: const Value('synced')),
        );
  }

  static String? _clean(String? v) {
    final t = v?.trim();
    return t == null || t.isEmpty ? null : t;
  }

  static SchoolRecord _toRecord(SchoolRecordsTableData row) => SchoolRecord(
    id: row.id,
    scheduleId: row.scheduleId,
    subject: row.subject,
    kind: row.kind == SchoolRecordKind.grade.name
        ? SchoolRecordKind.grade
        : SchoolRecordKind.absence,
    date: row.date,
    title: row.title,
    score: row.score,
    maxScore: row.maxScore,
    term: row.term,
    note: row.note,
    familyId: row.familyId,
    childId: row.childId,
    createdAt: row.createdAt,
    updatedAt: row.updatedAt,
  );
}

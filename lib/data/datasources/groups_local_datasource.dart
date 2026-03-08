import 'package:drift/drift.dart';

import '../local/app_database.dart';

class GroupsLocalDataSource {
  const GroupsLocalDataSource(this._db);
  final AppDatabase _db;

  Future<void> create(AgendaGroupsTableCompanion group) async {
    final withSync = group.copyWith(
      syncState: Value('pending'),
    );
    await _db.into(_db.agendaGroupsTable).insert(withSync);
  }

  Future<void> update(AgendaGroupsTableCompanion group) async {
    final withSync = group.copyWith(syncState: Value('pending'));
    await (_db.update(_db.agendaGroupsTable)
          ..where((t) => t.id.equals(group.id.value)))
        .write(withSync);
  }

  Future<void> deleteSoft(String id, DateTime when) async {
    await (_db.update(_db.agendaGroupsTable)..where((tbl) => tbl.id.equals(id)))
        .write(
      AgendaGroupsTableCompanion(
        deletedAt: Value(when),
        updatedAt: Value(when),
        syncState: const Value('pending'),
      ),
    );
  }

  Future<List<AgendaGroupsTableData>> getPending() {
    return (_db.select(_db.agendaGroupsTable)
          ..where((tbl) =>
              tbl.deletedAt.isNull() & tbl.syncState.equals('pending'))
          ..orderBy([(t) => OrderingTerm(expression: t.name)]))
        .get();
  }

  Future<void> markSynced(String id) async {
    await (_db.update(_db.agendaGroupsTable)..where((tbl) => tbl.id.equals(id)))
        .write(const AgendaGroupsTableCompanion(syncState: Value('synced')));
  }

  Future<List<AgendaGroupsTableData>> getAll() {
    return (_db.select(_db.agendaGroupsTable)
          ..where((tbl) => tbl.deletedAt.isNull())
          ..orderBy([(t) => OrderingTerm(expression: t.name)]))
        .get();
  }
}

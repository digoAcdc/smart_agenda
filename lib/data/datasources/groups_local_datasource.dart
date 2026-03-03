import 'package:drift/drift.dart';

import '../local/app_database.dart';

class GroupsLocalDataSource {
  const GroupsLocalDataSource(this._db);
  final AppDatabase _db;

  Future<void> create(AgendaGroupsTableCompanion group) async {
    await _db.into(_db.agendaGroupsTable).insert(group);
  }

  Future<void> update(AgendaGroupsTableCompanion group) async {
    await (_db.update(_db.agendaGroupsTable)
          ..where((t) => t.id.equals(group.id.value)))
        .write(group);
  }

  Future<void> deleteSoft(String id, DateTime when) async {
    await (_db.update(_db.agendaGroupsTable)..where((tbl) => tbl.id.equals(id)))
        .write(
      AgendaGroupsTableCompanion(
        deletedAt: Value(when),
        updatedAt: Value(when),
      ),
    );
  }

  Future<List<AgendaGroupsTableData>> getAll() {
    return (_db.select(_db.agendaGroupsTable)
          ..where((tbl) => tbl.deletedAt.isNull())
          ..orderBy([(t) => OrderingTerm(expression: t.name)]))
        .get();
  }
}

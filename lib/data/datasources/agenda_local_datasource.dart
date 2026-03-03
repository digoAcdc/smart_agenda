import 'package:drift/drift.dart';

import '../local/app_database.dart';

class AgendaItemRecord {
  const AgendaItemRecord({required this.item, required this.attachments});

  final AgendaItemsTableData item;
  final List<AttachmentsTableData> attachments;
}

class AgendaLocalDataSource {
  const AgendaLocalDataSource(this._db);
  final AppDatabase _db;

  Future<void> createItem(
    AgendaItemsTableCompanion item,
    List<AttachmentsTableCompanion> attachments,
  ) async {
    await _db.transaction(() async {
      await _db.into(_db.agendaItemsTable).insert(item);
      if (attachments.isNotEmpty) {
        await _db.batch((batch) {
          batch.insertAll(_db.attachmentsTable, attachments);
        });
      }
    });
  }

  Future<void> updateItem(
    AgendaItemsTableCompanion item,
    List<AttachmentsTableCompanion> attachments,
  ) async {
    await _db.transaction(() async {
      await (_db.update(_db.agendaItemsTable)
            ..where((tbl) => tbl.id.equals(item.id.value)))
          .write(item);
      await (_db.delete(_db.attachmentsTable)
            ..where((tbl) => tbl.itemId.equals(item.id.value)))
          .go();
      if (attachments.isNotEmpty) {
        await _db.batch((batch) {
          batch.insertAll(_db.attachmentsTable, attachments);
        });
      }
    });
  }

  Future<void> deleteItemSoft(String id, DateTime deletedAt) async {
    await (_db.update(_db.agendaItemsTable)..where((tbl) => tbl.id.equals(id)))
        .write(
      AgendaItemsTableCompanion(
        deletedAt: Value(deletedAt),
        updatedAt: Value(deletedAt),
        syncState: const Value('pending'),
      ),
    );
  }

  Future<AgendaItemRecord?> getById(String id) async {
    final item = await (_db.select(_db.agendaItemsTable)
          ..where((t) => t.id.equals(id)))
        .getSingleOrNull();
    if (item == null || item.deletedAt != null) return null;
    final atts = await (_db.select(_db.attachmentsTable)
          ..where((tbl) => tbl.itemId.equals(item.id)))
        .get();
    return AgendaItemRecord(item: item, attachments: atts);
  }

  Future<List<AgendaItemRecord>> getByRange(
      DateTime start, DateTime end) async {
    final rows = await (_db.select(_db.agendaItemsTable)
          ..where((t) =>
              t.startAt.isBetweenValues(start, end) & t.deletedAt.isNull())
          ..orderBy([(t) => OrderingTerm(expression: t.startAt)]))
        .get();
    return _joinAttachments(rows);
  }

  Future<List<AgendaItemRecord>> search(
    String query, {
    DateTime? start,
    DateTime? end,
    String? groupId,
    String? status,
  }) async {
    final q = _db.select(_db.agendaItemsTable)
      ..where((tbl) {
        Expression<bool> predicate = tbl.deletedAt.isNull();
        if (query.isNotEmpty) {
          predicate = predicate &
              (tbl.title.like('%$query%') | tbl.description.like('%$query%'));
        }
        if (start != null && end != null) {
          predicate = predicate & tbl.startAt.isBetweenValues(start, end);
        }
        if (groupId != null && groupId.isNotEmpty) {
          predicate = predicate & tbl.groupId.equals(groupId);
        }
        if (status != null && status.isNotEmpty) {
          predicate = predicate & tbl.status.equals(status);
        }
        return predicate;
      })
      ..orderBy([(t) => OrderingTerm(expression: t.startAt)]);
    final rows = await q.get();
    return _joinAttachments(rows);
  }

  Future<void> setStatus(String id, String status, DateTime updatedAt) async {
    await (_db.update(_db.agendaItemsTable)..where((tbl) => tbl.id.equals(id)))
        .write(
      AgendaItemsTableCompanion(
        status: Value(status),
        updatedAt: Value(updatedAt),
        syncState: const Value('pending'),
      ),
    );
  }

  Future<List<AgendaItemRecord>> _joinAttachments(
    List<AgendaItemsTableData> items,
  ) async {
    if (items.isEmpty) return [];
    final itemIds = items.map((e) => e.id).toList();
    final atts = await (_db.select(_db.attachmentsTable)
          ..where((tbl) => tbl.itemId.isIn(itemIds)))
        .get();

    return items
        .map(
          (item) => AgendaItemRecord(
            item: item,
            attachments: atts.where((a) => a.itemId == item.id).toList(),
          ),
        )
        .toList();
  }
}

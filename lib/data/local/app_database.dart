import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'app_database.g.dart';

class AgendaItemsTable extends Table {
  TextColumn get id => text()();
  TextColumn get title => text()();
  TextColumn get description => text().nullable()();
  DateTimeColumn get startAt => dateTime()();
  DateTimeColumn get endAt => dateTime().nullable()();
  BoolColumn get allDay => boolean().withDefault(const Constant(false))();
  TextColumn get timezone => text().nullable()();
  TextColumn get groupId => text().nullable()();
  TextColumn get status => text().withDefault(const Constant('pending'))();
  TextColumn get locationText => text().nullable()();
  TextColumn get reminderJson => text().nullable()();
  TextColumn get recurrenceJson => text().nullable()();
  TextColumn get source => text().withDefault(const Constant('local'))();
  TextColumn get syncState => text().withDefault(const Constant('pending'))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get deletedAt => dateTime().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class AgendaGroupsTable extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get colorHex => text().nullable()();
  IntColumn get iconCode => integer().nullable()();
  TextColumn get syncState => text().withDefault(const Constant('pending'))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get deletedAt => dateTime().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class AttachmentsTable extends Table {
  TextColumn get id => text()();
  TextColumn get itemId => text()();
  TextColumn get type => text()();
  TextColumn get localPath => text().nullable()();
  TextColumn get remoteUrl => text().nullable()();
  TextColumn get thumbPath => text().nullable()();
  TextColumn get title => text().nullable()();
  TextColumn get mimeType => text().nullable()();
  IntColumn get sizeBytes => integer().nullable()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class ClassScheduleSlotsTable extends Table {
  TextColumn get id => text()();
  IntColumn get dayOfWeek => integer()();
  IntColumn get startMinutes => integer()();
  IntColumn get endMinutes => integer()();
  TextColumn get subject => text().nullable()();
  TextColumn get syncState => text().withDefault(const Constant('pending'))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DriftDatabase(
  tables: [
    AgendaItemsTable,
    AgendaGroupsTable,
    AttachmentsTable,
    ClassScheduleSlotsTable,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async => m.createAll(),
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            await m.createTable(classScheduleSlotsTable);
          }
          if (from < 3) {
            await m.addColumn(agendaGroupsTable, agendaGroupsTable.syncState);
            await m.addColumn(classScheduleSlotsTable, classScheduleSlotsTable.syncState);
          }
        },
      );

  String encodeJson(Map<String, dynamic>? value) {
    if (value == null) return '';
    return jsonEncode(value);
  }

  Map<String, dynamic>? decodeJson(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    return jsonDecode(raw) as Map<String, dynamic>;
  }
}

QueryExecutor _openConnection() {
  return driftDatabase(name: 'smart_agenda_db');
}

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

class ClassGroupsTable extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get description => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class StudentsTable extends Table {
  TextColumn get id => text()();
  TextColumn get groupId => text()();
  TextColumn get name => text()();
  TextColumn get email => text().nullable()();
  TextColumn get phone => text().nullable()();
  TextColumn get guardianName => text().nullable()();
  TextColumn get guardianEmail => text().nullable()();
  TextColumn get guardianPhone => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class ClassScheduleSlotsTable extends Table {
  TextColumn get id => text()();
  IntColumn get dayOfWeek => integer()();
  IntColumn get startMinutes => integer()();
  IntColumn get endMinutes => integer()();
  TextColumn get subject => text().nullable()();
  TextColumn get professorName => text().nullable()();
  TextColumn get professorEmail => text().nullable()();
  TextColumn get professorPhone => text().nullable()();
  TextColumn get syncState => text().withDefault(const Constant('pending'))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class NotesTable extends Table {
  TextColumn get id => text()();
  TextColumn get title => text()();
  TextColumn get body => text().nullable()();
  TextColumn get imagePath => text().nullable()();
  TextColumn get imageUrl => text().nullable()();
  TextColumn get categoryId => text().nullable()();
  BoolColumn get isPinned => boolean().withDefault(const Constant(false))();
  DateTimeColumn get reminderAt => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class NoteChecklistItemsTable extends Table {
  TextColumn get id => text()();
  TextColumn get noteId => text()();
  TextColumn get itemText => text().named('text')();
  BoolColumn get completed => boolean().withDefault(const Constant(false))();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
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
    ClassGroupsTable,
    StudentsTable,
    ClassScheduleSlotsTable,
    NotesTable,
    NoteChecklistItemsTable,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 6;

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
          if (from < 4) {
            await m.addColumn(classScheduleSlotsTable, classScheduleSlotsTable.professorName);
            await m.addColumn(classScheduleSlotsTable, classScheduleSlotsTable.professorEmail);
            await m.addColumn(classScheduleSlotsTable, classScheduleSlotsTable.professorPhone);
          }
          if (from < 5) {
            await m.createTable(classGroupsTable);
            await m.createTable(studentsTable);
          }
          if (from < 6) {
            await m.createTable(notesTable);
            await m.createTable(noteChecklistItemsTable);
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

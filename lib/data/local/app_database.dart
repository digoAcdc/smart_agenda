import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart' show visibleForTesting;
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
  // Familia dona do item (nulo = agenda pessoal).
  TextColumn get familyId => text().nullable()();
  TextColumn get kind => text().withDefault(const Constant('event'))();
  TextColumn get subjectType => text().withDefault(const Constant('none'))();
  TextColumn get subjectChildId => text().nullable()();
  TextColumn get subjectUserId => text().nullable()();
  TextColumn get assigneeType => text().withDefault(const Constant('none'))();
  TextColumn get assigneeUserId => text().nullable()();
  TextColumn get createdBy => text().nullable()();
  TextColumn get updatedBy => text().nullable()();
  TextColumn get completedBy => text().nullable()();
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
  TextColumn get familyId => text().nullable()();
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
  // Grade de um filho da Familia (nulos = grade pessoal).
  TextColumn get familyId => text().nullable()();
  TextColumn get childId => text().nullable()();
  DateTimeColumn get deletedAt => dateTime().nullable()();
  TextColumn get scheduleId => text().nullable()();
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

/// Grade com nome. Com filho = da Familia; sem filho = pessoal.
class ClassSchedulesTable extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get familyId => text().nullable()();
  TextColumn get childId => text().nullable()();
  TextColumn get syncState => text().withDefault(const Constant('pending'))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get deletedAt => dateTime().nullable()();

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
    ClassSchedulesTable,
    NotesTable,
    NoteChecklistItemsTable,
  ],
)
class AppDatabase extends _$AppDatabase {
  /// [executor] permite banco em memoria nos testes.
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _openConnection());

  @override
  int get schemaVersion => 9;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async => m.createAll(),
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        await m.createTable(classScheduleSlotsTable);
      }
      if (from < 3) {
        await m.addColumn(agendaGroupsTable, agendaGroupsTable.syncState);
        await m.addColumn(
          classScheduleSlotsTable,
          classScheduleSlotsTable.syncState,
        );
      }
      if (from < 4) {
        await m.addColumn(
          classScheduleSlotsTable,
          classScheduleSlotsTable.professorName,
        );
        await m.addColumn(
          classScheduleSlotsTable,
          classScheduleSlotsTable.professorEmail,
        );
        await m.addColumn(
          classScheduleSlotsTable,
          classScheduleSlotsTable.professorPhone,
        );
      }
      if (from < 5) {
        await m.createTable(classGroupsTable);
        await m.createTable(studentsTable);
      }
      if (from < 6) {
        await m.createTable(notesTable);
        await m.createTable(noteChecklistItemsTable);
      }
      if (from < 7) {
        await m.addColumn(agendaItemsTable, agendaItemsTable.familyId);
        await m.addColumn(agendaItemsTable, agendaItemsTable.kind);
        await m.addColumn(agendaItemsTable, agendaItemsTable.subjectType);
        await m.addColumn(agendaItemsTable, agendaItemsTable.subjectChildId);
        await m.addColumn(agendaItemsTable, agendaItemsTable.subjectUserId);
        await m.addColumn(agendaItemsTable, agendaItemsTable.assigneeType);
        await m.addColumn(agendaItemsTable, agendaItemsTable.assigneeUserId);
        await m.addColumn(agendaItemsTable, agendaItemsTable.createdBy);
        await m.addColumn(agendaItemsTable, agendaItemsTable.updatedBy);
        await m.addColumn(agendaItemsTable, agendaItemsTable.completedBy);
        await m.addColumn(agendaGroupsTable, agendaGroupsTable.familyId);
      }
      if (from < 8) {
        await m.addColumn(
          classScheduleSlotsTable,
          classScheduleSlotsTable.familyId,
        );
        await m.addColumn(
          classScheduleSlotsTable,
          classScheduleSlotsTable.childId,
        );
        await m.addColumn(
          classScheduleSlotsTable,
          classScheduleSlotsTable.deletedAt,
        );
      }
      if (from < 9) {
        await m.createTable(classSchedulesTable);
        await m.addColumn(
          classScheduleSlotsTable,
          classScheduleSlotsTable.scheduleId,
        );
        await migrateSlotsToNamedSchedules();
      }
    },
  );

  /// v9: aulas existentes ganham uma grade. Pessoal vira "Minha grade";
  /// cada filho ganha a grade "Escola" (id igual ao da migration 021).
  @visibleForTesting
  Future<void> migrateSlotsToNamedSchedules() async {
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    await customStatement('''
      INSERT INTO class_schedules_table (id, name, family_id, child_id, sync_state, created_at, updated_at)
      SELECT 'legacy-personal', 'Minha grade', NULL, NULL, 'pending', $now, $now
      WHERE EXISTS (SELECT 1 FROM class_schedule_slots_table WHERE family_id IS NULL)
    ''');
    await customStatement('''
      UPDATE class_schedule_slots_table
      SET schedule_id = 'legacy-personal', sync_state = 'pending'
      WHERE family_id IS NULL
    ''');
    await customStatement('''
      INSERT OR IGNORE INTO class_schedules_table (id, name, family_id, child_id, sync_state, created_at, updated_at)
      SELECT DISTINCT 'legacy-' || child_id, 'Escola', family_id, child_id, 'pending', $now, $now
      FROM class_schedule_slots_table WHERE family_id IS NOT NULL
    ''');
    await customStatement('''
      UPDATE class_schedule_slots_table
      SET schedule_id = 'legacy-' || child_id, sync_state = 'pending'
      WHERE family_id IS NOT NULL
    ''');
  }

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

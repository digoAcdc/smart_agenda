import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../domain/entities/class_group.dart';
import '../../domain/entities/student.dart';
import '../local/app_database.dart';

class ClassGroupLocalDataSource {
  ClassGroupLocalDataSource(this._db);

  final AppDatabase _db;

  Future<List<ClassGroup>> getGroups() async {
    final rows = await (_db.select(_db.classGroupsTable)
          ..orderBy([(t) => OrderingTerm(expression: t.name)]))
        .get();
    return rows.map(_toGroup).toList();
  }

  Future<ClassGroup?> getGroupById(String id) async {
    final row = await (_db.select(_db.classGroupsTable)
          ..where((t) => t.id.equals(id)))
        .getSingleOrNull();
    return row != null ? _toGroup(row) : null;
  }

  Future<ClassGroup> createGroup(String name, {String? description}) async {
    final now = DateTime.now();
    final id = const Uuid().v4();
    await _db.into(_db.classGroupsTable).insert(
          ClassGroupsTableCompanion.insert(
            id: id,
            name: name.trim(),
            description: Value(description?.trim()),
            createdAt: now,
            updatedAt: now,
          ),
        );
    return ClassGroup(
      id: id,
      name: name.trim(),
      description: description?.trim(),
      createdAt: now,
      updatedAt: now,
    );
  }

  Future<void> updateGroup(ClassGroup group) async {
    await (_db.update(_db.classGroupsTable)..where((t) => t.id.equals(group.id)))
        .write(
      ClassGroupsTableCompanion(
        name: Value(group.name),
        description: Value(group.description),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> deleteGroup(String id) async {
    await (_db.delete(_db.studentsTable)..where((t) => t.groupId.equals(id)))
        .go();
    await (_db.delete(_db.classGroupsTable)..where((t) => t.id.equals(id)))
        .go();
  }

  Future<List<Student>> getStudentsByGroup(String groupId) async {
    final rows = await (_db.select(_db.studentsTable)
          ..where((t) => t.groupId.equals(groupId))
          ..orderBy([(t) => OrderingTerm(expression: t.name)]))
        .get();
    return rows.map(_toStudent).toList();
  }

  Future<Student?> getStudentById(String id) async {
    final row = await (_db.select(_db.studentsTable)
          ..where((t) => t.id.equals(id)))
        .getSingleOrNull();
    return row != null ? _toStudent(row) : null;
  }

  Future<Student> createStudent(Student student) async {
    final now = DateTime.now();
    final id = student.id.isEmpty ? const Uuid().v4() : student.id;
    await _db.into(_db.studentsTable).insert(
          StudentsTableCompanion.insert(
            id: id,
            groupId: student.groupId,
            name: student.name.trim(),
            email: Value(_trimOrNull(student.email)),
            phone: Value(_trimOrNull(student.phone)),
            guardianName: Value(_trimOrNull(student.guardianName)),
            guardianEmail: Value(_trimOrNull(student.guardianEmail)),
            guardianPhone: Value(_trimOrNull(student.guardianPhone)),
            createdAt: now,
            updatedAt: now,
          ),
        );
    return student.copyWith(
      id: id,
      name: student.name.trim(),
      email: _trimOrNull(student.email),
      phone: _trimOrNull(student.phone),
      guardianName: _trimOrNull(student.guardianName),
      guardianEmail: _trimOrNull(student.guardianEmail),
      guardianPhone: _trimOrNull(student.guardianPhone),
      createdAt: now,
      updatedAt: now,
    );
  }

  Future<void> updateStudent(Student student) async {
    await (_db.update(_db.studentsTable)..where((t) => t.id.equals(student.id)))
        .write(
      StudentsTableCompanion(
        name: Value(student.name),
        email: Value(_trimOrNull(student.email)),
        phone: Value(_trimOrNull(student.phone)),
        guardianName: Value(_trimOrNull(student.guardianName)),
        guardianEmail: Value(_trimOrNull(student.guardianEmail)),
        guardianPhone: Value(_trimOrNull(student.guardianPhone)),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> deleteStudent(String id) async {
    await (_db.delete(_db.studentsTable)..where((t) => t.id.equals(id))).go();
  }

  String? _trimOrNull(String? v) =>
      v == null || v.trim().isEmpty ? null : v.trim();

  ClassGroup _toGroup(ClassGroupsTableData row) {
    return ClassGroup(
      id: row.id,
      name: row.name,
      description: row.description,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
    );
  }

  Student _toStudent(StudentsTableData row) {
    return Student(
      id: row.id,
      groupId: row.groupId,
      name: row.name,
      email: row.email,
      phone: row.phone,
      guardianName: row.guardianName,
      guardianEmail: row.guardianEmail,
      guardianPhone: row.guardianPhone,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
    );
  }
}

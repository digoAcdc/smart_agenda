import '../../domain/entities/class_group.dart';
import '../../domain/entities/student.dart';
import '../../domain/repositories/i_class_group_repository.dart';
import '../../domain/repositories/i_sync_service.dart';
import '../datasources/class_group_local_datasource.dart';

class ClassGroupRepositoryImpl implements IClassGroupRepository {
  ClassGroupRepositoryImpl(this._dataSource, this._syncService);

  final ClassGroupLocalDataSource _dataSource;
  final ISyncService _syncService;

  void _scheduleSync() => _syncService.syncNow();

  @override
  Future<List<ClassGroup>> getGroups() => _dataSource.getGroups();

  @override
  Future<ClassGroup?> getGroupById(String id) => _dataSource.getGroupById(id);

  @override
  Future<ClassGroup> createGroup(String name, {String? description}) async {
    final group = await _dataSource.createGroup(name, description: description);
    _scheduleSync();
    return group;
  }

  @override
  Future<void> updateGroup(ClassGroup group) async {
    await _dataSource.updateGroup(group);
    _scheduleSync();
  }

  @override
  Future<void> deleteGroup(String id) async {
    await _dataSource.deleteGroup(id);
    _scheduleSync();
  }

  @override
  Future<List<Student>> getStudentsByGroup(String groupId) =>
      _dataSource.getStudentsByGroup(groupId);

  @override
  Future<Student?> getStudentById(String id) => _dataSource.getStudentById(id);

  @override
  Future<Student> createStudent(Student student) async {
    final created = await _dataSource.createStudent(student);
    _scheduleSync();
    return created;
  }

  @override
  Future<void> updateStudent(Student student) async {
    await _dataSource.updateStudent(student);
    _scheduleSync();
  }

  @override
  Future<void> deleteStudent(String id) async {
    await _dataSource.deleteStudent(id);
    _scheduleSync();
  }
}

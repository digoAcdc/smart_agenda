import '../entities/class_group.dart';
import '../entities/student.dart';

abstract class IClassGroupRepository {
  Future<List<ClassGroup>> getGroups();
  Future<ClassGroup?> getGroupById(String id);
  Future<ClassGroup> createGroup(String name, {String? description});
  Future<void> updateGroup(ClassGroup group);
  Future<void> deleteGroup(String id);

  Future<List<Student>> getStudentsByGroup(String groupId);
  Future<Student?> getStudentById(String id);
  Future<Student> createStudent(Student student);
  Future<void> updateStudent(Student student);
  Future<void> deleteStudent(String id);
}

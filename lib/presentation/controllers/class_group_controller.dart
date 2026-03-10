import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import '../../domain/entities/class_group.dart';
import '../../domain/entities/student.dart';
import '../../domain/repositories/i_class_group_repository.dart';

class ClassGroupController extends GetxController {
  ClassGroupController(this._repository);

  final IClassGroupRepository _repository;

  final RxList<ClassGroup> groups = <ClassGroup>[].obs;
  final RxList<Student> students = <Student>[].obs;
  final RxBool loading = false.obs;
  final Rxn<ClassGroup> selectedGroup = Rxn<ClassGroup>();

  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addPostFrameCallback((_) => loadGroups());
  }

  Future<void> loadGroups() async {
    loading.value = true;
    try {
      groups.assignAll(await _repository.getGroups());
    } finally {
      loading.value = false;
    }
  }

  Future<void> loadStudents(String groupId) async {
    loading.value = true;
    try {
      students.assignAll(await _repository.getStudentsByGroup(groupId));
    } finally {
      loading.value = false;
    }
  }

  void setSelectedGroup(ClassGroup? group) {
    selectedGroup.value = group;
  }

  Future<ClassGroup> createGroup(String name, {String? description}) async {
    final group = await _repository.createGroup(name, description: description);
    await loadGroups();
    return group;
  }

  Future<void> updateGroup(ClassGroup group) async {
    await _repository.updateGroup(group);
    await loadGroups();
    if (selectedGroup.value?.id == group.id) {
      selectedGroup.value = group;
    }
  }

  Future<void> deleteGroup(String id) async {
    await _repository.deleteGroup(id);
    if (selectedGroup.value?.id == id) {
      selectedGroup.value = null;
      students.clear();
    }
    await loadGroups();
  }

  Future<Student> createStudent(Student student) async {
    final created = await _repository.createStudent(student);
    await loadStudents(student.groupId);
    return created;
  }

  Future<void> updateStudent(Student student) async {
    await _repository.updateStudent(student);
    await loadStudents(student.groupId);
  }

  Future<void> deleteStudent(Student student) async {
    await _repository.deleteStudent(student.id);
    await loadStudents(student.groupId);
  }
}

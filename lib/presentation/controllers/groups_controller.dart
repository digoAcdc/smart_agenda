import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:uuid/uuid.dart';

import '../../domain/entities/agenda_group.dart';
import '../../domain/usecases/group_usecases.dart';

class GroupsController extends GetxController {
  GroupsController({
    required this.createGroupUseCase,
    required this.updateGroupUseCase,
    required this.deleteGroupUseCase,
    required this.getGroupsUseCase,
  });

  final CreateGroup createGroupUseCase;
  final UpdateGroup updateGroupUseCase;
  final DeleteGroup deleteGroupUseCase;
  final GetGroups getGroupsUseCase;

  final RxList<AgendaGroup> groups = <AgendaGroup>[].obs;
  final RxBool loading = false.obs;

  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addPostFrameCallback((_) => loadGroups());
  }

  Future<void> loadGroups() async {
    loading.value = true;
    final result = await getGroupsUseCase();
    if (result.isSuccess) {
      groups.assignAll(result.data ?? []);
    }
    loading.value = false;
  }

  Future<String?> create(String name, {String? colorHex}) async {
    final now = DateTime.now();
    final id = const Uuid().v4();
    final result = await createGroupUseCase(
      AgendaGroup(
        id: id,
        name: name,
        colorHex: colorHex,
        createdAt: now,
        updatedAt: now,
      ),
    );
    await loadGroups();
    return result.isSuccess ? id : null;
  }

  Future<void> updateGroup(AgendaGroup group, String name,
      {String? colorHex}) async {
    await updateGroupUseCase(
      group.copyWith(name: name, colorHex: colorHex, updatedAt: DateTime.now()),
    );
    await loadGroups();
  }

  Future<void> delete(String id) async {
    await deleteGroupUseCase(id);
    await loadGroups();
  }
}

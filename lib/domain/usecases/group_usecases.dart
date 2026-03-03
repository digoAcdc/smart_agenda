import '../../core/result/result.dart';
import '../entities/agenda_group.dart';
import '../repositories/i_groups_repository.dart';

class CreateGroup {
  const CreateGroup(this._repository);
  final IGroupsRepository _repository;

  Future<Result<void>> call(AgendaGroup group) =>
      _repository.createGroup(group);
}

class UpdateGroup {
  const UpdateGroup(this._repository);
  final IGroupsRepository _repository;

  Future<Result<void>> call(AgendaGroup group) =>
      _repository.updateGroup(group);
}

class DeleteGroup {
  const DeleteGroup(this._repository);
  final IGroupsRepository _repository;

  Future<Result<void>> call(String groupId) =>
      _repository.deleteGroupSoft(groupId);
}

class GetGroups {
  const GetGroups(this._repository);
  final IGroupsRepository _repository;

  Future<Result<List<AgendaGroup>>> call() => _repository.getGroups();
}

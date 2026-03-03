import '../../core/result/result.dart';
import '../../domain/entities/agenda_group.dart';
import '../../domain/repositories/i_groups_repository.dart';
import '../datasources/groups_local_datasource.dart';
import '../models/mappers.dart';

class GroupsRepositoryImpl implements IGroupsRepository {
  const GroupsRepositoryImpl(this._local);
  final GroupsLocalDataSource _local;

  @override
  Future<Result<void>> createGroup(AgendaGroup group) async {
    try {
      await _local.create(groupToCompanion(group));
      return Result.success(null);
    } catch (e) {
      return Result.failure('Erro ao criar grupo: $e');
    }
  }

  @override
  Future<Result<void>> deleteGroupSoft(String groupId) async {
    try {
      await _local.deleteSoft(groupId, DateTime.now());
      return Result.success(null);
    } catch (e) {
      return Result.failure('Erro ao remover grupo: $e');
    }
  }

  @override
  Future<Result<List<AgendaGroup>>> getGroups() async {
    try {
      final groups = await _local.getAll();
      return Result.success(groups.map(groupFromDb).toList());
    } catch (e) {
      return Result.failure('Erro ao listar grupos: $e');
    }
  }

  @override
  Future<Result<void>> updateGroup(AgendaGroup group) async {
    try {
      await _local.update(groupToCompanion(group));
      return Result.success(null);
    } catch (e) {
      return Result.failure('Erro ao atualizar grupo: $e');
    }
  }
}

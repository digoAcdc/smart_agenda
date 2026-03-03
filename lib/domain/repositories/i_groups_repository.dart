import '../../core/result/result.dart';
import '../entities/agenda_group.dart';

abstract class IGroupsRepository {
  Future<Result<void>> createGroup(AgendaGroup group);
  Future<Result<void>> updateGroup(AgendaGroup group);
  Future<Result<void>> deleteGroupSoft(String groupId);
  Future<Result<List<AgendaGroup>>> getGroups();
}

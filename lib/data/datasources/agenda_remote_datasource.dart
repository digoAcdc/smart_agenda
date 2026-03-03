import '../../core/result/result.dart';
import '../../domain/entities/agenda_item.dart';

abstract class IAgendaRemoteDataSource {
  Future<Result<void>> pushItem(AgendaItem item);
  Future<Result<List<AgendaItem>>> fetchChanges(DateTime since);
}

class AgendaRemoteDataSourceStub implements IAgendaRemoteDataSource {
  @override
  Future<Result<List<AgendaItem>>> fetchChanges(DateTime since) async {
    return Result.success(const []);
  }

  @override
  Future<Result<void>> pushItem(AgendaItem item) async {
    return Result.success(null);
  }
}

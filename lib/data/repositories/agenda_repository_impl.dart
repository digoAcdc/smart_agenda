import '../../core/result/result.dart';
import '../../core/utils/date_utils.dart';
import '../../domain/entities/agenda_enums.dart';
import '../../domain/entities/agenda_item.dart';
import '../../domain/repositories/i_agenda_repository.dart';
import '../../domain/value_objects/search_filters.dart';
import '../datasources/agenda_local_datasource.dart';
import '../datasources/agenda_remote_datasource.dart';
import '../models/mappers.dart';

class AgendaRepositoryImpl implements IAgendaRepository {
  const AgendaRepositoryImpl(this._local, this._remote);

  final AgendaLocalDataSource _local;
  final IAgendaRemoteDataSource _remote;

  @override
  Future<Result<void>> createItem(AgendaItem item) async {
    try {
      await _local.createItem(
        agendaItemToCompanion(item),
        item.attachments.map(attachmentToCompanion).toList(),
      );
      await _remote.pushItem(item);
      return Result.success(null);
    } catch (e) {
      return Result.failure('Erro ao criar item: $e');
    }
  }

  @override
  Future<Result<void>> deleteItemSoft(String itemId) async {
    try {
      await _local.deleteItemSoft(itemId, DateTime.now());
      return Result.success(null);
    } catch (e) {
      return Result.failure('Erro ao remover item: $e');
    }
  }

  @override
  Future<Result<AgendaItem?>> getItemById(String itemId) async {
    try {
      final data = await _local.getById(itemId);
      if (data == null) return Result.success(null);
      return Result.success(itemFromDb(data.item, data.attachments));
    } catch (e) {
      return Result.failure('Erro ao buscar item: $e');
    }
  }

  @override
  Future<Result<List<AgendaItem>>> getItemsByDay(DateTime date) async {
    final start = DateUtilsEx.startOfDay(date);
    final end = DateUtilsEx.endOfDay(date);
    return getItemsByRange(start, end);
  }

  @override
  Future<Result<List<AgendaItem>>> getItemsByRange(
      DateTime start, DateTime end) async {
    try {
      final list = await _local.getByRange(start, end);
      return Result.success(
        list.map((e) => itemFromDb(e.item, e.attachments)).toList(),
      );
    } catch (e) {
      return Result.failure('Erro ao listar itens: $e');
    }
  }

  @override
  Future<Result<Set<DateTime>>> getMarkersByRange(
      DateTime start, DateTime end) async {
    final result = await getItemsByRange(start, end);
    if (!result.isSuccess) {
      return Result.failure(
          result.errorMessage ?? 'Falha ao carregar marcadores');
    }
    final markers =
        result.data!.map((e) => DateUtilsEx.startOfDay(e.startAt)).toSet();
    return Result.success(markers);
  }

  @override
  Future<Result<List<AgendaItem>>> searchItems(
    String query,
    SearchFilters filters,
  ) async {
    try {
      DateTime? start;
      DateTime? end;
      final now = DateTime.now();
      switch (filters.dateRange) {
        case SearchDateRangeFilter.all:
          break;
        case SearchDateRangeFilter.today:
          start = DateUtilsEx.startOfDay(now);
          end = DateUtilsEx.endOfDay(now);
          break;
        case SearchDateRangeFilter.next7Days:
          start = DateUtilsEx.startOfDay(now);
          end = DateUtilsEx.endOfDay(now.add(const Duration(days: 7)));
          break;
        case SearchDateRangeFilter.thisMonth:
          start = DateUtilsEx.startOfMonth(now);
          end = DateUtilsEx.endOfMonth(now);
          break;
      }
      final list = await _local.search(
        query,
        start: start,
        end: end,
        groupId: filters.groupId,
        status: filters.status?.name,
      );
      return Result.success(
        list.map((e) => itemFromDb(e.item, e.attachments)).toList(),
      );
    } catch (e) {
      return Result.failure('Erro na busca: $e');
    }
  }

  @override
  Future<Result<void>> setStatus(String itemId, AgendaStatus status) async {
    try {
      await _local.setStatus(itemId, status.name, DateTime.now());
      return Result.success(null);
    } catch (e) {
      return Result.failure('Erro ao atualizar status: $e');
    }
  }

  @override
  Future<Result<void>> updateItem(AgendaItem item) async {
    try {
      await _local.updateItem(
        agendaItemToCompanion(item),
        item.attachments.map(attachmentToCompanion).toList(),
      );
      await _remote.pushItem(item);
      return Result.success(null);
    } catch (e) {
      return Result.failure('Erro ao atualizar item: $e');
    }
  }
}

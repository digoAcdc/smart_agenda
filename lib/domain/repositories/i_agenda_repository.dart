import '../../core/result/result.dart';
import '../entities/agenda_enums.dart';
import '../entities/agenda_item.dart';
import '../value_objects/search_filters.dart';

abstract class IAgendaRepository {
  Future<Result<void>> createItem(AgendaItem item);
  Future<Result<void>> updateItem(AgendaItem item);
  Future<Result<void>> deleteItemSoft(String itemId);
  Future<Result<AgendaItem?>> getItemById(String itemId);
  Future<Result<List<AgendaItem>>> getItemsByDay(DateTime date);
  Future<Result<List<AgendaItem>>> getItemsByRange(
      DateTime start, DateTime end);
  Future<Result<Set<DateTime>>> getMarkersByRange(DateTime start, DateTime end);
  Future<Result<List<AgendaItem>>> searchItems(
      String query, SearchFilters filters);
  Future<Result<void>> setStatus(String itemId, AgendaStatus status);
}

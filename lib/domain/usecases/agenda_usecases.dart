import '../../core/result/result.dart';
import '../entities/agenda_enums.dart';
import '../entities/agenda_item.dart';
import '../repositories/i_agenda_repository.dart';
import '../value_objects/search_filters.dart';

class CreateAgendaItem {
  const CreateAgendaItem(this._repository);
  final IAgendaRepository _repository;

  Future<Result<void>> call(AgendaItem item) => _repository.createItem(item);
}

class UpdateAgendaItem {
  const UpdateAgendaItem(this._repository);
  final IAgendaRepository _repository;

  Future<Result<void>> call(AgendaItem item) => _repository.updateItem(item);
}

class DeleteAgendaItem {
  const DeleteAgendaItem(this._repository);
  final IAgendaRepository _repository;

  Future<Result<void>> call(String itemId) =>
      _repository.deleteItemSoft(itemId);
}

class DuplicateAgendaItem {
  const DuplicateAgendaItem(this._repository, this._newId);
  final IAgendaRepository _repository;
  final String Function() _newId;

  Future<Result<void>> call(String itemId) async {
    final currentResult = await _repository.getItemById(itemId);
    if (!currentResult.isSuccess) {
      return Result.failure(
        currentResult.errorMessage ?? 'Falha ao duplicar item',
      );
    }
    final current = currentResult.data;
    if (current == null) {
      return Result.failure('Item não encontrado para duplicação');
    }

    final now = DateTime.now();
    final duplicated = current.copyWith(
      id: _newId(),
      createdAt: now,
      updatedAt: now,
      deletedAt: null,
      syncState: SyncState.pending,
      source: ItemSource.local,
    );
    return _repository.createItem(duplicated);
  }
}

class SetAgendaStatus {
  const SetAgendaStatus(this._repository);
  final IAgendaRepository _repository;

  Future<Result<void>> call(String itemId, AgendaStatus status) =>
      _repository.setStatus(itemId, status);

  /// Evento que se repete: so a ocorrencia do dia.
  Future<Result<void>> occurrenceDone(String itemId, DateTime day, bool done) =>
      _repository.setOccurrenceDone(itemId, day, done);

  Future<Result<void>> removeOccurrence(String itemId, DateTime day) =>
      _repository.removeOccurrence(itemId, day);
}

class GetAgendaItemsByDay {
  const GetAgendaItemsByDay(this._repository);
  final IAgendaRepository _repository;

  Future<Result<List<AgendaItem>>> call(DateTime date) =>
      _repository.getItemsByDay(date);
}

class GetAgendaItemsByRange {
  const GetAgendaItemsByRange(this._repository);
  final IAgendaRepository _repository;

  Future<Result<List<AgendaItem>>> call(DateTime start, DateTime end) =>
      _repository.getItemsByRange(start, end);
}

class GetAgendaMarkersByRange {
  const GetAgendaMarkersByRange(this._repository);
  final IAgendaRepository _repository;

  Future<Result<Set<DateTime>>> call(DateTime start, DateTime end) =>
      _repository.getMarkersByRange(start, end);
}

class SearchAgendaItems {
  const SearchAgendaItems(this._repository);
  final IAgendaRepository _repository;

  Future<Result<List<AgendaItem>>> call(String query, SearchFilters filters) =>
      _repository.searchItems(query, filters);
}

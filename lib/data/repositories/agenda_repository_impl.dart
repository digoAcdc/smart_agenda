import '../../core/result/result.dart';
import '../../core/utils/date_utils.dart';
import '../../domain/entities/agenda_enums.dart';
import '../../domain/entities/agenda_item.dart';
import '../../domain/repositories/i_agenda_repository.dart';
import '../../domain/repositories/i_family_service.dart';
import '../../domain/repositories/i_sync_service.dart';
import '../../domain/value_objects/search_filters.dart';
import '../datasources/agenda_local_datasource.dart';
import '../models/mappers.dart';

/// A UI le sempre do banco local (agenda pessoal + cache da Familia).
/// Gravacoes vao para o local e a sincronizacao envia para a nuvem.
class AgendaRepositoryImpl implements IAgendaRepository {
  AgendaRepositoryImpl(
    this._local,
    this._syncService,
    this._familyService,
    this._currentUserId,
  );

  final AgendaLocalDataSource _local;
  final ISyncService _syncService;
  final IFamilyService _familyService;
  final String? Function() _currentUserId;

  void _scheduleSync() => _syncService.syncNow();

  /// Itens da Familia so podem ser alterados por admin/editor de Familia ativa.
  String? _denyFamilyWrite(String? familyId) {
    if (familyId == null) return null;
    final ctx = _familyService.context;
    if (ctx.familyId != familyId) {
      return 'Este item não pertence à sua Família.';
    }
    if (!ctx.isActive) {
      return 'A assinatura Pro da Família não está ativa. A agenda está disponível só para consulta.';
    }
    if (!ctx.canEditAgenda) {
      return 'Seu acesso à Família é de visualização.';
    }
    return null;
  }

  @override
  Future<Result<void>> createItem(AgendaItem item) async {
    final denied = _denyFamilyWrite(item.familyId);
    if (denied != null) return Result.failure(denied);
    try {
      final uid = _currentUserId();
      await _local.createItem(
        agendaItemToCompanion(item.copyWith(createdBy: uid, updatedBy: uid)),
        item.attachments.map(attachmentToCompanion).toList(),
      );
      _scheduleSync();
      return Result.success(null);
    } catch (e) {
      return Result.failure('Erro ao criar item: $e');
    }
  }

  @override
  Future<Result<void>> updateItem(AgendaItem item) async {
    try {
      final existing = await _local.getById(item.id);
      final familyId = existing?.item.familyId ?? item.familyId;
      final denied = _denyFamilyWrite(familyId);
      if (denied != null) return Result.failure(denied);

      await _local.updateItem(
        agendaItemToCompanion(
          item.copyWith(familyId: familyId, updatedBy: _currentUserId()),
        ),
        item.attachments.map(attachmentToCompanion).toList(),
      );
      _scheduleSync();
      return Result.success(null);
    } catch (e) {
      return Result.failure('Erro ao atualizar item: $e');
    }
  }

  @override
  Future<Result<void>> deleteItemSoft(String itemId) async {
    try {
      final existing = await _local.getById(itemId);
      if (existing == null) return Result.failure('Item não encontrado.');
      final denied = _denyFamilyWrite(existing.item.familyId);
      if (denied != null) return Result.failure(denied);

      await _local.deleteItemSoft(itemId, DateTime.now());
      _scheduleSync();
      return Result.success(null);
    } catch (e) {
      return Result.failure('Erro ao remover item: $e');
    }
  }

  @override
  Future<Result<void>> setStatus(String itemId, AgendaStatus status) async {
    try {
      final existing = await _local.getById(itemId);
      if (existing == null) return Result.failure('Item não encontrado.');
      final denied = _denyFamilyWrite(existing.item.familyId);
      if (denied != null) return Result.failure(denied);

      await _local.setStatus(itemId, status.name, DateTime.now());
      _scheduleSync();
      return Result.success(null);
    } catch (e) {
      return Result.failure('Erro ao atualizar status: $e');
    }
  }

  @override
  Future<Result<AgendaItem?>> getItemById(String itemId) async {
    try {
      final data = await _local.getById(itemId);
      return Result.success(
        data == null ? null : itemFromDb(data.item, data.attachments),
      );
    } catch (e) {
      return Result.failure('Erro ao buscar item: $e');
    }
  }

  @override
  Future<Result<List<AgendaItem>>> getItemsByDay(DateTime date) {
    return getItemsByRange(
      DateUtilsEx.startOfDay(date),
      DateUtilsEx.endOfDay(date),
    );
  }

  @override
  Future<Result<List<AgendaItem>>> getItemsByRange(
    DateTime start,
    DateTime end,
  ) async {
    try {
      final rows = await _local.getByRange(start, end);
      return Result.success(
        rows.map((e) => itemFromDb(e.item, e.attachments)).toList(),
      );
    } catch (e) {
      return Result.failure('Erro ao listar itens: $e');
    }
  }

  @override
  Future<Result<Set<DateTime>>> getMarkersByRange(
    DateTime start,
    DateTime end,
  ) async {
    final result = await getItemsByRange(start, end);
    if (!result.isSuccess) {
      return Result.failure(
        result.errorMessage ?? 'Falha ao carregar marcadores',
      );
    }
    final markers = result.data!
        .map((e) => DateUtilsEx.startOfDay(e.startAt))
        .toSet();
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
      final rows = await _local.search(
        query,
        start: start,
        end: end,
        groupId: filters.groupId,
        status: filters.status?.name,
      );
      return Result.success(
        rows.map((e) => itemFromDb(e.item, e.attachments)).toList(),
      );
    } catch (e) {
      return Result.failure('Erro na busca: $e');
    }
  }
}

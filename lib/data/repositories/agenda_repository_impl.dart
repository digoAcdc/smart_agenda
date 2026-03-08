import '../../core/result/result.dart';
import '../../core/utils/date_utils.dart';
import '../../domain/entities/agenda_enums.dart';
import '../../domain/entities/agenda_item.dart';
import '../../domain/repositories/i_agenda_repository.dart';
import '../../domain/repositories/i_sharing_service.dart';
import '../../domain/repositories/i_sync_service.dart';
import '../../domain/value_objects/search_filters.dart';
import '../datasources/agenda_local_datasource.dart';
import '../datasources/agenda_supabase_datasource.dart';
import '../models/mappers.dart';

class AgendaRepositoryImpl implements IAgendaRepository {
  AgendaRepositoryImpl(
    this._local,
    this._syncService,
    this._supabase,
    this._sharingService,
  );

  final AgendaLocalDataSource _local;
  final ISyncService _syncService;
  final AgendaSupabaseDataSource? _supabase;
  final ISharingService _sharingService;

  void _scheduleSync() => _syncService.syncNow();

  @override
  Future<Result<void>> createItem(AgendaItem item) async {
    try {
      await _local.createItem(
        agendaItemToCompanion(item),
        item.attachments.map(attachmentToCompanion).toList(),
      );
      _scheduleSync();
      return Result.success(null);
    } catch (e) {
      return Result.failure('Erro ao criar item: $e');
    }
  }

  @override
  Future<Result<void>> deleteItemSoft(String itemId) async {
    try {
      if (await _isSharedItem(itemId)) {
        return Result.failure('Itens compartilhados sao somente leitura.');
      }
      final item = await _local.getById(itemId);
      if (item == null) {
        return Result.failure('Item nao encontrado.');
      }
      await _local.deleteItemSoft(itemId, DateTime.now());
      _scheduleSync();
      return Result.success(null);
    } catch (e) {
      return Result.failure('Erro ao remover item: $e');
    }
  }

  @override
  Future<Result<AgendaItem?>> getItemById(String itemId) async {
    try {
      final data = await _local.getById(itemId);
      if (data != null) {
        return Result.success(itemFromDb(data.item, data.attachments));
      }
      if (_supabase != null) {
        final ownItem = await _supabase.getById(itemId);
        if (ownItem != null) return Result.success(ownItem);
        final sharesResult = await _sharingService.getSharesWithMe();
        if (sharesResult.isSuccess && sharesResult.data!.isNotEmpty) {
          final ownerMap = {
            for (final s in sharesResult.data!) s.ownerId: s.ownerEmail
          };
          final shared = await _supabase.getSharedById(itemId, ownerMap);
          if (shared != null) return Result.success(shared);
        }
      }
      return Result.success(null);
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
      final localList = await _local.getByRange(start, end);
      var items = localList
          .map((e) => itemFromDb(e.item, e.attachments))
          .toList();
      final localIds = items.map((e) => e.id).toSet();

      if (_supabase != null) {
        final supabaseOwnList =
            await _supabase.getByRange(start, end);
        for (final item in supabaseOwnList) {
          if (!localIds.contains(item.id)) {
            items.add(item);
            localIds.add(item.id);
          }
        }
        final sharesResult = await _sharingService.getSharesWithMe();
        if (sharesResult.isSuccess && sharesResult.data!.isNotEmpty) {
          final ownerMap = {
            for (final s in sharesResult.data!) s.ownerId: s.ownerEmail
          };
          final sharedList =
              await _supabase.getSharedByRange(start, end, ownerMap);
          items = [...items, ...sharedList]
            ..sort((a, b) => a.startAt.compareTo(b.startAt));
        } else {
          items.sort((a, b) => a.startAt.compareTo(b.startAt));
        }
      }
      return Result.success(items);
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
      final localList = await _local.search(
        query,
        start: start,
        end: end,
        groupId: filters.groupId,
        status: filters.status?.name,
      );
      var items = localList
          .map((e) => itemFromDb(e.item, e.attachments))
          .toList();
      final localIds = items.map((e) => e.id).toSet();

      if (_supabase != null) {
        final supabaseOwnList = await _supabase.search(
          query,
          start: start,
          end: end,
          groupId: filters.groupId,
          status: filters.status?.name,
        );
        for (final item in supabaseOwnList) {
          if (!localIds.contains(item.id)) {
            items.add(item);
            localIds.add(item.id);
          }
        }
        final sharesResult = await _sharingService.getSharesWithMe();
        if (sharesResult.isSuccess && sharesResult.data!.isNotEmpty) {
          final ownerMap = {
            for (final s in sharesResult.data!) s.ownerId: s.ownerEmail
          };
          final sharedList = await _supabase.searchShared(
            query,
            start: start,
            end: end,
            groupId: filters.groupId,
            status: filters.status?.name,
            ownerIdToEmail: ownerMap,
          );
          items = [...items, ...sharedList];
        }
        items.sort((a, b) => a.startAt.compareTo(b.startAt));
      }
      return Result.success(items);
    } catch (e) {
      return Result.failure('Erro na busca: $e');
    }
  }

  @override
  Future<Result<void>> setStatus(String itemId, AgendaStatus status) async {
    try {
      if (await _isSharedItem(itemId)) {
        return Result.failure('Itens compartilhados sao somente leitura.');
      }
      await _local.setStatus(itemId, status.name, DateTime.now());
      _scheduleSync();
      return Result.success(null);
    } catch (e) {
      return Result.failure('Erro ao atualizar status: $e');
    }
  }

  @override
  Future<Result<void>> updateItem(AgendaItem item) async {
    try {
      if (item.ownerEmail != null) {
        return Result.failure('Itens compartilhados sao somente leitura.');
      }
      await _local.updateItem(
        agendaItemToCompanion(item),
        item.attachments.map(attachmentToCompanion).toList(),
      );
      _scheduleSync();
      return Result.success(null);
    } catch (e) {
      return Result.failure('Erro ao atualizar item: $e');
    }
  }

  Future<bool> _isSharedItem(String itemId) async {
    final local = await _local.getById(itemId);
    if (local != null) return false;
    if (_supabase == null) return false;
    final sharesResult = await _sharingService.getSharesWithMe();
    if (!sharesResult.isSuccess || sharesResult.data!.isEmpty) return false;
    final ownerMap = {
      for (final s in sharesResult.data!) s.ownerId: s.ownerEmail
    };
    final shared = await _supabase.getSharedById(itemId, ownerMap);
    return shared != null;
  }
}

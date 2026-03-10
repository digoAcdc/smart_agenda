import '../../core/result/result.dart';
import '../../domain/repositories/i_auth_service.dart';
import '../../domain/repositories/i_plan_service.dart';
import '../../domain/repositories/i_sharing_service.dart';
import '../datasources/agenda_sharing_supabase_datasource.dart';

/// Implementacao do SharingService (premium only).
class SharingServiceImpl implements ISharingService {
  SharingServiceImpl(this._planService, this._authService, this._ds);

  final IPlanService _planService;
  final IAuthService _authService;
  final AgendaSharingSupabaseDataSource _ds;

  @override
  Future<Result<void>> shareWith(String email) async {
    try {
      if (!await _planService.isPremium()) {
        return Result.failure('Compartilhamento disponivel apenas para premium.');
      }

      final authResult = await _authService.getCurrentUser();
      if (!authResult.isSuccess || authResult.data == null) {
        return Result.failure('Usuario nao autenticado.');
      }
      final user = authResult.data!;
      final ownerId = user.id;
      final ownerEmail = user.email;

      final normalized = email.trim().toLowerCase();
      if (normalized == ownerEmail.toLowerCase()) {
        return Result.failure('Nao e possivel compartilhar com voce mesmo.');
      }

      final sharedWithId = await _ds.getUserIdByEmail(normalized);
      if (sharedWithId == null) {
        return Result.failure('Usuario com este email nao encontrado.');
      }

      await _ds.createShare(
        ownerId: ownerId,
        sharedWithId: sharedWithId,
        ownerEmail: ownerEmail,
        sharedWithEmail: normalized,
      );
      return Result.success(null);
    } catch (e) {
      return Result.failure('Erro ao compartilhar: $e');
    }
  }

  @override
  Future<Result<void>> revokeShare(String sharedWithId) async {
    try {
      if (!await _planService.isPremium()) {
        return Result.failure('Compartilhamento disponivel apenas para premium.');
      }

      final rows = await _ds.getSharesByMe();
      final share = rows.where((s) => s.sharedWithId == sharedWithId).firstOrNull;
      if (share == null) {
        return Result.failure('Compartilhamento nao encontrado.');
      }

      await _ds.deleteShare(share.id);
      return Result.success(null);
    } catch (e) {
      return Result.failure('Erro ao revogar: $e');
    }
  }

  @override
  Future<Result<List<AgendaShare>>> getSharesByMe() async {
    try {
      if (!await _planService.isPremium()) {
        return Result.success([]);
      }
      final list = await _ds.getSharesByMe();
      return Result.success(list);
    } catch (e) {
      return Result.failure('Erro ao listar compartilhamentos: $e');
    }
  }

  @override
  Future<Result<List<AgendaShare>>> getSharesWithMe() async {
    try {
      final list = await _ds.getSharesWithMe();
      return Result.success(list);
    } catch (e) {
      return Result.failure('Erro ao listar compartilhamentos: $e');
    }
  }
}

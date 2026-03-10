import '../../core/result/result.dart';
import '../../domain/repositories/i_sharing_service.dart';

/// Stub quando Supabase nao esta configurado.
class SharingServiceStub implements ISharingService {
  @override
  Future<Result<void>> shareWith(String email) async =>
      Result.failure('Compartilhamento indisponivel.');

  @override
  Future<Result<void>> revokeShare(String sharedWithId) async =>
      Result.failure('Compartilhamento indisponivel.');

  @override
  Future<Result<List<AgendaShare>>> getSharesByMe() async =>
      Result.success([]);

  @override
  Future<Result<List<AgendaShare>>> getSharesWithMe() async =>
      Result.success([]);
}

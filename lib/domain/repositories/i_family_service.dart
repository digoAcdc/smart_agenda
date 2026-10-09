import '../../core/result/result.dart';
import '../entities/family.dart';

/// Familia do usuario logado: contexto (plano, papel, Familia ativa),
/// pessoas, filhos e convites. Os getters sao reativos na implementacao.
abstract class IFamilyService {
  FamilyContext get context;

  /// Usuario logado (nulo sem conta).
  String? get currentUserId;
  List<FamilyMember> get members;

  /// Filhos ativos (nao arquivados).
  List<FamilyChild> get children;
  List<FamilyChild> get allChildren;

  /// Convites pendentes da Familia (para administradores).
  List<FamilyInvite> get familyInvites;

  /// Convites recebidos pelo usuario.
  List<FamilyInvite> get myInvites;
  bool get loading;

  FamilyMember? memberById(String? userId);
  FamilyChild? childById(String? childId);

  /// Recarrega tudo do servidor. Sem conexao, mantem o ultimo cache.
  Future<Result<FamilyContext>> refresh();

  /// Limpa estado e cache (logout).
  Future<void> clear();

  Future<Result<void>> createFamily(String name, {String? nickname});
  Future<Result<void>> renameFamily(String name);
  Future<Result<void>> deleteFamily();
  Future<Result<void>> invite(String email, FamilyRole role);
  Future<Result<void>> revokeInvite(String inviteId);
  Future<Result<void>> acceptInvite(String inviteId, {String? nickname});
  Future<Result<void>> declineInvite(String inviteId);
  Future<Result<void>> changeRole(String userId, FamilyRole role);
  Future<Result<void>> removeMember(String userId);
  Future<Result<void>> leave();
  Future<Result<void>> updateMyNickname(String? nickname);
  Future<Result<void>> saveChild(FamilyChild child, {required bool isNew});
  Future<Result<void>> setChildArchived(String childId, bool archived);
}

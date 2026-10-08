import '../../core/result/result.dart';
import '../../domain/entities/family.dart';
import '../../domain/repositories/i_family_service.dart';

/// Sem nuvem configurada nao ha Familia.
class FamilyServiceStub implements IFamilyService {
  static final _unavailable = Result<void>.failure(
    'Recurso indisponível sem conexão com a nuvem.',
  );

  @override
  FamilyContext get context => FamilyContext.empty;
  @override
  List<FamilyMember> get members => const [];
  @override
  List<FamilyChild> get children => const [];
  @override
  List<FamilyChild> get allChildren => const [];
  @override
  List<FamilyInvite> get familyInvites => const [];
  @override
  List<FamilyInvite> get myInvites => const [];
  @override
  bool get loading => false;
  @override
  FamilyMember? memberById(String? userId) => null;
  @override
  FamilyChild? childById(String? childId) => null;
  @override
  Future<Result<FamilyContext>> refresh() async =>
      Result.success(FamilyContext.empty);
  @override
  Future<void> clear() async {}
  @override
  Future<Result<void>> createFamily(String name, {String? nickname}) async =>
      _unavailable;
  @override
  Future<Result<void>> renameFamily(String name) async => _unavailable;
  @override
  Future<Result<void>> deleteFamily() async => _unavailable;
  @override
  Future<Result<void>> invite(String email, FamilyRole role) async =>
      _unavailable;
  @override
  Future<Result<void>> revokeInvite(String inviteId) async => _unavailable;
  @override
  Future<Result<void>> acceptInvite(
    String inviteId, {
    String? nickname,
  }) async => _unavailable;
  @override
  Future<Result<void>> declineInvite(String inviteId) async => _unavailable;
  @override
  Future<Result<void>> changeRole(String userId, FamilyRole role) async =>
      _unavailable;
  @override
  Future<Result<void>> removeMember(String userId) async => _unavailable;
  @override
  Future<Result<void>> leave() async => _unavailable;
  @override
  Future<Result<void>> updateMyNickname(String? nickname) async => _unavailable;
  @override
  Future<Result<void>> saveChild(
    FamilyChild child, {
    required bool isNew,
  }) async => _unavailable;
  @override
  Future<Result<void>> setChildArchived(String childId, bool archived) async =>
      _unavailable;
}

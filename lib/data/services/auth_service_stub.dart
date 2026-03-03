import '../../core/result/result.dart';
import '../../domain/repositories/i_auth_service.dart';

class AuthServiceStub implements IAuthService {
  @override
  Future<Result<bool>> isLoggedIn() async => Result.success(false);

  @override
  Future<Result<void>> signInAnonymously() async => Result.success(null);

  @override
  Future<Result<void>> signOut() async => Result.success(null);
}

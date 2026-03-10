import '../../core/result/result.dart';
import '../../domain/entities/auth_user.dart';
import '../../domain/repositories/i_auth_service.dart';

class AuthServiceStub implements IAuthService {
  @override
  Future<Result<bool>> isLoggedIn() async => Result.success(false);

  @override
  Future<Result<AuthUser?>> getCurrentUser() async => Result.success(null);

  @override
  Future<Result<void>> signInWithEmail(String email, String password) async =>
      Result.success(null);

  @override
  Future<Result<void>> signUp(String email, String password) async =>
      Result.success(null);

  @override
  Future<Result<void>> resetPasswordForEmail(String email) async =>
      Result.success(null);

  @override
  Future<Result<void>> verifyRecoveryAndUpdatePassword(
    String email,
    String token,
    String newPassword,
  ) async =>
      Result.success(null);

  @override
  Future<Result<void>> signInAnonymously() async => Result.success(null);

  @override
  Future<Result<void>> signOut() async => Result.success(null);
}

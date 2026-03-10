import '../../core/result/result.dart';
import '../entities/auth_user.dart';

abstract class IAuthService {
  Future<Result<bool>> isLoggedIn();
  Future<Result<AuthUser?>> getCurrentUser();
  Future<Result<void>> signInWithEmail(String email, String password);
  Future<Result<void>> signUp(String email, String password);
  Future<Result<void>> resetPasswordForEmail(String email);
  Future<Result<void>> verifyRecoveryAndUpdatePassword(
    String email,
    String token,
    String newPassword,
  );
  Future<Result<void>> signInAnonymously();
  Future<Result<void>> signOut();
}

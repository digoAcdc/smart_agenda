import '../../core/result/result.dart';

abstract class IAuthService {
  Future<Result<bool>> isLoggedIn();
  Future<Result<void>> signInAnonymously();
  Future<Result<void>> signOut();
}

import '../../core/result/result.dart';

abstract class ISyncService {
  Future<Result<void>> syncNow();
}

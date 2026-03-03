import '../../core/result/result.dart';
import '../../domain/repositories/i_sync_service.dart';

class SyncServiceStub implements ISyncService {
  @override
  Future<Result<void>> syncNow() async => Result.success(null);
}

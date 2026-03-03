import '../../core/result/result.dart';
import '../../domain/repositories/i_ads_service.dart';

class AdsServiceStub implements IAdsService {
  @override
  Future<Result<void>> init() async => Result.success(null);

  @override
  Future<Result<void>> showBanner() async => Result.success(null);

  @override
  Future<Result<void>> showInterstitial() async => Result.success(null);
}

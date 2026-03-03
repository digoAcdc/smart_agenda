import '../../core/result/result.dart';

abstract class IAdsService {
  Future<Result<void>> init();
  Future<Result<void>> showBanner();
  Future<Result<void>> showInterstitial();
}

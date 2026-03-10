import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../../domain/repositories/i_ads_service.dart';

/// Stub do AdService para quando AdMob nao esta configurado.
class AdsServiceStub implements IAdsService {
  @override
  Future<void> initialize() async {}

  @override
  Future<BannerAd?> createAndLoadBanner() async => null;

  @override
  Future<bool> showRewardedAd() async => false;
}

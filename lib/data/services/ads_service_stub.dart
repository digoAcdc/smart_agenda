import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../../domain/repositories/i_ads_service.dart';

/// Plataformas sem AdMob (ex.: iOS ainda nao configurado, desktop).
class AdsServiceStub implements IAdsService {
  @override
  Future<bool> initialize() async => false;

  @override
  Future<BannerAd?> loadAnchoredBanner(int width) async => null;

  @override
  Future<NativeAd?> loadNative({required bool darkMode}) async => null;

  @override
  Future<bool> privacyOptionsRequired() async => false;

  @override
  Future<void> showPrivacyOptions() async {}
}

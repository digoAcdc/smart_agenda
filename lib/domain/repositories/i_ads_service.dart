import 'package:google_mobile_ads/google_mobile_ads.dart';

/// Servico de anuncios AdMob - banners e rewarded.
abstract class IAdsService {
  /// Inicializa o SDK do Mobile Ads.
  Future<void> initialize();

  /// Cria e carrega um novo BannerAd. Cada widget deve usar sua propria instancia.
  Future<BannerAd?> createAndLoadBanner();

  /// Exibe rewarded ad. Retorna true se usuario assistiu ate o fim.
  Future<bool> showRewardedAd();
}

import 'package:google_mobile_ads/google_mobile_ads.dart';

/// Anuncios (somente plano Free): consentimento, banner fixo e nativo.
abstract class IAdsService {
  /// Pede o consentimento quando a lei exige (UMP) e inicializa o SDK.
  /// Retorna se anuncios podem ser pedidos.
  Future<bool> initialize();

  /// Banner adaptativo ancorado na largura informada (pixels logicos).
  Future<BannerAd?> loadAnchoredBanner(int width);

  /// Anuncio nativo (modelo pequeno) para listas. Null se indisponivel.
  Future<NativeAd?> loadNative({required bool darkMode});

  /// Se o usuario precisa de um acesso as opcoes de privacidade (UMP).
  Future<bool> privacyOptionsRequired();

  Future<void> showPrivacyOptions();
}

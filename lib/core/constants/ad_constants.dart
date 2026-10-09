import 'package:flutter/foundation.dart';

/// Constantes para AdMob - IDs de anuncios e configuracao.
class AdConstants {
  AdConstants._();

  static const String bannerTestId = 'ca-app-pub-3940256099942544/9214589741';
  static const String nativeTestId = 'ca-app-pub-3940256099942544/2247696110';

  static const String bannerProdId = 'ca-app-pub-1515466936385187/6662778824';

  /// Bloco "Nativo avancado" criado no AdMob. Enquanto vazio, o anuncio
  /// nativo nao aparece em release (so com o ID de teste em debug).
  static const String nativeProdId = String.fromEnvironment('ADMOB_NATIVE_ID');

  /// Usar IDs de teste em debug, IDs de producao em release.
  static bool get useTestIds => kDebugMode;

  static String get bannerId => useTestIds ? bannerTestId : bannerProdId;
  static String get nativeId => useTestIds ? nativeTestId : nativeProdId;
  static bool get hasNativeId => nativeId.isNotEmpty;
}

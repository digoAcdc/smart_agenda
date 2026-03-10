import 'package:flutter/foundation.dart';

/// Constantes para AdMob - IDs de anuncios e configuracao.
class AdConstants {
  AdConstants._();

  static const String bannerTestId = 'ca-app-pub-3940256099942544/6300978111';
  static const String rewardedTestId = 'ca-app-pub-3940256099942544/5224354917';

  static const String bannerProdId = 'ca-app-pub-1515466936385187/6662778824';
  static const String rewardedProdId = 'ca-app-pub-1515466936385187/9516531664';

  /// Usar IDs de teste em debug, IDs de producao em release.
  static bool get useTestIds => kDebugMode;

  static String get bannerId => useTestIds ? bannerTestId : bannerProdId;
  static String get rewardedId => useTestIds ? rewardedTestId : rewardedProdId;
}

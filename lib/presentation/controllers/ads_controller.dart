import 'dart:async';

import 'package:get/get.dart';

import '../../domain/repositories/i_ads_service.dart';
import '../../domain/repositories/i_premium_service.dart';

/// Anuncios so para o plano Free: espera saber o plano, pede consentimento
/// (quando a lei exige) e so entao libera os widgets de anuncio.
/// Quem e Pro nunca ve o consentimento nem faz pedidos de anuncio.
class AdsController extends GetxController {
  AdsController(this._adsService, this._premium);

  final IAdsService _adsService;
  final IPremiumService _premium;

  /// SDK pronto e com consentimento para pedir anuncios.
  final RxBool isReady = false.obs;

  /// Mostrar a opcao "Privacidade dos anuncios" no Config (UMP).
  final RxBool privacyOptionsRequired = false.obs;

  StreamSubscription<void>? _planSub;
  bool _initializing = false;

  /// Mostrar anuncios agora (reativo em Obx): plano conhecido, Free e SDK pronto.
  bool get showAds =>
      isReady.value && _premium.isResolved && !_premium.isPremium;

  @override
  void onInit() {
    super.onInit();
    _planSub = _premium.changes.listen((_) => _maybeInitialize());
    _maybeInitialize();
  }

  @override
  void onClose() {
    _planSub?.cancel();
    super.onClose();
  }

  Future<void> _maybeInitialize() async {
    if (_initializing || isReady.value) return;
    if (!_premium.isResolved || _premium.isPremium) return;
    _initializing = true;
    try {
      isReady.value = await _adsService.initialize();
      if (isReady.value) {
        privacyOptionsRequired.value = await _adsService
            .privacyOptionsRequired();
      }
    } finally {
      _initializing = false;
    }
  }

  Future<void> showPrivacyOptions() => _adsService.showPrivacyOptions();
}

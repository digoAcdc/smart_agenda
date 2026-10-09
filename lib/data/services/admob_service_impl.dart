import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../../core/constants/ad_constants.dart';
import '../../domain/repositories/i_ads_service.dart';

/// Google Mobile Ads com consentimento (UMP) antes de inicializar o SDK.
class AdmobServiceImpl implements IAdsService {
  Future<bool>? _init;

  @override
  Future<bool> initialize() => _init ??= _initialize();

  Future<bool> _initialize() async {
    final consentDone = Completer<void>();
    ConsentInformation.instance.requestConsentInfoUpdate(
      ConsentRequestParameters(),
      () {
        // Mostra o formulario so onde a lei exige (ex.: Europa).
        ConsentForm.loadAndShowConsentFormIfRequired((error) {
          if (error != null) debugPrint('[Ads] consent form: ${error.message}');
          if (!consentDone.isCompleted) consentDone.complete();
        });
      },
      (error) {
        debugPrint('[Ads] consent info: ${error.message}');
        if (!consentDone.isCompleted) consentDone.complete();
      },
    );
    await consentDone.future;

    if (!await ConsentInformation.instance.canRequestAds()) {
      debugPrint('[Ads] sem consentimento para pedir anuncios');
      return false;
    }
    await MobileAds.instance.initialize();
    debugPrint('[Ads] SDK inicializado');
    return true;
  }

  @override
  Future<BannerAd?> loadAnchoredBanner(int width) async {
    final size = await AdSize.getCurrentOrientationAnchoredAdaptiveBannerAdSize(
      width,
    );
    if (size == null) return null;
    final completer = Completer<BannerAd?>();
    final banner = BannerAd(
      adUnitId: AdConstants.bannerId,
      size: size,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          if (!completer.isCompleted) completer.complete(ad as BannerAd);
        },
        onAdFailedToLoad: (ad, error) {
          debugPrint('[Ads] banner falhou: ${error.message}');
          ad.dispose();
          if (!completer.isCompleted) completer.complete(null);
        },
      ),
    );
    unawaited(banner.load());
    return completer.future;
  }

  @override
  Future<NativeAd?> loadNative({required bool darkMode}) async {
    if (!AdConstants.hasNativeId) return null;
    final completer = Completer<NativeAd?>();
    final ad = NativeAd(
      adUnitId: AdConstants.nativeId,
      request: const AdRequest(),
      nativeTemplateStyle: NativeTemplateStyle(
        templateType: TemplateType.small,
        cornerRadius: 16,
        mainBackgroundColor: darkMode ? const Color(0xFF1C1B22) : Colors.white,
      ),
      listener: NativeAdListener(
        onAdLoaded: (ad) {
          if (!completer.isCompleted) completer.complete(ad as NativeAd);
        },
        onAdFailedToLoad: (ad, error) {
          debugPrint('[Ads] nativo falhou: ${error.message}');
          ad.dispose();
          if (!completer.isCompleted) completer.complete(null);
        },
      ),
    );
    unawaited(ad.load());
    return completer.future;
  }

  @override
  Future<bool> privacyOptionsRequired() async =>
      await ConsentInformation.instance.getPrivacyOptionsRequirementStatus() ==
      PrivacyOptionsRequirementStatus.required;

  @override
  Future<void> showPrivacyOptions() async {
    await ConsentForm.showPrivacyOptionsForm((error) {
      if (error != null) debugPrint('[Ads] privacy options: ${error.message}');
    });
  }
}

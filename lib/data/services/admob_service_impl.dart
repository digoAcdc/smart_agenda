import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../../core/constants/ad_constants.dart';
import '../../domain/repositories/i_ads_service.dart';

/// Implementacao do AdService usando Google Mobile Ads.
class AdmobServiceImpl implements IAdsService {
  @override
  Future<void> initialize() async {
    await MobileAds.instance.initialize();
    debugPrint('[AdmobService] SDK inicializado');
    _loadRewardedAdPreload();
  }

  void _loadRewardedAdPreload() {
    RewardedAd.load(
      adUnitId: AdConstants.rewardedId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          debugPrint('[AdmobService] Rewarded ad preloaded');
          ad.dispose();
        },
        onAdFailedToLoad: (error) {
          debugPrint('[AdmobService] Rewarded ad preload failed: $error');
        },
      ),
    );
  }

  @override
  Future<BannerAd?> createAndLoadBanner() async {
    final completer = Completer<BannerAd?>();
    final banner = BannerAd(
      adUnitId: AdConstants.bannerId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          debugPrint('[AdmobService] Banner loaded');
          if (!completer.isCompleted) completer.complete(ad as BannerAd);
        },
        onAdFailedToLoad: (ad, error) {
          debugPrint('[AdmobService] Banner failed: $error');
          ad.dispose();
          if (!completer.isCompleted) completer.complete(null);
        },
      ),
    );
    unawaited(banner.load());
    return completer.future;
  }

  @override
  Future<bool> showRewardedAd() async {
    final completer = Completer<bool>();
    var userEarnedReward = false;

    RewardedAd.load(
      adUnitId: AdConstants.rewardedId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              if (!completer.isCompleted) {
                completer.complete(userEarnedReward);
              }
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              debugPrint('[AdmobService] Rewarded show failed: $error');
              ad.dispose();
              if (!completer.isCompleted) {
                completer.complete(false);
              }
            },
          );
          ad.show(
            onUserEarnedReward: (ad, reward) {
              userEarnedReward = true;
            },
          );
        },
        onAdFailedToLoad: (error) {
          debugPrint('[AdmobService] Rewarded load failed: $error');
          if (!completer.isCompleted) {
            completer.complete(false);
          }
        },
      ),
    );

    return completer.future;
  }
}

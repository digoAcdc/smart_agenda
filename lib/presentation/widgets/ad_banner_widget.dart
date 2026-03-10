import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../../domain/repositories/i_ads_service.dart';
import '../../domain/repositories/i_premium_service.dart';

/// Widget que exibe banner AdMob apenas para usuarios free.
/// Cada instancia cria e possui seu proprio BannerAd (evita erro "already in Widget tree").
class AdBannerWidget extends StatefulWidget {
  const AdBannerWidget({
    super.key,
    this.premiumService,
    this.adsService,
  });

  final IPremiumService? premiumService;
  final IAdsService? adsService;

  @override
  State<AdBannerWidget> createState() => _AdBannerWidgetState();
}

class _AdBannerWidgetState extends State<AdBannerWidget> {
  IPremiumService get _premiumService =>
      widget.premiumService ?? Get.find<IPremiumService>();
  IAdsService get _adsService =>
      widget.adsService ?? Get.find<IAdsService>();

  BannerAd? _bannerAd;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    if (!_premiumService.isPremium) {
      _loadBanner();
    } else {
      _loading = false;
    }
  }

  Future<void> _loadBanner() async {
    final banner = await _adsService.createAndLoadBanner();
    if (!mounted) {
      banner?.dispose();
      return;
    }
    setState(() {
      _bannerAd = banner;
      _loading = false;
    });
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    _bannerAd = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (_premiumService.isPremium) {
        return const SizedBox.shrink();
      }

      if (_loading || _bannerAd == null) {
        return const SizedBox.shrink();
      }

      final banner = _bannerAd!;
      return SizedBox(
        width: banner.size.width.toDouble(),
        height: banner.size.height.toDouble(),
        child: AdWidget(ad: banner),
      );
    });
  }
}

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../../domain/repositories/i_ads_service.dart';
import '../controllers/ads_controller.dart';

/// Banner adaptativo fixo no rodape (plano Free). Uma unica instancia na Home:
/// nao recarrega ao rolar o conteudo e some quando a pessoa vira Pro.
class AnchoredAdBanner extends StatefulWidget {
  const AnchoredAdBanner({super.key});

  @override
  State<AnchoredAdBanner> createState() => _AnchoredAdBannerState();
}

class _AnchoredAdBannerState extends State<AnchoredAdBanner> {
  BannerAd? _banner;
  bool _loading = false;
  int? _loadedWidth;

  AdsController? get _ads =>
      Get.isRegistered<AdsController>() ? Get.find<AdsController>() : null;

  Future<void> _load(int width) async {
    if (_loading || _loadedWidth == width) return;
    _loading = true;
    final banner = await Get.find<IAdsService>().loadAnchoredBanner(width);
    _loading = false;
    if (!mounted) {
      banner?.dispose();
      return;
    }
    setState(() {
      _banner?.dispose();
      _banner = banner;
      _loadedWidth = width;
    });
  }

  void _release() {
    if (_banner == null) return;
    _banner!.dispose();
    _banner = null;
    _loadedWidth = null;
  }

  @override
  void dispose() {
    _release();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ads = _ads;
    if (ads == null) return const SizedBox.shrink();
    return Obx(() {
      if (!ads.showAds) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && _banner != null) setState(_release);
        });
        return const SizedBox.shrink();
      }
      final width = MediaQuery.of(context).size.width.truncate();
      if (_loadedWidth != width) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _load(width));
      }
      final banner = _banner;
      if (banner == null) return const SizedBox.shrink();
      return SizedBox(
        width: banner.size.width.toDouble(),
        height: banner.size.height.toDouble(),
        child: AdWidget(ad: banner),
      );
    });
  }
}

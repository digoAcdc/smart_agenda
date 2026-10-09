import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../../domain/repositories/i_ads_service.dart';
import '../controllers/ads_controller.dart';

/// Anuncio nativo (modelo pequeno) no meio de uma lista, para o plano Free.
/// O modelo do Google ja traz a marcacao de anuncio.
class NativeAdCard extends StatefulWidget {
  const NativeAdCard({super.key});

  @override
  State<NativeAdCard> createState() => _NativeAdCardState();
}

class _NativeAdCardState extends State<NativeAdCard> {
  NativeAd? _ad;
  bool _requested = false;

  Future<void> _load(bool darkMode) async {
    _requested = true;
    final ad = await Get.find<IAdsService>().loadNative(darkMode: darkMode);
    if (!mounted) {
      ad?.dispose();
      return;
    }
    setState(() => _ad = ad);
  }

  @override
  void dispose() {
    _ad?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<AdsController>()) return const SizedBox.shrink();
    final ads = Get.find<AdsController>();
    return Obx(() {
      if (!ads.showAds) return const SizedBox.shrink();
      if (!_requested) {
        final dark = Theme.of(context).brightness == Brightness.dark;
        WidgetsBinding.instance.addPostFrameCallback((_) => _load(dark));
      }
      final ad = _ad;
      if (ad == null) return const SizedBox.shrink();
      return Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 90, maxHeight: 120),
          child: AdWidget(ad: ad),
        ),
      );
    });
  }
}

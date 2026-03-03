import 'package:get/get.dart';

import '../../domain/repositories/i_ads_service.dart';

class AdsController extends GetxController {
  AdsController(this._adsService);
  final IAdsService _adsService;

  final RxBool isReady = false.obs;

  @override
  Future<void> onInit() async {
    super.onInit();
    await _adsService.init();
    isReady.value = true;
  }
}

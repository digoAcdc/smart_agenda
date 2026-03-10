import 'package:get/get.dart';

import '../../domain/repositories/i_plan_service.dart';
import '../../domain/repositories/i_premium_service.dart';

/// Implementacao do PremiumService: cacheia isPremium para acesso sincrono.
/// AuthController deve chamar refresh() quando o estado de auth mudar.
class PremiumServiceImpl extends GetxController implements IPremiumService {
  PremiumServiceImpl(this._planService);

  final IPlanService _planService;
  final RxBool _isPremium = false.obs;

  @override
  bool get isPremium => _isPremium.value;

  @override
  Future<void> refresh() async {
    _isPremium.value = await _planService.isPremium();
  }

  @override
  void onInit() {
    super.onInit();
    refresh();
  }
}

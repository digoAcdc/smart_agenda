import 'dart:async';

import 'package:get/get.dart';

import '../../domain/repositories/i_plan_service.dart';
import '../../domain/repositories/i_premium_service.dart';

/// Implementacao do PremiumService: cacheia isPremium para acesso sincrono.
/// AuthController deve chamar refresh() quando o estado de auth mudar.
class PremiumServiceImpl extends GetxController implements IPremiumService {
  PremiumServiceImpl(this._planService);

  final IPlanService _planService;
  final RxBool _isPremium = false.obs;
  final RxBool _isResolved = false.obs;

  @override
  bool get isPremium => _isPremium.value;

  final _changes = StreamController<void>.broadcast();

  @override
  bool get isResolved => _isResolved.value;

  @override
  Stream<void> get changes => _changes.stream;

  @override
  Future<void> refresh() async {
    _isPremium.value = await _planService.isPremium();
    _isResolved.value = true;
    _changes.add(null);
  }

  @override
  void onClose() {
    _changes.close();
    super.onClose();
  }

  @override
  void onInit() {
    super.onInit();
    refresh();
  }
}

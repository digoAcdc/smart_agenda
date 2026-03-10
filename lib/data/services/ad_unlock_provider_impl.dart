import 'package:get/get.dart';

import '../../domain/repositories/i_ad_unlock_provider.dart';

/// Implementacao simples do AdUnlockProvider usando variavel em memoria.
class AdUnlockProviderImpl extends GetxController implements IAdUnlockProvider {
  bool _isShareUnlocked = false;

  @override
  bool get isShareUnlocked => _isShareUnlocked;

  @override
  void setShareUnlocked(bool value) {
    _isShareUnlocked = value;
  }
}

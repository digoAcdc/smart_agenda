import 'package:get/get.dart';

class HomeController extends GetxController {
  final RxInt currentIndex = 0.obs;
  final Rxn<DateTime> initialDateForAgenda = Rxn<DateTime>();
  final RxnString initialModeForAgenda = RxnString();
  bool _navigationArgsApplied = false;

  void setIndex(int value) {
    if (value < 0 || value > 4) return;
    currentIndex.value = value;
  }

  void setInitialDate(DateTime date) {
    initialDateForAgenda.value = date;
  }

  void setInitialMode(String mode) {
    initialModeForAgenda.value = mode;
  }

  DateTime? get initialDateValueForAgenda => initialDateForAgenda.value;
  String? get initialModeValueForAgenda => initialModeForAgenda.value;

  void clearInitialAgendaNavigation() {
    initialDateForAgenda.value = null;
    initialModeForAgenda.value = null;
  }

  bool get navigationArgsApplied => _navigationArgsApplied;
  void markNavigationArgsApplied() {
    _navigationArgsApplied = true;
  }

  DateTime? consumeInitialDate() {
    final d = initialDateForAgenda.value;
    initialDateForAgenda.value = null;
    return d;
  }

  String? consumeInitialMode() {
    final m = initialModeForAgenda.value;
    initialModeForAgenda.value = null;
    return m;
  }
}

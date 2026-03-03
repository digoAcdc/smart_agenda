import 'package:get/get.dart';

class HomeController extends GetxController {
  final RxInt currentIndex = 0.obs;

  void setIndex(int value) {
    if (value < 0 || value > 4) return;
    currentIndex.value = value;
  }
}

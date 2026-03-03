import 'package:flutter_test/flutter_test.dart';
import 'package:smart_agenda/presentation/controllers/home_controller.dart';

void main() {
  test('HomeController altera indice de navegacao', () {
    final controller = HomeController();
    expect(controller.currentIndex.value, 0);
    controller.setIndex(2);
    expect(controller.currentIndex.value, 2);
  });
}

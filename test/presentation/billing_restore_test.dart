import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_agenda/domain/repositories/i_billing_service.dart';
import 'package:smart_agenda/domain/repositories/i_plan_service.dart';
import 'package:smart_agenda/presentation/controllers/billing_controller.dart';

/// Google Play sem nenhuma assinatura ativa: restaurar nao devolve compras.
class _NoPurchasesBilling implements IBillingService {
  @override
  Future<bool> get isAvailable async => true;
  @override
  Future<bool> loadProducts() async => true;
  @override
  String? get premiumProductPrice => 'R\$ 9,90 por mês';
  @override
  Future<void> restorePurchases() async {}
  @override
  void startPurchaseStreamListener(void Function(PurchaseUpdate) onUpdate) {}
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FreePlan implements IPlanService {
  @override
  Future<bool> isPremium() async => false;
  @override
  Future<void> refresh() async {}
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  test('restaurar sem assinatura ativa nao fica carregando para sempre', () {
    fakeAsync((async) {
      final controller = BillingController(_NoPurchasesBilling(), _FreePlan());
      controller.onInit();
      async.flushMicrotasks();

      controller.restorePurchases();
      async.flushMicrotasks();
      expect(controller.purchaseStatus.value, BillingPurchaseStatus.loading);

      async.elapse(const Duration(seconds: 9));

      expect(controller.purchaseStatus.value, BillingPurchaseStatus.idle);
      expect(controller.errorMessage.value, contains('Nenhuma assinatura ativa'));
    });
  });
}

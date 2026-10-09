import 'package:flutter_test/flutter_test.dart';
import 'package:smart_agenda/data/datasources/subscription_supabase_datasource.dart';
import 'package:smart_agenda/domain/entities/purchase_payload.dart';
import 'package:smart_agenda/domain/repositories/i_billing_service.dart';
import 'package:smart_agenda/domain/repositories/i_plan_service.dart';
import 'package:smart_agenda/presentation/controllers/billing_controller.dart';

/// Google Play falso: entrega uma compra paga e registra as confirmacoes.
class _FakeBilling implements IBillingService {
  _FakeBilling(this.validate);

  final Future<SubscriptionValidationResult> Function() validate;
  final finished = <String>[];
  void Function(PurchaseUpdate)? _onUpdate;

  void deliverPurchase(String token) => _onUpdate!(
    PurchaseUpdate(
      status: PurchaseUpdateStatus.purchased,
      payload: PurchasePayload(
        productId: 'smart_agenda_premium',
        purchaseToken: token,
        packageName: 'app',
      ),
    ),
  );

  @override
  Future<bool> get isAvailable async => true;
  @override
  Future<bool> loadProducts() async => true;
  @override
  String? get premiumProductPrice => null;
  @override
  void startPurchaseStreamListener(void Function(PurchaseUpdate) onUpdate) =>
      _onUpdate = onUpdate;
  @override
  Future<SubscriptionValidationResult> validatePurchaseWithBackend(
    PurchasePayload payload,
  ) => validate();
  @override
  Future<void> finishPurchase(String purchaseToken) async =>
      finished.add(purchaseToken);
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Plan implements IPlanService {
  @override
  Future<void> refresh() async {}
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Future<BillingController> _start(_FakeBilling billing) async {
  final controller = BillingController(billing, _Plan());
  controller.onInit();
  await Future<void>.delayed(Duration.zero);
  return controller;
}

void main() {
  test('confirma a compra no Google depois que o servidor valida', () async {
    final billing = _FakeBilling(
      () async =>
          const SubscriptionValidationResult(isPremium: true, status: 'active'),
    );
    final controller = await _start(billing);

    billing.deliverPurchase('tok-1');
    await Future<void>.delayed(Duration.zero);

    expect(billing.finished, ['tok-1']);
    expect(controller.purchaseStatus.value, BillingPurchaseStatus.success);
  });

  test(
    'servidor fora do ar: nao confirma (volta no proximo restore)',
    () async {
      final billing = _FakeBilling(() async => throw Exception('offline'));
      final controller = await _start(billing);

      billing.deliverPurchase('tok-2');
      await Future<void>.delayed(Duration.zero);

      expect(billing.finished, isEmpty);
      expect(controller.purchaseStatus.value, BillingPurchaseStatus.error);
    },
  );

  test('mensagens de erro da validacao em portugues', () {
    expect(validationErrorMessage(409, 'x'), contains('outra conta'));
    expect(validationErrorMessage(502, null), contains('não se perde'));
  });
}

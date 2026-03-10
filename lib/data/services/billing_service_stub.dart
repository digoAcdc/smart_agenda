import 'dart:async';

import '../../domain/entities/purchase_payload.dart';
import '../../domain/repositories/i_billing_service.dart';

/// Stub do BillingService quando billing nao esta disponivel (ex: iOS, web).
class BillingServiceStub implements IBillingService {
  @override
  Future<bool> loadProducts() => Future.value(false);

  @override
  Future<bool> purchase() => Future.value(false);

  @override
  Future<void> restorePurchases() => Future.value();

  @override
  Stream<PurchaseUpdate> get purchaseStream => const Stream.empty();

  @override
  void startPurchaseStreamListener(void Function(PurchaseUpdate) onUpdate) {}

  @override
  Future<SubscriptionValidationResult> validatePurchaseWithBackend(
    PurchasePayload payload,
  ) =>
      Future.value(const SubscriptionValidationResult(
        isPremium: false,
        status: 'unavailable',
      ));

  @override
  Future<bool> get isAvailable => Future.value(false);

  @override
  String? get premiumProductPrice => null;
}

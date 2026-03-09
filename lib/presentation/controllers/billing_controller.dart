import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import '../../domain/entities/purchase_payload.dart';
import '../../domain/repositories/i_billing_service.dart';
import '../../domain/repositories/i_plan_service.dart';

/// Estado do fluxo de compra para a UI.
enum BillingPurchaseStatus {
  idle,
  loading,
  purchasing,
  validating,
  pending,
  success,
  error,
  canceled,
}

class BillingController extends GetxController {
  BillingController(this._billingService, this._planService);

  final IBillingService _billingService;
  final IPlanService _planService;

  final RxBool isAvailable = false.obs;
  final RxBool productsLoaded = false.obs;
  final Rx<BillingPurchaseStatus> purchaseStatus = BillingPurchaseStatus.idle.obs;
  final RxnString errorMessage = RxnString();
  final RxnString productPrice = RxnString();

  @override
  void onInit() {
    super.onInit();
    _init();
  }

  Future<void> _init() async {
    isAvailable.value = await _billingService.isAvailable;
    if (!isAvailable.value) return;

    _billingService.startPurchaseStreamListener(_onPurchaseUpdate);

    final ok = await _billingService.loadProducts();
    productsLoaded.value = ok;
    if (ok) {
      productPrice.value = _billingService.premiumProductPrice;
    }
  }

  void _onPurchaseUpdate(PurchaseUpdate update) {
    switch (update.status) {
      case PurchaseUpdateStatus.pending:
        purchaseStatus.value = BillingPurchaseStatus.pending;
        errorMessage.value = null;
        break;
      case PurchaseUpdateStatus.purchased:
        _validateAndRefresh(update.payload);
        break;
      case PurchaseUpdateStatus.error:
        purchaseStatus.value = BillingPurchaseStatus.error;
        errorMessage.value = update.errorMessage ?? 'Erro na compra.';
        break;
      case PurchaseUpdateStatus.canceled:
        purchaseStatus.value = BillingPurchaseStatus.canceled;
        errorMessage.value = null;
        break;
    }
  }

  Future<void> _validateAndRefresh(PurchasePayload payload) async {
    purchaseStatus.value = BillingPurchaseStatus.validating;
    errorMessage.value = null;

    try {
      final result = await _billingService.validatePurchaseWithBackend(payload);
      if (result.isPremium) {
        await _planService.refresh();
        purchaseStatus.value = BillingPurchaseStatus.success;
      } else {
        purchaseStatus.value = BillingPurchaseStatus.error;
        errorMessage.value = 'Assinatura nao ativa. Status: ${result.status}';
      }
    } catch (e) {
      debugPrint('[BillingController] validate error: $e');
      purchaseStatus.value = BillingPurchaseStatus.error;
      errorMessage.value = e.toString().replaceFirst('Exception: ', '');
    }
  }

  Future<void> purchase() async {
    if (!isAvailable.value || !productsLoaded.value) return;
    purchaseStatus.value = BillingPurchaseStatus.purchasing;
    errorMessage.value = null;

    final ok = await _billingService.purchase();
    if (!ok) {
      purchaseStatus.value = BillingPurchaseStatus.error;
      errorMessage.value = 'Nao foi possivel iniciar a compra.';
    }
  }

  Future<void> restorePurchases() async {
    if (!isAvailable.value) return;
    purchaseStatus.value = BillingPurchaseStatus.loading;
    errorMessage.value = null;

    await _billingService.restorePurchases();
    // O purchaseStream vai receber as compras restauradas e chamar _validateAndRefresh
  }

  void clearStatus() {
    purchaseStatus.value = BillingPurchaseStatus.idle;
    errorMessage.value = null;
  }
}

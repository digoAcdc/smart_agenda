import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import '../../core/constants/billing_constants.dart';
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
  final RxBool isRuntimeConfigured = true.obs;

  Completer<void>? _restoreWaiter;
  Future<void>? _autoRevalidationTask;
  DateTime? _lastAutoRevalidationAt;

  @override
  void onInit() {
    super.onInit();
    _init();
  }

  Future<void> _init() async {
    isRuntimeConfigured.value = BillingConstants.hasBillingApiConfigured;
    if (!isRuntimeConfigured.value) {
      errorMessage.value =
          'Configuração de cobrança indisponível. Atualize o app ou contate o suporte.';
      debugPrint('[billing_config_missing] BILLING_API_BASE_URL ausente');
    }

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
    debugPrint('[billing_purchase_update] status=${update.status.name}');
    switch (update.status) {
      case PurchaseUpdateStatus.pending:
        purchaseStatus.value = BillingPurchaseStatus.pending;
        errorMessage.value = null;
        break;
      case PurchaseUpdateStatus.purchased:
        unawaited(_validateAndRefresh(update.payload));
        break;
      case PurchaseUpdateStatus.error:
        purchaseStatus.value = BillingPurchaseStatus.error;
        errorMessage.value = update.errorMessage ?? 'Erro na compra.';
        _completeRestoreWaiter();
        break;
      case PurchaseUpdateStatus.canceled:
        purchaseStatus.value = BillingPurchaseStatus.canceled;
        errorMessage.value = null;
        _completeRestoreWaiter();
        break;
    }
  }

  Future<void> _validateAndRefresh(PurchasePayload payload) async {
    debugPrint('[subscription_revalidation_started] source=purchase_stream');
    purchaseStatus.value = BillingPurchaseStatus.validating;
    errorMessage.value = null;

    try {
      final result = await _billingService.validatePurchaseWithBackend(payload);
      if (result.isPremium) {
        await _planService.refresh();
        purchaseStatus.value = BillingPurchaseStatus.success;
        debugPrint(
          '[subscription_revalidation_completed] isPremium=true status=${result.status} source=${result.source}',
        );
      } else {
        purchaseStatus.value = BillingPurchaseStatus.error;
        errorMessage.value = 'Assinatura nao ativa. Status: ${result.status}';
        debugPrint(
          '[subscription_revalidation_completed] isPremium=false status=${result.status} source=${result.source}',
        );
      }
    } catch (e) {
      debugPrint('[BillingController] validate error: $e');
      debugPrint('[subscription_revalidation_failed] source=purchase_stream error=$e');
      purchaseStatus.value = BillingPurchaseStatus.error;
      errorMessage.value = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _completeRestoreWaiter();
    }
  }

  Future<void> purchase() async {
    if (!isRuntimeConfigured.value) {
      purchaseStatus.value = BillingPurchaseStatus.error;
      errorMessage.value =
          'Cobrança indisponível no momento. Tente novamente mais tarde.';
      return;
    }
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
    if (!isRuntimeConfigured.value) {
      purchaseStatus.value = BillingPurchaseStatus.error;
      errorMessage.value =
          'Cobrança indisponível no momento. Tente novamente mais tarde.';
      return;
    }
    if (!isAvailable.value) return;
    debugPrint('[billing_restore_started] source=user_action');
    purchaseStatus.value = BillingPurchaseStatus.loading;
    errorMessage.value = null;

    try {
      _restoreWaiter = Completer<void>();
      await _billingService.restorePurchases();
      await _restoreWaiter!.future.timeout(const Duration(seconds: 8), onTimeout: () {
        debugPrint('[billing_restore_timeout] waited_ms=8000');
      });
      debugPrint('[billing_restore_completed] source=user_action');
    } catch (e) {
      debugPrint('[billing_restore_failed] source=user_action error=$e');
      purchaseStatus.value = BillingPurchaseStatus.error;
      errorMessage.value = 'Nao foi possivel restaurar compras agora.';
    }
    // O purchaseStream vai receber as compras restauradas e chamar _validateAndRefresh
  }

  Future<void> revalidateInBackground({
    bool triggerRestore = false,
    String reason = 'unknown',
  }) async {
    if (!isRuntimeConfigured.value || !isAvailable.value) return;
    final now = DateTime.now();
    final last = _lastAutoRevalidationAt;
    if (last != null && now.difference(last) < const Duration(minutes: 2)) {
      return;
    }
    if (_autoRevalidationTask != null) {
      await _autoRevalidationTask;
      return;
    }

    _autoRevalidationTask = _runAutoRevalidation(triggerRestore: triggerRestore, reason: reason);
    await _autoRevalidationTask;
    _autoRevalidationTask = null;
    _lastAutoRevalidationAt = now;
  }

  Future<void> _runAutoRevalidation({
    required bool triggerRestore,
    required String reason,
  }) async {
    debugPrint('[subscription_revalidation_started] source=auto reason=$reason');
    try {
      if (triggerRestore) {
        debugPrint('[billing_restore_started] source=auto reason=$reason');
        try {
          _restoreWaiter = Completer<void>();
          await _billingService.restorePurchases();
          await _restoreWaiter!.future.timeout(
            const Duration(seconds: 8),
            onTimeout: () => debugPrint('[billing_restore_timeout] source=auto waited_ms=8000'),
          );
          debugPrint('[billing_restore_completed] source=auto reason=$reason');
        } catch (e) {
          debugPrint('[billing_restore_failed] source=auto reason=$reason error=$e');
        }
      }
      await _planService.refresh();
      debugPrint('[subscription_revalidation_completed] source=auto reason=$reason');
    } catch (e) {
      debugPrint('[subscription_revalidation_failed] source=auto reason=$reason error=$e');
    }
  }

  void _completeRestoreWaiter() {
    if (_restoreWaiter != null && !_restoreWaiter!.isCompleted) {
      _restoreWaiter!.complete();
    }
  }

  void clearStatus() {
    purchaseStatus.value = BillingPurchaseStatus.idle;
    errorMessage.value = null;
  }
}

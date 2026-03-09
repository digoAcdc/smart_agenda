import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import '../../core/constants/billing_constants.dart';
import '../../domain/entities/purchase_payload.dart';
import '../../domain/repositories/i_billing_service.dart';
import '../datasources/subscription_supabase_datasource.dart';

/// Implementacao do BillingService com Google Play e Supabase.
/// Disponivel apenas em Android.
class BillingServiceImpl implements IBillingService {
  BillingServiceImpl({
    required InAppPurchase iap,
    required SubscriptionSupabaseDataSource subscriptionDataSource,
  })  : _iap = iap,
        _subscriptionDataSource = subscriptionDataSource;

  final InAppPurchase _iap;
  final SubscriptionSupabaseDataSource _subscriptionDataSource;

  final _purchaseController = StreamController<PurchaseUpdate>.broadcast();
  ProductDetails? _premiumProduct;
  StreamSubscription<List<PurchaseDetails>>? _subscription;

  @override
  Stream<PurchaseUpdate> get purchaseStream => _purchaseController.stream;

  @override
  Future<bool> get isAvailable async {
    if (!Platform.isAndroid) return false;
    return _iap.isAvailable();
  }

  @override
  Future<bool> loadProducts() async {
    if (!await isAvailable) return false;
    try {
      final response = await _iap.queryProductDetails(BillingConstants.productIds);
      if (response.notFoundIDs.isNotEmpty) {
        debugPrint('[BillingService] Products not found: ${response.notFoundIDs}');
      }
      final list = response.productDetails
          .where((p) => p.id == BillingConstants.premiumMonthlyProductId)
          .toList();
      _premiumProduct = list.isEmpty ? null : list.first;
      return _premiumProduct != null;
    } catch (e) {
      debugPrint('[BillingService] loadProducts error: $e');
      return false;
    }
  }

  ProductDetails? get premiumProduct => _premiumProduct;

  @override
  String? get premiumProductPrice => _premiumProduct?.price;

  @override
  Future<bool> purchase() async {
    if (!await isAvailable) return false;
    final product = _premiumProduct;
    if (product == null) {
      debugPrint('[BillingService] Product not loaded');
      return false;
    }
    try {
      final param = PurchaseParam(productDetails: product);
      return _iap.buyNonConsumable(purchaseParam: param);
    } catch (e) {
      debugPrint('[BillingService] purchase error: $e');
      return false;
    }
  }

  @override
  Future<void> restorePurchases() async {
    if (!await isAvailable) return;
    await _iap.restorePurchases();
  }

  @override
  Future<SubscriptionValidationResult> validatePurchaseWithBackend(
    PurchasePayload payload,
  ) async {
    return _subscriptionDataSource.validateSubscription(payload);
  }

  @override
  void startPurchaseStreamListener(
    void Function(PurchaseUpdate) onUpdate,
  ) {
    _subscription?.cancel();
    _subscription = _iap.purchaseStream.listen(
      (purchases) => _handlePurchases(purchases, onUpdate),
      onError: (e) {
        debugPrint('[BillingService] purchaseStream error: $e');
        onUpdate(PurchaseUpdate(
          status: PurchaseUpdateStatus.error,
          payload: const PurchasePayload(
            productId: '',
            purchaseToken: '',
            packageName: '',
          ),
          errorMessage: e.toString(),
        ));
      },
    );
  }

  void _handlePurchases(
    List<PurchaseDetails> purchases,
    void Function(PurchaseUpdate) onUpdate,
  ) {
    for (final p in purchases) {
      final payload = _toPayload(p);
      if (payload == null) continue;

      switch (p.status) {
        case PurchaseStatus.pending:
          onUpdate(PurchaseUpdate(status: PurchaseUpdateStatus.pending, payload: payload));
          break;
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          onUpdate(PurchaseUpdate(status: PurchaseUpdateStatus.purchased, payload: payload));
          if (p.pendingCompletePurchase) {
            _iap.completePurchase(p);
          }
          break;
        case PurchaseStatus.error:
          onUpdate(PurchaseUpdate(
            status: PurchaseUpdateStatus.error,
            payload: payload,
            errorMessage: p.error?.message,
          ));
          if (p.pendingCompletePurchase) {
            _iap.completePurchase(p);
          }
          break;
        case PurchaseStatus.canceled:
          onUpdate(PurchaseUpdate(status: PurchaseUpdateStatus.canceled, payload: payload));
          if (p.pendingCompletePurchase) {
            _iap.completePurchase(p);
          }
          break;
      }
    }
  }

  PurchasePayload? _toPayload(PurchaseDetails p) {
    final token = p.verificationData.serverVerificationData;
    if (token.isEmpty) return null;
    int? purchaseTime;
    if (p.transactionDate != null) {
      try {
        final dt = DateTime.tryParse(p.transactionDate!);
        if (dt != null) purchaseTime = dt.millisecondsSinceEpoch;
      } catch (_) {}
    }
    int? purchaseState;
    switch (p.status) {
      case PurchaseStatus.pending:
        purchaseState = 0;
        break;
      case PurchaseStatus.purchased:
      case PurchaseStatus.restored:
        purchaseState = 1;
        break;
      case PurchaseStatus.error:
        purchaseState = 2;
        break;
      case PurchaseStatus.canceled:
        purchaseState = 3;
        break;
    }
    return PurchasePayload(
      productId: p.productID,
      purchaseToken: token,
      packageName: BillingConstants.packageName,
      orderId: p.purchaseID,
      purchaseTime: purchaseTime,
      platform: BillingConstants.platform,
      purchaseState: purchaseState,
    );
  }

  void dispose() {
    _subscription?.cancel();
    _purchaseController.close();
  }
}

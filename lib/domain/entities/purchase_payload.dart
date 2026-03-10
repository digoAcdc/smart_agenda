import 'package:equatable/equatable.dart';

/// DTO para enviar dados da compra ao backend de billing.
class PurchasePayload extends Equatable {
  const PurchasePayload({
    required this.productId,
    required this.purchaseToken,
    required this.packageName,
    this.orderId,
    this.purchaseTime,
    this.platform = 'android',
    this.purchaseState,
  });

  final String productId;
  final String purchaseToken;
  final String packageName;
  final String? orderId;
  final int? purchaseTime;
  final String platform;
  final int? purchaseState;

  Map<String, dynamic> toJson() => {
        'productId': productId,
        'purchaseToken': purchaseToken,
        'packageName': packageName,
        if (orderId != null) 'orderId': orderId,
        if (purchaseTime != null) 'purchaseTime': purchaseTime,
        'platform': platform,
        if (purchaseState != null) 'purchaseState': purchaseState,
      };

  @override
  List<Object?> get props => [productId, purchaseToken, packageName, orderId, purchaseTime, platform, purchaseState];
}

import '../entities/purchase_payload.dart';

/// Resultado da validacao de assinatura no backend.
class SubscriptionValidationResult {
  const SubscriptionValidationResult({
    required this.isPremium,
    required this.status,
    this.expiresAt,
    this.productId,
    this.source = 'subscription',
  });

  final bool isPremium;
  final String status;
  final String? expiresAt;
  final String? productId;
  final String source;
}

/// Servico de billing para compras in-app (Google Play).
/// Abstrai InAppPurchase e envio para API Node de validação.
abstract class IBillingService {
  /// Carrega os produtos disponiveis (assinaturas).
  Future<bool> loadProducts();

  /// Inicia o fluxo de compra do produto premium mensal.
  /// Retorna true se o fluxo foi iniciado com sucesso.
  Future<bool> purchase();

  /// Restaura compras anteriores (restore).
  Future<void> restorePurchases();

  /// Stream de atualizacoes de compra (pending, purchased, error, canceled).
  Stream<PurchaseUpdate> get purchaseStream;

  /// Inicia a escuta do purchaseStream. Chamar no init do controller.
  void startPurchaseStreamListener(void Function(PurchaseUpdate) onUpdate);

  /// Envia dados da compra para o backend validar e persistir.
  /// Retorna o resultado da validacao.
  Future<SubscriptionValidationResult> validatePurchaseWithBackend(
    PurchasePayload payload,
  );

  /// Indica se o billing esta disponivel (ex: apenas Android com Google Play).
  Future<bool> get isAvailable;

  /// Preco formatado do produto premium (ex: "R$ 4,99 /mes"). Null se nao carregado.
  String? get premiumProductPrice;
}

/// Atualizacao de compra do purchaseStream.
enum PurchaseUpdateStatus {
  pending,
  purchased,
  error,
  canceled,
}

class PurchaseUpdate {
  const PurchaseUpdate({
    required this.status,
    required this.payload,
    this.errorMessage,
  });

  final PurchaseUpdateStatus status;
  final PurchasePayload payload;
  final String? errorMessage;
}

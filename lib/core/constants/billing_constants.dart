/// Constantes para integracao com Google Play Billing.
class BillingConstants {
  BillingConstants._();

  /// Product ID da assinatura mensal premium (configurar no Play Console).
  static const String premiumMonthlyProductId = 'smart_agenda_premium_monthly';

  /// IDs de produtos disponiveis para carregar.
  static const Set<String> productIds = {premiumMonthlyProductId};

  /// Package name do app Android (deve bater com applicationId).
  static const String packageName = 'com.digo.smartagenda';

  /// Base URL da API de billing Node.
  /// Exemplo: https://smart-agenda-billing-api.vybg0t.easypanel.host
  static const String billingApiBaseUrl = String.fromEnvironment(
    'BILLING_API_BASE_URL',
    defaultValue: '',
  );

  /// Plataforma para envio ao backend.
  static const String platform = 'android';

  /// Store para envio ao backend.
  static const String store = 'google_play';
}

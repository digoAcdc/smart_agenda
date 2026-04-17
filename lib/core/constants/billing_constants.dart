/// Constantes para integracao com Google Play Billing.
class BillingConstants {
  BillingConstants._();

  /// ID do produto de assinatura no Play Console (Subscriptions > produto).
  /// O plano basico (ex.: premium-mensal) e interno ao Google Play; aqui vai so o product id.
  static const String premiumMonthlyProductId = 'smart_agenda_premium';

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

  static bool get hasBillingApiConfigured => billingApiBaseUrl.trim().isNotEmpty;

  /// Plataforma para envio ao backend.
  static const String platform = 'android';

  /// Store para envio ao backend.
  static const String store = 'google_play';
}

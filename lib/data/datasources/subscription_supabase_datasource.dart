import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/constants/billing_constants.dart';
import '../../domain/entities/purchase_payload.dart';
import '../../domain/repositories/i_billing_service.dart';

/// Data source para assinaturas: chama API Node e consulta RPC.
class SubscriptionSupabaseDataSource {
  SubscriptionSupabaseDataSource(this._client);

  final SupabaseClient _client;

  /// Envia dados da compra para a API Node validar com Google Play API.
  /// Exige usuario autenticado.
  Future<SubscriptionValidationResult> validateSubscription(
    PurchasePayload payload,
  ) async {
    final session = _client.auth.currentSession;
    if (session == null) {
      throw StateError('Usuario nao autenticado');
    }

    final baseUrl = BillingConstants.billingApiBaseUrl.trim();
    if (baseUrl.isEmpty) {
      throw Exception(
        'BILLING_API_BASE_URL nao configurada. '
        'Use --dart-define=BILLING_API_BASE_URL=...',
      );
    }
    final uri = Uri.parse('$baseUrl/validate-subscription');

    final client = HttpClient();
    try {
      final request = await client.postUrl(uri);
      request.headers.set(HttpHeaders.contentTypeHeader, 'application/json');
      request.headers.set(
        HttpHeaders.authorizationHeader,
        'Bearer ${session.accessToken}',
      );
      request.add(
        utf8.encode(
          jsonEncode({
            'productId': payload.productId,
            'purchaseToken': payload.purchaseToken,
          }),
        ),
      );

      final response = await request.close();
      final responseBody = await response.transform(utf8.decoder).join();
      final parsed = responseBody.isNotEmpty
          ? jsonDecode(responseBody) as Map<String, dynamic>
          : <String, dynamic>{};

      if (response.statusCode != 200) {
        final err = parsed['error']?.toString();
        throw Exception(err ?? 'Validacao falhou');
      }

      final data = parsed;

      return SubscriptionValidationResult(
        isPremium: data['isPremium'] as bool? ?? false,
        status: (data['status'] as String?) ??
            (data['subscriptionStatus'] as String?) ??
            'unknown',
        expiresAt: data['expiresAt'] as String?,
        productId: data['productId'] as String?,
        source: data['source'] as String? ?? 'subscription',
      );
    } finally {
      client.close();
    }
  }

  /// Consulta status premium por assinatura via RPC.
  /// Retorna null se nao houver assinatura valida.
  Future<SubscriptionPremiumStatus?> getSubscriptionPremiumStatus() async {
    try {
      final result = await _client.rpc('get_subscription_premium_status');
      if (result == null) return null;
      final list = result as List;
      if (list.isEmpty) return null;
      final row = list.first as Map<String, dynamic>;
      return SubscriptionPremiumStatus(
        isPremium: row['is_premium'] as bool? ?? false,
        status: row['status'] as String? ?? '',
        expiresAt: row['expires_at'] as String?,
        productId: row['product_id'] as String?,
      );
    } catch (e) {
      debugPrint('[SubscriptionDS] getSubscriptionPremiumStatus error: $e');
      return null;
    }
  }
}

/// Status premium retornado pela RPC.
class SubscriptionPremiumStatus {
  const SubscriptionPremiumStatus({
    required this.isPremium,
    required this.status,
    this.expiresAt,
    this.productId,
  });

  final bool isPremium;
  final String status;
  final String? expiresAt;
  final String? productId;
}

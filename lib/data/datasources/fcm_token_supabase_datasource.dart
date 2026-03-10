import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

/// Data source para tokens FCM (push notifications).
class FcmTokenSupabaseDataSource {
  FcmTokenSupabaseDataSource(this._client);

  final SupabaseClient _client;

  /// Insere ou atualiza o token para o usuario.
  /// Usa upsert por (user_id, token) para suportar token refresh.
  Future<void> upsertToken(String userId, String token, {String? platform}) async {
    final p = platform ?? _platform;
    await _client.from('user_fcm_tokens').upsert(
      {
        'user_id': userId,
        'token': token,
        'platform': p,
        'updated_at': DateTime.now().toIso8601String(),
      },
      onConflict: 'user_id,token',
    );
  }

  /// Remove o token no logout.
  Future<void> deleteToken(String userId, String token) async {
    await _client
        .from('user_fcm_tokens')
        .delete()
        .eq('user_id', userId)
        .eq('token', token);
  }

  static String get _platform =>
      Platform.isAndroid ? 'android' : (Platform.isIOS ? 'ios' : 'unknown');
}

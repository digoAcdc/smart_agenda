import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/push_preferences.dart';

/// Data source para preferencias de push (agenda do dia, amanha, semana).
class PushPreferencesSupabaseDataSource {
  PushPreferencesSupabaseDataSource(this._client);

  final SupabaseClient _client;

  Future<PushPreferences> getPreferences() async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) {
      return const PushPreferences(
        pushDailySummary: true,
        pushTomorrowSummary: false,
        pushWeeklySummary: true,
      );
    }

    final rows = await _client
        .from('user_push_preferences')
        .select()
        .eq('user_id', uid)
        .maybeSingle();

    if (rows == null) {
      return const PushPreferences(
        pushDailySummary: true,
        pushTomorrowSummary: false,
        pushWeeklySummary: true,
      );
    }

    final r = Map<String, dynamic>.from(rows);
    return PushPreferences(
      pushDailySummary: r['push_daily_summary'] as bool? ?? true,
      pushTomorrowSummary: r['push_tomorrow_summary'] as bool? ?? false,
      pushWeeklySummary: r['push_weekly_summary'] as bool? ?? true,
    );
  }

  Future<void> updatePreferences({
    required bool pushDailySummary,
    required bool pushTomorrowSummary,
    required bool pushWeeklySummary,
  }) async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return;

    await _client.from('user_push_preferences').upsert(
      {
        'user_id': uid,
        'push_daily_summary': pushDailySummary,
        'push_tomorrow_summary': pushTomorrowSummary,
        'push_weekly_summary': pushWeeklySummary,
        'updated_at': DateTime.now().toIso8601String(),
      },
      onConflict: 'user_id',
    );
  }
}

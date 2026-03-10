import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/user_notification.dart';

/// Data source para notificacoes push (resumo diario/semanal).
class NotificationsSupabaseDataSource {
  NotificationsSupabaseDataSource(this._client);

  final SupabaseClient _client;

  Future<List<UserNotification>> getNotifications() async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return [];

    final rows = await _client
        .from('user_notifications')
        .select()
        .eq('user_id', uid)
        .order('created_at', ascending: false);

    return (rows as List)
        .map((r) => _fromRow(Map<String, dynamic>.from(r)))
        .toList();
  }

  Future<void> markAsRead(String id) async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return;

    await _client
        .from('user_notifications')
        .update({'read_at': DateTime.now().toIso8601String()})
        .eq('id', id)
        .eq('user_id', uid);
  }

  UserNotification _fromRow(Map<String, dynamic> row) {
    final refDate = row['reference_date'] as String?;
    final createdAt = row['created_at'] as String?;
    final readAt = row['read_at'] as String?;
    return UserNotification(
      id: row['id'] as String,
      type: row['type'] as String? ?? '',
      referenceDate: refDate != null ? DateTime.parse(refDate) : DateTime.now(),
      title: row['title'] as String? ?? '',
      body: row['body'] as String? ?? '',
      createdAt: createdAt != null ? DateTime.parse(createdAt) : DateTime.now(),
      readAt: readAt != null ? DateTime.parse(readAt) : null,
    );
  }
}

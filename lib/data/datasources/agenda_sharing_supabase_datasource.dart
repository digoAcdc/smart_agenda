import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/repositories/i_sharing_service.dart';

/// Data source para agenda_shares no Supabase.
class AgendaSharingSupabaseDataSource {
  AgendaSharingSupabaseDataSource(this._client);

  final SupabaseClient _client;

  String? get _userId => _client.auth.currentUser?.id;
  String? get _userEmail => _client.auth.currentUser?.email;

  /// Busca user_id por email via RPC.
  Future<String?> getUserIdByEmail(String email) async {
    try {
      final result = await _client.rpc(
        'get_user_id_by_email',
        params: {'email_input': email.trim().toLowerCase()},
      );
      return result as String?;
    } catch (e) {
      debugPrint('[AgendaSharingDS] getUserIdByEmail error: $e');
      return null;
    }
  }

  Future<void> createShare({
    required String ownerId,
    required String sharedWithId,
    required String ownerEmail,
    required String sharedWithEmail,
  }) async {
    await _client.from('agenda_shares').insert({
      'owner_id': ownerId,
      'shared_with_id': sharedWithId,
      'owner_email': ownerEmail,
      'shared_with_email': sharedWithEmail,
    });
    debugPrint('[AgendaSharingDS] share created: $ownerEmail -> $sharedWithEmail');
  }

  Future<void> deleteShare(String id) async {
    final uid = _userId;
    if (uid == null) throw StateError('Usuario nao autenticado');

    await _client.from('agenda_shares').delete().eq('id', id).eq('owner_id', uid);
    debugPrint('[AgendaSharingDS] share revoked $id');
  }

  Future<List<AgendaShare>> getSharesByMe() async {
    final uid = _userId;
    if (uid == null) return [];

    final rows = await _client
        .from('agenda_shares')
        .select()
        .eq('owner_id', uid)
        .order('created_at', ascending: false);

    return (rows as List)
        .map((r) => _rowToShare(Map<String, dynamic>.from(r)))
        .toList();
  }

  Future<List<AgendaShare>> getSharesWithMe() async {
    final uid = _userId;
    if (uid == null) return [];

    final rows = await _client
        .from('agenda_shares')
        .select()
        .eq('shared_with_id', uid)
        .order('created_at', ascending: false);

    return (rows as List)
        .map((r) => _rowToShare(Map<String, dynamic>.from(r)))
        .toList();
  }

  AgendaShare _rowToShare(Map<String, dynamic> r) {
    return AgendaShare(
      id: r['id'] as String,
      ownerId: r['owner_id'] as String,
      sharedWithId: r['shared_with_id'] as String,
      ownerEmail: r['owner_email'] as String,
      sharedWithEmail: r['shared_with_email'] as String,
      createdAt: DateTime.parse(r['created_at'] as String),
    );
  }
}

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/family.dart';

/// Acesso as tabelas e RPCs da Familia. As regras (papeis, limite de membros,
/// Pro do dono) sao aplicadas no banco; aqui so traduzimos chamadas.
class FamilySupabaseDataSource {
  FamilySupabaseDataSource(this._client);

  final SupabaseClient _client;

  String? get currentUserId => _client.auth.currentUser?.id;

  Future<FamilyContext> getContext() async {
    final rows = await _client.rpc('get_my_family_context') as List;
    if (rows.isEmpty) return FamilyContext.empty;
    return FamilyContext.fromJson(Map<String, dynamic>.from(rows.first as Map));
  }

  Future<List<FamilyMember>> getMembers(String familyId) async {
    final family = await _client
        .from('families')
        .select('owner_id')
        .eq('id', familyId)
        .single();
    final ownerId = family['owner_id'] as String;

    final rows = List<Map<String, dynamic>>.from(
      await _client
          .from('family_members')
          .select('user_id, role, nickname, joined_at')
          .eq('family_id', familyId)
          .order('joined_at'),
    );
    if (rows.isEmpty) return const [];

    final ids = rows.map((r) => r['user_id'] as String).toList();
    final profiles = List<Map<String, dynamic>>.from(
      await _client
          .from('profiles')
          .select('id, display_name')
          .inFilter('id', ids),
    );
    final names = {
      for (final p in profiles) p['id'] as String: p['display_name'] as String?,
    };

    return rows
        .map(
          (r) => FamilyMember.fromJson({
            ...r,
            'display_name': names[r['user_id']],
            'is_owner': r['user_id'] == ownerId,
          }),
        )
        .toList();
  }

  Future<List<FamilyChild>> getChildren(String familyId) async {
    final rows = await _client
        .from('family_children')
        .select()
        .eq('family_id', familyId)
        .order('created_at');
    return List<Map<String, dynamic>>.from(
      rows,
    ).map(FamilyChild.fromJson).toList();
  }

  /// Convites pendentes da Familia (visiveis para administradores).
  Future<List<FamilyInvite>> getFamilyInvites(String familyId) async {
    final rows = await _client
        .from('family_invites')
        .select('id, family_id, email, role, created_at, expires_at')
        .eq('family_id', familyId)
        .eq('status', 'pending')
        .gt('expires_at', DateTime.now().toUtc().toIso8601String())
        .order('created_at');
    return List<Map<String, dynamic>>.from(rows)
        .map(
          (r) => FamilyInvite(
            id: r['id'] as String,
            familyId: r['family_id'] as String,
            email: r['email'] as String,
            role: familyRoleFromName(r['role'] as String?),
            createdAt: DateTime.parse(r['created_at'] as String),
            expiresAt: DateTime.parse(r['expires_at'] as String),
          ),
        )
        .toList();
  }

  /// Convites recebidos pelo usuario logado.
  Future<List<FamilyInvite>> getMyInvites() async {
    final rows = await _client.rpc('list_my_family_invites') as List;
    return parseMyInvites(rows);
  }

  /// Resposta de list_my_family_invites -> convites.
  static List<FamilyInvite> parseMyInvites(List rows) {
    return rows
        .map((raw) => Map<String, dynamic>.from(raw as Map))
        .map((r) => FamilyInvite(
              id: r['invite_id'] as String,
              familyId: r['family_id'] as String,
              familyName: r['family_name'] as String?,
              invitedByName: r['invited_by_name'] as String?,
              role: familyRoleFromName(r['role'] as String?),
              createdAt: DateTime.parse(r['created_at'] as String),
              expiresAt: DateTime.parse(r['expires_at'] as String),
            ))
        .toList();
  }

  Future<String> createFamily(String name, {String? nickname}) async {
    final id = await _client.rpc(
      'create_family',
      params: {'p_name': name, 'p_nickname': nickname},
    );
    return id as String;
  }

  Future<void> renameFamily(String familyId, String name) async {
    await _client.from('families').update({'name': name}).eq('id', familyId);
  }

  Future<void> deleteFamily(String familyId) async {
    await _client.rpc('delete_family', params: {'p_family': familyId});
  }

  Future<void> invite(String familyId, String email, FamilyRole role) async {
    await _client.rpc(
      'invite_family_member',
      params: {'p_family': familyId, 'p_email': email, 'p_role': role.name},
    );
  }

  Future<void> revokeInvite(String inviteId) async {
    await _client.rpc('revoke_family_invite', params: {'p_invite': inviteId});
  }

  Future<String> acceptInvite(String inviteId, {String? nickname}) async {
    final id = await _client.rpc(
      'accept_family_invite',
      params: {'p_invite': inviteId, 'p_nickname': nickname},
    );
    return id as String;
  }

  Future<void> declineInvite(String inviteId) async {
    await _client.rpc('decline_family_invite', params: {'p_invite': inviteId});
  }

  Future<void> changeRole(
    String familyId,
    String userId,
    FamilyRole role,
  ) async {
    await _client.rpc(
      'change_family_member_role',
      params: {'p_family': familyId, 'p_user': userId, 'p_role': role.name},
    );
  }

  Future<void> removeMember(String familyId, String userId) async {
    await _client.rpc(
      'remove_family_member',
      params: {'p_family': familyId, 'p_user': userId},
    );
  }

  Future<void> leave(String familyId) async {
    await _client.rpc('leave_family', params: {'p_family': familyId});
  }

  Future<void> updateMyNickname(String familyId, String? nickname) async {
    final uid = currentUserId;
    if (uid == null) throw StateError('Usuario nao autenticado');
    await _client
        .from('family_members')
        .update({'nickname': nickname})
        .eq('family_id', familyId)
        .eq('user_id', uid);
  }

  Future<FamilyChild> saveChild(
    FamilyChild child, {
    required bool isNew,
  }) async {
    final payload = Map<String, dynamic>.from(child.toJson())
      ..remove('archived_at');
    final row = isNew
        ? await _client
              .from('family_children')
              .insert(payload)
              .select()
              .single()
        : await _client
              .from('family_children')
              .update(
                payload
                  ..remove('id')
                  ..remove('family_id'),
              )
              .eq('id', child.id)
              .select()
              .single();
    return FamilyChild.fromJson(row);
  }

  Future<void> setChildArchived(String childId, bool archived) async {
    await _client
        .from('family_children')
        .update({
          'archived_at': archived
              ? DateTime.now().toUtc().toIso8601String()
              : null,
        })
        .eq('id', childId);
  }

  /// Canal Realtime com as mudancas de membros, filhos e da propria Familia.
  RealtimeChannel subscribeFamily(String familyId, void Function() onChange) {
    final channel = _client.channel('family-meta-$familyId');
    for (final table in ['family_members', 'family_children']) {
      channel.onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: table,
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'family_id',
          value: familyId,
        ),
        callback: (_) => onChange(),
      );
    }
    channel.onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: 'public',
      table: 'families',
      filter: PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: 'id',
        value: familyId,
      ),
      callback: (_) => onChange(),
    );
    return channel.subscribe();
  }

  Future<void> unsubscribe(RealtimeChannel channel) async {
    await _client.removeChannel(channel);
  }
}

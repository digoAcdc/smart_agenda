import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/agenda_group.dart';
import '../models/supabase_mappers.dart';

/// Data source para grupos no Supabase (plano premium).
class GroupsSupabaseDataSource {
  GroupsSupabaseDataSource(this._client);

  final SupabaseClient _client;

  String? get _userId => _client.auth.currentUser?.id;

  Future<void> create(AgendaGroup group) async {
    final uid = _userId;
    if (uid == null) throw StateError('Usuario nao autenticado');

    await _client.from('agenda_groups').insert(groupToSupabase(group, uid));
    debugPrint('[GroupsSupabaseDS] create ${group.id}');
  }

  Future<void> update(AgendaGroup group) async {
    final uid = _userId;
    if (uid == null) throw StateError('Usuario nao autenticado');

    await _client.from('agenda_groups').upsert(
          groupToSupabase(group, uid),
          onConflict: 'id',
        );
    debugPrint('[GroupsSupabaseDS] update ${group.id}');
  }

  Future<void> deleteSoft(String groupId, DateTime deletedAt) async {
    final uid = _userId;
    if (uid == null) throw StateError('Usuario nao autenticado');

    await _client.from('agenda_groups').update({
      'deleted_at': deletedAt.toIso8601String(),
      'updated_at': deletedAt.toIso8601String(),
    }).eq('id', groupId).eq('user_id', uid);
    debugPrint('[GroupsSupabaseDS] deleteSoft $groupId');
  }

  Future<List<AgendaGroup>> getAll() async {
    final uid = _userId;
    if (uid == null) return [];

    final rows = await _client
        .from('agenda_groups')
        .select()
        .eq('user_id', uid)
        .isFilter('deleted_at', null)
        .order('name');

    if (rows.isEmpty) return [];
    return rows.map((r) => groupFromSupabase(Map<String, dynamic>.from(r))).toList();
  }
}

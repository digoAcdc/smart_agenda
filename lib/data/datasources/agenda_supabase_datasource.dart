import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/agenda_group.dart';
import '../../domain/entities/agenda_item.dart';
import '../models/supabase_mappers.dart';

/// Escopo de sincronizacao: agenda pessoal do usuario ou agenda de uma Familia.
class SyncScope {
  const SyncScope.personal(String this.userId) : familyId = null;
  const SyncScope.family(String this.familyId) : userId = null;

  final String? userId;
  final String? familyId;

  bool get isFamily => familyId != null;
  String get key => isFamily ? 'family_$familyId' : 'personal_$userId';
}

class RemoteChanges<T> {
  const RemoteChanges(this.rows, this.maxUpdatedAt);

  final List<T> rows;

  /// Maior updated_at (texto do servidor) visto: proximo cursor.
  final String? maxUpdatedAt;
}

/// Data source da agenda no Supabase. Le e grava respeitando a RLS:
/// itens pessoais (owner_user_id) e itens da Familia (family_id).
class AgendaSupabaseDataSource {
  AgendaSupabaseDataSource(this._client);

  final SupabaseClient _client;

  static const _pageSize = 500;

  String? get currentUserId => _client.auth.currentUser?.id;

  String _requireUid() {
    final uid = currentUserId;
    if (uid == null) throw StateError('Usuario nao autenticado');
    return uid;
  }

  Future<void> upsertItem(AgendaItem item) async {
    final uid = _requireUid();
    await _client
        .from('agenda_items')
        .upsert(agendaItemToSupabase(item, uid), onConflict: 'id');

    await _client.from('attachments').delete().eq('item_id', item.id);
    final remoteAttachments = item.attachments
        .where((a) => a.remoteUrl != null)
        .toList();
    if (remoteAttachments.isNotEmpty) {
      await _client
          .from('attachments')
          .insert(remoteAttachments.map(attachmentToSupabase).toList());
    }
    debugPrint('[AgendaSupabaseDS] upsert ${item.id}');
  }

  Future<AgendaItem?> fetchItem(String id) async {
    final row = await _client
        .from('agenda_items')
        .select()
        .eq('id', id)
        .maybeSingle();
    if (row == null) return null;
    final atts = await _client.from('attachments').select().eq('item_id', id);
    return agendaItemFromSupabase(
      Map<String, dynamic>.from(row),
      List<Map<String, dynamic>>.from(atts),
    );
  }

  /// Itens alterados depois de [since] (inclui excluidos logicamente).
  Future<RemoteChanges<AgendaItem>> fetchItemChanges(
    SyncScope scope, {
    String? since,
  }) async {
    final rows = <Map<String, dynamic>>[];
    String? cursor = since;
    while (true) {
      var q = _client.from('agenda_items').select();
      q = scope.isFamily
          ? q.eq('family_id', scope.familyId!)
          : q.eq('owner_user_id', scope.userId!);
      if (cursor != null) q = q.gt('updated_at', cursor);
      final page = List<Map<String, dynamic>>.from(
        await q.order('updated_at').limit(_pageSize),
      );
      rows.addAll(page);
      if (page.length < _pageSize) break;
      cursor = page.last['updated_at'] as String;
    }
    if (rows.isEmpty) return RemoteChanges(const [], since);

    final ids = rows.map((r) => r['id'] as String).toList();
    final atts = <Map<String, dynamic>>[];
    for (var i = 0; i < ids.length; i += 100) {
      final chunk = ids.sublist(i, i + 100 > ids.length ? ids.length : i + 100);
      atts.addAll(
        List<Map<String, dynamic>>.from(
          await _client.from('attachments').select().inFilter('item_id', chunk),
        ),
      );
    }

    final items = rows
        .map(
          (r) => agendaItemFromSupabase(
            r,
            atts.where((a) => a['item_id'] == r['id']).toList(),
          ),
        )
        .toList();
    return RemoteChanges(items, rows.last['updated_at'] as String);
  }

  Future<void> upsertGroup(AgendaGroup group) async {
    final uid = _requireUid();
    await _client
        .from('agenda_groups')
        .upsert(groupToSupabase(group, uid), onConflict: 'id');
  }

  Future<RemoteChanges<AgendaGroup>> fetchGroupChanges(
    SyncScope scope, {
    String? since,
  }) async {
    var q = _client.from('agenda_groups').select();
    q = scope.isFamily
        ? q.eq('family_id', scope.familyId!)
        : q.eq('owner_user_id', scope.userId!);
    if (since != null) q = q.gt('updated_at', since);
    final rows = List<Map<String, dynamic>>.from(await q.order('updated_at'));
    if (rows.isEmpty) return RemoteChanges(const [], since);
    return RemoteChanges(
      rows.map(groupFromSupabase).toList(),
      rows.last['updated_at'] as String,
    );
  }

  /// Grade de um filho: upsert (exclusao logica via deleted_at).
  Future<void> upsertFamilySlot(Map<String, dynamic> row) async {
    await _client.from('class_schedule_slots').upsert(row, onConflict: 'id');
  }

  Future<RemoteChanges<Map<String, dynamic>>> fetchFamilySlotChanges(
    String familyId, {
    String? since,
  }) async {
    var q = _client
        .from('class_schedule_slots')
        .select()
        .eq('family_id', familyId);
    if (since != null) q = q.gt('updated_at', since);
    final rows = List<Map<String, dynamic>>.from(await q.order('updated_at'));
    if (rows.isEmpty) return RemoteChanges(const [], since);
    return RemoteChanges(rows, rows.last['updated_at'] as String);
  }
}

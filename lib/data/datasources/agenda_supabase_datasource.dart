import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/agenda_item.dart';
import '../models/supabase_mappers.dart';

/// Data source para agenda no Supabase (plano premium).
class AgendaSupabaseDataSource {
  AgendaSupabaseDataSource(this._client);

  final SupabaseClient _client;

  String? get _userId => _client.auth.currentUser?.id;

  Future<void> createItem(AgendaItem item) async {
    final uid = _userId;
    if (uid == null) throw StateError('Usuario nao autenticado');

    await _client.from('agenda_items').insert(
          agendaItemToSupabase(item, uid),
        );

    if (item.attachments.isNotEmpty) {
      await _client.from('attachments').insert(
            item.attachments
                .map((a) => attachmentToSupabase(a, uid))
                .toList(),
          );
    }
    debugPrint('[AgendaSupabaseDS] createItem ${item.id}');
  }

  Future<void> updateItem(AgendaItem item) async {
    final uid = _userId;
    if (uid == null) throw StateError('Usuario nao autenticado');

    await _client.from('agenda_items').upsert(
          agendaItemToSupabase(item, uid),
          onConflict: 'id',
        );

    await _client.from('attachments').delete().eq('item_id', item.id);
    if (item.attachments.isNotEmpty) {
      await _client.from('attachments').insert(
            item.attachments
                .map((a) => attachmentToSupabase(a, uid))
                .toList(),
          );
    }
    debugPrint('[AgendaSupabaseDS] updateItem ${item.id}');
  }

  Future<void> deleteItemSoft(String id, DateTime deletedAt) async {
    final uid = _userId;
    if (uid == null) throw StateError('Usuario nao autenticado');

    await _client.from('agenda_items').update({
      'deleted_at': deletedAt.toIso8601String(),
      'updated_at': deletedAt.toIso8601String(),
    }).eq('id', id).eq('user_id', uid);
    debugPrint('[AgendaSupabaseDS] deleteItemSoft $id');
  }

  Future<AgendaItem?> getById(String id) async {
    final uid = _userId;
    if (uid == null) return null;

    final rows = await _client
        .from('agenda_items')
        .select()
        .eq('id', id)
        .eq('user_id', uid)
        .isFilter('deleted_at', null);

    if (rows.isEmpty) return null;
    final row = rows.first;

    final attRows = await _client
        .from('attachments')
        .select()
        .eq('item_id', id)
        .eq('user_id', uid);
    final attList = List<Map<String, dynamic>>.from(attRows);

    return agendaItemFromSupabase(
      Map<String, dynamic>.from(row),
      attList,
    );
  }

  /// Itens compartilhados comigo (somente leitura, com ownerEmail).
  Future<List<AgendaItem>> getSharedByRange(
    DateTime start,
    DateTime end,
    Map<String, String> ownerIdToEmail,
  ) async {
    final uid = _userId;
    if (uid == null || ownerIdToEmail.isEmpty) return [];

    final ownerIds = ownerIdToEmail.keys.toList();
    final rows = await _client
        .from('agenda_items')
        .select()
        .inFilter('user_id', ownerIds)
        .gte('start_at', start.toIso8601String())
        .lte('start_at', end.toIso8601String())
        .isFilter('deleted_at', null)
        .order('start_at');

    if (rows.isEmpty) return [];
    final items = rows.map((r) => Map<String, dynamic>.from(r)).toList();
    return _joinAttachmentsWithOwnerEmail(items, ownerIdToEmail);
  }

  Future<AgendaItem?> getSharedById(
    String id,
    Map<String, String> ownerIdToEmail,
  ) async {
    if (ownerIdToEmail.isEmpty) return null;

    final rows = await _client
        .from('agenda_items')
        .select()
        .eq('id', id)
        .inFilter('user_id', ownerIdToEmail.keys.toList())
        .isFilter('deleted_at', null);

    if (rows.isEmpty) return null;
    final row = Map<String, dynamic>.from(rows.first);
    final ownerId = row['user_id'] as String?;
    final ownerEmail = ownerId != null ? ownerIdToEmail[ownerId] : null;

    final attRows = await _client
        .from('attachments')
        .select()
        .eq('item_id', id)
        .inFilter('user_id', ownerIdToEmail.keys.toList());
    final attList = List<Map<String, dynamic>>.from(attRows);

    return agendaItemFromSupabase(row, attList, ownerEmail: ownerEmail);
  }

  Future<List<AgendaItem>> searchShared(
    String query, {
    DateTime? start,
    DateTime? end,
    String? groupId,
    String? status,
    required Map<String, String> ownerIdToEmail,
  }) async {
    if (ownerIdToEmail.isEmpty) return [];

    var q = _client
        .from('agenda_items')
        .select()
        .inFilter('user_id', ownerIdToEmail.keys.toList())
        .isFilter('deleted_at', null);

    if (query.isNotEmpty) {
      final pattern = '%$query%';
      q = q.or('title.ilike.$pattern,description.ilike.$pattern');
    }
    if (start != null && end != null) {
      q = q
          .gte('start_at', start.toIso8601String())
          .lte('start_at', end.toIso8601String());
    }
    if (groupId != null && groupId.isNotEmpty) {
      q = q.eq('group_id', groupId);
    }
    if (status != null && status.isNotEmpty) {
      q = q.eq('status', status);
    }

    final rows = await q.order('start_at');
    if (rows.isEmpty) return [];
    return _joinAttachmentsWithOwnerEmail(
      List<Map<String, dynamic>>.from(rows),
      ownerIdToEmail,
    );
  }

  Future<List<AgendaItem>> _joinAttachmentsWithOwnerEmail(
    List<Map<String, dynamic>> items,
    Map<String, String> ownerIdToEmail,
  ) async {
    if (items.isEmpty) return [];
    final itemIds = items.map((e) => e['id'] as String).toList();
    final ownerIds = ownerIdToEmail.keys.toList();

    final attRows = await _client
        .from('attachments')
        .select()
        .inFilter('user_id', ownerIds)
        .inFilter('item_id', itemIds);
    final attList =
        (attRows as List).map((e) => Map<String, dynamic>.from(e)).toList();

    return items.map((row) {
      final ownerId = row['user_id'] as String?;
      final ownerEmail = ownerId != null ? ownerIdToEmail[ownerId] : null;
      final itemAtts =
          attList.where((a) => a['item_id'] == row['id']).toList();
      return agendaItemFromSupabase(row, itemAtts, ownerEmail: ownerEmail);
    }).toList();
  }

  Future<List<AgendaItem>> getByRange(DateTime start, DateTime end) async {
    final uid = _userId;
    if (uid == null) return [];

    final rows = await _client
        .from('agenda_items')
        .select()
        .eq('user_id', uid)
        .gte('start_at', start.toIso8601String())
        .lte('start_at', end.toIso8601String())
        .isFilter('deleted_at', null)
        .order('start_at');

    if (rows.isEmpty) return [];
    return _joinAttachments(
      rows.map((r) => Map<String, dynamic>.from(r)).toList(),
      uid,
    );
  }

  Future<List<AgendaItem>> search(
    String query, {
    DateTime? start,
    DateTime? end,
    String? groupId,
    String? status,
  }) async {
    final uid = _userId;
    if (uid == null) return [];

    var q = _client
        .from('agenda_items')
        .select()
        .eq('user_id', uid)
        .isFilter('deleted_at', null);

    if (query.isNotEmpty) {
      final pattern = '%$query%';
      q = q.or('title.ilike.$pattern,description.ilike.$pattern');
    }
    if (start != null && end != null) {
      q = q
          .gte('start_at', start.toIso8601String())
          .lte('start_at', end.toIso8601String());
    }
    if (groupId != null && groupId.isNotEmpty) {
      q = q.eq('group_id', groupId);
    }
    if (status != null && status.isNotEmpty) {
      q = q.eq('status', status);
    }

    final rows = await q.order('start_at');
    if (rows.isEmpty) return [];
    return _joinAttachments(List<Map<String, dynamic>>.from(rows), uid);
  }

  Future<void> setStatus(String id, String status, DateTime updatedAt) async {
    final uid = _userId;
    if (uid == null) return;

    await _client.from('agenda_items').update({
      'status': status,
      'updated_at': updatedAt.toIso8601String(),
    }).eq('id', id).eq('user_id', uid);
  }

  Future<List<AgendaItem>> _joinAttachments(
    List<Map<String, dynamic>> items,
    String uid,
  ) async {
    if (items.isEmpty) return [];
    final itemIds = items.map((e) => e['id'] as String).toList();

    final attRows = await _client
        .from('attachments')
        .select()
        .eq('user_id', uid)
        .inFilter('item_id', itemIds);
    final attList =
        (attRows as List).map((e) => Map<String, dynamic>.from(e)).toList();

    return items.map((row) {
      final itemAtts =
          attList.where((a) => a['item_id'] == row['id']).toList();
      return agendaItemFromSupabase(row, itemAtts);
    }).toList();
  }
}

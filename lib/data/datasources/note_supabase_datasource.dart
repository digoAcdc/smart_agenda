import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/note.dart';

/// Data source para anotacoes no Supabase (plano premium).
class NoteSupabaseDataSource {
  NoteSupabaseDataSource(this._client);

  final SupabaseClient _client;

  String? get _userId => _client.auth.currentUser?.id;

  Future<void> upsertNote(Note note) async {
    final uid = _userId;
    if (uid == null) throw StateError('Usuario nao autenticado');

    await _client.from('notes').upsert(
          _noteToSupabase(note, uid),
          onConflict: 'id',
        );
    debugPrint('[NoteSupabaseDS] upsert note ${note.id}');
  }

  Future<void> upsertChecklistItems(String noteId, List<ChecklistItem> items) async {
    final uid = _userId;
    if (uid == null) throw StateError('Usuario nao autenticado');

    if (items.isEmpty) return;

    await _client.from('note_checklist_items').delete().eq('note_id', noteId);

    for (final item in items) {
      await _client.from('note_checklist_items').insert({
        'id': item.id,
        'user_id': uid,
        'note_id': noteId,
        'text': item.text,
        'completed': item.completed,
        'sort_order': item.sortOrder,
        'created_at': item.createdAt.toIso8601String(),
        'updated_at': item.updatedAt.toIso8601String(),
      });
    }
    debugPrint('[NoteSupabaseDS] upsert ${items.length} checklist items for note $noteId');
  }

  Future<void> deleteNote(String id) async {
    final uid = _userId;
    if (uid == null) throw StateError('Usuario nao autenticado');

    await _client.from('note_checklist_items').delete().eq('note_id', id).eq('user_id', uid);
    await _client.from('notes').delete().eq('id', id).eq('user_id', uid);
    debugPrint('[NoteSupabaseDS] delete note $id');
  }

  /// Remove todas as notas e itens do usuario (para full replace no sync).
  Future<void> deleteAllForUser(String userId) async {
    await _client.from('note_checklist_items').delete().eq('user_id', userId);
    await _client.from('notes').delete().eq('user_id', userId);
    debugPrint('[NoteSupabaseDS] deleteAllForUser $userId');
  }

  Future<List<Note>> getNotes(String userId) async {
    final rows = await _client
        .from('notes')
        .select()
        .eq('user_id', userId)
        .order('updated_at', ascending: false);

    if (rows.isEmpty) return [];

    final notes = <Note>[];
    for (final r in rows) {
      final row = Map<String, dynamic>.from(r);
      final itemsRows = await _client
          .from('note_checklist_items')
          .select()
          .eq('note_id', row['id'] as String)
          .order('sort_order');
      final items = (itemsRows as List)
          .map((x) => _checklistItemFromSupabase(Map<String, dynamic>.from(x)))
          .toList();
      notes.add(_noteFromSupabase(row, items));
    }
    return notes;
  }

  Map<String, dynamic> _noteToSupabase(Note note, String uid) {
    return {
      'id': note.id,
      'user_id': uid,
      'title': note.title,
      'body': note.body,
      'image_url': note.imageUrl,
      'category_id': note.categoryId,
      'is_pinned': note.isPinned,
      'reminder_at': note.reminderAt?.toIso8601String(),
      'created_at': note.createdAt.toIso8601String(),
      'updated_at': note.updatedAt.toIso8601String(),
    };
  }

  Note _noteFromSupabase(Map<String, dynamic> row, List<ChecklistItem> items) {
    return Note(
      id: row['id'] as String,
      title: row['title'] as String,
      body: row['body'] as String?,
      checklistItems: items,
      imagePath: null,
      imageUrl: row['image_url'] as String?,
      categoryId: row['category_id'] as String?,
      isPinned: row['is_pinned'] as bool? ?? false,
      reminderAt: row['reminder_at'] == null
          ? null
          : DateTime.parse(row['reminder_at'] as String),
      createdAt: DateTime.parse(row['created_at'] as String),
      updatedAt: DateTime.parse(row['updated_at'] as String),
    );
  }

  ChecklistItem _checklistItemFromSupabase(Map<String, dynamic> row) {
    return ChecklistItem(
      id: row['id'] as String,
      noteId: row['note_id'] as String,
      text: row['text'] as String,
      completed: row['completed'] as bool? ?? false,
      sortOrder: row['sort_order'] as int? ?? 0,
      createdAt: DateTime.parse(row['created_at'] as String),
      updatedAt: DateTime.parse(row['updated_at'] as String),
    );
  }
}

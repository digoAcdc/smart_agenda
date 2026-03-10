import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../domain/entities/note.dart';
import '../local/app_database.dart';

class NoteLocalDataSource {
  NoteLocalDataSource(this._db);

  final AppDatabase _db;

  Future<List<Note>> getNotes() async {
    final rows = await (_db.select(_db.notesTable)
          ..orderBy([
            (t) => OrderingTerm.desc(t.isPinned),
            (t) => OrderingTerm.desc(t.updatedAt),
          ]))
        .get();
    final notes = <Note>[];
    for (final row in rows) {
      final items = await getChecklistItems(row.id);
      notes.add(_toNote(row, items));
    }
    return notes;
  }

  Future<Note?> getNoteById(String id) async {
    final row = await (_db.select(_db.notesTable)
          ..where((t) => t.id.equals(id)))
        .getSingleOrNull();
    if (row == null) return null;
    final items = await getChecklistItems(row.id);
    return _toNote(row, items);
  }

  Future<Note> createNote(Note note) async {
    final now = DateTime.now();
    final id = note.id.isEmpty ? const Uuid().v4() : note.id;
    await _db.into(_db.notesTable).insert(
          NotesTableCompanion.insert(
            id: id,
            title: note.title.trim(),
            body: Value(note.body?.trim()),
            imagePath: Value(note.imagePath),
            imageUrl: Value(note.imageUrl),
            categoryId: Value(note.categoryId),
            isPinned: Value(note.isPinned),
            reminderAt: Value(note.reminderAt),
            createdAt: now,
            updatedAt: now,
          ),
        );
    for (var i = 0; i < note.checklistItems.length; i++) {
      final item = note.checklistItems[i];
      await _upsertChecklistItem(
        ChecklistItem(
          id: item.id.isEmpty ? const Uuid().v4() : item.id,
          noteId: id,
          text: item.text,
          completed: item.completed,
          sortOrder: i,
          createdAt: now,
          updatedAt: now,
        ),
      );
    }
    return (await getNoteById(id))!;
  }

  Future<void> updateNote(Note note) async {
    final now = DateTime.now();
    await (_db.update(_db.notesTable)..where((t) => t.id.equals(note.id)))
        .write(
      NotesTableCompanion(
        title: Value(note.title.trim()),
        body: Value(note.body?.trim()),
        imagePath: Value(note.imagePath),
        imageUrl: Value(note.imageUrl),
        categoryId: Value(note.categoryId),
        isPinned: Value(note.isPinned),
        reminderAt: Value(note.reminderAt),
        updatedAt: Value(now),
      ),
    );
    await (_db.delete(_db.noteChecklistItemsTable)
          ..where((t) => t.noteId.equals(note.id)))
        .go();
    for (var i = 0; i < note.checklistItems.length; i++) {
      final item = note.checklistItems[i];
      await _upsertChecklistItem(
        item.copyWith(
          noteId: note.id,
          sortOrder: i,
          updatedAt: now,
          createdAt: item.createdAt,
        ),
      );
    }
  }

  Future<void> deleteNote(String id) async {
    await (_db.delete(_db.noteChecklistItemsTable)
          ..where((t) => t.noteId.equals(id)))
        .go();
    await (_db.delete(_db.notesTable)..where((t) => t.id.equals(id))).go();
  }

  Future<List<ChecklistItem>> getChecklistItems(String noteId) async {
    final rows = await (_db.select(_db.noteChecklistItemsTable)
          ..where((t) => t.noteId.equals(noteId))
          ..orderBy([(t) => OrderingTerm.asc(t.sortOrder)]))
        .get();
    return rows.map(_toChecklistItem).toList();
  }

  Future<void> toggleChecklistItem(String itemId, bool completed) async {
    final now = DateTime.now();
    await (_db.update(_db.noteChecklistItemsTable)
          ..where((t) => t.id.equals(itemId)))
        .write(
      NoteChecklistItemsTableCompanion(
        completed: Value(completed),
        updatedAt: Value(now),
      ),
    );
  }

  Future<void> upsertChecklistItem(ChecklistItem item) async {
    await _upsertChecklistItem(item);
  }

  Future<void> _upsertChecklistItem(ChecklistItem item) async {
    final now = DateTime.now();
    final id = item.id.isEmpty ? const Uuid().v4() : item.id;
    await _db.into(_db.noteChecklistItemsTable).insert(
          NoteChecklistItemsTableCompanion.insert(
            id: id,
            noteId: item.noteId,
            itemText: item.text,
            completed: Value(item.completed),
            sortOrder: Value(item.sortOrder),
            createdAt: item.createdAt,
            updatedAt: now,
          ),
        );
  }

  Future<void> deleteChecklistItem(String id) async {
    await (_db.delete(_db.noteChecklistItemsTable)
          ..where((t) => t.id.equals(id)))
        .go();
  }

  Note _toNote(NotesTableData row, List<ChecklistItem> items) {
    return Note(
      id: row.id,
      title: row.title,
      body: row.body,
      checklistItems: items,
      imagePath: row.imagePath,
      imageUrl: row.imageUrl,
      categoryId: row.categoryId,
      isPinned: row.isPinned,
      reminderAt: row.reminderAt,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
    );
  }

  ChecklistItem _toChecklistItem(NoteChecklistItemsTableData row) {
    return ChecklistItem(
      id: row.id,
      noteId: row.noteId,
      text: row.itemText,
      completed: row.completed,
      sortOrder: row.sortOrder,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
    );
  }
}

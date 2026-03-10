import '../entities/note.dart';

abstract class INoteRepository {
  Future<List<Note>> getNotes();
  Future<Note?> getNoteById(String id);
  Future<Note> createNote(Note note);
  Future<void> updateNote(Note note);
  Future<void> deleteNote(String id);
  Future<void> toggleChecklistItem(String itemId, bool completed);
}

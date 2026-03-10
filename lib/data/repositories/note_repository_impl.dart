import '../../domain/entities/note.dart';
import '../../domain/repositories/i_note_repository.dart';
import '../../domain/repositories/i_sync_service.dart';
import '../datasources/note_local_datasource.dart';

class NoteRepositoryImpl implements INoteRepository {
  NoteRepositoryImpl(this._dataSource, this._syncService);

  final NoteLocalDataSource _dataSource;
  final ISyncService _syncService;

  void _scheduleSync() => _syncService.syncNow();

  @override
  Future<List<Note>> getNotes() => _dataSource.getNotes();

  @override
  Future<Note?> getNoteById(String id) => _dataSource.getNoteById(id);

  @override
  Future<Note> createNote(Note note) async {
    final created = await _dataSource.createNote(note);
    _scheduleSync();
    return created;
  }

  @override
  Future<void> updateNote(Note note) async {
    await _dataSource.updateNote(note);
    _scheduleSync();
  }

  @override
  Future<void> deleteNote(String id) async {
    await _dataSource.deleteNote(id);
    _scheduleSync();
  }

  @override
  Future<void> toggleChecklistItem(String itemId, bool completed) async {
    await _dataSource.toggleChecklistItem(itemId, completed);
    _scheduleSync();
  }
}

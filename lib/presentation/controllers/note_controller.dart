import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:uuid/uuid.dart';

import '../../domain/entities/note.dart';
import '../../domain/repositories/i_note_repository.dart';

class NoteController extends GetxController {
  NoteController(this._repository);

  final INoteRepository _repository;

  final RxList<Note> notes = <Note>[].obs;
  final RxBool loading = false.obs;

  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addPostFrameCallback((_) => loadNotes());
  }

  Future<void> loadNotes() async {
    loading.value = true;
    try {
      notes.assignAll(await _repository.getNotes());
    } finally {
      loading.value = false;
    }
  }

  Future<Note?> getNoteById(String id) async {
    return _repository.getNoteById(id);
  }

  Future<Note> createNote(Note note) async {
    final id = note.id.isEmpty ? const Uuid().v4() : note.id;
    final toCreate = note.copyWith(id: id);
    final created = await _repository.createNote(toCreate);
    await loadNotes();
    return created;
  }

  Future<void> updateNote(Note note) async {
    await _repository.updateNote(note);
    await loadNotes();
  }

  Future<void> deleteNote(String id) async {
    await _repository.deleteNote(id);
    await loadNotes();
  }

  Future<void> toggleChecklistItem(String itemId, bool completed) async {
    await _repository.toggleChecklistItem(itemId, completed);
    await loadNotes();
  }
}

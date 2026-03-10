import 'package:equatable/equatable.dart';

/// Item de checklist dentro de uma anotacao.
class ChecklistItem extends Equatable {
  const ChecklistItem({
    required this.id,
    required this.noteId,
    required this.text,
    this.completed = false,
    this.sortOrder = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String noteId;
  final String text;
  final bool completed;
  final int sortOrder;
  final DateTime createdAt;
  final DateTime updatedAt;

  ChecklistItem copyWith({
    String? id,
    String? noteId,
    String? text,
    bool? completed,
    int? sortOrder,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ChecklistItem(
      id: id ?? this.id,
      noteId: noteId ?? this.noteId,
      text: text ?? this.text,
      completed: completed ?? this.completed,
      sortOrder: sortOrder ?? this.sortOrder,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props =>
      [id, noteId, text, completed, sortOrder, createdAt, updatedAt];
}

/// Anotacao com titulo, texto livre, checklist e imagem opcional.
class Note extends Equatable {
  const Note({
    required this.id,
    required this.title,
    this.body,
    this.checklistItems = const [],
    this.imagePath,
    this.imageUrl,
    this.categoryId,
    this.isPinned = false,
    this.reminderAt,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String title;
  final String? body;
  final List<ChecklistItem> checklistItems;
  final String? imagePath;
  final String? imageUrl;
  final String? categoryId;
  final bool isPinned;
  final DateTime? reminderAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  Note copyWith({
    String? id,
    String? title,
    String? body,
    List<ChecklistItem>? checklistItems,
    String? imagePath,
    String? imageUrl,
    String? categoryId,
    bool? isPinned,
    DateTime? reminderAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Note(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      checklistItems: checklistItems ?? this.checklistItems,
      imagePath: imagePath ?? this.imagePath,
      imageUrl: imageUrl ?? this.imageUrl,
      categoryId: categoryId ?? this.categoryId,
      isPinned: isPinned ?? this.isPinned,
      reminderAt: reminderAt ?? this.reminderAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        title,
        body,
        checklistItems,
        imagePath,
        imageUrl,
        categoryId,
        isPinned,
        reminderAt,
        createdAt,
        updatedAt,
      ];
}

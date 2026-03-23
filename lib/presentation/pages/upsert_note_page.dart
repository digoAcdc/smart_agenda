import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

import '../../core/theme/design_tokens.dart';
import '../../core/utils/account_prompt_utils.dart';
import '../../core/utils/form_validators.dart';
import '../../domain/entities/note.dart';
import '../../domain/repositories/i_file_storage_service.dart';
import '../../domain/repositories/i_plan_service.dart';
import '../controllers/note_controller.dart';
import '../widgets/checklist_item_tile.dart';

class UpsertNotePage extends StatefulWidget {
  const UpsertNotePage({super.key});

  @override
  State<UpsertNotePage> createState() => _UpsertNotePageState();
}

class _UpsertNotePageState extends State<UpsertNotePage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  final _newItemController = TextEditingController();
  final _imagePicker = ImagePicker();

  Note? _editingNote;
  List<ChecklistItem> _checklistItems = [];
  String? _imagePath;
  String? _imageUrl;
  bool _isPremium = false;

  @override
  void initState() {
    super.initState();
    final arg = Get.arguments;
    if (arg is Note) {
      _editingNote = arg;
      _titleController.text = arg.title;
      _bodyController.text = arg.body ?? '';
      _checklistItems = [...arg.checklistItems];
      _imagePath = arg.imagePath;
      _imageUrl = arg.imageUrl;
    }
    _loadPlanStatus();
  }

  Future<void> _loadPlanStatus() async {
    final plan = Get.find<IPlanService>();
    await plan.refresh();
    final isPremium = await plan.isPremium();
    if (!mounted) return;
    setState(() => _isPremium = isPremium);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    _newItemController.dispose();
    super.dispose();
  }

  Future<void> _addImage() async {
    if (!_isPremium) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Upload de imagem e uma funcionalidade Premium.')),
      );
      return;
    }
    final picked = await _imagePicker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;
    final fileStorage = Get.find<IFileStorageService>();
    final result = await fileStorage.copyImageToAppStorage(picked.path);
    if (!result.isSuccess || result.data == null) return;
    setState(() {
      final pathOrUrl = result.data!;
      final isUrl =
          pathOrUrl.startsWith('http://') || pathOrUrl.startsWith('https://');
      if (isUrl) {
        _imageUrl = pathOrUrl;
        _imagePath = null;
      } else {
        _imagePath = pathOrUrl;
        _imageUrl = null;
      }
    });
  }

  void _removeImage() {
    setState(() {
      _imagePath = null;
      _imageUrl = null;
    });
  }

  void _addChecklistItem() {
    final text = _newItemController.text.trim();
    if (text.isEmpty) return;
    final noteId = _editingNote?.id ?? const Uuid().v4();
    final now = DateTime.now();
    setState(() {
      _checklistItems.add(
        ChecklistItem(
          id: const Uuid().v4(),
          noteId: noteId,
          text: text,
          completed: false,
          sortOrder: _checklistItems.length,
          createdAt: now,
          updatedAt: now,
        ),
      );
      _newItemController.clear();
    });
  }

  void _removeChecklistItem(int index) {
    setState(() => _checklistItems.removeAt(index));
  }

  void _updateChecklistItem(int index, ChecklistItem updated) {
    setState(() {
      _checklistItems[index] = updated;
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final canProceed = await AccountPromptUtils.confirmSaveWithoutAccount();
    if (!canProceed) return;

    final controller = Get.find<NoteController>();
    final now = DateTime.now();
    final noteId = _editingNote?.id ?? const Uuid().v4();

    final note = Note(
      id: noteId,
      title: _titleController.text.trim(),
      body: _bodyController.text.trim().isEmpty
          ? null
          : _bodyController.text.trim(),
      checklistItems: _checklistItems
          .asMap()
          .entries
          .map((e) => e.value.copyWith(sortOrder: e.key))
          .toList(),
      imagePath: _imagePath,
      imageUrl: _imageUrl,
      categoryId: _editingNote?.categoryId,
      isPinned: _editingNote?.isPinned ?? false,
      reminderAt: _editingNote?.reminderAt,
      createdAt: _editingNote?.createdAt ?? now,
      updatedAt: now,
    );

    if (_editingNote != null) {
      await controller.updateNote(note);
    } else {
      await controller.createNote(note);
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Anotacao salva')),
      );
      Get.back();
    }
  }

  Future<void> _delete() async {
    if (_editingNote == null) return;
    final ok = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Excluir anotacao?'),
        content: const Text(
          'Esta acao nao pode ser desfeita.',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Get.back(result: true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await Get.find<NoteController>().deleteNote(_editingNote!.id);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Anotacao excluida')),
      );
    }
    Get.back();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEditing = _editingNote != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Editar anotacao' : 'Nova anotacao'),
        actions: [
          TextButton(
            onPressed: _save,
            child: const Text('Salvar'),
          ),
          if (isEditing)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: _delete,
              tooltip: 'Excluir',
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(DesignTokens.spaceMd),
          children: [
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Titulo *',
                hintText: 'Ex: Ideias para o projeto',
              ),
              textCapitalization: TextCapitalization.sentences,
              validator: (v) => requiredValidator(v, 'Titulo e obrigatorio'),
            ),
            const SizedBox(height: DesignTokens.spaceMd),
            TextFormField(
              controller: _bodyController,
              decoration: const InputDecoration(
                labelText: 'Texto (opcional)',
                hintText: 'Escreva suas anotacoes aqui...',
                alignLabelWithHint: true,
              ),
              maxLines: 4,
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: DesignTokens.spaceLg),
            Text(
              'Checklist',
              style: theme.textTheme.titleSmall,
            ),
            const SizedBox(height: DesignTokens.spaceSm),
            ...List.generate(_checklistItems.length, (i) {
              final item = _checklistItems[i];
              return ChecklistItemTile(
                item: item,
                editable: true,
                onChanged: (completed) {
                  _updateChecklistItem(
                    i,
                    item.copyWith(completed: completed, updatedAt: DateTime.now()),
                  );
                },
                onRemove: () => _removeChecklistItem(i),
              );
            }),
            const SizedBox(height: DesignTokens.spaceSm),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _newItemController,
                    decoration: const InputDecoration(
                      hintText: 'Adicionar item',
                      isDense: true,
                    ),
                    textCapitalization: TextCapitalization.sentences,
                    onFieldSubmitted: (_) => _addChecklistItem(),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline),
                  onPressed: _addChecklistItem,
                  tooltip: 'Adicionar item',
                ),
              ],
            ),
            const SizedBox(height: DesignTokens.spaceLg),
            Text(
              'Imagem (opcional)',
              style: theme.textTheme.titleSmall,
            ),
            if (!_isPremium) ...[
              const SizedBox(height: DesignTokens.spaceXs),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: theme.colorScheme.outline.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.lock_outline,
                      size: 14,
                      color: theme.colorScheme.outline,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Premium',
                      style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.outline,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: DesignTokens.spaceSm),
            if (_imagePath != null || _imageUrl != null) ...[
              Stack(
                children: [
                  ClipRRect(
                    borderRadius:
                        BorderRadius.circular(DesignTokens.radiusMd),
                    child: _imagePath != null
                        ? Image.file(
                            File(_imagePath!),
                            height: 120,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          )
                        : Image.network(
                            _imageUrl!,
                            height: 120,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                _imagePlaceholder(),
                          ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: IconButton.filled(
                      icon: const Icon(Icons.close, size: 18),
                      onPressed: _removeImage,
                      style: IconButton.styleFrom(
                        backgroundColor: theme.colorScheme.error,
                        foregroundColor: theme.colorScheme.onError,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: DesignTokens.spaceSm),
            ],
            OutlinedButton.icon(
              onPressed: _isPremium ? _addImage : null,
              icon: const Icon(Icons.add_photo_alternate_outlined),
              label: const Text('Adicionar imagem'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _imagePlaceholder() {
    return Container(
      height: 120,
      width: double.infinity,
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Icon(
        Icons.image_not_supported_outlined,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
        size: 40,
      ),
    );
  }
}

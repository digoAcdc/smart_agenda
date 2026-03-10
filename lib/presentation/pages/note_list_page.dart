import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/routes/app_routes.dart';
import '../../domain/entities/note.dart';
import '../controllers/note_controller.dart';
import '../widgets/empty_state_widget.dart';
import '../widgets/loading_placeholder_list.dart';
import '../widgets/note_card.dart';
import '../widgets/section_header.dart';

class NoteListPage extends GetView<NoteController> {
  const NoteListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Anotacoes'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _openUpsert(context),
            tooltip: 'Nova anotacao',
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        bottom: false,
        child: Obx(() {
          if (controller.loading.value && controller.notes.isEmpty) {
            return const LoadingPlaceholderList();
          }
          if (controller.notes.isEmpty) {
            return EmptyStateWidget(
              icon: Icons.note_outlined,
              title: 'Nenhuma anotacao',
              message: 'Crie anotacoes rapidas com titulo, texto e checklist.',
              ctaLabel: 'Nova anotacao',
              onTapCta: () => _openUpsert(context),
            );
          }
          return Column(
            children: [
              const SectionHeader(
                title: 'Suas anotacoes',
                subtitle: 'Toque para editar',
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  itemCount: controller.notes.length,
                  itemBuilder: (context, index) {
                    final note = controller.notes[index];
                    return NoteCard(
                      note: note,
                      onTap: () => _openUpsert(context, note: note),
                      onDelete: () => _confirmDelete(note),
                    );
                  },
                ),
              ),
            ],
          );
        }),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openUpsert(context),
        icon: const Icon(Icons.add),
        label: const Text('Nova anotacao'),
      ),
    );
  }

  void _openUpsert(BuildContext context, {Note? note}) {
    Get.toNamed(AppRoutes.upsertNote, arguments: note);
  }

  Future<bool?> _confirmDelete(Note note) async {
    final ok = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Excluir anotacao?'),
        content: Text(
          'A anotacao "${note.title}" sera excluida. Esta acao nao pode ser desfeita.',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Get.back(result: true),
            style: FilledButton.styleFrom(
              backgroundColor: Get.theme.colorScheme.error,
            ),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await controller.deleteNote(note.id);
      if (Get.context != null) {
        ScaffoldMessenger.of(Get.context!).showSnackBar(
          const SnackBar(content: Text('Anotacao excluida')),
        );
      }
    }
    return ok;
  }
}

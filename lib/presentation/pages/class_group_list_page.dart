import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/routes/app_routes.dart';
import '../../core/theme/design_tokens.dart';
import '../../core/utils/form_validators.dart';
import '../../domain/entities/class_group.dart';
import '../controllers/class_group_controller.dart';
import '../widgets/empty_state_widget.dart';
import '../widgets/loading_placeholder_list.dart';
import '../widgets/section_header.dart';
import '../widgets/ui_primitives.dart';

class ClassGroupListPage extends GetView<ClassGroupController> {
  const ClassGroupListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Turmas'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _openGroupForm(context),
            tooltip: 'Nova turma',
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        bottom: false,
        child: Obx(() {
          if (controller.loading.value && controller.groups.isEmpty) {
            return const LoadingPlaceholderList();
          }
          if (controller.groups.isEmpty) {
            return EmptyStateWidget(
              icon: Icons.group_outlined,
              title: 'Nenhuma turma ainda',
              message:
                  'Crie turmas como Minha sala, Trabalho de ingles e adicione contatos.',
              ctaLabel: 'Criar turma',
              onTapCta: () => _openGroupForm(context),
            );
          }
          return Column(
            children: [
              const SectionHeader(
                title: 'Suas turmas',
                subtitle: 'Toque para ver contatos e gerenciar',
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  itemCount: controller.groups.length,
                  itemBuilder: (context, index) {
                    final group = controller.groups[index];
                    return _GroupCard(
                      group: group,
                      onTap: () => Get.toNamed(
                        AppRoutes.classGroupDetail,
                        arguments: group,
                      ),
                      onEdit: () => _openGroupForm(context, group: group),
                      onDelete: () => _confirmDelete(context, group),
                    );
                  },
                ),
              ),
            ],
          );
        }),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openGroupForm(context),
        icon: const Icon(Icons.add),
        label: const Text('Nova turma'),
      ),
    );
  }

  Future<void> _openGroupForm(BuildContext context, {ClassGroup? group}) async {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: group?.name ?? '');
    final descController = TextEditingController(text: group?.description ?? '');

    await Get.dialog(
      AlertDialog(
        title: Text(group == null ? 'Nova turma' : 'Editar turma'),
        content: SingleChildScrollView(
          child: Form(
            key: formKey,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Nome da turma *',
                    hintText: 'Ex: Minha sala, Trabalho de ingles',
                  ),
                  autofocus: true,
                  textCapitalization: TextCapitalization.sentences,
                  validator: (v) => requiredValidator(v, 'Nome e obrigatorio'),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: descController,
                  decoration: const InputDecoration(
                    labelText: 'Descricao (opcional)',
                    hintText: 'Ex: Turma do 3o ano',
                  ),
                  maxLines: 2,
                  textCapitalization: TextCapitalization.sentences,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: Get.back, child: const Text('Cancelar')),
          FilledButton(
            onPressed: () async {
              if (formKey.currentState?.validate() != true) return;
              final name = nameController.text.trim();
              if (group == null) {
                final created = await controller.createGroup(name,
                    description: descController.text.trim().isEmpty
                        ? null
                        : descController.text.trim());
                Get.back();
                Get.toNamed(
                  AppRoutes.classGroupDetail,
                  arguments: {'group': created, 'isNew': true},
                );
              } else {
                await controller.updateGroup(group.copyWith(
                  name: name,
                  description: descController.text.trim().isEmpty
                      ? null
                      : descController.text.trim(),
                  updatedAt: DateTime.now(),
                ));
                Get.back();
              }
            },
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, ClassGroup group) async {
    final ok = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Excluir turma'),
        content: Text(
          'Excluir "${group.name}"? Todos os contatos serao removidos.',
        ),
        actions: [
          TextButton(onPressed: () => Get.back(result: false), child: const Text('Cancelar')),
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
    if (ok == true) {
      await controller.deleteGroup(group.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Turma excluida')),
        );
      }
    }
  }
}

class _GroupCard extends StatelessWidget {
  const _GroupCard({
    required this.group,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  final ClassGroup group;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final color = DesignTokens.groupPalette[
        group.name.hashCode.abs() % DesignTokens.groupPalette.length];
    return AppSurfaceCard(
      margin: const EdgeInsets.only(bottom: DesignTokens.spaceXs),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
        child: Padding(
          padding: const EdgeInsets.all(DesignTokens.spaceMd),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: color.withValues(alpha: 0.22),
                child: Text(
                  group.name.characters.first.toUpperCase(),
                  style: TextStyle(color: color, fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(width: DesignTokens.spaceMd),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      group.name,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    if (group.description?.isNotEmpty == true) ...[
                      const SizedBox(height: 4),
                      Text(
                        group.description!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              PopupMenuButton<String>(
                onSelected: (v) {
                  if (v == 'edit') onEdit();
                  if (v == 'delete') onDelete();
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'edit', child: Text('Editar')),
                  PopupMenuItem(value: 'delete', child: Text('Excluir')),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

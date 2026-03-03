import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/groups_controller.dart';
import '../widgets/empty_state_widget.dart';
import '../widgets/section_header.dart';

class GroupsPage extends StatelessWidget {
  const GroupsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<GroupsController>();
    return Scaffold(
      appBar: AppBar(title: const Text('Gerenciar grupos')),
      body: Obx(
        () {
          if (controller.groups.isEmpty) {
            return EmptyStateWidget(
              icon: Icons.category_outlined,
              title: 'Sem grupos ainda',
              message: 'Crie grupos para organizar melhor seus eventos.',
              ctaLabel: 'Criar grupo',
              onTapCta: () => _openCreateDialog(context, controller),
            );
          }
          return Column(
            children: [
              const SectionHeader(
                title: 'Seus grupos',
                subtitle: 'Organize eventos por contexto ou projeto',
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: controller.groups.length,
                  itemBuilder: (context, index) {
                    final group = controller.groups[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 6),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        leading: CircleAvatar(
                          backgroundColor:
                              Theme.of(context).colorScheme.primaryContainer,
                          child:
                              Text(group.name.characters.first.toUpperCase()),
                        ),
                        title: Text(group.name),
                        subtitle: Text(group.colorHex ?? 'Cor padrao'),
                        trailing: PopupMenuButton<String>(
                          onSelected: (value) async {
                            if (value == 'delete') {
                              await controller.delete(group.id);
                            }
                            if (value == 'edit') {
                              final textController =
                                  TextEditingController(text: group.name);
                              await Get.dialog(
                                AlertDialog(
                                  title: const Text('Editar grupo'),
                                  content:
                                      TextField(controller: textController),
                                  actions: [
                                    TextButton(
                                        onPressed: Get.back,
                                        child: const Text('Cancelar')),
                                    FilledButton(
                                      onPressed: () async {
                                        await controller.updateGroup(
                                            group, textController.text);
                                        Get.back();
                                      },
                                      child: const Text('Salvar'),
                                    ),
                                  ],
                                ),
                              );
                            }
                          },
                          itemBuilder: (context) => const [
                            PopupMenuItem(value: 'edit', child: Text('Editar')),
                            PopupMenuItem(
                                value: 'delete', child: Text('Excluir')),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openCreateDialog(context, controller),
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _openCreateDialog(
      BuildContext context, GroupsController controller) async {
    final textController = TextEditingController();
    await Get.dialog(
      AlertDialog(
        title: const Text('Novo grupo'),
        content: TextField(controller: textController),
        actions: [
          TextButton(onPressed: Get.back, child: const Text('Cancelar')),
          FilledButton(
            onPressed: () async {
              await controller.create(textController.text);
              Get.back();
            },
            child: const Text('Criar'),
          ),
        ],
      ),
    );
  }
}

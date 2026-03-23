import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/theme/design_tokens.dart';
import '../../core/utils/account_prompt_utils.dart';
import '../../core/utils/form_validators.dart';
import '../controllers/groups_controller.dart';
import '../widgets/empty_state_widget.dart';
import '../widgets/section_header.dart';
import '../widgets/ui_primitives.dart';

class GroupsPage extends StatelessWidget {
  const GroupsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<GroupsController>();
    return Scaffold(
      appBar: AppBar(title: const Text('Gerenciar grupos')),
      body: SafeArea(
        top: false,
        bottom: false,
        child: Obx(
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
                      final avatarColor =
                          _resolveGroupColor(group.colorHex, index, context);
                      return AppSurfaceCard(
                        child: ListTile(
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        leading: CircleAvatar(
                          backgroundColor: avatarColor.withValues(alpha: 0.22),
                          child:
                              Text(
                            group.name.characters.first.toUpperCase(),
                            style: TextStyle(
                              color: avatarColor,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        title: Text(group.name),
                        trailing: PopupMenuButton<String>(
                          onSelected: (value) async {
                            if (value == 'delete') {
                              await controller.delete(group.id);
                            }
                            if (value == 'edit') {
                              final formKey = GlobalKey<FormState>();
                              final textController =
                                  TextEditingController(text: group.name);
                              await Get.dialog(
                                AlertDialog(
                                  title: const Text('Editar grupo'),
                                  content: Form(
                                    key: formKey,
                                    autovalidateMode: AutovalidateMode.onUserInteraction,
                                    child: TextFormField(
                                      controller: textController,
                                      decoration: const InputDecoration(
                                        labelText: 'Nome do grupo',
                                      ),
                                      validator: (v) =>
                                          requiredValidator(v, 'Nome e obrigatorio'),
                                    ),
                                  ),
                                  actions: [
                                    TextButton(
                                        onPressed: Get.back,
                                        child: const Text('Cancelar')),
                                    FilledButton(
                                      onPressed: () async {
                                        if (formKey.currentState?.validate() != true) return;
                                        final canProceed =
                                            await AccountPromptUtils.confirmSaveWithoutAccount();
                                        if (!canProceed) return;
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
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
          child: FilledButton.icon(
            onPressed: () => _openCreateDialog(context, controller),
            icon: const Icon(Icons.add),
            label: const Text('Novo grupo'),
          ),
        ),
      ),
    );
  }

  Future<void> _openCreateDialog(
      BuildContext context, GroupsController controller) async {
    final formKey = GlobalKey<FormState>();
    final textController = TextEditingController();
    await Get.dialog(
      AlertDialog(
        title: const Text('Novo grupo'),
        content: Form(
          key: formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: TextFormField(
            controller: textController,
            decoration: const InputDecoration(
              labelText: 'Nome do grupo',
              hintText: 'Ex: Trabalho, Pessoal',
            ),
            autofocus: true,
            validator: (v) => requiredValidator(v, 'Nome e obrigatorio'),
          ),
        ),
        actions: [
          TextButton(onPressed: Get.back, child: const Text('Cancelar')),
          FilledButton(
            onPressed: () async {
              if (formKey.currentState?.validate() != true) return;
              final canProceed = await AccountPromptUtils.confirmSaveWithoutAccount();
              if (!canProceed) return;
              await controller.create(textController.text);
              Get.back();
            },
            child: const Text('Criar'),
          ),
        ],
      ),
    );
  }

  Color _resolveGroupColor(String? colorHex, int index, BuildContext context) {
    if (colorHex != null && colorHex.isNotEmpty) {
      final sanitized = colorHex.replaceAll('#', '');
      final normalized =
          sanitized.length == 6 ? 'FF$sanitized' : sanitized.padLeft(8, 'F');
      final value = int.tryParse(normalized, radix: 16);
      if (value != null) return Color(value);
    }

    return DesignTokens.groupPalette[index % DesignTokens.groupPalette.length];
  }
}

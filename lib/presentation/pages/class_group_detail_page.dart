import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/design_tokens.dart';
import '../../core/utils/form_validators.dart';
import '../../domain/entities/class_group.dart';
import '../../domain/entities/student.dart';
import '../controllers/class_group_controller.dart';
import '../widgets/empty_state_widget.dart';
import '../widgets/loading_placeholder_list.dart';
import '../widgets/ui_primitives.dart';

class ClassGroupDetailPage extends StatefulWidget {
  const ClassGroupDetailPage({super.key});

  @override
  State<ClassGroupDetailPage> createState() => _ClassGroupDetailPageState();
}

class _ClassGroupDetailPageState extends State<ClassGroupDetailPage> {
  late final ClassGroup group;
  late final bool _isNew;

  @override
  void initState() {
    super.initState();
    final args = Get.arguments;
    if (args is Map) {
      group = args['group'] as ClassGroup;
      _isNew = args['isNew'] as bool? ?? false;
    } else {
      group = args as ClassGroup;
      _isNew = false;
    }
    final controller = Get.find<ClassGroupController>();
    controller.setSelectedGroup(group);
    if (_isNew) {
      controller.students.clear();
      controller.loading.value = false;
    } else {
      controller.loadStudents(group.id);
    }
  }

  @override
  void dispose() {
    Get.find<ClassGroupController>().setSelectedGroup(null);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<ClassGroupController>();
    return Scaffold(
      appBar: AppBar(
        title: Text(group.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => _openGroupForm(context, controller),
            tooltip: 'Editar turma',
          ),
          PopupMenuButton<String>(
            onSelected: (v) async {
              if (v == 'delete') {
                final ok = await Get.dialog<bool>(
                  AlertDialog(
                    title: const Text('Excluir turma'),
                    content: Text(
                      'Excluir "${group.name}"? Todos os contatos serao removidos.',
                    ),
                    actions: [
                      TextButton(
                          onPressed: () => Get.back(result: false),
                          child: const Text('Cancelar')),
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
                  Get.back();
                }
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'delete', child: Text('Excluir turma')),
            ],
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        bottom: false,
        child: Obx(() {
          if (controller.loading.value && controller.students.isEmpty) {
            return const LoadingPlaceholderList();
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (group.description?.isNotEmpty == true)
                Padding(
                  padding: const EdgeInsets.all(DesignTokens.spaceMd),
                  child: Text(
                    group.description!,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurfaceVariant,
                        ),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: DesignTokens.spaceMd),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Contatos (${controller.students.length})',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    TextButton.icon(
                      onPressed: () => _openStudentForm(context, controller),
                      icon: const Icon(Icons.person_add, size: 20),
                      label: const Text('Adicionar'),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: controller.students.isEmpty
                    ? EmptyStateWidget(
                        icon: Icons.person_outline,
                        title: 'Nenhum contato',
                        message: 'Adicione contatos a esta turma.',
                        ctaLabel: 'Adicionar contato',
                        onTapCta: () => _openStudentForm(context, controller),
                        compact: true,
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                        itemCount: controller.students.length,
                        itemBuilder: (context, index) {
                          final student = controller.students[index];
                          return _StudentCard(
                            student: student,
                            onTap: () => _openStudentForm(context, controller,
                                student: student),
                            onDelete: () => _confirmDeleteStudent(
                                context, controller, student),
                          );
                        },
                      ),
              ),
            ],
          );
        }),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openStudentForm(context, controller),
        icon: const Icon(Icons.person_add),
        label: const Text('Adicionar contato'),
      ),
    );
  }

  Future<void> _openGroupForm(
      BuildContext context, ClassGroupController controller) async {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: group.name);
    final descController =
        TextEditingController(text: group.description ?? '');

    await Get.dialog(
      AlertDialog(
        title: const Text('Editar turma'),
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
                  ),
                  textCapitalization: TextCapitalization.sentences,
                  validator: (v) => requiredValidator(v, 'Nome e obrigatorio'),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: descController,
                  decoration: const InputDecoration(
                    labelText: 'Descricao (opcional)',
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
              await controller.updateGroup(group.copyWith(
                name: name,
                description: descController.text.trim().isEmpty
                    ? null
                    : descController.text.trim(),
                updatedAt: DateTime.now(),
              ));
              Get.back();
            },
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
  }

  Future<void> _openStudentForm(BuildContext context,
      ClassGroupController controller, {Student? student}) async {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: student?.name ?? '');
    final emailController = TextEditingController(text: student?.email ?? '');
    final phoneController = TextEditingController(
      text: formatPhoneForDisplay(student?.phone),
    );
    final guardianNameController =
        TextEditingController(text: student?.guardianName ?? '');
    final guardianEmailController =
        TextEditingController(text: student?.guardianEmail ?? '');
    final guardianPhoneController = TextEditingController(
      text: formatPhoneForDisplay(student?.guardianPhone),
    );

    await Get.dialog(
      AlertDialog(
        title: Text(student == null ? 'Novo contato' : 'Editar contato'),
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
                    labelText: 'Nome do contato *',
                    hintText: 'Ex: Maria Silva',
                  ),
                  autofocus: true,
                  textCapitalization: TextCapitalization.words,
                  validator: (v) =>
                      requiredValidator(v, 'Nome do contato e obrigatorio'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email (opcional)',
                    hintText: 'aluno@email.com',
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) => emailValidator(v),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: phoneController,
                  decoration: const InputDecoration(
                    labelText: 'Telefone (opcional)',
                    hintText: '(11) 99999-9999',
                  ),
                  keyboardType: TextInputType.phone,
                  inputFormatters: phoneInputFormatters,
                  validator: (v) => phoneValidator(v),
                ),
                const SizedBox(height: 20),
                Text(
                  'Responsavel (opcional)',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: guardianNameController,
                  decoration: const InputDecoration(
                    labelText: 'Nome do responsavel',
                  ),
                  textCapitalization: TextCapitalization.words,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: guardianEmailController,
                  decoration: const InputDecoration(
                    labelText: 'Email do responsavel',
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) => emailValidator(v),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: guardianPhoneController,
                  decoration: const InputDecoration(
                    labelText: 'Telefone do responsavel',
                  ),
                  keyboardType: TextInputType.phone,
                  inputFormatters: phoneInputFormatters,
                  validator: (v) => phoneValidator(v),
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
              final email = emailController.text.trim();
              final phone = unmaskPhone(phoneController.text);
              final guardianName = guardianNameController.text.trim();
              final guardianEmail = guardianEmailController.text.trim();
              final guardianPhone =
                  unmaskPhone(guardianPhoneController.text);
              final now = DateTime.now();
              if (student == null) {
                await controller.createStudent(Student(
                  id: '',
                  groupId: group.id,
                  name: name,
                  email: email.isEmpty ? null : email,
                  phone: phone.isEmpty ? null : phone,
                  guardianName: guardianName.isEmpty ? null : guardianName,
                  guardianEmail: guardianEmail.isEmpty ? null : guardianEmail,
                  guardianPhone: guardianPhone.isEmpty ? null : guardianPhone,
                  createdAt: now,
                  updatedAt: now,
                ));
              } else {
                await controller.updateStudent(student.copyWith(
                  name: name,
                  email: email.isEmpty ? null : email,
                  phone: phone.isEmpty ? null : phone,
                  guardianName: guardianName.isEmpty ? null : guardianName,
                  guardianEmail: guardianEmail.isEmpty ? null : guardianEmail,
                  guardianPhone: guardianPhone.isEmpty ? null : guardianPhone,
                  updatedAt: now,
                ));
              }
              Get.back();
            },
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDeleteStudent(BuildContext context,
      ClassGroupController controller, Student student) async {
    final ok = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Excluir contato'),
        content: Text('Excluir "${student.name}"?'),
        actions: [
          TextButton(
              onPressed: () => Get.back(result: false),
              child: const Text('Cancelar')),
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
      await controller.deleteStudent(student);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Contato excluido')),
        );
      }
    }
  }
}

class _StudentCard extends StatelessWidget {
  const _StudentCard({
    required this.student,
    required this.onTap,
    required this.onDelete,
  });

  final Student student;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return AppSurfaceCard(
      margin: const EdgeInsets.only(bottom: DesignTokens.spaceXs),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
        child: Padding(
          padding: const EdgeInsets.all(DesignTokens.spaceMd),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Theme.of(context)
                        .colorScheme
                        .primaryContainer
                        .withValues(alpha: 0.5),
                    child: Text(
                      student.name.characters.first.toUpperCase(),
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: DesignTokens.spaceMd),
                  Expanded(
                    child: Text(
                      student.name,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  PopupMenuButton<String>(
                    onSelected: (v) {
                      if (v == 'delete') onDelete();
                      if (v == 'call' && student.phone != null) {
                        _launchTel(student.phone!);
                      }
                      if (v == 'whatsapp' && student.phone != null) {
                        _launchWhatsApp(student.phone!);
                      }
                      if (v == 'email' && student.email != null) {
                        _launchMailto(student.email!);
                      }
                      if (v == 'guardian_call' &&
                          student.guardianPhone != null) {
                        _launchTel(student.guardianPhone!);
                      }
                      if (v == 'guardian_whatsapp' &&
                          student.guardianPhone != null) {
                        _launchWhatsApp(student.guardianPhone!);
                      }
                    },
                    itemBuilder: (_) {
                      final items = <PopupMenuItem<String>>[
                        const PopupMenuItem(
                            value: 'delete', child: Text('Excluir')),
                      ];
                      if (student.phone != null) {
                        items.add(const PopupMenuItem(
                            value: 'call', child: Text('Ligar')));
                        items.add(const PopupMenuItem(
                            value: 'whatsapp', child: Text('WhatsApp')));
                      }
                      if (student.email != null) {
                        items.add(const PopupMenuItem(
                            value: 'email', child: Text('Email')));
                      }
                      if (student.guardianPhone != null) {
                        items.add(const PopupMenuItem(
                            value: 'guardian_call',
                            child: Text('Ligar responsavel')));
                        items.add(const PopupMenuItem(
                            value: 'guardian_whatsapp',
                            child: Text('WhatsApp responsavel')));
                      }
                      return items;
                    },
                  ),
                ],
              ),
              if (student.email?.isNotEmpty == true ||
                  student.phone?.isNotEmpty == true ||
                  student.guardianName?.isNotEmpty == true) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 12,
                  runSpacing: 4,
                  children: [
                    if (student.email?.isNotEmpty == true)
                      _ContactChip(
                        icon: Icons.email_outlined,
                        label: student.email!,
                        onTap: () => _launchMailto(student.email!),
                      ),
                    if (student.phone?.isNotEmpty == true)
                      _ContactChip(
                        icon: Icons.phone_outlined,
                        label: formatPhoneForDisplay(student.phone),
                        onTap: () => _launchTel(student.phone!),
                      ),
                    if (student.guardianName?.isNotEmpty == true)
                      Text(
                        'Resp: ${student.guardianName}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _launchMailto(String email) async {
    final uri = Uri.parse('mailto:$email');
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  Future<void> _launchTel(String phone) async {
    final digits = phone.replaceAll(RegExp(r'\D'), '');
    final uri = Uri.parse('tel:$digits');
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  Future<void> _launchWhatsApp(String phone) async {
    final digits = phone.replaceAll(RegExp(r'\D'), '');
    final number = digits.length >= 12 ? digits : '55$digits';
    final uri = Uri.parse('https://wa.me/$number');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}

class _ContactChip extends StatelessWidget {
  const _ContactChip({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 4),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    decoration: TextDecoration.underline,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

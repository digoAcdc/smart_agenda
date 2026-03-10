import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../domain/entities/class_schedule_slot.dart';
import '../../core/theme/design_tokens.dart';
import '../controllers/class_schedule_controller.dart';
import '../widgets/empty_state_widget.dart';
import '../widgets/loading_placeholder_list.dart';
import '../widgets/section_header.dart';

class ClassSchedulePage extends GetView<ClassScheduleController> {
  const ClassSchedulePage({super.key});

  static const double _timeColWidth = 110;
  static const double _dayColWidth = 120;

  static const dayLabels = <int, String>{
    1: 'Segunda',
    2: 'Terca',
    3: 'Quarta',
    4: 'Quinta',
    5: 'Sexta',
  };

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return SafeArea(
      bottom: false,
      child: Container(
        color: palette.appBackground,
        child: Column(
          children: [
            SectionHeader(
              title: 'Grade horaria',
              subtitle: 'Monte sua semana de aulas por horario',
              trailing: IconButton(
                onPressed: () => _openAddTimeRangeDialog(context),
                icon: const Icon(Icons.add),
                tooltip: 'Adicionar horario',
              ),
            ),
            Expanded(
              child: Obx(() {
                if (controller.loading.value) {
                  return const LoadingPlaceholderList();
                }
                final ranges = controller.timeRanges;
                if (ranges.isEmpty) {
                  return EmptyStateWidget(
                    icon: Icons.view_week_outlined,
                    title: 'Sem grade ainda',
                    message:
                        'Adicione horarios e depois toque nas celulas para inserir materias.',
                    ctaLabel: 'Adicionar horario',
                    onTapCta: () => _openAddTimeRangeDialog(context),
                  );
                }

                return LayoutBuilder(
                  builder: (context, constraints) {
                    final compact = constraints.maxWidth < 420;
                    final minContentWidth = compact
                        ? (_timeColWidth +
                            (_dayColWidth *
                                ClassScheduleController.weekdays.length))
                        : constraints.maxWidth;
                    return SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(12, 6, 12, 120),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: ConstrainedBox(
                          constraints: BoxConstraints(minWidth: minContentWidth),
                          child: Column(
                            children: [
                              _buildHeaderRow(context),
                              const SizedBox(height: 8),
                              ...ranges.map((range) {
                                final start = range.start;
                                final end = range.end;
                                return _buildTimeRangeRow(context, start, end);
                              }),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderRow(BuildContext context) {
    final palette = context.palette;
    return Container(
      decoration: BoxDecoration(
        color: palette.scheduleHeader,
        borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      child: Row(
        children: [
          const SizedBox(
            width: _timeColWidth,
            child: Text(
              'Horario',
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          for (final day in ClassScheduleController.weekdays)
            SizedBox(
              width: _dayColWidth,
              child: Text(
                dayLabels[day] ?? '-',
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTimeRangeRow(BuildContext context, int start, int end) {
    final palette = context.palette;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      constraints: const BoxConstraints(minHeight: 86),
      decoration: BoxDecoration(
        color: palette.surfaceSoft,
        borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: _timeColWidth,
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
            decoration: BoxDecoration(
              color: palette.scheduleTimeColumn,
              borderRadius: const BorderRadius.horizontal(
                left: Radius.circular(14),
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  controller.formatMinutes(start),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                Text(
                  controller.formatMinutes(end),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 6),
                InkWell(
                  onTap: () => controller.removeTimeRange(start, end),
                  borderRadius: BorderRadius.circular(20),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    child: Icon(Icons.delete_outline, size: 16),
                  ),
                ),
              ],
            ),
          ),
          for (final day in ClassScheduleController.weekdays)
            SizedBox(
              width: _dayColWidth,
              child: Padding(
                padding: const EdgeInsets.all(6),
                child: _buildEditableCell(context, day, start, end),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEditableCell(BuildContext context, int day, int start, int end) {
    final palette = context.palette;
    final cell = controller.getCell(day, start, end);
    final subject = cell?.subject;
    return InkWell(
      onTap: () => _onCellTap(context, day, start, end, cell),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        constraints: const BoxConstraints(minWidth: 90, minHeight: 64),
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: subject == null || subject.isEmpty
              ? palette.scheduleCellEmpty
              : palette.scheduleCellFilled,
        ),
        child: Text(
          subject?.isNotEmpty == true ? subject! : '+ adicionar',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: subject?.isNotEmpty == true
                    ? FontWeight.w600
                    : FontWeight.w400,
              ),
        ),
      ),
    );
  }

  Future<void> _openAddTimeRangeDialog(BuildContext context) async {
    final startController = TextEditingController();
    final endController = TextEditingController();

    Future<void> pickTime(TextEditingController target) async {
      final now = TimeOfDay.now();
      final picked = await showTimePicker(context: context, initialTime: now);
      if (picked != null) {
        final h = picked.hour.toString().padLeft(2, '0');
        final m = picked.minute.toString().padLeft(2, '0');
        target.text = '$h:$m';
      }
    }

    await Get.dialog(
      AlertDialog(
        title: const Text('Adicionar horario'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: startController,
              readOnly: true,
              onTap: () => pickTime(startController),
              decoration: const InputDecoration(labelText: 'Inicio (HH:mm)'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: endController,
              readOnly: true,
              onTap: () => pickTime(endController),
              decoration: const InputDecoration(labelText: 'Fim (HH:mm)'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: Get.back, child: const Text('Cancelar')),
          FilledButton(
            onPressed: () async {
              final start = _parseTime(startController.text);
              final end = _parseTime(endController.text);
              if (start == null || end == null) return;
              final error = await controller.addTimeRange(start, end);
              if (error != null) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context)
                      .showSnackBar(SnackBar(content: Text(error)));
                }
                return;
              }
              Get.back();
            },
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
  }

  void _onCellTap(
    BuildContext context,
    int day,
    int start,
    int end,
    ClassScheduleSlot? cell,
  ) {
    if (cell == null) return;
    final hasContent = (cell.subject?.isNotEmpty ?? false) ||
        (cell.professorName?.isNotEmpty ?? false) ||
        (cell.professorEmail?.isNotEmpty ?? false) ||
        (cell.professorPhone?.isNotEmpty ?? false);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!context.mounted) return;
      if (hasContent) {
        _openSubjectViewDialog(context, day, cell);
      } else {
        _openSubjectEditDialog(context, day, cell);
      }
    });
  }

  Future<void> _openSubjectViewDialog(
    BuildContext context,
    int day,
    ClassScheduleSlot cell,
  ) async {
    final items = <Widget>[];
    if (cell.subject?.isNotEmpty == true) {
      items.add(_detailRow(label: 'Materia', value: cell.subject!));
    }
    if (cell.professorName?.isNotEmpty == true) {
      items.add(_detailRow(label: 'Professor', value: cell.professorName!));
    }
    if (cell.professorEmail?.isNotEmpty == true) {
      items.add(_emailRow(context, cell.professorEmail!));
    }
    if (cell.professorPhone?.isNotEmpty == true) {
      items.add(_phoneRow(context, cell.professorPhone!));
    }
    if (items.isEmpty) {
      items.add(const Text('Nenhum detalhe cadastrado.'));
    }

    await Get.dialog(
      AlertDialog(
        title: Text('${dayLabels[day] ?? 'Dia'} - ${controller.formatMinutes(cell.startMinutes)}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: items,
        ),
        actions: [
          TextButton(onPressed: Get.back, child: const Text('Fechar')),
          FilledButton(
            onPressed: () {
              Get.back();
              _openSubjectEditDialog(context, day, cell);
            },
            child: const Text('Editar'),
          ),
        ],
      ),
    );
  }

  static const String _novaMateriaValue = '__nova__';

  Future<void> _openSubjectEditDialog(
    BuildContext context,
    int day,
    ClassScheduleSlot cell,
  ) async {
    final existingSubjects = controller.existingSubjects;
    final currentSubject = cell.subject?.trim();
    final isExisting = currentSubject != null &&
        currentSubject.isNotEmpty &&
        existingSubjects.contains(currentSubject);

    String? dropdownValue = isExisting
        ? currentSubject
        : (currentSubject?.isNotEmpty == true ? _novaMateriaValue : null);

    final subjectController = TextEditingController(
      text: dropdownValue == _novaMateriaValue || !isExisting ? (cell.subject ?? '') : '',
    );
    final professorController =
        TextEditingController(text: cell.professorName ?? '');
    final emailController = TextEditingController(text: cell.professorEmail ?? '');
    final phoneController = TextEditingController(text: cell.professorPhone ?? '');

    void onDropdownChanged(String? value) {
      dropdownValue = value;
      if (value == null || value.isEmpty) {
        subjectController.text = '';
        professorController.text = '';
        emailController.text = '';
        phoneController.text = '';
      } else if (value == _novaMateriaValue) {
        subjectController.text = subjectController.text;
        professorController.text = '';
        emailController.text = '';
        phoneController.text = '';
      } else {
        final slot = controller.getSlotForSubject(value);
        subjectController.text = value;
        professorController.text = slot?.professorName ?? '';
        emailController.text = slot?.professorEmail ?? '';
        phoneController.text = slot?.professorPhone ?? '';
      }
    }

    await Get.dialog(
      AlertDialog(
        title: Text(dayLabels[day] ?? 'Dia'),
        content: SingleChildScrollView(
          child: StatefulBuilder(
            builder: (context, setState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  DropdownButtonFormField<String?>(
                    value: dropdownValue,
                    decoration: const InputDecoration(
                      labelText: 'Materia (opcional)',
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    items: [
                      const DropdownMenuItem<String?>(
                        value: null,
                        child: Text('Nenhuma'),
                      ),
                      ...existingSubjects.map(
                        (s) => DropdownMenuItem<String?>(value: s, child: Text(s)),
                      ),
                      const DropdownMenuItem<String?>(
                        value: _novaMateriaValue,
                        child: Text('+ Nova materia'),
                      ),
                    ],
                    onChanged: (v) {
                      setState(() => onDropdownChanged(v));
                    },
                  ),
                  if (dropdownValue == _novaMateriaValue) ...[
                    const SizedBox(height: 8),
                    TextField(
                      controller: subjectController,
                      decoration: const InputDecoration(
                        labelText: 'Nome da materia',
                        hintText: 'Ex: Matematica',
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                    ),
                  ],
                  const SizedBox(height: 10),
                  TextField(
                    controller: professorController,
                    decoration: const InputDecoration(
                      labelText: 'Professor (opcional)',
                      hintText: 'Ex: Joao Silva',
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Email (opcional)',
                      hintText: 'professor@email.com',
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'Telefone (opcional)',
                      hintText: '(11) 99999-9999',
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              await controller.updateSlotDetails(cell.id);
              Get.back();
            },
            child: const Text('Limpar'),
          ),
          TextButton(onPressed: Get.back, child: const Text('Cancelar')),
          FilledButton(
            onPressed: () async {
              final subject = dropdownValue == _novaMateriaValue
                  ? subjectController.text
                  : (dropdownValue ?? subjectController.text);
              await controller.updateSlotDetails(
                cell.id,
                subject: subject.trim().isEmpty ? null : subject.trim(),
                professorName: professorController.text,
                professorEmail: emailController.text,
                professorPhone: phoneController.text,
              );
              Get.back();
            },
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
  }

  Widget _detailRow({required String label, required String value}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 2),
          Text(value),
        ],
      ),
    );
  }

  Widget _emailRow(BuildContext context, String email) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Email',
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 2),
          MenuAnchor(
            builder: (context, controller, child) => InkWell(
              onTap: () => controller.isOpen ? controller.close() : controller.open(),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    email,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(Icons.arrow_drop_down, size: 18, color: Theme.of(context).colorScheme.primary),
                ],
              ),
            ),
            menuChildren: [
              MenuItemButton(
                onPressed: () => _launchMailto(email),
                leadingIcon: const Icon(Icons.email_outlined),
                child: const Text('Enviar email'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _phoneRow(BuildContext context, String phone) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Telefone',
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 2),
          MenuAnchor(
            builder: (context, controller, child) => InkWell(
              onTap: () => controller.isOpen ? controller.close() : controller.open(),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    phone,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(Icons.arrow_drop_down, size: 18, color: Theme.of(context).colorScheme.primary),
                ],
              ),
            ),
            menuChildren: [
              MenuItemButton(
                onPressed: () => _launchTel(phone),
                leadingIcon: const Icon(Icons.phone_outlined),
                child: const Text('Ligar'),
              ),
              MenuItemButton(
                onPressed: () => _launchWhatsApp(phone),
                leadingIcon: const Icon(Icons.chat_outlined),
                child: const Text('WhatsApp'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _launchMailto(String email) async {
    final uri = Uri.parse('mailto:$email');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _launchTel(String phone) async {
    final digits = phone.replaceAll(RegExp(r'\D'), '');
    final uri = Uri.parse('tel:$digits');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _launchWhatsApp(String phone) async {
    final digits = phone.replaceAll(RegExp(r'\D'), '');
    final number = digits.length >= 12 ? digits : '55$digits';
    final uri = Uri.parse('https://wa.me/$number');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  int? _parseTime(String raw) {
    final parts = raw.split(':');
    if (parts.length != 2) return null;
    final h = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    if (h == null || m == null) return null;
    if (h < 0 || h > 23 || m < 0 || m > 59) return null;
    return h * 60 + m;
  }
}

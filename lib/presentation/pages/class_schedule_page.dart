import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/design_tokens.dart';
import '../../core/utils/form_validators.dart';
import '../../domain/entities/class_schedule_slot.dart';
import '../../domain/entities/family.dart';
import '../../domain/repositories/i_family_service.dart';
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

  IFamilyService? get _family =>
      Get.isRegistered<IFamilyService>() ? Get.find<IFamilyService>() : null;

  /// Grade sem filho (pessoal) sempre editavel; com filho segue o papel na Familia.
  bool _canEditSchedule(ClassSchedule? schedule) {
    if (schedule == null || !schedule.isFamily) return true;
    final ctx = _family?.context;
    return ctx != null &&
        ctx.familyId == schedule.familyId &&
        ctx.canEditAgenda;
  }

  bool get _canEdit => _canEditSchedule(controller.selected.value);

  /// "Joao · Escola" para grade de filho; o nome para grade pessoal.
  String _scheduleLabel(ClassSchedule schedule) {
    final child = _family?.childById(schedule.childId)?.name;
    return child == null ? schedule.name : '$child · ${schedule.name}';
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return SafeArea(
      bottom: false,
      child: Container(
        color: palette.appBackground,
        child: Column(
          children: [
            Obx(() {
              final current = controller.selected.value;
              return SectionHeader(
                title: 'Grade horaria',
                subtitle: current == null
                    ? 'Monte a semana de aulas'
                    : _canEdit
                    ? _scheduleLabel(current)
                    : '${_scheduleLabel(current)} (somente leitura)',
                trailing: current == null || !_canEdit
                    ? null
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            onPressed: () => _openAddTimeRangeDialog(context),
                            icon: const Icon(Icons.add),
                            tooltip: 'Adicionar horario',
                          ),
                          PopupMenuButton<String>(
                            tooltip: 'Opcoes da grade',
                            onSelected: (v) => v == 'rename'
                                ? _openRenameDialog(context, current)
                                : _confirmDelete(context, current),
                            itemBuilder: (_) => const [
                              PopupMenuItem(
                                value: 'rename',
                                child: Text('Renomear grade'),
                              ),
                              PopupMenuItem(
                                value: 'delete',
                                child: Text('Excluir grade'),
                              ),
                            ],
                          ),
                        ],
                      ),
              );
            }),
            _buildScheduleSelector(context),
            Expanded(
              child: Obx(() {
                if (controller.loading.value) {
                  return const LoadingPlaceholderList();
                }
                if (controller.schedules.isEmpty) {
                  return EmptyStateWidget(
                    icon: Icons.view_week_outlined,
                    title: 'Nenhuma grade ainda',
                    message:
                        'Crie uma grade para voce ou para um filho. Ela ja vem com '
                        '6 materias de segunda a sexta; depois e so ajustar.',
                    ctaLabel: 'Criar grade',
                    onTapCta: () => _openNewScheduleDialog(context),
                  );
                }
                final ranges = controller.timeRanges;
                if (ranges.isEmpty) {
                  if (!_canEdit) {
                    return const EmptyStateWidget(
                      icon: Icons.view_week_outlined,
                      title: 'Sem grade ainda',
                      message: 'Esta grade ainda nao tem aulas.',
                    );
                  }
                  return SingleChildScrollView(
                    child: Column(
                      children: [
                        EmptyStateWidget(
                          icon: Icons.view_week_outlined,
                          title: 'Sem grade ainda',
                          message:
                              'Comece pela grade modelo: 6 aulas de segunda a sexta com '
                              'Matematica, Portugues, Ciencias, Historia, Geografia e Ingles. '
                              'Depois e so tocar para trocar materias e horarios.',
                          ctaLabel: 'Usar grade modelo',
                          onTapCta: controller.applyTemplate,
                        ),
                        TextButton(
                          onPressed: () => _openAddTimeRangeDialog(context),
                          child: const Text('Comecar do zero'),
                        ),
                      ],
                    ),
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
                          constraints: BoxConstraints(
                            minWidth: minContentWidth,
                          ),
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

  /// Uma etiqueta por grade + "Nova grade".
  Widget _buildScheduleSelector(BuildContext context) {
    return Obx(() {
      final list = controller.schedules.toList();
      final current = controller.selected.value;
      // Reage a mudancas de filhos (nomes/cores) na Familia.
      _family?.children;
      if (list.isEmpty) return const SizedBox.shrink();

      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
        child: Row(
          children: [
            for (final g in list)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(_scheduleLabel(g)),
                  selected: current?.id == g.id,
                  avatar: g.childId == null
                      ? null
                      : CircleAvatar(
                          radius: 6,
                          backgroundColor:
                              _parseHexColor(
                                _family?.childById(g.childId)?.colorHex,
                              ) ??
                              Theme.of(context).colorScheme.primary,
                        ),
                  onSelected: (_) => controller.select(g),
                ),
              ),
            ActionChip(
              avatar: const Icon(Icons.add, size: 16),
              label: const Text('Nova grade'),
              onPressed: () => _openNewScheduleDialog(context),
            ),
          ],
        ),
      );
    });
  }

  /// Nome, filho (opcional) e grade modelo.
  Future<void> _openNewScheduleDialog(BuildContext context) async {
    final family = _family;
    final ctx = family?.context;
    // Na Familia (podendo editar), toda grade nova e da Familia; filho opcional.
    final inFamily = ctx?.canEditAgenda ?? false;
    final kids = inFamily
        ? (family?.children ?? const <FamilyChild>[])
        : const <FamilyChild>[];
    final nameController = TextEditingController(
      text: controller.schedules.isEmpty ? 'Minha grade' : '',
    );
    String? childId;
    var withTemplate = true;
    final formKey = GlobalKey<FormState>();

    await Get.dialog(
      StatefulBuilder(
        builder: (dialogContext, setLocal) => AlertDialog(
          title: const Text('Nova grade'),
          scrollable: true,
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: nameController,
                  autofocus: nameController.text.isEmpty,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    labelText: 'Nome',
                    hintText: 'Ex.: Escola, Ingles, Cursinho',
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Informe um nome'
                      : null,
                ),
                if (kids.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    'Filho (opcional)',
                    style: Theme.of(dialogContext).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      ChoiceChip(
                        label: const Text('Nenhum'),
                        selected: childId == null,
                        onSelected: (_) => setLocal(() => childId = null),
                      ),
                      for (final c in kids)
                        ChoiceChip(
                          label: Text(c.name),
                          selected: childId == c.id,
                          avatar: CircleAvatar(
                            radius: 6,
                            backgroundColor:
                                _parseHexColor(c.colorHex) ??
                                Theme.of(dialogContext).colorScheme.primary,
                          ),
                          onSelected: (_) => setLocal(() {
                            childId = c.id;
                            if (nameController.text.trim().isEmpty ||
                                nameController.text == 'Minha grade') {
                              nameController.text = 'Escola';
                            }
                          }),
                        ),
                    ],
                  ),
                ],
                if (inFamily) ...[
                  const SizedBox(height: 6),
                  Text(
                    'A Familia ve e edita esta grade conforme o papel de cada um.',
                    style: Theme.of(dialogContext).textTheme.bodySmall,
                  ),
                ] else if (ctx?.hasFamily ?? false) ...[
                  const SizedBox(height: 6),
                  Text(
                    'A agenda da Familia esta so para consulta; esta grade ficara so para voce.',
                    style: Theme.of(dialogContext).textTheme.bodySmall,
                  ),
                ],
                const SizedBox(height: 8),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  value: withTemplate,
                  onChanged: (v) => setLocal(() => withTemplate = v ?? true),
                  title: const Text('Comecar com a grade modelo'),
                  subtitle: const Text('6 materias de segunda a sexta'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: Get.back, child: const Text('Cancelar')),
            FilledButton(
              onPressed: () async {
                if (formKey.currentState?.validate() != true) return;
                Get.back();
                await controller.createSchedule(
                  name: nameController.text,
                  familyId: inFamily ? ctx?.familyId : null,
                  childId: childId,
                  withTemplate: withTemplate,
                );
              },
              child: const Text('Criar'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openRenameDialog(BuildContext context, ClassSchedule g) async {
    final nameController = TextEditingController(text: g.name);
    await Get.dialog(
      AlertDialog(
        title: const Text('Renomear grade'),
        content: TextField(
          controller: nameController,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Nome'),
        ),
        actions: [
          TextButton(onPressed: Get.back, child: const Text('Cancelar')),
          FilledButton(
            onPressed: () async {
              if (nameController.text.trim().isEmpty) return;
              Get.back();
              await controller.renameSelected(nameController.text);
            },
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, ClassSchedule g) async {
    final ok = await Get.dialog<bool>(
      AlertDialog(
        title: Text('Excluir "${_scheduleLabel(g)}"?'),
        content: Text(
          g.isFamily
              ? 'A grade e as aulas saem para toda a Familia.'
              : 'A grade e as aulas serao apagadas.',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Get.back(result: true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
    if (ok == true) await controller.deleteSelected();
  }

  Color? _parseHexColor(String? hex) {
    if (hex == null || hex.isEmpty) return null;
    final h = hex.replaceFirst('#', '');
    final v = int.tryParse(h.length == 6 ? 'FF$h' : h, radix: 16);
    return v == null ? null : Color(v);
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
                InkWell(
                  onTap: _canEdit
                      ? () => _openEditTimeRangeDialog(context, start, end)
                      : null,
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Column(
                      children: [
                        Text(
                          controller.formatMinutes(start),
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        Text(
                          controller.formatMinutes(end),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                if (_canEdit)
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

  /// Troca o horario de uma linha (todos os dias).
  Future<void> _openEditTimeRangeDialog(
    BuildContext context,
    int start,
    int end,
  ) async {
    var newStart = start;
    var newEnd = end;
    TimeOfDay toTime(int m) => TimeOfDay(hour: m ~/ 60, minute: m % 60);

    await Get.dialog(
      StatefulBuilder(
        builder: (dialogContext, setLocal) => AlertDialog(
          title: const Text('Horario da aula'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.schedule),
                title: const Text('Inicio'),
                trailing: Text(controller.formatMinutes(newStart)),
                onTap: () async {
                  final picked = await showTimePicker(
                    context: dialogContext,
                    initialTime: toTime(newStart),
                  );
                  if (picked == null) return;
                  final duration = newEnd - newStart;
                  setLocal(() {
                    newStart = picked.hour * 60 + picked.minute;
                    newEnd = newStart + duration;
                  });
                },
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.schedule_outlined),
                title: const Text('Fim'),
                trailing: Text(controller.formatMinutes(newEnd)),
                onTap: () async {
                  final picked = await showTimePicker(
                    context: dialogContext,
                    initialTime: toTime(newEnd),
                  );
                  if (picked == null) return;
                  setLocal(() => newEnd = picked.hour * 60 + picked.minute);
                },
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: Get.back, child: const Text('Cancelar')),
            FilledButton(
              onPressed: () async {
                final error = await controller.updateTimeRange(
                  start,
                  end,
                  newStart,
                  newEnd,
                );
                if (error != null) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text(error)));
                  }
                  return;
                }
                Get.back();
              },
              child: const Text('Salvar'),
            ),
          ],
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
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text(error)));
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
    final hasContent =
        (cell.subject?.isNotEmpty ?? false) ||
        (cell.professorName?.isNotEmpty ?? false) ||
        (cell.professorEmail?.isNotEmpty ?? false) ||
        (cell.professorPhone?.isNotEmpty ?? false);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!context.mounted) return;
      if (hasContent) {
        _openSubjectViewDialog(context, day, cell);
      } else if (_canEdit) {
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
      items.add(
        _phoneRow(
          context,
          cell.professorPhone!,
          formatPhoneForDisplay(cell.professorPhone),
        ),
      );
    }
    if (items.isEmpty) {
      items.add(const Text('Nenhum detalhe cadastrado.'));
    }

    await Get.dialog(
      AlertDialog(
        title: Text(
          '${dayLabels[day] ?? 'Dia'} - ${controller.formatMinutes(cell.startMinutes)}',
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: items,
        ),
        actions: [
          TextButton(onPressed: Get.back, child: const Text('Fechar')),
          if (_canEdit)
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
    final existingSubjects = controller.subjectOptions;
    final currentSubject = cell.subject?.trim();
    final isExisting =
        currentSubject != null &&
        currentSubject.isNotEmpty &&
        existingSubjects.contains(currentSubject);

    String? dropdownValue = isExisting
        ? currentSubject
        : (currentSubject?.isNotEmpty == true ? _novaMateriaValue : null);

    final subjectController = TextEditingController(
      text: dropdownValue == _novaMateriaValue || !isExisting
          ? (cell.subject ?? '')
          : '',
    );
    final professorController = TextEditingController(
      text: cell.professorName ?? '',
    );
    final emailController = TextEditingController(
      text: cell.professorEmail ?? '',
    );
    final phoneController = TextEditingController(
      text: formatPhoneForDisplay(cell.professorPhone),
    );

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
        phoneController.text = formatPhoneForDisplay(slot?.professorPhone);
      }
    }

    final formKey = GlobalKey<FormState>();

    await Get.dialog(
      AlertDialog(
        title: Text(dayLabels[day] ?? 'Dia'),
        content: SingleChildScrollView(
          child: Form(
            key: formKey,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            child: StatefulBuilder(
              builder: (context, setState) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    DropdownButtonFormField<String?>(
                      initialValue: dropdownValue,
                      decoration: const InputDecoration(
                        labelText: 'Materia (opcional)',
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                      items: [
                        const DropdownMenuItem<String?>(
                          value: null,
                          child: Text('Nenhuma'),
                        ),
                        ...existingSubjects.map(
                          (s) => DropdownMenuItem<String?>(
                            value: s,
                            child: Text(s),
                          ),
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
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
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
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'Email (opcional)',
                        hintText: 'professor@email.com',
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                      validator: (v) => emailValidator(v),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'Telefone (opcional)',
                        hintText: '(11) 99999-9999',
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                      inputFormatters: phoneInputFormatters,
                      validator: (v) => phoneValidator(v),
                    ),
                  ],
                );
              },
            ),
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
              if (formKey.currentState?.validate() != true) return;
              final subject = dropdownValue == _novaMateriaValue
                  ? subjectController.text
                  : (dropdownValue ?? subjectController.text);
              final phone = unmaskPhone(phoneController.text);
              await controller.updateSlotDetails(
                cell.id,
                subject: subject.trim().isEmpty ? null : subject.trim(),
                professorName: professorController.text,
                professorEmail: emailController.text,
                professorPhone: phone.isEmpty ? null : phone,
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
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
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
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
          ),
          const SizedBox(height: 2),
          MenuAnchor(
            builder: (context, controller, child) => InkWell(
              onTap: () =>
                  controller.isOpen ? controller.close() : controller.open(),
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
                  Icon(
                    Icons.arrow_drop_down,
                    size: 18,
                    color: Theme.of(context).colorScheme.primary,
                  ),
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

  Widget _phoneRow(BuildContext context, String phoneRaw, String phoneDisplay) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Telefone',
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
          ),
          const SizedBox(height: 2),
          MenuAnchor(
            builder: (context, controller, child) => InkWell(
              onTap: () =>
                  controller.isOpen ? controller.close() : controller.open(),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    phoneDisplay,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.arrow_drop_down,
                    size: 18,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ],
              ),
            ),
            menuChildren: [
              MenuItemButton(
                onPressed: () => _launchTel(phoneRaw),
                leadingIcon: const Icon(Icons.phone_outlined),
                child: const Text('Ligar'),
              ),
              MenuItemButton(
                onPressed: () => _launchWhatsApp(phoneRaw),
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

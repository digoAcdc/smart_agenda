import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/routes/app_routes.dart';
import '../../core/theme/design_tokens.dart';
import '../../core/utils/form_validators.dart';
import '../../domain/entities/class_schedule_slot.dart';
import '../../domain/entities/family.dart';
import '../../domain/repositories/i_family_service.dart';
import '../controllers/class_schedule_controller.dart';
import '../widgets/empty_state_widget.dart';
import '../widgets/loading_placeholder_list.dart';
import '../utils/schedule_permissions.dart';
import '../widgets/section_header.dart';
import 'subject_detail_page.dart';

class ClassSchedulePage extends GetView<ClassScheduleController> {
  const ClassSchedulePage({super.key});

  static const double _timeColWidth = 110;
  static const double _dayColWidth = 120;

  static const dayLabels = <int, String>{
    1: 'Segunda',
    2: 'Terça',
    3: 'Quarta',
    4: 'Quinta',
    5: 'Sexta',
  };

  IFamilyService? get _family =>
      Get.isRegistered<IFamilyService>() ? Get.find<IFamilyService>() : null;

  bool _canEditSchedule(ClassSchedule? schedule) =>
      canEditClassSchedule(schedule);

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
                title: 'Aulas',
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
                            tooltip: 'Adicionar horário',
                          ),
                          PopupMenuButton<String>(
                            tooltip: 'Opções da grade',
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
                        'Crie uma grade para você ou para um filho. Ela já vem com '
                        '6 matérias de segunda a sexta; depois é só ajustar.',
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
                      message: 'Esta grade ainda não tem aulas.',
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
                              'Matemática, Português, Ciências, História, Geografia e Inglês. '
                              'Depois é só tocar para trocar matérias e horários.',
                          ctaLabel: 'Usar grade modelo',
                          onTapCta: controller.applyTemplate,
                        ),
                        TextButton(
                          onPressed: () => _openAddTimeRangeDialog(context),
                          child: const Text('Começar do zero'),
                        ),
                      ],
                    ),
                  );
                }

                return LayoutBuilder(
                  builder: (context, constraints) {
                    final minContentWidth =
                        _timeColWidth +
                        _dayColWidth * ClassScheduleController.weekdays.length +
                        24;
                    // No celular a semana inteira nao cabe: mostra um dia por
                    // vez, com abas de segunda a sexta.
                    if (constraints.maxWidth < minContentWidth) {
                      return _buildDayView(context, ranges);
                    }
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

  /// Celular: abas Seg-Sex e as aulas do dia escolhido em lista.
  Widget _buildDayView(BuildContext context, List<TimeRange> ranges) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final palette = context.palette;
    return Obx(() {
      final day = controller.selectedWeekday.value;
      final today = DateTime.now().weekday;
      return Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
            child: Row(
              children: [
                for (final d in ClassScheduleController.weekdays)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 3),
                      child: Semantics(
                        selected: d == day,
                        button: true,
                        label: dayLabels[d],
                        excludeSemantics: true,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(14),
                          onTap: () => controller.selectedWeekday.value = d,
                          child: AnimatedContainer(
                            duration: DesignTokens.motionStandard,
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: d == day
                                  ? scheme.primary
                                  : palette.surfaceSoft,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Column(
                              children: [
                                Text(
                                  dayLabels[d]!.substring(0, 3),
                                  style: theme.textTheme.labelLarge?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: d == day
                                        ? scheme.onPrimary
                                        : scheme.onSurface,
                                  ),
                                ),
                                if (d == today)
                                  Text(
                                    'hoje',
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      color: d == day
                                          ? scheme.onPrimary
                                          : scheme.primary,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          _backpackTip(context),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 120),
              children: [
                for (final r in ranges)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 76,
                          child: InkWell(
                            onTap: _canEdit
                                ? () => _openEditTimeRangeDialog(
                                    context,
                                    r.start,
                                    r.end,
                                  )
                                : null,
                            borderRadius: BorderRadius.circular(10),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Column(
                                children: [
                                  Text(
                                    controller.formatMinutes(r.start),
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  Text(
                                    controller.formatMinutes(r.end),
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: scheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildEditableCell(
                            context,
                            day,
                            r.start,
                            r.end,
                          ),
                        ),
                      ],
                    ),
                  ),
                if (_canEdit)
                  Text(
                    'Toque na matéria para ver o que levar na mochila ou '
                    'editar a aula, e no horário para mudar ou excluir. O '
                    'horário vale para todos os dias.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ),
        ],
      );
    });
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
                    hintText: 'Ex.: Escola, Inglês, Cursinho',
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
                    'A Família vê e edita esta grade conforme o papel de cada um.',
                    style: Theme.of(dialogContext).textTheme.bodySmall,
                  ),
                ] else if (ctx?.hasFamily ?? false) ...[
                  const SizedBox(height: 6),
                  Text(
                    'A agenda da Família está só para consulta; esta grade ficará só para você.',
                    style: Theme.of(dialogContext).textTheme.bodySmall,
                  ),
                ],
                const SizedBox(height: 8),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  value: withTemplate,
                  onChanged: (v) => setLocal(() => withTemplate = v ?? true),
                  title: const Text('Começar com a grade modelo'),
                  subtitle: const Text('6 matérias de segunda a sexta'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: Get.back, child: const Text('Cancelar')),
            FilledButton(
              style: FilledButton.styleFrom(minimumSize: const Size(0, 44)),
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
            style: FilledButton.styleFrom(minimumSize: const Size(0, 44)),
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
              ? 'A grade e as aulas saem para toda a Família.'
              : 'A grade e as aulas serao apagadas.',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(minimumSize: const Size(0, 44)),
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
              'Horário',
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              subject?.isNotEmpty == true ? subject! : '+ adicionar',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: subject?.isNotEmpty == true
                    ? FontWeight.w600
                    : FontWeight.w400,
              ),
            ),
            // Mochila: quantos itens a materia tem (cinza quando vazia).
            if (subject?.trim().isNotEmpty == true)
              _backpackCount(context, controller.backpackFor(subject).length),
          ],
        ),
      ),
    );
  }

  /// Icone de mochila com o numero de itens da materia. Sem itens, so o
  /// icone apagado (um "0" em toda celula poluia a grade).
  Widget _backpackCount(BuildContext context, int count) {
    final scheme = Theme.of(context).colorScheme;
    final color = count == 0
        ? scheme.outline.withValues(alpha: 0.7)
        : scheme.primary;
    return Semantics(
      label: count == 0
          ? 'Mochila vazia, toque para adicionar'
          : '$count ${count == 1 ? 'item' : 'itens'} na mochila',
      excludeSemantics: true,
      child: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              count == 0 ? Icons.backpack_outlined : Icons.backpack,
              size: 15,
              color: color,
            ),
            if (count > 0) ...[
              const SizedBox(width: 3),
              Text(
                '$count',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Mochila na tela Aulas: a dica enquanto nenhuma materia tem itens e
  /// ninguem fechou; depois, o chip "Mochila de amanhã" (abre a checklist
  /// de amanha), para a funcao nao sumir de vista.
  Widget _backpackTip(BuildContext context) {
    final schedule = controller.selected.value;
    if (schedule == null) return const SizedBox.shrink();
    final showTip =
        _canEdit &&
        !controller.hasBackpackItems &&
        !controller.backpackTipDismissed.value;
    if (!showTip) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 6),
        child: Align(
          alignment: Alignment.centerLeft,
          child: ActionChip(
            avatar: const Text('🎒'),
            label: const Text('Mochila de amanhã'),
            tooltip: 'Ver o que levar amanhã',
            onPressed: () => Get.toNamed(AppRoutes.backpackTomorrow),
          ),
        ),
      );
    }
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 10),
      padding: const EdgeInsets.fromLTRB(12, 10, 4, 10),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('🎒', style: TextStyle(fontSize: 22)),
          const SizedBox(width: 10),
          Expanded(
            child: Text.rich(
              TextSpan(
                children: [
                  const TextSpan(
                    text: 'Mochila de amanhã\n',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  TextSpan(
                    text:
                        'Toque numa matéria e em "Adicionar à mochila" (ex.: '
                        'tênis na Ed. Física). Escolha o dia e se quer '
                        'lembrete às 20h da véspera.',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ),
          IconButton(
            tooltip: 'Fechar dica',
            visualDensity: VisualDensity.compact,
            onPressed: controller.dismissBackpackTip,
            icon: const Icon(Icons.close_rounded, size: 18),
          ),
        ],
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
          title: const Text('Horário da aula'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.schedule),
                title: const Text('Início'),
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
            TextButton(
              onPressed: () async {
                final ok = await Get.dialog<bool>(
                  AlertDialog(
                    title: const Text('Excluir este horário?'),
                    content: Text(
                      'O horário ${controller.formatMinutes(start)}–'
                      '${controller.formatMinutes(end)} sai de todos os dias, '
                      'com as aulas dele.',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Get.back(result: false),
                        child: const Text('Cancelar'),
                      ),
                      TextButton(
                        onPressed: () => Get.back(result: true),
                        child: const Text('Excluir'),
                      ),
                    ],
                  ),
                );
                if (ok != true) return;
                await controller.removeTimeRange(start, end);
                Get.back();
              },
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(dialogContext).colorScheme.error,
              ),
              child: const Text('Excluir'),
            ),
            TextButton(onPressed: Get.back, child: const Text('Cancelar')),
            FilledButton(
              style: FilledButton.styleFrom(minimumSize: const Size(0, 44)),
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
        title: const Text('Adicionar horário'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: startController,
              readOnly: true,
              onTap: () => pickTime(startController),
              decoration: const InputDecoration(labelText: 'Início (HH:mm)'),
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
            style: FilledButton.styleFrom(minimumSize: const Size(0, 44)),
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
    final subject = cell.subject?.trim() ?? '';
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!context.mounted) return;
      if (subject.isNotEmpty) {
        // Detalhe da materia (Mochila); volta com true
        // quando o usuario pede para editar a aula.
        final edit = await Get.toNamed(
          AppRoutes.subjectDetail,
          arguments: SubjectDetailArgs(
            slot: cell,
            dayLabel: dayLabels[day] ?? 'Dia',
            canEdit: _canEdit,
          ),
        );
        if (edit == true && context.mounted) {
          _openSubjectEditDialog(context, day, cell);
        }
      } else if (_canEdit) {
        _openSubjectEditDialog(context, day, cell);
      }
    });
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
                        labelText: 'Matéria (opcional)',
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
                          child: Text('+ Nova matéria'),
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
                          labelText: 'Nome da matéria',
                          hintText: 'Ex: Matemática',
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
            style: FilledButton.styleFrom(minimumSize: const Size(0, 44)),
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

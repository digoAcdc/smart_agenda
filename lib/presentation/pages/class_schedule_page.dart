import 'package:flutter/material.dart';
import 'package:get/get.dart';

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
    return Container(
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
      onTap: () =>
          _openSubjectDialog(context, day, start, end, cell?.id, subject),
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

  Future<void> _openSubjectDialog(
    BuildContext context,
    int day,
    int start,
    int end,
    String? cellId,
    String? current,
  ) async {
    if (cellId == null) return;
    final textController = TextEditingController(text: current ?? '');
    await Get.dialog(
      AlertDialog(
        title: Text(dayLabels[day] ?? 'Dia'),
        content: TextField(
          controller: textController,
          decoration: const InputDecoration(
            labelText: 'Materia (opcional)',
            hintText: 'Ex: Matematica',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              await controller.updateSubject(cellId, null);
              Get.back();
            },
            child: const Text('Limpar'),
          ),
          TextButton(onPressed: Get.back, child: const Text('Cancelar')),
          FilledButton(
            onPressed: () async {
              await controller.updateSubject(cellId, textController.text);
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

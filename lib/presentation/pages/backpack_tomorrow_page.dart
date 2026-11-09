import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../domain/services/backpack_planner.dart';
import '../controllers/class_schedule_controller.dart';
import '../services/backpack_reminder_service.dart';
import '../utils/schedule_permissions.dart';
import '../widgets/add_backpack_sheet.dart';
import '../widgets/backpack_checklist.dart';
import '../widgets/empty_state_widget.dart';

/// Checklist da Mochila de amanha em tela cheia: abre pelo aviso das 20h e
/// pelo chip "🎒 Mochila de amanhã" da tela Aulas. Da para adicionar daqui
/// mesmo: escolhe a materia e segue o mesmo passo a passo da tela da materia.
class BackpackTomorrowPage extends StatelessWidget {
  const BackpackTomorrowPage({super.key});

  static DateTime _tomorrow() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day + 1);
  }

  @override
  Widget build(BuildContext context) {
    final service = Get.find<BackpackReminderService>();
    final schedules = Get.find<ClassScheduleController>();
    final theme = Theme.of(context);
    final tomorrow = _tomorrow();
    return Obx(() {
      final groups = service.tomorrowGroups();
      // Sem grade com materia (ou sem permissao), nao ha onde adicionar.
      final canAdd =
          schedules.existingSubjects.isNotEmpty &&
          canEditClassSchedule(schedules.selected.value);
      return Scaffold(
        appBar: AppBar(title: const Text('Mochila de amanhã')),
        floatingActionButton: canAdd
            ? FloatingActionButton.extended(
                onPressed: () => _pickSubjectAndAdd(context),
                icon: const Icon(Icons.add_rounded),
                label: const Text('Adicionar à mochila'),
              )
            : null,
        body: SafeArea(
          top: false,
          child: groups.isEmpty
              ? EmptyStateWidget(
                  icon: Icons.backpack_outlined,
                  title: 'Nada para levar amanhã',
                  message: canAdd
                      ? 'Toque em "Adicionar à mochila", aqui embaixo, '
                            'escolha a matéria e o que levar (ex.: tênis na '
                            'Ed. Física). Os itens das aulas de amanhã '
                            'aparecem aqui para marcar o que já colocou.'
                      : 'Os itens das aulas de amanhã aparecem aqui para '
                            'marcar o que já colocou. Monte a grade em Aulas '
                            'para começar.',
                )
              : _buildChecklist(theme, service, groups, tomorrow),
        ),
      );
    });
  }

  Widget _buildChecklist(
    ThemeData theme,
    BackpackReminderService service,
    List<BackpackSubjectGroup> groups,
    DateTime tomorrow,
  ) {
    final (done, total) = BackpackChecklist.progress(service, groups);
    return ListView(
      // Espaco embaixo para o botao nao cobrir o ultimo item.
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
      children: [
        Text(
          toBeginningOfSentenceCase(
            DateFormat('EEEE, d MMMM', 'pt_BR').format(tomorrow),
          ),
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          done == total
              ? 'Tudo na mochila! 🎒'
              : 'Marque o que já colocou · $done de $total',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        BackpackChecklist(groups: groups),
      ],
    );
  }

  /// "Para qual matéria?" (as de amanha primeiro) e depois o passo a passo.
  static Future<void> _pickSubjectAndAdd(BuildContext context) async {
    final controller = Get.find<ClassScheduleController>();
    final weekday = _tomorrow().weekday;
    final tomorrowSlots =
        controller.slots
            .where(
              (s) =>
                  s.dayOfWeek == weekday &&
                  (s.subject?.trim().isNotEmpty ?? false),
            )
            .toList()
          ..sort((a, b) => a.startMinutes.compareTo(b.startMinutes));
    final tomorrowSubjects = <String>{
      for (final s in tomorrowSlots) s.subject!.trim(),
    }.toList();
    final otherSubjects = controller.existingSubjects
        .where((s) => !tomorrowSubjects.contains(s))
        .toList();
    final scheduleName = controller.schedules.length > 1
        ? controller.selected.value?.name
        : null;

    final subject = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) {
        final theme = Theme.of(sheetContext);
        Widget header(String text) => Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
          child: Text(
            text,
            style: theme.textTheme.labelLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w700,
            ),
          ),
        );
        Widget tile(String s) {
          final count = controller.backpackFor(s).length;
          return ListTile(
            leading: const Icon(Icons.menu_book_rounded),
            title: Text(s),
            trailing: count == 0
                ? null
                : Text('🎒 $count', style: theme.textTheme.labelMedium),
            onTap: () => Navigator.of(sheetContext).pop(s),
          );
        }

        return SafeArea(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(sheetContext).height * 0.75,
            ),
            child: ListView(
              shrinkWrap: true,
              padding: const EdgeInsets.only(bottom: 16),
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 4),
                  child: Text(
                    'Para qual matéria?',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (scheduleName != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      'Grade: $scheduleName',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                if (tomorrowSubjects.isNotEmpty) ...[
                  header('Aulas de amanhã'),
                  for (final s in tomorrowSubjects) tile(s),
                ],
                if (otherSubjects.isNotEmpty) ...[
                  header(
                    tomorrowSubjects.isEmpty
                        ? 'Matérias da grade'
                        : 'Outras matérias',
                  ),
                  for (final s in otherSubjects) tile(s),
                ],
              ],
            ),
          ),
        );
      },
    );
    if (subject == null || !context.mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    final added = await AddBackpackSheet.show(context, subject);
    if (added == null || added == 0) return;
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          added == 1
              ? '1 item na mochila de $subject'
              : '$added itens na mochila de $subject',
        ),
      ),
    );
  }
}

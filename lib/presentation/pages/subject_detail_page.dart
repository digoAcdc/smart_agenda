import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/theme/design_tokens.dart';
import '../../core/utils/contact_launcher.dart';
import '../../core/utils/form_validators.dart';
import '../../domain/entities/backpack_item.dart';
import '../../domain/entities/class_schedule_slot.dart';
import '../controllers/class_schedule_controller.dart';
import '../services/backpack_reminder_service.dart';
import '../widgets/add_backpack_sheet.dart';

/// Argumentos da tela de detalhe da materia.
class SubjectDetailArgs {
  const SubjectDetailArgs({
    required this.slot,
    required this.dayLabel,
    required this.canEdit,
  });

  /// Aula tocada na grade (da a materia, o horario e o professor).
  final ClassScheduleSlot slot;
  final String dayLabel;
  final bool canEdit;
}

/// Detalhe da materia, aberto ao tocar numa aula da grade. O conteudo e a
/// Mochila da materia (o que levar), com o botao "Adicionar à mochila".
/// Faltas e Notas entram aqui quando existirem (abas vazias "em breve"
/// escondiam a Mochila). Volta com `true` quando o usuario pede para editar
/// a aula (a edicao continua no dialogo da tela Aulas).
class SubjectDetailPage extends StatelessWidget {
  const SubjectDetailPage({super.key});

  @override
  Widget build(BuildContext context) {
    final args = Get.arguments;
    if (args is! SubjectDetailArgs ||
        (args.slot.subject?.trim().isEmpty ?? true)) {
      return Scaffold(
        appBar: AppBar(title: const Text('Matéria')),
        body: const Center(child: Text('Matéria inválida.')),
      );
    }
    final controller = Get.find<ClassScheduleController>();
    final slot = args.slot;
    final subject = slot.subject!.trim();
    final theme = Theme.of(context);
    final professor = slot.professorName?.trim() ?? '';
    final hasContact =
        (slot.professorEmail?.isNotEmpty ?? false) ||
        (slot.professorPhone?.isNotEmpty ?? false);
    final time =
        '${controller.formatMinutes(slot.startMinutes)}–'
        '${controller.formatMinutes(slot.endMinutes)}';

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(subject),
            Text(
              [
                '${args.dayLabel} · $time',
                if (professor.isNotEmpty) professor,
              ].join(' · '),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        actions: [
          if (hasContact)
            IconButton(
              tooltip: 'Contato do professor',
              onPressed: () => _openContactSheet(slot),
              icon: const Icon(Icons.contact_phone_outlined),
            ),
          if (args.canEdit)
            IconButton(
              tooltip: 'Editar aula',
              onPressed: () => Get.back(result: true),
              icon: const Icon(Icons.edit_outlined),
            ),
        ],
      ),
      // Sempre visivel: e a acao principal da tela (em tela estreita com
      // fonte grande, um botao no meio da lista ficava fora de vista).
      floatingActionButton: args.canEdit
          ? FloatingActionButton.extended(
              onPressed: () => _openAddSheet(context, subject),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Adicionar à mochila'),
            )
          : null,
      body: SafeArea(
        top: false,
        child: _BackpackSection(subject: subject, canEdit: args.canEdit),
      ),
    );
  }

  static Future<void> _openAddSheet(
    BuildContext context,
    String subject,
  ) async {
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

  void _openContactSheet(ClassScheduleSlot slot) {
    final email = slot.professorEmail?.trim() ?? '';
    final phone = slot.professorPhone?.trim() ?? '';
    Get.bottomSheet(
      SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (email.isNotEmpty)
              ListTile(
                leading: const Icon(Icons.email_outlined),
                title: const Text('Enviar email'),
                subtitle: Text(email),
                onTap: () {
                  Get.back();
                  launchMailto(email);
                },
              ),
            if (phone.isNotEmpty) ...[
              ListTile(
                leading: const Icon(Icons.phone_outlined),
                title: const Text('Ligar'),
                subtitle: Text(formatPhoneForDisplay(phone)),
                onTap: () {
                  Get.back();
                  launchTel(phone);
                },
              ),
              ListTile(
                leading: const Icon(Icons.chat_outlined),
                title: const Text('WhatsApp'),
                onTap: () {
                  Get.back();
                  launchWhatsApp(phone);
                },
              ),
            ],
          ],
        ),
      ),
      backgroundColor: Theme.of(Get.context!).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
    );
  }
}

/// Mochila da materia: lista do que levar, com quando e se tem lembrete.
class _BackpackSection extends StatelessWidget {
  const _BackpackSection({required this.subject, required this.canEdit});

  final String subject;
  final bool canEdit;

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<ClassScheduleController>();
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final reminders = Get.isRegistered<BackpackReminderService>()
        ? Get.find<BackpackReminderService>()
        : null;
    return Obx(() {
      // Reage a grade (itens gravados/sincronizados) e ao liga/desliga geral.
      controller.selected.value;
      final globalOff = reminders != null && !reminders.enabled.value;
      final items = controller.backpackFor(subject);
      final weekdays = controller.classWeekdaysFor(subject);
      return ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
        children: [
          Row(
            children: [
              const Text('🎒', style: TextStyle(fontSize: 26)),
              const SizedBox(width: 10),
              Expanded(
                child: Semantics(
                  header: true,
                  child: Text(
                    'O que levar na mochila',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Itens para as aulas de $subject. Com o sininho ligado, você '
            'recebe um lembrete às 20h da véspera.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          if (globalOff && items.any((i) => i.remind)) ...[
            const SizedBox(height: DesignTokens.spaceSm),
            _RemindersOffBanner(service: reminders),
          ],
          const SizedBox(height: DesignTokens.spaceMd),
          if (items.isEmpty)
            _EmptyBackpack(subject: subject, canEdit: canEdit)
          else
            for (final item in items)
              _BackpackItemCard(
                item: item,
                weekdays: weekdays,
                canEdit: canEdit,
                onToggleRemind: () =>
                    controller.setBackpackItemRemind(item.id, !item.remind),
                onRemove: () => controller.removeBackpackItem(item.id),
              ),
          if (!canEdit) ...[
            const SizedBox(height: DesignTokens.spaceMd),
            Text(
              'Só quem pode editar a agenda da Família muda a mochila.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      );
    });
  }
}

class _EmptyBackpack extends StatelessWidget {
  const _EmptyBackpack({required this.subject, required this.canEdit});

  final String subject;
  final bool canEdit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.all(DesignTokens.spaceMd),
      decoration: BoxDecoration(
        color: scheme.primaryContainer.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Icon(Icons.backpack_outlined, size: 40, color: scheme.primary),
          const SizedBox(height: DesignTokens.spaceXs),
          Text(
            'Nada na mochila ainda',
            textAlign: TextAlign.center,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            canEdit
                ? 'Toque em "Adicionar à mochila", aqui embaixo, e escolha '
                      'o que levar (ex.: tênis, livro), se vai toda aula ou '
                      'só num dia, e se quer lembrete.'
                : 'Ninguém colocou nada para $subject ainda.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _BackpackItemCard extends StatelessWidget {
  const _BackpackItemCard({
    required this.item,
    required this.weekdays,
    required this.canEdit,
    required this.onToggleRemind,
    required this.onRemove,
  });

  final BackpackItem item;
  final List<int> weekdays;
  final bool canEdit;
  final VoidCallback onToggleRemind;
  final VoidCallback onRemove;

  String get _when {
    if (item.isWeekly) {
      return weekdays.isEmpty
          ? 'Toda aula'
          : 'Toda aula · ${formatWeekdays(weekdays)}';
    }
    final due = item.dueDate;
    return due == null ? 'Só uma vez' : 'Só ${formatBackpackDay(due)}';
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final remindText = item.remind ? 'com lembrete' : 'sem lembrete';
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        contentPadding: const EdgeInsets.only(left: 16, right: 4),
        leading: Icon(Icons.backpack_outlined, color: scheme.primary),
        title: Text(item.label),
        subtitle: Text('$_when · $remindText'),
        trailing: canEdit
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    tooltip: item.remind
                        ? 'Desligar lembrete de ${item.label}'
                        : 'Ligar lembrete de ${item.label}',
                    isSelected: item.remind,
                    onPressed: onToggleRemind,
                    icon: Icon(
                      Icons.notifications_off_outlined,
                      color: scheme.outline,
                    ),
                    selectedIcon: Icon(
                      Icons.notifications_active,
                      color: scheme.primary,
                    ),
                  ),
                  IconButton(
                    tooltip: 'Tirar ${item.label} da mochila',
                    onPressed: onRemove,
                    icon: const Icon(Icons.delete_outline_rounded),
                  ),
                ],
              )
            : Icon(
                item.remind
                    ? Icons.notifications_active_outlined
                    : Icons.notifications_off_outlined,
                color: item.remind ? scheme.primary : scheme.outline,
                semanticLabel: remindText,
              ),
      ),
    );
  }
}

/// Aviso quando os lembretes da Mochila estao desligados no geral.
class _RemindersOffBanner extends StatelessWidget {
  const _RemindersOffBanner({required this.service});

  final BackpackReminderService service;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
      decoration: BoxDecoration(
        color: scheme.errorContainer,
        borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
      ),
      child: Row(
        children: [
          Icon(
            Icons.notifications_off_outlined,
            color: scheme.onErrorContainer,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Os lembretes da Mochila estão desligados.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onErrorContainer,
              ),
            ),
          ),
          TextButton(
            onPressed: () => service.setEnabled(true),
            child: const Text('Ligar'),
          ),
        ],
      ),
    );
  }
}

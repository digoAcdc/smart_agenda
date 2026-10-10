import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/routes/app_routes.dart';
import '../../core/theme/design_tokens.dart';
import '../../domain/entities/agenda_enums.dart';
import '../../domain/entities/agenda_item.dart';
import '../controllers/agenda_controller.dart';
import '../controllers/groups_controller.dart';
import '../widgets/group_chip.dart';
import '../widgets/ui_primitives.dart';
import '../utils/family_item_labels.dart';
import '../utils/recurring_scope_prompt.dart';
import '../../domain/repositories/i_agenda_repository.dart';

class EventDetailPage extends StatelessWidget {
  const EventDetailPage({super.key});

  /// Repeticao: editar so este dia (vira um evento separado) ou a serie.
  Future<void> _edit(BuildContext context, AgendaItem item) async {
    // Depois de salvar, fecha o detalhe (ele mostraria os dados antigos).
    Future<void> openForm(Object args) async {
      final saved = await Get.toNamed(AppRoutes.upsertAgenda, arguments: args);
      if (saved == true) Get.back();
    }

    if (!item.isOccurrence) {
      await openForm(item);
      return;
    }
    final scope = await askRecurringScope(context, title: 'Editar evento');
    if (scope == null) return;
    if (scope == RecurringScope.onlyThis) {
      await openForm({'detachOccurrence': item});
      return;
    }
    final master = await Get.find<IAgendaRepository>().getItemById(item.id);
    if (master.data != null) await openForm(master.data!);
  }

  Future<void> _share(AgendaItem item, String dateLabel) async {
    final lines = [
      '📅 ${item.title}',
      dateLabel[0].toUpperCase() + dateLabel.substring(1),
      if ((item.locationText ?? '').trim().isNotEmpty)
        '📍 ${item.locationText!.trim()}',
      if (item.isRecurring) '🔁 ${item.recurrence!.shortLabel}',
      if ((item.description ?? '').trim().isNotEmpty) item.description!.trim(),
      '',
      'Enviado pelo Smart Agenda',
    ];
    await SharePlus.instance.share(ShareParams(text: lines.join('\n')));
  }

  @override
  Widget build(BuildContext context) {
    final arg = Get.arguments;
    if (arg is! AgendaItem) {
      return Scaffold(
        appBar: AppBar(title: const Text('Detalhe do evento')),
        body: const SafeArea(
          top: false,
          bottom: false,
          child: Center(child: Text('Evento inválido.')),
        ),
      );
    }
    final agendaController = Get.find<AgendaController>();
    final groupsController = Get.find<GroupsController>();
    final groupName =
        groupsController.groups
            .firstWhereOrNull((g) => g.id == arg.groupId)
            ?.name ??
        'Sem grupo';
    final groupColor = groupsController.groups
        .firstWhereOrNull((g) => g.id == arg.groupId)
        ?.colorHex;

    final startFmt = DateFormat('EEEE, dd MMM • HH:mm');
    final endFmt = DateFormat('HH:mm');
    final dateLabel = arg.allDay
        ? DateFormat('EEEE, dd MMM').format(arg.startAt)
        : '${startFmt.format(arg.startAt)}${arg.endAt != null ? ' - ${endFmt.format(arg.endAt!)}' : ''}';
    final isShared = !FamilyItemLabels.canEdit(arg);
    final familyRows = <(IconData, String)>[
      if (FamilyItemLabels.subject(arg) != null)
        (
          Icons.family_restroom_outlined,
          'Para: ${FamilyItemLabels.subject(arg)}',
        ),
      if (FamilyItemLabels.assignee(arg) != null)
        (
          Icons.assignment_ind_outlined,
          'Responsável: ${FamilyItemLabels.assignee(arg)}',
        ),
      if (FamilyItemLabels.createdBy(arg) != null)
        (Icons.person_outline, 'Criado por ${FamilyItemLabels.createdBy(arg)}'),
      if (FamilyItemLabels.completedBy(arg) != null)
        (Icons.task_alt, 'Concluído por ${FamilyItemLabels.completedBy(arg)}'),
      if (arg.isFamilyItem && isShared)
        (Icons.visibility_outlined, 'Somente leitura para você'),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalhe do evento'),
        actions: [
          IconButton(
            tooltip: 'Compartilhar',
            onPressed: () => _share(arg, dateLabel),
            icon: const Icon(Icons.share_outlined),
          ),
          if (!isShared)
            IconButton(
              tooltip: 'Editar',
              onPressed: () => _edit(context, arg),
              icon: const Icon(Icons.edit_outlined),
            ),
        ],
      ),
      body: SafeArea(
        top: false,
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(0, 10, 0, 120),
          children: [
            if (familyRows.isNotEmpty)
              AppSurfaceCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final (icon, text) in familyRows)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 3),
                        child: Row(
                          children: [
                            Icon(
                              icon,
                              size: 18,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            const SizedBox(width: DesignTokens.spaceSm),
                            Expanded(
                              child: Text(
                                text,
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            AppSurfaceCard(
              child: Row(
                children: [
                  StatusPill(status: arg.status),
                  const SizedBox(width: DesignTokens.spaceSm),
                  Expanded(
                    child: GroupChip(
                      label: groupName,
                      color: _parseColor(groupColor),
                    ),
                  ),
                ],
              ),
            ),
            AppSurfaceCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (arg.kind.isSchoolWork)
                    Text(
                      '${arg.kind.label}${(arg.schoolSubject ?? '').trim().isEmpty ? '' : ' de ${arg.schoolSubject!.trim()}'}',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  Text(
                    arg.title,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: DesignTokens.spaceXs),
                  Text(
                    dateLabel,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  if (arg.isRecurring) ...[
                    const SizedBox(height: DesignTokens.spaceXs),
                    Row(
                      children: [
                        Icon(
                          Icons.repeat_rounded,
                          size: 18,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: DesignTokens.spaceXs),
                        Expanded(child: Text(arg.recurrence!.shortLabel)),
                      ],
                    ),
                  ],
                  if ((arg.locationText ?? '').trim().isNotEmpty) ...[
                    const SizedBox(height: DesignTokens.spaceSm),
                    Row(
                      children: [
                        const Icon(Icons.location_on_outlined, size: 18),
                        const SizedBox(width: DesignTokens.spaceXs),
                        Expanded(child: Text(arg.locationText!.trim())),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            if (!isShared)
              AppSurfaceCard(
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () async {
                          // Na repeticao: tira so este dia.
                          await agendaController.toggleItemStatus(
                            arg,
                            AgendaStatus.canceled,
                          );
                          Get.back();
                        },
                        child: Text(
                          arg.isOccurrence
                              ? 'Cancelar este dia'
                              : 'Cancelar evento',
                        ),
                      ),
                    ),
                    const SizedBox(width: DesignTokens.spaceSm),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () async {
                          await agendaController.toggleItemStatus(
                            arg,
                            arg.status == AgendaStatus.done
                                ? AgendaStatus.pending
                                : AgendaStatus.done,
                          );
                          Get.back();
                        },
                        icon: const Icon(Icons.check_rounded),
                        label: Text(
                          arg.status == AgendaStatus.done
                              ? 'Reabrir'
                              : 'Marcar concluído',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            if ((arg.description ?? '').trim().isNotEmpty)
              AppSurfaceCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Descrição',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: DesignTokens.spaceXs),
                    Text(arg.description!.trim()),
                  ],
                ),
              ),
            AppSurfaceCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Anexos',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: DesignTokens.spaceSm),
                  if (arg.attachments.isEmpty)
                    Text(
                      'Sem anexos para este evento.',
                      style: Theme.of(context).textTheme.bodySmall,
                    )
                  else
                    Column(
                      children: arg.attachments.map((a) {
                        final hasLocal =
                            a.localPath != null &&
                            File(a.localPath!).existsSync();
                        final hasRemote =
                            a.remoteUrl != null &&
                            (a.remoteUrl!.startsWith('http://') ||
                                a.remoteUrl!.startsWith('https://'));
                        final hasImage = hasLocal || hasRemote;
                        return InkWell(
                          borderRadius: BorderRadius.circular(
                            DesignTokens.radiusMd,
                          ),
                          onTap: () => _openAttachmentPreview(
                            context,
                            localPath: a.localPath,
                            remoteUrl: a.remoteUrl,
                          ),
                          child: Container(
                            margin: const EdgeInsets.only(
                              bottom: DesignTokens.spaceXs,
                            ),
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.surface,
                              borderRadius: BorderRadius.circular(
                                DesignTokens.radiusMd,
                              ),
                            ),
                            child: Row(
                              children: [
                                if (hasImage)
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: hasLocal
                                        ? Image.file(
                                            File(a.localPath!),
                                            width: 42,
                                            height: 42,
                                            fit: BoxFit.cover,
                                          )
                                        : Image.network(
                                            a.remoteUrl!,
                                            width: 42,
                                            height: 42,
                                            fit: BoxFit.cover,
                                            errorBuilder:
                                                (context, error, stackTrace) =>
                                                    const Icon(
                                                      Icons.broken_image,
                                                    ),
                                          ),
                                  )
                                else
                                  const Icon(Icons.attachment_outlined),
                                const SizedBox(width: DesignTokens.spaceXs),
                                Expanded(
                                  child: Text(
                                    a.title ?? 'Anexo',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Icon(
                                  hasImage
                                      ? Icons.open_in_full_rounded
                                      : Icons.error_outline_rounded,
                                  size: 18,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color? _parseColor(String? colorHex) {
    if (colorHex == null || colorHex.isEmpty) return null;
    final hex = colorHex.replaceFirst('#', '');
    final normalized = hex.length == 6 ? 'FF$hex' : hex;
    final value = int.tryParse(normalized, radix: 16);
    if (value == null) return null;
    return Color(value);
  }

  Future<void> _openAttachmentPreview(
    BuildContext context, {
    String? localPath,
    String? remoteUrl,
  }) async {
    final hasLocal = localPath != null && File(localPath).existsSync();
    final hasRemote =
        remoteUrl != null &&
        (remoteUrl.startsWith('http://') || remoteUrl.startsWith('https://'));

    if (!hasLocal && !hasRemote) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Arquivo do anexo não encontrado.')),
      );
      return;
    }

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          insetPadding: const EdgeInsets.all(14),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
            child: Stack(
              children: [
                SizedBox(
                  width: double.infinity,
                  height: MediaQuery.of(dialogContext).size.height * 0.72,
                  child: InteractiveViewer(
                    minScale: 0.8,
                    maxScale: 4,
                    child: hasLocal
                        ? Image.file(File(localPath), fit: BoxFit.contain)
                        : Image.network(
                            remoteUrl as String,
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) =>
                                const Center(
                                  child: Icon(Icons.broken_image, size: 64),
                                ),
                          ),
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: IconButton.filledTonal(
                    onPressed: () => Navigator.of(dialogContext).pop(),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

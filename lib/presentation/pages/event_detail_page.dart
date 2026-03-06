import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../core/routes/app_routes.dart';
import '../../core/theme/design_tokens.dart';
import '../../domain/entities/agenda_enums.dart';
import '../../domain/entities/agenda_item.dart';
import '../controllers/agenda_controller.dart';
import '../controllers/groups_controller.dart';
import '../widgets/group_chip.dart';
import '../widgets/ui_primitives.dart';

class EventDetailPage extends StatelessWidget {
  const EventDetailPage({super.key});

  @override
  Widget build(BuildContext context) {
    final arg = Get.arguments;
    if (arg is! AgendaItem) {
      return Scaffold(
        appBar: AppBar(title: const Text('Detalhe do evento')),
        body: const Center(child: Text('Evento invalido.')),
      );
    }
    final agendaController = Get.find<AgendaController>();
    final groupsController = Get.find<GroupsController>();
    final groupName = groupsController.groups
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalhe do evento'),
        actions: [
          IconButton(
            tooltip: 'Editar',
            onPressed: () => Get.toNamed(AppRoutes.upsertAgenda, arguments: arg),
            icon: const Icon(Icons.edit_outlined),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(0, 10, 0, 120),
        children: [
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
          AppSurfaceCard(
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () async {
                      await agendaController.toggleStatus(
                        arg.id,
                        AgendaStatus.canceled,
                      );
                      Get.back();
                    },
                    child: const Text('Cancelar evento'),
                  ),
                ),
                const SizedBox(width: DesignTokens.spaceSm),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () async {
                      await agendaController.toggleStatus(arg.id, AgendaStatus.done);
                      Get.back();
                    },
                    icon: const Icon(Icons.check_rounded),
                    label: const Text('Marcar concluido'),
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
                    'Descricao',
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
                      return Container(
                        margin: const EdgeInsets.only(bottom: DesignTokens.spaceXs),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface,
                          borderRadius:
                              BorderRadius.circular(DesignTokens.radiusMd),
                        ),
                        child: Row(
                          children: [
                            if (a.localPath != null && File(a.localPath!).existsSync())
                              ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: Image.file(
                                  File(a.localPath!),
                                  width: 42,
                                  height: 42,
                                  fit: BoxFit.cover,
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
                          ],
                        ),
                      );
                    }).toList(),
                  ),
              ],
            ),
          ),
        ],
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
}

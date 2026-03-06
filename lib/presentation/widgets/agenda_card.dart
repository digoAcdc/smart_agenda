import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/theme/design_tokens.dart';
import '../../domain/entities/agenda_enums.dart';
import '../../domain/entities/agenda_item.dart';
import 'group_chip.dart';

enum AgendaCardVariant { regular, timeline }

class AgendaCard extends StatelessWidget {
  const AgendaCard({
    super.key,
    required this.item,
    this.groupName,
    this.groupColor,
    this.onTap,
    this.onToggleStatus,
    this.onDelete,
    this.variant = AgendaCardVariant.regular,
  });

  final AgendaItem item;
  final String? groupName;
  final Color? groupColor;
  final VoidCallback? onTap;
  final ValueChanged<AgendaStatus>? onToggleStatus;
  final Future<bool?> Function()? onDelete;
  final AgendaCardVariant variant;

  @override
  Widget build(BuildContext context) {
    final isDone = item.status == AgendaStatus.done;
    final timeLabel =
        item.allDay ? 'Dia inteiro' : DateFormat('HH:mm').format(item.startAt);
    final metaLabel = DateFormat('dd MMM').format(item.startAt);
    Color statusColor;
    switch (item.status) {
      case AgendaStatus.done:
        statusColor = context.semanticColors.success;
        break;
      case AgendaStatus.canceled:
        statusColor = context.semanticColors.warning;
        break;
      case AgendaStatus.pending:
        statusColor = context.semanticColors.pending;
        break;
    }
    final padding = variant == AgendaCardVariant.timeline
        ? const EdgeInsets.all(12)
        : const EdgeInsets.all(14);
    final margin = variant == AgendaCardVariant.timeline
        ? const EdgeInsets.symmetric(horizontal: 12, vertical: 4)
        : const EdgeInsets.symmetric(horizontal: 16, vertical: 6);
    final radius = variant == AgendaCardVariant.timeline
        ? DesignTokens.radiusMd
        : DesignTokens.radiusLg;
    final railHeight = variant == AgendaCardVariant.timeline ? 48.0 : 56.0;

    return Dismissible(
      key: ValueKey(item.id),
      background: _swipeBackground(
        context,
        icon: Icons.check_circle,
        label: 'Concluir',
        color: context.semanticColors.success,
        alignLeft: true,
        margin: margin,
        radius: radius,
      ),
      secondaryBackground: _swipeBackground(
        context,
        icon: Icons.delete_outline,
        label: 'Excluir',
        color: context.semanticColors.danger,
        alignLeft: false,
        margin: margin,
        radius: radius,
      ),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          onToggleStatus?.call(AgendaStatus.done);
          return false;
        }
        if (onDelete != null) {
          return onDelete!.call();
        }
        return false;
      },
      child: AnimatedContainer(
        duration: DesignTokens.motionStandard,
        curve: DesignTokens.curveStandard,
        margin: margin,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(radius),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.035),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(radius),
          onTap: onTap,
          child: Opacity(
            opacity: isDone ? 0.7 : 1,
            child: Padding(
              padding: padding,
              child: Row(
                children: [
                  Container(
                    width: 4,
                    height: railHeight,
                    decoration: BoxDecoration(
                      color: groupColor ?? statusColor,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              timeLabel,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                            ),
                            const SizedBox(width: 10),
                            if (groupName != null)
                              GroupChip(label: groupName!, color: groupColor),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          item.title,
                          style: Theme.of(context)
                              .textTheme
                              .bodyLarge
                              ?.copyWith(
                                fontWeight: FontWeight.w600,
                                decoration:
                                    isDone ? TextDecoration.lineThrough : null,
                              ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: DesignTokens.space4),
                        Text(
                          '$metaLabel • ${item.status.name}',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                  ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      if (item.status == AgendaStatus.done) {
                        onToggleStatus?.call(AgendaStatus.pending);
                      } else {
                        onToggleStatus?.call(AgendaStatus.done);
                      }
                    },
                    icon: Icon(
                      item.status == AgendaStatus.done
                          ? Icons.check_circle
                          : Icons.radio_button_unchecked,
                      color: statusColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _swipeBackground(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required bool alignLeft,
    required EdgeInsets margin,
    required double radius,
  }) {
    return Container(
      margin: margin,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: color.withValues(alpha: DesignTokens.opacityPressed),
        borderRadius: BorderRadius.circular(radius),
      ),
      child: Row(
        mainAxisAlignment:
            alignLeft ? MainAxisAlignment.start : MainAxisAlignment.end,
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 8),
          Text(label,
              style: TextStyle(color: color, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

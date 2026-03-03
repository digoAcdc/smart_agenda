import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../domain/entities/agenda_enums.dart';
import '../../domain/entities/agenda_item.dart';
import 'group_chip.dart';

class AgendaCard extends StatelessWidget {
  const AgendaCard({
    super.key,
    required this.item,
    this.groupName,
    this.groupColor,
    this.onTap,
    this.onToggleStatus,
    this.onDelete,
  });

  final AgendaItem item;
  final String? groupName;
  final Color? groupColor;
  final VoidCallback? onTap;
  final ValueChanged<AgendaStatus>? onToggleStatus;
  final Future<bool?> Function()? onDelete;

  @override
  Widget build(BuildContext context) {
    final isDone = item.status == AgendaStatus.done;
    final timeLabel =
        item.allDay ? 'Dia inteiro' : DateFormat('HH:mm').format(item.startAt);
    final metaLabel = item.allDay
        ? DateFormat('dd MMM').format(item.startAt)
        : DateFormat('dd MMM').format(item.startAt);
    Color statusColor;
    switch (item.status) {
      case AgendaStatus.done:
        statusColor = Colors.green;
        break;
      case AgendaStatus.canceled:
        statusColor = Colors.orange;
        break;
      case AgendaStatus.pending:
        statusColor = Theme.of(context).colorScheme.primary;
        break;
    }

    return Dismissible(
      key: ValueKey(item.id),
      background: _swipeBackground(
        context,
        icon: Icons.check_circle,
        label: 'Concluir',
        color: Colors.green,
        alignLeft: true,
      ),
      secondaryBackground: _swipeBackground(
        context,
        icon: Icons.delete_outline,
        label: 'Excluir',
        color: Colors.red,
        alignLeft: false,
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
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Opacity(
            opacity: isDone ? 0.7 : 1,
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Container(
                    width: 4,
                    height: 56,
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
                        const SizedBox(height: 4),
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
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(18),
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

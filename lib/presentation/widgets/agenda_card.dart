import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/theme/design_tokens.dart';
import '../../domain/entities/agenda_enums.dart';
import '../../domain/entities/agenda_item.dart';
import 'group_chip.dart';

enum AgendaCardVariant { regular, timeline }

class AgendaCard extends StatefulWidget {
  const AgendaCard({
    super.key,
    required this.item,
    this.groupName,
    this.groupColor,
    this.onTap,
    this.onToggleStatus,
    this.onDelete,
    this.variant = AgendaCardVariant.regular,
    this.initialExpanded = false,
  });

  final AgendaItem item;
  final String? groupName;
  final Color? groupColor;
  final VoidCallback? onTap;
  final ValueChanged<AgendaStatus>? onToggleStatus;
  final Future<bool?> Function()? onDelete;
  final AgendaCardVariant variant;
  final bool initialExpanded;

  @override
  State<AgendaCard> createState() => _AgendaCardState();
}

class _AgendaCardState extends State<AgendaCard> {
  late bool _expanded;

  @override
  void initState() {
    super.initState();
    _expanded = widget.initialExpanded;
  }

  @override
  void didUpdateWidget(AgendaCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.item.id != widget.item.id) {
      _expanded = widget.initialExpanded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
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
    final padding = widget.variant == AgendaCardVariant.timeline
        ? const EdgeInsets.all(12)
        : const EdgeInsets.all(14);
    final margin = widget.variant == AgendaCardVariant.timeline
        ? const EdgeInsets.symmetric(horizontal: 12, vertical: 4)
        : const EdgeInsets.symmetric(horizontal: 16, vertical: 6);
    final radius = widget.variant == AgendaCardVariant.timeline
        ? DesignTokens.radiusMd
        : DesignTokens.radiusLg;
    final railHeight = widget.variant == AgendaCardVariant.timeline ? 48.0 : 56.0;
    final compactRailHeight = 36.0;

    final isShared = item.ownerEmail != null;

    return Dismissible(
      key: ValueKey(item.id),
      direction: isShared ? DismissDirection.none : DismissDirection.horizontal,
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
        if (isShared) return false;
        if (direction == DismissDirection.startToEnd) {
          widget.onToggleStatus?.call(AgendaStatus.done);
          return false;
        }
        if (widget.onDelete != null) {
          return widget.onDelete!.call();
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
          onTap: widget.onTap,
          child: Opacity(
            opacity: isDone ? 0.7 : 1,
            child: Padding(
              padding: padding,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 4,
                        height: _expanded ? railHeight : compactRailHeight,
                        decoration: BoxDecoration(
                          color: widget.groupColor ?? statusColor,
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
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
                                if (widget.groupName != null && _expanded)
                                  GroupChip(
                                      label: widget.groupName!,
                                      color: widget.groupColor),
                              ],
                            ),
                            const SizedBox(height: 4),
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
                              maxLines: _expanded ? 3 : 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (_expanded) ...[
                              if (isShared) ...[
                                const SizedBox(height: 4),
                                Text(
                                  'Compartilhada por ${item.ownerEmail}',
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelSmall
                                      ?.copyWith(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .primary,
                                      ),
                                ),
                              ],
                              const SizedBox(height: DesignTokens.space4),
                              Text(
                                '$metaLabel • ${item.status.name}',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurfaceVariant,
                                    ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => setState(() => _expanded = !_expanded),
                        icon: Icon(
                          _expanded
                              ? Icons.keyboard_arrow_up
                              : Icons.keyboard_arrow_down,
                          color: Theme.of(context)
                              .colorScheme
                              .onSurfaceVariant,
                        ),
                        style: IconButton.styleFrom(
                          minimumSize: const Size(36, 36),
                          padding: EdgeInsets.zero,
                        ),
                      ),
                      if (!isShared)
                        IconButton(
                          onPressed: () {
                            if (item.status == AgendaStatus.done) {
                              widget.onToggleStatus?.call(AgendaStatus.pending);
                            } else {
                              widget.onToggleStatus?.call(AgendaStatus.done);
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

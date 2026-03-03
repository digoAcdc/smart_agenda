import 'package:flutter/material.dart';

import '../../domain/entities/agenda_enums.dart';
import '../../domain/entities/agenda_item.dart';
import 'agenda_card.dart';

class AgendaItemTile extends StatelessWidget {
  const AgendaItemTile({
    super.key,
    required this.item,
    this.onTap,
    this.onToggleStatus,
    this.onDelete,
  });

  final AgendaItem item;
  final VoidCallback? onTap;
  final ValueChanged<AgendaStatus>? onToggleStatus;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    return AgendaCard(
      item: item,
      onTap: onTap,
      onToggleStatus: onToggleStatus,
      onDelete: () async {
        onDelete?.call();
        return false;
      },
    );
  }
}

import 'package:flutter/material.dart';

import '../../core/theme/design_tokens.dart';
import '../../domain/entities/note.dart';

class ChecklistItemTile extends StatelessWidget {
  const ChecklistItemTile({
    super.key,
    required this.item,
    this.onChanged,
    this.onTap,
    this.onRemove,
    this.editable = true,
  });

  final ChecklistItem item;
  final ValueChanged<bool>? onChanged;
  final VoidCallback? onTap;
  final VoidCallback? onRemove;
  final bool editable;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          vertical: DesignTokens.spaceXs,
          horizontal: DesignTokens.spaceSm,
        ),
        child: Row(
          children: [
            if (editable)
              Checkbox(
                value: item.completed,
                onChanged: onChanged != null
                    ? (v) => onChanged!(v ?? false)
                    : null,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
              )
            else
              Icon(
                item.completed ? Icons.check_circle : Icons.radio_button_unchecked,
                size: 22,
                color: item.completed
                    ? theme.colorScheme.primary
                    : theme.colorScheme.outline,
              ),
            const SizedBox(width: DesignTokens.spaceSm),
            Expanded(
              child: Text(
                item.text,
                style: theme.textTheme.bodyMedium?.copyWith(
                  decoration: item.completed ? TextDecoration.lineThrough : null,
                  color: item.completed
                      ? theme.colorScheme.onSurfaceVariant
                      : theme.colorScheme.onSurface,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (onRemove != null)
              IconButton(
                icon: const Icon(Icons.close, size: 20),
                onPressed: onRemove,
                style: IconButton.styleFrom(
                  minimumSize: const Size(36, 36),
                  padding: EdgeInsets.zero,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../../core/theme/design_tokens.dart';

class GroupChip extends StatelessWidget {
  const GroupChip({
    super.key,
    required this.label,
    this.color,
  });

  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final chipColor = color ?? Theme.of(context).colorScheme.primary;
    return Chip(
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.compact,
      labelPadding: const EdgeInsets.symmetric(
        horizontal: DesignTokens.space6,
      ),
      side: BorderSide.none,
      backgroundColor: chipColor.withValues(alpha: DesignTokens.opacityPressed),
      label: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: chipColor,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}

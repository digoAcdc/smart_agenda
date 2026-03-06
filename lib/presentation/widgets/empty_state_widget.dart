import 'package:flutter/material.dart';

import '../../core/theme/design_tokens.dart';

class EmptyStateWidget extends StatelessWidget {
  const EmptyStateWidget({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.ctaLabel,
    this.onTapCta,
    this.compact = false,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? ctaLabel;
  final VoidCallback? onTapCta;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: compact ? 56 : 72,
              height: compact ? 56 : 72,
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
              ),
              child: Icon(
                icon,
                size: compact ? 26 : 32,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: DesignTokens.spaceMd),
            Text(title, style: theme.textTheme.titleMedium),
            const SizedBox(height: DesignTokens.spaceXs),
            Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            if (ctaLabel != null && onTapCta != null) ...[
              const SizedBox(height: DesignTokens.spaceMd),
              FilledButton(onPressed: onTapCta, child: Text(ctaLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}

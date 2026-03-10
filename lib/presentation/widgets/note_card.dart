import 'dart:io';

import 'package:flutter/material.dart';

import '../../core/theme/design_tokens.dart';
import '../../domain/entities/note.dart';
import 'ui_primitives.dart';

class NoteCard extends StatelessWidget {
  const NoteCard({
    super.key,
    required this.note,
    this.onTap,
    this.onDelete,
  });

  final Note note;
  final VoidCallback? onTap;
  final Future<bool?> Function()? onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasChecklist = note.checklistItems.isNotEmpty;
    final completedCount =
        note.checklistItems.where((i) => i.completed).length;
    final checklistPreview = hasChecklist
        ? '$completedCount de ${note.checklistItems.length} concluidos'
        : null;

    return AppSurfaceCard(
      margin: const EdgeInsets.only(bottom: DesignTokens.spaceXs),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
        child: Padding(
          padding: const EdgeInsets.all(DesignTokens.spaceMd),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (note.imagePath != null || note.imageUrl != null) ...[
                    ClipRRect(
                      borderRadius:
                          BorderRadius.circular(DesignTokens.radiusMd),
                      child: _buildThumbnail(context),
                    ),
                    const SizedBox(width: DesignTokens.spaceMd),
                  ],
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          note.title,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (note.body?.isNotEmpty == true) ...[
                          const SizedBox(height: 4),
                          Text(
                            note.body!,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                        if (checklistPreview != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            checklistPreview,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    onSelected: (v) {
                      if (v == 'delete' && onDelete != null) onDelete!();
                    },
                    itemBuilder: (_) => const [
                      PopupMenuItem(value: 'delete', child: Text('Excluir')),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildThumbnail(BuildContext context) {
    const size = 56.0;
    if (note.imagePath != null) {
      final path = note.imagePath!;
      if (File(path).existsSync()) {
        return Image.file(
          File(path),
          width: size,
          height: size,
          fit: BoxFit.cover,
        );
      }
    }
    if (note.imageUrl != null && note.imageUrl!.isNotEmpty) {
      return Image.network(
        note.imageUrl!,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) =>
            _placeholder(context, size),
      );
    }
    return _placeholder(context, size);
  }

  Widget _placeholder(BuildContext context, double size) {
    return Container(
      width: size,
      height: size,
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Icon(
        Icons.image_outlined,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
        size: 24,
      ),
    );
  }
}

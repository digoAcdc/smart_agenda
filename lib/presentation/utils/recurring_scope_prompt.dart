import 'package:flutter/material.dart';

enum RecurringScope { onlyThis, all }

/// Evento que se repete: pergunta se a acao vale so para o dia tocado ou
/// para a serie inteira. Retorna nulo se a pessoa cancelar.
Future<RecurringScope?> askRecurringScope(
  BuildContext context, {
  required String title,
}) {
  return showModalBottomSheet<RecurringScope>(
    context: context,
    showDragHandle: true,
    builder: (sheetContext) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 0, 8, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Text(
                title,
                style: Theme.of(sheetContext).textTheme.titleMedium,
              ),
            ),
            ListTile(
              leading: const Icon(Icons.event_outlined),
              title: const Text('Só este dia'),
              onTap: () => Navigator.pop(sheetContext, RecurringScope.onlyThis),
            ),
            ListTile(
              leading: const Icon(Icons.repeat_rounded),
              title: const Text('Todos os dias da repetição'),
              onTap: () => Navigator.pop(sheetContext, RecurringScope.all),
            ),
          ],
        ),
      ),
    ),
  );
}

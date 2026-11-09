import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/theme/design_tokens.dart';
import '../../domain/services/backpack_planner.dart';
import '../services/backpack_reminder_service.dart';

/// Checklist "ja coloquei" da Mochila de amanha, por materia. Usada no
/// quadro "Amanhã leve:" da Inicio e na tela aberta pelo aviso das 20h.
class BackpackChecklist extends StatelessWidget {
  const BackpackChecklist({super.key, required this.groups});

  final List<BackpackSubjectGroup> groups;

  /// (marcados, total) para o "2 de 5".
  static (int, int) progress(
    BackpackReminderService service,
    List<BackpackSubjectGroup> groups,
  ) {
    var done = 0;
    var total = 0;
    for (final g in groups) {
      for (final i in g.items) {
        total++;
        if (service.isChecked(g, i)) done++;
      }
    }
    return (done, total);
  }

  @override
  Widget build(BuildContext context) {
    final service = Get.find<BackpackReminderService>();
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Obx(() {
      // Reage as marcacoes.
      service.checked.length;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final g in groups) ...[
            Padding(
              padding: const EdgeInsets.only(top: DesignTokens.spaceSm),
              child: Text(
                g.owner == null ? g.subject : '${g.owner} · ${g.subject}',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            for (final item in g.items)
              _BackpackCheckRow(
                label: item.label,
                oneOff: !item.isWeekly,
                checked: service.isChecked(g, item),
                onToggle: () => service.toggleChecked(g, item),
              ),
          ],
        ],
      );
    });
  }
}

class _BackpackCheckRow extends StatelessWidget {
  const _BackpackCheckRow({
    required this.label,
    required this.oneOff,
    required this.checked,
    required this.onToggle,
  });

  final String label;
  final bool oneOff;
  final bool checked;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Semantics(
      checked: checked,
      label: checked ? '$label, já coloquei' : label,
      excludeSemantics: true,
      child: InkWell(
        onTap: onToggle,
        borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 44),
          child: Row(
            children: [
              Checkbox(
                value: checked,
                onChanged: (_) => onToggle(),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              Expanded(
                child: Text(
                  label,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    decoration: checked ? TextDecoration.lineThrough : null,
                    color: checked ? scheme.onSurfaceVariant : scheme.onSurface,
                  ),
                ),
              ),
              if (oneOff)
                Padding(
                  padding: const EdgeInsets.only(left: 6, right: 4),
                  child: Text(
                    'só desta vez',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: scheme.primary,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

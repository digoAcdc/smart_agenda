import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../core/theme/design_tokens.dart';
import '../../domain/entities/school_record.dart';
import '../../domain/services/school_records_summary.dart';
import '../controllers/school_records_controller.dart';
import 'school_record_form_sheet.dart';

/// Aba "Notas e faltas" da tela Aulas: um cartao por materia da grade
/// aberta, com media e faltas, e atalhos para lancar.
class SchoolRecordsView extends StatelessWidget {
  const SchoolRecordsView({super.key, required this.canEdit});

  final bool canEdit;

  static const _termLabels = <int?, String>{
    1: '1º bim',
    2: '2º bim',
    3: '3º bim',
    4: '4º bim',
    null: 'Ano todo',
  };

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<SchoolRecordsController>();
    final theme = Theme.of(context);
    return Obx(() {
      final term = controller.term.value;
      final summaries = controller.summaries;
      return ListView(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 120),
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final entry in _termLabels.entries)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(entry.value),
                      selected: term == entry.key,
                      onSelected: (_) => controller.term.value = entry.key,
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 6, 4, 10),
            child: Text(
              term == null
                  ? 'Média do ano e faltas de cada matéria.'
                  : 'Média do $termº bimestre e faltas do ano.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          for (final s in summaries)
            _SubjectCard(summary: s, term: term, canEdit: canEdit),
          if (!canEdit)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'Só quem pode editar a agenda da Família lança notas e faltas.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
        ],
      );
    });
  }
}

class _SubjectCard extends StatelessWidget {
  const _SubjectCard({
    required this.summary,
    required this.term,
    required this.canEdit,
  });

  final SubjectRecordsSummary summary;
  final int? term;
  final bool canEdit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final average = summary.average;
    final absences = summary.absences;
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _SubjectRecordsSheet.show(
          context,
          subject: summary.subject,
          canEdit: canEdit,
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          summary.subject,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: [
                            _Pill(
                              icon: Icons.event_busy_outlined,
                              text: absences == 1
                                  ? '1 falta'
                                  : '$absences faltas',
                            ),
                            _Pill(
                              icon: Icons.grade_outlined,
                              text: summary.grades.length == 1
                                  ? '1 nota'
                                  : '${summary.grades.length} notas',
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Semantics(
                    label: average == null
                        ? 'Sem notas'
                        : 'Média ${formatScore(average)}',
                    excludeSemantics: true,
                    child: Column(
                      children: [
                        Text(
                          average == null ? '—' : formatScore(average),
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: average == null
                                ? scheme.outline
                                : scheme.primary,
                          ),
                        ),
                        Text(
                          'média',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (canEdit) ...[
                const SizedBox(height: 6),
                Row(
                  children: [
                    TextButton.icon(
                      onPressed: () => SchoolRecordFormSheet.show(
                        context,
                        subject: summary.subject,
                        kind: SchoolRecordKind.grade,
                      ),
                      icon: const Icon(Icons.add_rounded, size: 18),
                      label: const Text('Nota'),
                    ),
                    TextButton.icon(
                      onPressed: () => SchoolRecordFormSheet.show(
                        context,
                        subject: summary.subject,
                        kind: SchoolRecordKind.absence,
                      ),
                      icon: const Icon(Icons.add_rounded, size: 18),
                      label: const Text('Falta'),
                    ),
                    const Spacer(),
                    Icon(Icons.chevron_right_rounded, color: scheme.outline),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: context.palette.surfaceSoft,
        borderRadius: BorderRadius.circular(DesignTokens.radiusSm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 4),
          Text(text, style: theme.textTheme.labelMedium),
        ],
      ),
    );
  }
}

/// Tudo de uma materia: notas (do bimestre escolhido) e faltas, com editar.
class _SubjectRecordsSheet extends StatelessWidget {
  const _SubjectRecordsSheet({required this.subject, required this.canEdit});

  final String subject;
  final bool canEdit;

  static Future<void> show(
    BuildContext context, {
    required String subject,
    required bool canEdit,
  }) => showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => _SubjectRecordsSheet(subject: subject, canEdit: canEdit),
  );

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<SchoolRecordsController>();
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final dayFmt = DateFormat('EEE, dd/MM', 'pt_BR');
    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.85,
        ),
        child: Obx(() {
          final term = controller.term.value;
          final all = controller.recordsFor(subject);
          final grades = all
              .where((r) => !r.isAbsence && (term == null || r.term == term))
              .toList();
          final absences = all.where((r) => r.isAbsence).toList();
          final average = averageOf(grades);
          return ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            children: [
              Text(
                subject,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                [
                  if (average != null)
                    'Média ${formatScore(average)}'
                        '${term == null ? ' no ano' : ' no $termº bimestre'}',
                  absences.length == 1
                      ? '1 falta'
                      : '${absences.length} faltas',
                ].join(' · '),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: DesignTokens.spaceMd),
              _sectionTitle(
                theme,
                term == null ? 'Notas do ano' : 'Notas do $termº bimestre',
              ),
              if (grades.isEmpty)
                _emptyLine(theme, 'Nenhuma nota lançada.')
              else
                for (final g in grades)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.grade_outlined),
                    title: Text(g.title ?? 'Avaliação'),
                    subtitle: Text(
                      [
                        dayFmt.format(g.date),
                        if (g.term != null) '${g.term}º bim',
                        if (g.note != null) g.note!,
                      ].join(' · '),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: Text(
                      '${formatScore(g.score ?? 0)}/'
                      '${formatScore(g.maxScore ?? 10)}',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    onTap: canEdit
                        ? () => SchoolRecordFormSheet.show(
                            context,
                            subject: subject,
                            kind: SchoolRecordKind.grade,
                            record: g,
                          )
                        : null,
                  ),
              const SizedBox(height: DesignTokens.spaceSm),
              _sectionTitle(theme, 'Faltas'),
              if (absences.isEmpty)
                _emptyLine(theme, 'Nenhuma falta lançada.')
              else
                for (final a in absences)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.event_busy_outlined),
                    title: Text(
                      toBeginningOfSentenceCase(
                        DateFormat('EEEE, dd/MM/yyyy', 'pt_BR').format(a.date),
                      ),
                    ),
                    subtitle: a.note == null
                        ? null
                        : Text(
                            a.note!,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                    onTap: canEdit
                        ? () => SchoolRecordFormSheet.show(
                            context,
                            subject: subject,
                            kind: SchoolRecordKind.absence,
                            record: a,
                          )
                        : null,
                  ),
              if (canEdit) ...[
                const SizedBox(height: DesignTokens.spaceMd),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(48),
                        ),
                        onPressed: () => SchoolRecordFormSheet.show(
                          context,
                          subject: subject,
                          kind: SchoolRecordKind.grade,
                        ),
                        icon: const Icon(Icons.add_rounded),
                        label: const Text('Nota'),
                      ),
                    ),
                    const SizedBox(width: DesignTokens.spaceSm),
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(48),
                        ),
                        onPressed: () => SchoolRecordFormSheet.show(
                          context,
                          subject: subject,
                          kind: SchoolRecordKind.absence,
                        ),
                        icon: const Icon(Icons.add_rounded),
                        label: const Text('Falta'),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          );
        }),
      ),
    );
  }

  Widget _sectionTitle(ThemeData theme, String text) => Padding(
    padding: const EdgeInsets.only(bottom: 4),
    child: Text(
      text,
      style: theme.textTheme.labelLarge?.copyWith(
        fontWeight: FontWeight.w700,
        color: theme.colorScheme.onSurfaceVariant,
      ),
    ),
  );

  Widget _emptyLine(ThemeData theme, String text) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Text(text, style: theme.textTheme.bodyMedium),
  );
}

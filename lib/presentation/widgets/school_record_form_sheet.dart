import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../core/theme/design_tokens.dart';
import '../../domain/entities/school_record.dart';
import '../../domain/services/school_records_summary.dart';
import '../controllers/school_records_controller.dart';

/// Lancar ou editar uma nota ou falta de uma materia.
class SchoolRecordFormSheet extends StatefulWidget {
  const SchoolRecordFormSheet({
    super.key,
    required this.subject,
    required this.kind,
    this.record,
  });

  final String subject;
  final SchoolRecordKind kind;

  /// Preenchido na edicao.
  final SchoolRecord? record;

  /// Abre o formulario. Retorna true se salvou ou excluiu.
  static Future<bool?> show(
    BuildContext context, {
    required String subject,
    required SchoolRecordKind kind,
    SchoolRecord? record,
  }) => showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) =>
        SchoolRecordFormSheet(subject: subject, kind: kind, record: record),
  );

  @override
  State<SchoolRecordFormSheet> createState() => _SchoolRecordFormSheetState();
}

class _SchoolRecordFormSheetState extends State<SchoolRecordFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _title;
  late final TextEditingController _score;
  late final TextEditingController _maxScore;
  late final TextEditingController _note;
  late DateTime _date;
  late int _term;
  bool _saving = false;

  bool get _isGrade => widget.kind == SchoolRecordKind.grade;
  bool get _isEdit => widget.record != null;

  SchoolRecordsController get _controller =>
      Get.find<SchoolRecordsController>();

  @override
  void initState() {
    super.initState();
    final r = widget.record;
    final now = DateTime.now();
    _date = r?.date ?? DateTime(now.year, now.month, now.day);
    _term = r?.term ?? termForDate(_date);
    _title = TextEditingController(text: r?.title ?? '');
    _score = TextEditingController(
      text: r?.score == null ? '' : formatScore(r!.score!),
    );
    _maxScore = TextEditingController(text: formatScore(r?.maxScore ?? 10));
    _note = TextEditingController(text: r?.note ?? '');
  }

  @override
  void dispose() {
    _title.dispose();
    _score.dispose();
    _maxScore.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(_date.year - 2),
      lastDate: DateTime(DateTime.now().year + 1, 12, 31),
    );
    if (picked == null) return;
    setState(() {
      // Nota nova acompanha o bimestre da data escolhida.
      if (_isGrade && !_isEdit) _term = termForDate(picked);
      _date = picked;
    });
  }

  Future<void> _save() async {
    if (_saving || _formKey.currentState?.validate() != true) return;
    setState(() => _saving = true);
    final note = _note.text.trim().isEmpty ? null : _note.text.trim();
    final r = widget.record;
    if (_isGrade) {
      final score = parseScore(_score.text)!;
      final max = parseScore(_maxScore.text) ?? 10;
      final title = _title.text.trim().isEmpty ? null : _title.text.trim();
      if (r == null) {
        await _controller.addGrade(
          widget.subject,
          score: score,
          maxScore: max,
          term: _term,
          date: _date,
          title: title,
          note: note,
        );
      } else {
        await _controller.updateRecord(
          _withEdits(r, score: score, maxScore: max, title: title, note: note),
        );
      }
    } else if (r == null) {
      await _controller.addAbsence(widget.subject, date: _date, note: note);
    } else {
      await _controller.updateRecord(_withEdits(r, note: note));
    }
    if (mounted) Navigator.of(context).pop(true);
  }

  /// copyWith nao limpa campos; aqui titulo/observacao podem ser apagados.
  SchoolRecord _withEdits(
    SchoolRecord r, {
    double? score,
    double? maxScore,
    String? title,
    String? note,
  }) => SchoolRecord(
    id: r.id,
    scheduleId: r.scheduleId,
    subject: r.subject,
    kind: r.kind,
    date: _date,
    title: _isGrade ? title : null,
    score: score ?? r.score,
    maxScore: maxScore ?? r.maxScore,
    term: _isGrade ? _term : null,
    note: note,
    familyId: r.familyId,
    childId: r.childId,
    createdAt: r.createdAt,
    updatedAt: r.updatedAt,
  );

  Future<void> _delete() async {
    final r = widget.record;
    if (r == null) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(_isGrade ? 'Excluir nota?' : 'Excluir falta?'),
        content: const Text('Não dá para desfazer.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await _controller.deleteRecord(r.id);
    if (mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final title = _isGrade
        ? (_isEdit ? 'Editar nota' : 'Nova nota')
        : (_isEdit ? 'Editar falta' : 'Nova falta');
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  widget.subject,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: DesignTokens.spaceMd),
                if (_isGrade) ...[
                  TextFormField(
                    controller: _title,
                    textCapitalization: TextCapitalization.sentences,
                    maxLength: 80,
                    decoration: const InputDecoration(
                      labelText: 'Avaliação (opcional)',
                      hintText: 'Ex.: Prova 1, Trabalho de grupo',
                      counterText: '',
                    ),
                  ),
                  const SizedBox(height: DesignTokens.spaceSm),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _score,
                          autofocus: !_isEdit,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: const InputDecoration(
                            labelText: 'Nota',
                            hintText: 'Ex.: 8,5',
                          ),
                          validator: (v) {
                            final score = parseScore(v ?? '');
                            if (score == null) return 'Digite a nota';
                            final max = parseScore(_maxScore.text);
                            if (max != null && score > max) {
                              return 'Maior que a nota máxima';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: DesignTokens.spaceSm),
                      Expanded(
                        child: TextFormField(
                          controller: _maxScore,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: const InputDecoration(
                            labelText: 'Vale',
                            helperText: 'Nota máxima',
                          ),
                          validator: (v) {
                            final max = parseScore(v ?? '');
                            if (max == null || max <= 0) {
                              return 'Valor inválido';
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: DesignTokens.spaceSm),
                  Text('Bimestre', style: theme.textTheme.labelLarge),
                  const SizedBox(height: DesignTokens.spaceXxs),
                  Wrap(
                    spacing: 8,
                    children: [
                      for (var t = 1; t <= 4; t++)
                        ChoiceChip(
                          label: Text('$tº'),
                          selected: _term == t,
                          onSelected: (_) => setState(() => _term = t),
                        ),
                    ],
                  ),
                  const SizedBox(height: DesignTokens.spaceSm),
                ],
                _DateField(
                  label: _isGrade ? 'Data da avaliação' : 'Dia da falta',
                  date: _date,
                  onTap: _pickDate,
                ),
                const SizedBox(height: DesignTokens.spaceSm),
                TextFormField(
                  controller: _note,
                  textCapitalization: TextCapitalization.sentences,
                  maxLength: 500,
                  minLines: 1,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: 'Observação (opcional)',
                    hintText: _isGrade
                        ? 'Ex.: recuperação, conteúdo da prova'
                        : 'Ex.: atestado médico, viagem',
                  ),
                ),
                const SizedBox(height: DesignTokens.spaceSm),
                FilledButton(
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(
                      DesignTokens.buttonHeight,
                    ),
                  ),
                  onPressed: _saving ? null : _save,
                  child: Text(_isGrade ? 'Salvar nota' : 'Salvar falta'),
                ),
                if (_isEdit)
                  TextButton(
                    style: TextButton.styleFrom(
                      foregroundColor: theme.colorScheme.error,
                      minimumSize: const Size.fromHeight(44),
                    ),
                    onPressed: _saving ? null : _delete,
                    child: Text(_isGrade ? 'Excluir nota' : 'Excluir falta'),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DateField extends StatelessWidget {
  const _DateField({
    required this.label,
    required this.date,
    required this.onTap,
  });

  final String label;
  final DateTime date;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(DesignTokens.radiusSm),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          suffixIcon: const Icon(Icons.calendar_today_outlined, size: 20),
        ),
        child: Text(
          toBeginningOfSentenceCase(
            DateFormat('EEE, dd/MM/yyyy', 'pt_BR').format(date),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/theme/design_tokens.dart';
import '../../domain/services/backpack_planner.dart';
import '../controllers/class_schedule_controller.dart';
import '../services/backpack_reminder_service.dart';

const _weekdayShort = ['seg', 'ter', 'qua', 'qui', 'sex', 'sáb', 'dom'];

/// "ter, 10/11"; "hoje" e "amanhã" quando for o caso ("amanhã, ter 10/11").
String formatBackpackDay(DateTime day, {DateTime? now}) {
  final ref = now ?? DateTime.now();
  final today = DateTime(ref.year, ref.month, ref.day);
  final d = DateTime(day.year, day.month, day.day);
  final dd = d.day.toString().padLeft(2, '0');
  final mm = d.month.toString().padLeft(2, '0');
  final weekday = _weekdayShort[d.weekday - 1];
  final diff = d.difference(today).inDays;
  if (diff == 0) return 'hoje, $weekday $dd/$mm';
  if (diff == 1) return 'amanhã, $weekday $dd/$mm';
  return '$weekday, $dd/$mm';
}

/// "seg e qua" a partir dos dias da semana (1 = segunda).
String formatWeekdays(List<int> weekdays) =>
    joinPt([for (final d in weekdays) _weekdayShort[d - 1]]);

/// Fluxo "Adicionar à mochila": o que levar (sugestoes + texto livre, varios
/// de uma vez), quando (toda aula ou um dia de aula) e se quer o lembrete
/// das 20h da vespera. Volta com quantos itens entraram (ou nulo).
class AddBackpackSheet extends StatefulWidget {
  const AddBackpackSheet({super.key, required this.subject});

  final String subject;

  static const suggestions = [
    'Tênis',
    'Uniforme de Ed. Física',
    'Calculadora',
    'Livro',
    'Caderno',
    'Material de arte',
  ];

  static Future<int?> show(BuildContext context, String subject) =>
      showModalBottomSheet<int>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        showDragHandle: true,
        builder: (_) => AddBackpackSheet(subject: subject),
      );

  @override
  State<AddBackpackSheet> createState() => _AddBackpackSheetState();
}

class _AddBackpackSheetState extends State<AddBackpackSheet> {
  final _textController = TextEditingController();

  /// Itens escolhidos, na ordem do toque.
  final List<String> _picked = [];

  /// Itens digitados (aparecem como chips ja marcados).
  final List<String> _custom = [];

  /// Nulo = toda aula.
  DateTime? _day;
  bool _remind = true;
  bool _saving = false;
  String? _error;

  ClassScheduleController get _controller =>
      Get.find<ClassScheduleController>();

  @override
  void initState() {
    super.initState();
    _textController.addListener(() => setState(() => _error = null));
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  bool _isPicked(String label) =>
      _picked.any((p) => p.toLowerCase() == label.toLowerCase());

  void _toggle(String label) {
    setState(() {
      _error = null;
      if (_isPicked(label)) {
        _picked.removeWhere((p) => p.toLowerCase() == label.toLowerCase());
      } else {
        _picked.add(label);
      }
    });
  }

  /// Texto digitado vira chip marcado.
  void _addTyped() {
    final text = _textController.text.trim();
    if (text.isEmpty) return;
    setState(() {
      final known = [
        ...AddBackpackSheet.suggestions,
        ..._custom,
      ].firstWhereOrNull((s) => s.toLowerCase() == text.toLowerCase());
      if (known == null) _custom.add(text);
      if (!_isPicked(text)) _picked.add(known ?? text);
    });
    _textController.clear();
  }

  /// O que vai ser gravado: os marcados + o que ficou digitado no campo.
  List<String> get _labels {
    final typed = _textController.text.trim();
    return [..._picked, if (typed.isNotEmpty && !_isPicked(typed)) typed];
  }

  Future<void> _save() async {
    final labels = _labels;
    if (labels.isEmpty || _saving) return;
    setState(() => _saving = true);
    final error = await _controller.addBackpackItems(
      widget.subject,
      labels,
      onDay: _day,
      remind: _remind,
    );
    if (!mounted) return;
    if (error != null) {
      setState(() {
        _saving = false;
        _error = error;
      });
      return;
    }
    Navigator.of(context).pop(labels.length);
  }

  Widget _stepTitle(BuildContext context, String text) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(
        top: DesignTokens.spaceMd,
        bottom: DesignTokens.spaceXs,
      ),
      child: Semantics(
        header: true,
        child: Text(
          text,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final subject = widget.subject;
    final dates = _controller.upcomingClassDatesFor(subject);
    final weekdays = _controller.classWeekdaysFor(subject);
    // Itens de toda aula que a materia ja tem nao aparecem como sugestao.
    final already = {
      for (final i in _controller.backpackFor(subject))
        if (i.isWeekly) i.label.toLowerCase(),
    };
    final options = [
      ..._custom,
      for (final s in AddBackpackSheet.suggestions)
        if (!already.contains(s.toLowerCase()) &&
            !_custom.any((c) => c.toLowerCase() == s.toLowerCase()))
          s,
    ];
    final globalOff =
        Get.isRegistered<BackpackReminderService>() &&
        !Get.find<BackpackReminderService>().enabled.value;
    final count = _labels.length;

    final String remindSubtitle;
    final day = _day;
    if (!_remind) {
      remindSubtitle =
          'Sem aviso. O item aparece só na lista "Amanhã leve" da Início.';
    } else if (day == null) {
      remindSubtitle = 'Às 20h da véspera de cada aula de $subject.';
    } else {
      final eve = DateTime(day.year, day.month, day.day - 1, 20);
      remindSubtitle = eve.isAfter(DateTime.now())
          ? 'Às 20h de ${formatBackpackDay(eve)}.'
          : 'O aviso das 20h da véspera desse dia já passou.';
    }

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Adicionar à mochila',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    subject,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  _stepTitle(context, '1. O que levar?'),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      for (final s in options)
                        FilterChip(
                          label: Text(s),
                          selected: _isPicked(s),
                          onSelected: (_) => _toggle(s),
                        ),
                    ],
                  ),
                  const SizedBox(height: DesignTokens.spaceXs),
                  TextField(
                    controller: _textController,
                    textCapitalization: TextCapitalization.sentences,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _addTyped(),
                    decoration: InputDecoration(
                      labelText: 'Outro item',
                      hintText: 'ex.: flauta, autorização assinada',
                      suffixIcon: IconButton(
                        tooltip: 'Incluir item',
                        onPressed: _textController.text.trim().isEmpty
                            ? null
                            : _addTyped,
                        icon: const Icon(Icons.add_circle_outline_rounded),
                      ),
                    ),
                  ),
                  _stepTitle(context, '2. Quando levar?'),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      ChoiceChip(
                        label: Text(
                          weekdays.isEmpty
                              ? 'Toda aula'
                              : 'Toda aula (${formatWeekdays(weekdays)})',
                        ),
                        selected: _day == null,
                        onSelected: (_) => setState(() => _day = null),
                      ),
                      for (final d in dates)
                        ChoiceChip(
                          label: Text('Só ${formatBackpackDay(d)}'),
                          selected: _day == d,
                          onSelected: (_) => setState(() => _day = d),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _day == null
                        ? 'Vai na mochila sempre que tiver $subject.'
                        : 'Só nesse dia. Depois da aula, sai da lista sozinho.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  _stepTitle(context, '3. Quer lembrete?'),
                  Container(
                    decoration: BoxDecoration(
                      color: scheme.primaryContainer.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(
                        DesignTokens.radiusMd,
                      ),
                    ),
                    child: SwitchListTile(
                      value: _remind,
                      onChanged: (v) => setState(() => _remind = v),
                      secondary: Icon(
                        _remind
                            ? Icons.notifications_active_outlined
                            : Icons.notifications_off_outlined,
                        color: _remind ? scheme.primary : scheme.outline,
                      ),
                      title: const Text('Me avisar na véspera'),
                      subtitle: Text(remindSubtitle),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          DesignTokens.radiusMd,
                        ),
                      ),
                    ),
                  ),
                  if (globalOff && _remind)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        'Os lembretes da Mochila estão desligados em '
                        'Notificações. Ligue lá para receber o aviso.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.error,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
              child: Text(
                _error!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: scheme.error,
                ),
              ),
            ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                ),
                onPressed: count == 0 || _saving ? null : _save,
                icon: const Icon(Icons.backpack_outlined),
                label: Text(
                  count == 0
                      ? 'Escolha o que levar'
                      : count == 1
                      ? 'Adicionar 1 item'
                      : 'Adicionar $count itens',
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

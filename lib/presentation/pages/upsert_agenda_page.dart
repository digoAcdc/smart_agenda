import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../core/constants/image_upload_constants.dart';
import '../../core/theme/design_tokens.dart';
import '../../core/utils/account_prompt_utils.dart';
import '../../core/utils/form_validators.dart';
import '../../domain/entities/agenda_enums.dart';
import '../../domain/entities/agenda_item.dart';
import '../../domain/entities/attachment_ref.dart';
import '../../domain/entities/recurrence_rule.dart';
import '../../domain/entities/reminder_config.dart';
import '../../domain/entities/family.dart';
import '../../domain/repositories/i_family_service.dart';
import '../../domain/repositories/i_file_storage_service.dart';
import '../../domain/repositories/i_notification_service.dart';
import '../../domain/repositories/i_plan_service.dart';
import '../controllers/agenda_controller.dart';
import '../controllers/billing_controller.dart';
import '../controllers/groups_controller.dart';

class UpsertAgendaPage extends StatefulWidget {
  const UpsertAgendaPage({super.key});

  @override
  State<UpsertAgendaPage> createState() => _UpsertAgendaPageState();
}

class _UpsertAgendaPageState extends State<UpsertAgendaPage> {
  final _formKey = GlobalKey<FormState>();
  final titleController = TextEditingController();
  final descriptionController = TextEditingController();
  final imagePicker = ImagePicker();

  DateTime startAt = DateTime.now();
  DateTime? endAt;
  bool allDay = false;
  AgendaStatus status = AgendaStatus.pending;
  String? groupId;
  bool reminderEnabled = false;
  int? reminderMinutes = 10;
  List<AttachmentRef> attachments = [];

  // Repeticao (Fase 1 do roadmap).
  RecurrenceType repeatType = RecurrenceType.none;
  Set<int> repeatDays = {};
  _RepeatEnd repeatEnd = _RepeatEnd.never;
  DateTime? repeatUntil;
  int repeatCount = 10;
  RecurrenceRule? _originalRule;

  /// "Editar so este dia" de um evento que se repete: salva como evento
  /// novo e tira o dia da serie original.
  AgendaItem? _detachFrom;
  AgendaItem? editingItem;
  bool _isPremium = false;

  final _family = Get.find<IFamilyService>();
  // Destino e papeis do item na Familia (nulo = agenda pessoal).
  String? familyId;
  AgendaItemKind kind = AgendaItemKind.event;
  AgendaSubjectType subjectType = AgendaSubjectType.family;
  String? subjectChildId;
  String? subjectUserId;
  AgendaAssigneeType assigneeType = AgendaAssigneeType.none;
  String? assigneeUserId;

  /// Imagens: Pro pessoal, ou item de Familia (a assinatura e do dono).
  /// Fotos liberadas para todos. Sem Pro (e fora da Familia) ficam so no
  /// aparelho; o servidor so aceita upload com Pro ou na Familia.
  bool get _photosStayOnDevice => !_isPremium && familyId == null;

  @override
  void initState() {
    super.initState();
    final rawArg = Get.arguments;
    final detach = rawArg is Map ? rawArg['detachOccurrence'] : null;
    final arg = detach is AgendaItem ? detach : rawArg;
    if (arg is AgendaItem) {
      if (detach is AgendaItem) {
        _detachFrom = detach;
      } else {
        editingItem = arg;
        _loadRecurrence(arg.recurrence, arg.startAt);
      }
      titleController.text = arg.title;
      descriptionController.text = arg.description ?? '';
      startAt = arg.startAt;
      endAt = arg.endAt;
      allDay = arg.allDay;
      status = arg.status;
      groupId = arg.groupId;
      reminderEnabled = arg.reminder?.enabled ?? false;
      reminderMinutes = arg.reminder?.minutesBefore;
      attachments = _detachFrom == null
          ? [...arg.attachments]
          // Copia de evento da serie: anexos com ids novos.
          : arg.attachments
                .map((a) => a.copyWith(id: const Uuid().v4()))
                .toList();
      familyId = arg.familyId;
      kind = arg.kind;
      subjectType = arg.subjectType;
      subjectChildId = arg.subjectChildId;
      subjectUserId = arg.subjectUserId;
      assigneeType = arg.assigneeType;
      assigneeUserId = arg.assigneeUserId;
    } else {
      // Com Familia editavel, novos itens vao para a agenda da Familia.
      final ctx = _family.context;
      if (ctx.canEditAgenda) familyId = ctx.familyId;
      if (arg is Map && arg['childId'] is String && familyId != null) {
        subjectType = AgendaSubjectType.child;
        subjectChildId = arg['childId'] as String;
      }
    }
    _loadPlanStatus();
  }

  Future<void> _loadPlanStatus() async {
    final plan = Get.find<IPlanService>();
    await plan.refresh();
    var isPremium = await plan.isPremium();
    if (!isPremium && Get.isRegistered<BillingController>()) {
      await Get.find<BillingController>().revalidateInBackground(
        triggerRestore: true,
        reason: 'upsert_agenda_gate',
      );
      await plan.refresh();
      isPremium = await plan.isPremium();
    }
    if (!mounted) return;
    setState(() => _isPremium = isPremium);
  }

  void _loadRecurrence(RecurrenceRule? rule, DateTime start) {
    if (rule == null || !rule.repeats) return;
    _originalRule = rule;
    repeatType = rule.type;
    repeatDays = {...?rule.byWeekDays};
    if (rule.until != null) {
      repeatEnd = _RepeatEnd.until;
      repeatUntil = rule.until;
    } else if (rule.count != null) {
      repeatEnd = _RepeatEnd.count;
      repeatCount = rule.count!;
    }
  }

  RecurrenceRule? _buildRecurrence() {
    if (repeatType == RecurrenceType.none) return null;
    // Mesmo tipo de antes: mantem dias concluidos/excluidos da serie.
    final keep = _originalRule?.type == repeatType ? _originalRule : null;
    final days = repeatDays.isEmpty ? {startAt.weekday} : repeatDays;
    return RecurrenceRule(
      type: repeatType,
      byWeekDays: repeatType == RecurrenceType.weekly
          ? (days.toList()..sort())
          : null,
      until: repeatEnd == _RepeatEnd.until ? repeatUntil : null,
      count: repeatEnd == _RepeatEnd.count ? repeatCount : null,
      exceptions: keep?.exceptions ?? const [],
      completedDates: keep?.completedDates ?? const [],
    );
  }

  static const _weekdayShort = {
    1: 'Seg',
    2: 'Ter',
    3: 'Qua',
    4: 'Qui',
    5: 'Sex',
    6: 'Sáb',
    7: 'Dom',
  };

  Widget _buildRepeatSection(BuildContext context, Color accent) {
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    String typeLabel(RecurrenceType t) => switch (t) {
      RecurrenceType.none => 'Não repete',
      RecurrenceType.daily => 'Todo dia',
      RecurrenceType.weekly => 'Toda semana',
      RecurrenceType.monthly => 'Todo mês',
      RecurrenceType.custom => 'Personalizado',
    };
    final untilLabel = repeatUntil == null
        ? 'Até uma data'
        : 'Até ${DateFormat('dd/MM/yyyy').format(repeatUntil!)}';
    return _sectionCard(
      context,
      children: [
        Row(
          children: [
            Icon(Icons.repeat_rounded, size: 16, color: accent),
            const SizedBox(width: 6),
            Text(
              'Repetir',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final t in const [
              RecurrenceType.none,
              RecurrenceType.daily,
              RecurrenceType.weekly,
              RecurrenceType.monthly,
            ])
              ChoiceChip(
                label: Text(typeLabel(t)),
                selected: repeatType == t,
                onSelected: (_) => setState(() {
                  repeatType = t;
                  if (t == RecurrenceType.weekly && repeatDays.isEmpty) {
                    repeatDays = {startAt.weekday};
                  }
                }),
              ),
          ],
        ),
        if (repeatType == RecurrenceType.weekly) ...[
          const SizedBox(height: 12),
          Text('Nos dias', style: muted),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (var d = 1; d <= 7; d++)
                FilterChip(
                  label: Text(_weekdayShort[d]!),
                  selected: repeatDays.contains(d),
                  showCheckmark: false,
                  onSelected: (on) => setState(() {
                    if (on) {
                      repeatDays = {...repeatDays, d};
                    } else if (repeatDays.length > 1) {
                      repeatDays = {...repeatDays}..remove(d);
                    }
                  }),
                ),
            ],
          ),
        ],
        if (repeatType == RecurrenceType.monthly) ...[
          const SizedBox(height: 8),
          Text('Todo dia ${startAt.day} do mês', style: muted),
        ],
        if (repeatType != RecurrenceType.none) ...[
          const SizedBox(height: 12),
          Text('Termina', style: muted),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ChoiceChip(
                label: const Text('Nunca'),
                selected: repeatEnd == _RepeatEnd.never,
                onSelected: (_) => setState(() => repeatEnd = _RepeatEnd.never),
              ),
              ChoiceChip(
                label: Text(untilLabel),
                selected: repeatEnd == _RepeatEnd.until,
                onSelected: (_) => _pickRepeatUntil(),
              ),
              ChoiceChip(
                label: const Text('Depois de N vezes'),
                selected: repeatEnd == _RepeatEnd.count,
                onSelected: (_) => setState(() => repeatEnd = _RepeatEnd.count),
              ),
            ],
          ),
          if (repeatEnd == _RepeatEnd.count)
            Row(
              children: [
                IconButton(
                  tooltip: 'Menos',
                  onPressed: repeatCount > 2
                      ? () => setState(() => repeatCount--)
                      : null,
                  icon: const Icon(Icons.remove_circle_outline),
                ),
                Text('$repeatCount vezes', style: theme.textTheme.titleSmall),
                IconButton(
                  tooltip: 'Mais',
                  onPressed: repeatCount < 365
                      ? () => setState(() => repeatCount++)
                      : null,
                  icon: const Icon(Icons.add_circle_outline),
                ),
              ],
            ),
        ],
      ],
    );
  }

  Future<void> _pickRepeatUntil() async {
    final first = DateTime(startAt.year, startAt.month, startAt.day);
    final picked = await showDatePicker(
      context: context,
      firstDate: first,
      lastDate: DateTime(2050),
      initialDate: repeatUntil != null && !repeatUntil!.isBefore(first)
          ? repeatUntil!
          : first.add(const Duration(days: 30)),
      helpText: 'Repetir até',
    );
    if (picked == null || !mounted) return;
    setState(() {
      repeatUntil = picked;
      repeatEnd = _RepeatEnd.until;
    });
  }

  Future<void> _pickStartDateTime() async {
    final date = await showDatePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2050),
      initialDate: startAt,
    );
    if (date == null) return;
    if (!mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(startAt),
    );
    setState(() {
      startAt = DateTime(
        date.year,
        date.month,
        date.day,
        time?.hour ?? startAt.hour,
        time?.minute ?? startAt.minute,
      );
    });
  }

  Future<void> _pickEndDateTime() async {
    final current = endAt ?? startAt.add(const Duration(hours: 1));
    final date = await showDatePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2050),
      initialDate: current,
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(current),
    );
    setState(() {
      endAt = DateTime(
        date.year,
        date.month,
        date.day,
        time?.hour ?? current.hour,
        time?.minute ?? current.minute,
      );
    });
  }

  bool get _attachmentsFull =>
      attachments.length >= ImageUploadConstants.maxAttachmentsPerItem;

  Future<void> _addImageAttachment() async {
    if (_attachmentsFull) {
      _showSaved(
        'Máximo de ${ImageUploadConstants.maxAttachmentsPerItem} fotos por evento.',
      );
      return;
    }
    final fileStorage = Get.find<IFileStorageService>();
    final picked = await imagePicker.pickImage(
      source: ImageSource.gallery,
      maxWidth: ImageUploadConstants.pickImageMaxWidth,
      maxHeight: ImageUploadConstants.pickImageMaxHeight,
      imageQuality: ImageUploadConstants.pickImageQuality,
    );
    if (picked == null) return;
    final stored = await fileStorage.copyImageToAppStorage(picked.path);
    if (!stored.isSuccess || stored.data == null) {
      _showSaved(
        stored.errorMessage?.startsWith('Imagem muito grande') == true
            ? stored.errorMessage!
            : 'Não foi possível anexar a imagem. Tente de novo.',
      );
      return;
    }

    final itemId = editingItem?.id ?? const Uuid().v4();
    final pathOrUrl = stored.data!;
    final isUrl =
        pathOrUrl.startsWith('http://') || pathOrUrl.startsWith('https://');
    setState(() {
      attachments.add(
        AttachmentRef(
          id: const Uuid().v4(),
          itemId: itemId,
          type: AttachmentType.image,
          localPath: isUrl ? null : pathOrUrl,
          remoteUrl: isUrl ? pathOrUrl : null,
          title: picked.name,
          createdAt: DateTime.now(),
        ),
      );
    });
  }

  Future<void> _handleReminderToggle(bool value) async {
    if (!value) {
      setState(() => reminderEnabled = false);
      return;
    }

    final notificationService = Get.find<INotificationService>();
    final permissionResult = await notificationService.ensurePermissions();
    if (!mounted) return;

    if (!permissionResult.isSuccess) {
      _showSaved(
        permissionResult.errorMessage ??
            'Não foi possível solicitar permissão de notificações.',
      );
      setState(() => reminderEnabled = false);
      return;
    }

    final granted = permissionResult.data ?? false;
    if (!granted) {
      _showSaved(
        'Permissão de notificação negada. Ative nas configurações do sistema.',
      );
      setState(() => reminderEnabled = false);
      return;
    }

    setState(() => reminderEnabled = true);
  }

  Future<void> _save() async {
    if (_formKey.currentState?.validate() != true) return;
    final canProceed = await AccountPromptUtils.confirmSaveWithoutAccount();
    if (!canProceed) return;

    final controller = Get.find<AgendaController>();

    final notificationId = editingItem?.reminder?.notificationId ?? 0;
    final reminder = reminderEnabled
        ? ReminderConfig(
            enabled: true,
            minutesBefore: reminderMinutes,
            notificationId: notificationId,
          )
        : ReminderConfig(
            enabled: false,
            minutesBefore: null,
            notificationId: notificationId,
          );

    if (editingItem == null) {
      final newItem = controller.buildNewItem(
        title: titleController.text.trim(),
        description: descriptionController.text.trim(),
        startAt: startAt,
        endAt: endAt,
        allDay: allDay,
        groupId: familyId == null ? groupId : null,
        status: status,
        reminder: reminder,
        recurrence: _buildRecurrence(),
        attachments: const [],
      );
      final item = _withFamilyFields(
        newItem.copyWith(
          attachments: attachments
              .map((a) => a.copyWith(itemId: newItem.id))
              .toList(),
        ),
      );
      final ok = await controller.createItem(item);
      if (ok && _detachFrom != null) {
        await controller.deleteOccurrence(_detachFrom!);
      }
      if (ok) {
        if (controller.errorMessage.value != null &&
            controller.errorMessage.value!.isNotEmpty) {
          _showSaved(
            'Evento criado, mas o lembrete falhou: ${controller.errorMessage.value}',
          );
        } else {
          _showSaved('Evento criado com sucesso');
        }
        Get.back(result: true);
      }
      return;
    }

    final updated = _withFamilyFields(editingItem!).copyWith(
      title: titleController.text.trim(),
      description: descriptionController.text.trim(),
      startAt: startAt,
      endAt: endAt,
      allDay: allDay,
      groupId: familyId == null ? groupId : null,
      status: status,
      reminder: reminder,
      recurrence: _buildRecurrence(),
      clearRecurrence: repeatType == RecurrenceType.none,
      attachments: attachments
          .map((a) => a.copyWith(itemId: editingItem!.id))
          .toList(),
      updatedAt: DateTime.now(),
    );
    final ok = await controller.updateItem(updated);
    if (ok) {
      if (controller.errorMessage.value != null &&
          controller.errorMessage.value!.isNotEmpty) {
        _showSaved(
          'Evento atualizado, mas o lembrete falhou: ${controller.errorMessage.value}',
        );
      } else {
        _showSaved('Evento atualizado');
      }
      Get.back(result: true);
    }
  }

  Future<void> _openCreateGroupDialog(BuildContext context) async {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    final groupsController = Get.find<GroupsController>();
    await Get.dialog(
      AlertDialog(
        title: const Text('Novo grupo'),
        content: Form(
          key: formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: TextFormField(
            controller: nameController,
            decoration: const InputDecoration(
              labelText: 'Nome do grupo',
              hintText: 'Ex: Trabalho, Pessoal',
            ),
            autofocus: true,
            textCapitalization: TextCapitalization.sentences,
            validator: (v) => requiredValidator(v, 'Nome é obrigatório'),
          ),
        ),
        actions: [
          TextButton(onPressed: Get.back, child: const Text('Cancelar')),
          FilledButton(
            style: FilledButton.styleFrom(minimumSize: const Size(0, 44)),
            onPressed: () async {
              if (formKey.currentState?.validate() != true) return;
              final canProceed =
                  await AccountPromptUtils.confirmSaveWithoutAccount();
              if (!canProceed) return;
              final name = nameController.text.trim();
              final newId = await groupsController.create(name);
              Get.back();
              if (newId != null && mounted) {
                setState(() => groupId = newId);
              }
            },
            child: const Text('Criar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final groupsController = Get.find<GroupsController>();
    final dateFmt = DateFormat('EEE, dd MMM', 'pt_BR');
    final timeFmt = DateFormat('HH:mm');
    final bottomInset = MediaQuery.of(context).padding.bottom;
    const accentGreen = Color(0xFF9CD64A);
    const inputNeutral = Color(0xFFF3F4F1);
    final bg = context.palette.appBackground;
    final baseTheme = Theme.of(context);
    final pageTheme = baseTheme.copyWith(
      colorScheme: baseTheme.colorScheme.copyWith(
        primary: accentGreen,
        onPrimary: Colors.white,
      ),
      inputDecorationTheme: baseTheme.inputDecorationTheme.copyWith(
        fillColor: inputNeutral,
        hintStyle: baseTheme.textTheme.bodyMedium?.copyWith(
          color: const Color(0xFF9BA39C),
        ),
      ),
    );

    return Scaffold(
      backgroundColor: bg,
      body: Theme(
        data: pageTheme,
        child: SafeArea(
          bottom: false,
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(14, 10, 14, 20 + bottomInset),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    IconButton(
                      onPressed: () => Get.back(),
                      icon: const Icon(Icons.close_rounded),
                      style: IconButton.styleFrom(
                        backgroundColor: inputNeutral,
                      ),
                    ),
                    Expanded(
                      child: Center(
                        child: Text(
                          _detachFrom != null
                              ? 'Editar este dia'
                              : editingItem == null
                              ? 'Novo evento'
                              : 'Editar evento',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                    if (editingItem != null)
                      IconButton(
                        onPressed: () async {
                          await Get.find<AgendaController>().duplicateItem(
                            editingItem!.id,
                          );
                          if (mounted) Get.back();
                        },
                        icon: const Icon(Icons.copy_rounded),
                        tooltip: 'Duplicar',
                        style: IconButton.styleFrom(
                          backgroundColor: inputNeutral,
                        ),
                      ),
                    // Salvar sem precisar rolar ate o fim do formulario.
                    TextButton(
                      onPressed: _save,
                      child: const Text(
                        'Salvar',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Form(
                  key: _formKey,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _sectionCard(
                        context,
                        children: [
                          Text(
                            'TÍTULO DO EVENTO *',
                            style: Theme.of(context).textTheme.labelSmall
                                ?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: .9,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                ),
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: titleController,
                            decoration: const InputDecoration(
                              hintText: 'O que você está planejando?',
                            ),
                            validator: (v) =>
                                requiredValidator(v, 'Título é obrigatório'),
                          ),
                        ],
                      ),
                      _buildFamilySection(context),
                      _sectionCard(
                        context,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.event_note_rounded,
                                size: 16,
                                color: accentGreen,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Data e hora',
                                style: Theme.of(context).textTheme.titleSmall
                                    ?.copyWith(fontWeight: FontWeight.w700),
                              ),
                              const Spacer(),
                              Text(
                                'Dia todo',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                              const SizedBox(width: 8),
                              Transform.scale(
                                scale: .86,
                                child: Switch(
                                  value: allDay,
                                  activeThumbColor: Colors.white,
                                  activeTrackColor: accentGreen,
                                  onChanged: (value) =>
                                      setState(() => allDay = value),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: inputNeutral,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: Theme.of(
                                  context,
                                ).colorScheme.outlineVariant,
                              ),
                            ),
                            child: Column(
                              children: [
                                _dateLine(
                                  context,
                                  label: 'INÍCIO',
                                  date: dateFmt.format(startAt),
                                  time: timeFmt.format(startAt),
                                  onTap: _pickStartDateTime,
                                ),
                                Divider(
                                  height: 14,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.outlineVariant,
                                ),
                                const SizedBox(height: 8),
                                _dateLine(
                                  context,
                                  label: 'FIM',
                                  date: endAt == null
                                      ? 'Definir'
                                      : dateFmt.format(endAt!),
                                  time: endAt == null
                                      ? '--:--'
                                      : timeFmt.format(endAt!),
                                  onTap: _pickEndDateTime,
                                  onClear: endAt == null
                                      ? null
                                      : () => setState(() => endAt = null),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      if (_detachFrom == null)
                        _buildRepeatSection(context, accentGreen),
                      // V1: categorias sao da agenda pessoal.
                      if (familyId == null)
                        _sectionCard(
                          context,
                          children: [
                            Text(
                              'Grupo',
                              style: Theme.of(context).textTheme.titleSmall
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: 10),
                            Obx(
                              () => Wrap(
                                spacing: 10,
                                runSpacing: 10,
                                children: [
                                  _groupTile(
                                    context,
                                    title: 'Sem grupo',
                                    selected: groupId == null,
                                    onTap: () => setState(() => groupId = null),
                                  ),
                                  ...groupsController.groups.map(
                                    (g) => _groupTile(
                                      context,
                                      title: g.name,
                                      selected: groupId == g.id,
                                      onTap: () =>
                                          setState(() => groupId = g.id),
                                    ),
                                  ),
                                  _groupTile(
                                    context,
                                    title: 'Novo',
                                    selected: false,
                                    outlined: true,
                                    onTap: () =>
                                        _openCreateGroupDialog(context),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      _sectionCard(
                        context,
                        children: [
                          Text(
                            'Descrição (opcional)',
                            style: Theme.of(context).textTheme.labelSmall
                                ?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                ),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: descriptionController,
                            decoration: const InputDecoration(
                              hintText: 'Adicione notas do evento',
                            ),
                            minLines: 2,
                            maxLines: 3,
                          ),
                        ],
                      ),
                      _sectionCard(
                        context,
                        children: [_buildAttachmentsSection(context)],
                      ),
                      _sectionCard(
                        context,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      'Lembretes',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleSmall
                                          ?.copyWith(
                                            fontWeight: FontWeight.w700,
                                          ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Receba alertas antes do evento',
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                            color: Theme.of(
                                              context,
                                            ).colorScheme.onSurfaceVariant,
                                            fontSize: 11,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Transform.scale(
                                scale: .86,
                                child: Switch(
                                  value: reminderEnabled,
                                  activeThumbColor: Colors.white,
                                  activeTrackColor: accentGreen,
                                  onChanged: _handleReminderToggle,
                                ),
                              ),
                            ],
                          ),
                          if (reminderEnabled) ...[
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [5, 10, 15, 30, 60]
                                  .map(
                                    (e) => ChoiceChip(
                                      label: Text('$e min antes'),
                                      selected: reminderMinutes == e,
                                      selectedColor: accentGreen.withValues(
                                        alpha: 0.2,
                                      ),
                                      backgroundColor:
                                          context.palette.scheduleCellEmpty,
                                      onSelected: (_) =>
                                          setState(() => reminderMinutes = e),
                                    ),
                                  )
                                  .toList(),
                            ),
                          ],
                        ],
                      ),
                      // Evento novo sempre comeca pendente.
                      if (editingItem != null)
                        _sectionCard(
                          context,
                          children: [
                            Text(
                              'Status',
                              style: Theme.of(context).textTheme.titleSmall
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: 8),
                            DropdownButtonFormField<AgendaStatus>(
                              initialValue: status,
                              decoration: const InputDecoration(
                                labelText: 'Status',
                              ),
                              items: AgendaStatus.values
                                  .map(
                                    (e) => DropdownMenuItem(
                                      value: e,
                                      child: Text(
                                        e == AgendaStatus.pending
                                            ? 'Pendente'
                                            : e == AgendaStatus.done
                                            ? 'Concluído'
                                            : 'Cancelado',
                                      ),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (value) {
                                if (value != null) {
                                  setState(() => status = value);
                                }
                              },
                            ),
                          ],
                        ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                minimumSize: const Size(double.infinity, 48),
                              ),
                              onPressed: () => Get.back(),
                              child: const Text('Cancelar'),
                            ),
                          ),
                          const SizedBox(width: DesignTokens.spaceSm),
                          Expanded(
                            child: FilledButton.icon(
                              style: FilledButton.styleFrom(
                                backgroundColor: accentGreen,
                                foregroundColor: Theme.of(
                                  context,
                                ).colorScheme.onPrimary,
                                minimumSize: const Size(double.infinity, 48),
                              ),
                              onPressed: _save,
                              icon: const Icon(Icons.check_rounded),
                              label: Text(
                                editingItem == null
                                    ? 'Salvar evento'
                                    : 'Salvar alterações',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _sectionCard(BuildContext context, {required List<Widget> children}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: context.palette.surfaceSoft,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  /// Aplica destino (pessoal/Familia), tipo, "para quem" e responsavel.
  AgendaItem _withFamilyFields(AgendaItem base) {
    final isFamily = familyId != null;
    return AgendaItem(
      id: base.id,
      title: base.title,
      description: base.description,
      startAt: base.startAt,
      endAt: base.endAt,
      allDay: base.allDay,
      timezone: base.timezone,
      groupId: isFamily ? null : base.groupId,
      status: base.status,
      locationText: base.locationText,
      reminder: base.reminder,
      recurrence: base.recurrence,
      attachments: base.attachments,
      familyId: familyId,
      kind: kind,
      subjectType: isFamily ? subjectType : AgendaSubjectType.none,
      subjectChildId: isFamily && subjectType == AgendaSubjectType.child
          ? subjectChildId
          : null,
      subjectUserId: isFamily && subjectType == AgendaSubjectType.member
          ? subjectUserId
          : null,
      assigneeType: isFamily ? assigneeType : AgendaAssigneeType.none,
      assigneeUserId: isFamily && assigneeType == AgendaAssigneeType.member
          ? assigneeUserId
          : null,
      createdBy: base.createdBy,
      updatedBy: base.updatedBy,
      completedBy: base.completedBy,
      source: base.source,
      syncState: base.syncState,
      createdAt: base.createdAt,
      updatedAt: base.updatedAt,
      deletedAt: base.deletedAt,
    );
  }

  Widget _label(BuildContext context, String text) => Padding(
    padding: const EdgeInsets.only(bottom: 8, top: 4),
    child: Text(
      text,
      style: Theme.of(
        context,
      ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
    ),
  );

  /// Tipo + (na Familia) agenda de destino, "para quem" e responsavel.
  Widget _buildFamilySection(BuildContext context) {
    return Obx(() {
      final ctx = _family.context;
      final members = _family.members;
      final children = _family.children;
      final canChooseScope = editingItem == null && ctx.canEditAgenda;
      final isFamily = familyId != null;
      return _sectionCard(
        context,
        children: [
          _label(context, 'Tipo'),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (final k in AgendaItemKind.values)
                _groupTile(
                  context,
                  title: switch (k) {
                    AgendaItemKind.event => 'Compromisso',
                    AgendaItemKind.task => 'Tarefa',
                    AgendaItemKind.reminder => 'Lembrete',
                  },
                  icon: switch (k) {
                    AgendaItemKind.event => Icons.event_rounded,
                    AgendaItemKind.task => Icons.task_alt_rounded,
                    AgendaItemKind.reminder => Icons.notifications_none_rounded,
                  },
                  perRow: 3,
                  selected: kind == k,
                  onTap: () => setState(() => kind = k),
                ),
            ],
          ),
          if (editingItem == null && ctx.hasFamily && !ctx.canEditAgenda) ...[
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.info_outline,
                  size: 18,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    ctx.isActive
                        ? 'Seu acesso à Família é de visualização. Este item ficará só para você.'
                        : 'A assinatura Pro da Família não está ativa. Este item ficará só para você.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          ],
          if (canChooseScope) ...[
            const SizedBox(height: 12),
            _label(context, 'Agenda'),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _groupTile(
                  context,
                  title: ctx.familyName ?? 'Família',
                  selected: isFamily,
                  onTap: () => setState(() => familyId = ctx.familyId),
                ),
                _groupTile(
                  context,
                  title: 'Só minha',
                  selected: !isFamily,
                  onTap: () => setState(() => familyId = null),
                ),
              ],
            ),
          ],
          if (isFamily) ...[
            const SizedBox(height: 12),
            _label(context, 'Para quem'),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _groupTile(
                  context,
                  title: 'Família toda',
                  selected:
                      subjectType == AgendaSubjectType.family ||
                      subjectType == AgendaSubjectType.none,
                  onTap: () =>
                      setState(() => subjectType = AgendaSubjectType.family),
                ),
                for (final FamilyChild c in children)
                  _groupTile(
                    context,
                    title: c.name,
                    selected:
                        subjectType == AgendaSubjectType.child &&
                        subjectChildId == c.id,
                    onTap: () => setState(() {
                      subjectType = AgendaSubjectType.child;
                      subjectChildId = c.id;
                    }),
                  ),
                for (final FamilyMember m in members)
                  _groupTile(
                    context,
                    title: m.label,
                    selected:
                        subjectType == AgendaSubjectType.member &&
                        subjectUserId == m.userId,
                    onTap: () => setState(() {
                      subjectType = AgendaSubjectType.member;
                      subjectUserId = m.userId;
                    }),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            _label(context, 'Responsável'),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _groupTile(
                  context,
                  title: 'Ninguém',
                  selected: assigneeType == AgendaAssigneeType.none,
                  onTap: () =>
                      setState(() => assigneeType = AgendaAssigneeType.none),
                ),
                _groupTile(
                  context,
                  title: 'Todos',
                  selected: assigneeType == AgendaAssigneeType.all,
                  onTap: () =>
                      setState(() => assigneeType = AgendaAssigneeType.all),
                ),
                for (final FamilyMember m in members)
                  _groupTile(
                    context,
                    title: m.label,
                    selected:
                        assigneeType == AgendaAssigneeType.member &&
                        assigneeUserId == m.userId,
                    onTap: () => setState(() {
                      assigneeType = AgendaAssigneeType.member;
                      assigneeUserId = m.userId;
                    }),
                  ),
              ],
            ),
          ],
        ],
      );
    });
  }

  Widget _photosOnDeviceNotice(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.phone_android_rounded, size: 16, color: scheme.primary),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            'No plano Grátis as fotos ficam só neste celular. Com o Pro elas '
            'vão para a nuvem e aparecem nos seus outros aparelhos.',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
          ),
        ),
      ],
    );
  }

  Widget _buildAttachmentsSection(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              attachments.isEmpty
                  ? 'ANEXOS'
                  : 'ANEXOS ${attachments.length}/${ImageUploadConstants.maxAttachmentsPerItem}',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const Spacer(),
            FilledButton.tonalIcon(
              onPressed: _attachmentsFull ? null : _addImageAttachment,
              icon: const Icon(Icons.attach_file_rounded),
              label: const Text('Adicionar'),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFF3F4F1),
                foregroundColor: const Color(0xFF9CD64A),
                minimumSize: const Size(0, 40),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
              ),
            ),
          ],
        ),
        if (_photosStayOnDevice) ...[
          const SizedBox(height: 6),
          _photosOnDeviceNotice(context),
        ],
        const SizedBox(height: 10),
        if (attachments.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
            decoration: BoxDecoration(
              color: scheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: scheme.outlineVariant),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.image_not_supported_outlined,
                  color: scheme.onSurfaceVariant,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Nenhum anexo ainda. Adicione imagens para esse evento.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          )
        else
          SizedBox(
            height: 118,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              // Sem o quadro "Adicionar" quando ja chegou no limite.
              itemCount: attachments.length + (_attachmentsFull ? 0 : 1),
              separatorBuilder: (_, separatorIndex) =>
                  const SizedBox(width: 10),
              itemBuilder: (context, index) {
                if (index == attachments.length) {
                  return InkWell(
                    onTap: _addImageAttachment,
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      width: 104,
                      decoration: BoxDecoration(
                        color: scheme.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: scheme.outlineVariant),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.cloud_upload_outlined,
                            color: scheme.onSurfaceVariant,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Adicionar',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  );
                }
                final attachment = attachments[index];
                final path = attachment.localPath;
                final url = attachment.remoteUrl;
                final hasLocal = path != null && File(path).existsSync();
                final hasRemote =
                    url != null &&
                    (url.startsWith('http://') || url.startsWith('https://'));
                final hasImage = hasLocal || hasRemote;
                return Container(
                  width: 104,
                  decoration: BoxDecoration(
                    color: scheme.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: scheme.outlineVariant),
                  ),
                  child: Stack(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(14),
                              ),
                              child: SizedBox.expand(
                                child: hasImage
                                    ? hasLocal
                                          ? Image.file(
                                              File(path),
                                              fit: BoxFit.cover,
                                            )
                                          : Image.network(
                                              url as String,
                                              fit: BoxFit.cover,
                                              errorBuilder:
                                                  (
                                                    context,
                                                    error,
                                                    stackTrace,
                                                  ) => Icon(
                                                    Icons.broken_image,
                                                    color:
                                                        scheme.onSurfaceVariant,
                                                  ),
                                            )
                                    : Icon(
                                        Icons.insert_drive_file,
                                        color: scheme.onSurfaceVariant,
                                      ),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8),
                            child: Text(
                              attachment.title ?? 'Imagem',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ),
                        ],
                      ),
                      Positioned(
                        right: 6,
                        top: 6,
                        child: Material(
                          color: Colors.black.withValues(alpha: 0.56),
                          shape: const CircleBorder(),
                          child: InkWell(
                            customBorder: const CircleBorder(),
                            onTap: () {
                              setState(() {
                                attachments = attachments
                                    .where((e) => e.id != attachment.id)
                                    .toList();
                              });
                            },
                            child: const Padding(
                              padding: EdgeInsets.all(4),
                              child: Icon(
                                Icons.close,
                                size: 14,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  void _showSaved(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        duration: const Duration(milliseconds: 1400),
        content: Text(message),
      ),
    );
  }

  Widget _dateLine(
    BuildContext context, {
    required String label,
    required String date,
    required String time,
    required VoidCallback onTap,
    VoidCallback? onClear,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  date,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  time,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              if (onClear != null) ...[
                const SizedBox(width: 6),
                InkWell(
                  onTap: onClear,
                  borderRadius: BorderRadius.circular(999),
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).colorScheme.surfaceContainerHighest,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.close_rounded, size: 16),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _groupTile(
    BuildContext context, {
    required String title,
    required bool selected,
    required VoidCallback onTap,
    bool outlined = false,
    IconData? icon,
    int perRow = 2,
  }) {
    final selectedColor = Theme.of(context).colorScheme.primary;
    final width =
        (MediaQuery.of(context).size.width - 60 - 10 * perRow) / perRow;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: width,
        height: 76,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: selected
              ? selectedColor.withValues(alpha: 0.18)
              : Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected
                ? selectedColor.withValues(alpha: 0.46)
                : outlined
                ? Theme.of(context).colorScheme.outlineVariant
                : Colors.transparent,
            style: selected || outlined ? BorderStyle.solid : BorderStyle.none,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon ??
                  (title == 'Novo'
                      ? Icons.add_rounded
                      : Icons.folder_copy_outlined),
              size: icon == null ? 16 : 20,
              color: selected
                  ? selectedColor
                  : Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 5),
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}

enum _RepeatEnd { never, until, count }

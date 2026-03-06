import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../core/routes/app_routes.dart';
import '../../core/theme/design_tokens.dart';
import '../../domain/entities/agenda_enums.dart';
import '../../domain/entities/agenda_item.dart';
import '../../domain/entities/attachment_ref.dart';
import '../../domain/entities/recurrence_rule.dart';
import '../../domain/entities/reminder_config.dart';
import '../../domain/repositories/i_file_storage_service.dart';
import '../../domain/repositories/i_notification_service.dart';
import '../controllers/agenda_controller.dart';
import '../controllers/groups_controller.dart';

class UpsertAgendaPage extends StatefulWidget {
  const UpsertAgendaPage({super.key});

  @override
  State<UpsertAgendaPage> createState() => _UpsertAgendaPageState();
}

class _UpsertAgendaPageState extends State<UpsertAgendaPage> {
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
  RecurrenceType recurrenceType = RecurrenceType.none;
  List<AttachmentRef> attachments = [];
  AgendaItem? editingItem;

  @override
  void initState() {
    super.initState();
    final arg = Get.arguments;
    if (arg is AgendaItem) {
      editingItem = arg;
      titleController.text = arg.title;
      descriptionController.text = arg.description ?? '';
      startAt = arg.startAt;
      endAt = arg.endAt;
      allDay = arg.allDay;
      status = arg.status;
      groupId = arg.groupId;
      reminderEnabled = arg.reminder?.enabled ?? false;
      reminderMinutes = arg.reminder?.minutesBefore;
      recurrenceType = arg.recurrence?.type ?? RecurrenceType.none;
      attachments = [...arg.attachments];
    }
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

  Future<void> _addImageAttachment() async {
    final fileStorage = Get.find<IFileStorageService>();
    final picked = await imagePicker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;
    final stored = await fileStorage.copyImageToAppStorage(picked.path);
    if (!stored.isSuccess || stored.data == null) return;

    final itemId = editingItem?.id ?? const Uuid().v4();
    setState(() {
      attachments.add(
        AttachmentRef(
          id: const Uuid().v4(),
          itemId: itemId,
          type: AttachmentType.image,
          localPath: stored.data,
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
            'Nao foi possivel solicitar permissao de notificacoes.',
      );
      setState(() => reminderEnabled = false);
      return;
    }

    final granted = permissionResult.data ?? false;
    if (!granted) {
      _showSaved(
        'Permissao de notificacao negada. Ative nas configuracoes do sistema.',
      );
      setState(() => reminderEnabled = false);
      return;
    }

    setState(() => reminderEnabled = true);
  }

  Future<void> _save() async {
    final controller = Get.find<AgendaController>();
    if (titleController.text.trim().isEmpty) return;

    final reminder = reminderEnabled
        ? ReminderConfig(
            enabled: true,
            minutesBefore: reminderMinutes,
            notificationId: editingItem?.reminder?.notificationId ??
                DateTime.now().millisecondsSinceEpoch.remainder(1000000),
          )
        : ReminderConfig(
            enabled: false,
            minutesBefore: null,
            notificationId: editingItem?.reminder?.notificationId ??
                DateTime.now().millisecondsSinceEpoch.remainder(1000000),
          );

    final recurrence = RecurrenceRule(type: recurrenceType);

    if (editingItem == null) {
      final item = controller.buildNewItem(
        title: titleController.text.trim(),
        description: descriptionController.text.trim(),
        startAt: startAt,
        endAt: endAt,
        allDay: allDay,
        groupId: groupId,
        status: status,
        reminder: reminder,
        recurrence: recurrenceType == RecurrenceType.none ? null : recurrence,
        attachments: attachments,
      );
      final ok = await controller.createItem(item);
      if (ok) {
        _showSaved('Evento criado com sucesso');
        Get.back();
      }
      return;
    }

    final updated = editingItem!.copyWith(
      title: titleController.text.trim(),
      description: descriptionController.text.trim(),
      startAt: startAt,
      endAt: endAt,
      allDay: allDay,
      groupId: groupId,
      status: status,
      reminder: reminder,
      recurrence: recurrenceType == RecurrenceType.none ? null : recurrence,
      attachments:
          attachments.map((a) => a.copyWith(itemId: editingItem!.id)).toList(),
      updatedAt: DateTime.now(),
    );
    final ok = await controller.updateItem(updated);
    if (ok) {
      _showSaved('Evento atualizado');
      Get.back();
    }
  }

  @override
  Widget build(BuildContext context) {
    final groupsController = Get.find<GroupsController>();
    final dateFmt = DateFormat('EEE, dd MMM', 'pt_BR');
    final timeFmt = DateFormat('HH:mm');
    final bottomInset = MediaQuery.of(context).padding.bottom;
    final accentGreen = Theme.of(context).colorScheme.primary;
    final surfaceSoft = context.palette.surfaceSoft;
    final bg = context.palette.appBackground;
    final pageTheme = Theme.of(context).copyWith(
      inputDecorationTheme: Theme.of(context).inputDecorationTheme.copyWith(
            fillColor: Colors.white,
            hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
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
                    backgroundColor: Colors.white,
                  ),
                ),
                Expanded(
                  child: Center(
                    child: Text(
                      editingItem == null ? 'Novo evento' : 'Editar evento',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ),
                ),
                if (editingItem != null)
                  IconButton(
                    onPressed: () async {
                      await Get.find<AgendaController>()
                          .duplicateItem(editingItem!.id);
                      if (mounted) Get.back();
                    },
                    icon: const Icon(Icons.copy_rounded),
                    style: IconButton.styleFrom(backgroundColor: Colors.white),
                  )
                else
                  const SizedBox(width: 48),
              ],
            ),
            const SizedBox(height: 12),
            _sectionCard(
              context,
              children: [
                Text(
                  'TITULO DO EVENTO *',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        letterSpacing: .9,
                        color: const Color(0xFF7D857C),
                      ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    hintText: 'O que voce esta planejando?',
                  ),
                ),
              ],
            ),
            _sectionCard(
              context,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.event_note_rounded,
                      size: 16,
                      color: Color(0xFF9CD64A),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Date & Time',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
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
                        onChanged: (value) => setState(() => allDay = value),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.68),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: Theme.of(context).colorScheme.outlineVariant,
                    ),
                  ),
                  child: Column(
                    children: [
                      _dateLine(
                        context,
                        label: 'INICIO',
                        date: dateFmt.format(startAt),
                        time: timeFmt.format(startAt),
                        onTap: _pickStartDateTime,
                      ),
                      Divider(
                        height: 14,
                        color: Theme.of(context).colorScheme.outlineVariant,
                      ),
                      const SizedBox(height: 8),
                      _dateLine(
                        context,
                        label: 'FIM',
                        date: endAt == null
                            ? 'Definir'
                            : dateFmt.format(endAt!),
                        time: endAt == null ? '--:--' : timeFmt.format(endAt!),
                        onTap: _pickEndDateTime,
                        onClear: endAt == null
                            ? null
                            : () => setState(() => endAt = null),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 2,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: Text(
                        'Sugestoes',
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                    ),
                    _timeSuggestionChip(context, _suggestedTime(startAt, 0),
                        onTap: () {
                      setState(() => endAt = startAt.add(const Duration(minutes: 30)));
                    }, selected: endAt != null &&
                        endAt!.difference(startAt).inMinutes == 30),
                    _timeSuggestionChip(context, _suggestedTime(startAt, 30),
                        onTap: () {
                      setState(() => endAt = startAt.add(const Duration(hours: 1)));
                    }, selected: endAt != null &&
                        endAt!.difference(startAt).inMinutes == 60),
                    _timeSuggestionChip(context, _suggestedTime(startAt, 60),
                        onTap: () {
                      setState(() => endAt = startAt.add(const Duration(hours: 2)));
                    }, selected: endAt != null &&
                        endAt!.difference(startAt).inMinutes == 120),
                    _timeSuggestionChip(context, _suggestedTime(startAt, 90),
                        onTap: () {
                      setState(() {
                        endAt = startAt.add(const Duration(hours: 2, minutes: 30));
                      });
                    }, selected: endAt != null &&
                        endAt!.difference(startAt).inMinutes == 150),
                  ],
                ),
              ],
            ),
            _sectionCard(
              context,
              children: [
                const Row(
                  children: [
                    Icon(
                      Icons.auto_awesome_rounded,
                      size: 16,
                      color: Color(0xFF9CD64A),
                    ),
                    SizedBox(width: 6),
                  ],
                ),
                Text(
                  'Grupo',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
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
                        baseColor: const Color(0xFF6B5CFF),
                      ),
                      ...groupsController.groups.map(
                        (g) => _groupTile(
                          context,
                          title: g.name,
                          selected: groupId == g.id,
                          onTap: () => setState(() => groupId = g.id),
                          baseColor: _resolveGroupColor(g.colorHex),
                        ),
                      ),
                      _groupTile(
                        context,
                        title: 'Novo',
                        selected: false,
                        outlined: true,
                        onTap: () => Get.toNamed(AppRoutes.groups),
                        baseColor: Theme.of(context).colorScheme.outline,
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
                  'Descricao (opcional)',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF7D857C),
                      ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: descriptionController,
                  decoration:
                      const InputDecoration(hintText: 'Adicione notas do evento'),
                  minLines: 2,
                  maxLines: 3,
                ),
              ],
            ),
            _sectionCard(
              context,
              children: [
                _buildAttachmentsSection(context),
              ],
            ),
            _sectionCard(
              context,
              children: [
                Row(
                  children: [
                    Text(
                      'Lembretes',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Get notified before the event',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                            fontSize: 11,
                          ),
                    ),
                    const Spacer(),
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
                            selectedColor: const Color(0xFFFFE2CC),
                            backgroundColor: surfaceSoft,
                            onSelected: (_) =>
                                setState(() => reminderMinutes = e),
                          ),
                        )
                        .toList(),
                  ),
                ],
                const SizedBox(height: 8),
                DropdownButtonFormField<AgendaStatus>(
                  initialValue: status,
                  decoration: const InputDecoration(labelText: 'Status'),
                  items: AgendaStatus.values
                      .map(
                        (e) => DropdownMenuItem(
                          value: e,
                          child: Text(
                            e == AgendaStatus.pending
                                ? 'Pendente'
                                : e == AgendaStatus.done
                                    ? 'Concluido'
                                    : 'Cancelado',
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value != null) setState(() => status = value);
                  },
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<RecurrenceType>(
                  initialValue: recurrenceType,
                  decoration: const InputDecoration(labelText: 'Recorrencia'),
                  items: RecurrenceType.values
                      .map((e) => DropdownMenuItem(value: e, child: Text(e.name)))
                      .toList(),
                  onChanged: (value) {
                    if (value != null) setState(() => recurrenceType = value);
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
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 48),
                    ),
                    onPressed: _save,
                    icon: const Icon(Icons.check_rounded),
                    label: Text(
                      editingItem == null ? 'Salvar evento' : 'Salvar alteracoes',
                    ),
                  ),
                ),
              ],
              ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _sectionCard(BuildContext context, {required List<Widget> children}) {
    const cardBg = Color(0xFFEFF2EE);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? Theme.of(context).colorScheme.surfaceContainerLow
            : cardBg,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, children: children),
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
              'ANEXOS',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF7D857C),
                  ),
            ),
            const Spacer(),
            FilledButton.tonalIcon(
              onPressed: _addImageAttachment,
              icon: const Icon(Icons.attach_file_rounded),
              label: const Text('Add Files'),
              style: FilledButton.styleFrom(
                minimumSize: const Size(0, 40),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
            ),
          ],
        ),
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
                Icon(Icons.image_not_supported_outlined,
                    color: scheme.onSurfaceVariant),
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
              itemCount: attachments.length + 1,
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
                          Icon(Icons.cloud_upload_outlined,
                              color: scheme.onSurfaceVariant),
                          const SizedBox(height: 6),
                          Text(
                            'Upload',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  );
                }
                final attachment = attachments[index];
                final path = attachment.localPath;
                final hasFile = path != null && File(path).existsSync();
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
                                child: hasFile
                                    ? Image.file(File(path), fit: BoxFit.cover)
                                    : Icon(Icons.insert_drive_file,
                                        color: scheme.onSurfaceVariant),
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
                              child: Icon(Icons.close,
                                  size: 14, color: Colors.white),
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
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  time,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
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
                      color: Theme.of(context).colorScheme.surfaceContainerHighest,
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

  Widget _timeSuggestionChip(
    BuildContext context,
    String label, {
    required VoidCallback onTap,
    required bool selected,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        selectedColor: const Color(0xFF9CD64A),
        backgroundColor: Colors.white.withValues(alpha: 0.68),
        onSelected: (_) => onTap(),
        labelStyle: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: selected ? Colors.white : null,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }

  Widget _groupTile(
    BuildContext context, {
    required String title,
    required bool selected,
    required VoidCallback onTap,
    required Color baseColor,
    bool outlined = false,
  }) {
    final width = (MediaQuery.of(context).size.width - 70) / 2;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: width,
        height: 76,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: selected
              ? baseColor.withValues(alpha: 0.18)
              : Colors.white.withValues(alpha: 0.88),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected
                ? baseColor.withValues(alpha: 0.46)
                : outlined
                    ? Theme.of(context).colorScheme.outlineVariant
                    : Colors.transparent,
            style: selected || outlined ? BorderStyle.solid : BorderStyle.none,
          ),
        ),
        child: Column(
          children: [
            Icon(
              title == 'Novo' ? Icons.add_rounded : Icons.folder_copy_outlined,
              size: 16,
              color: selected
                  ? baseColor
                  : Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 5),
            Text(
              title,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Color _resolveGroupColor(String? colorHex) {
    if (colorHex != null && colorHex.isNotEmpty) {
      final sanitized = colorHex.replaceAll('#', '');
      final normalized =
          sanitized.length == 6 ? 'FF$sanitized' : sanitized.padLeft(8, 'F');
      final value = int.tryParse(normalized, radix: 16);
      if (value != null) return Color(value);
    }
    return const Color(0xFF6B5CFF);
  }

  String _suggestedTime(DateTime date, int addMinutes) {
    return DateFormat('HH:mm').format(date.add(Duration(minutes: addMinutes)));
  }
}

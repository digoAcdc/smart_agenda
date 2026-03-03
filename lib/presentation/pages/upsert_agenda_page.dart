import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../core/routes/app_routes.dart';
import '../../domain/entities/agenda_enums.dart';
import '../../domain/entities/agenda_item.dart';
import '../../domain/entities/attachment_ref.dart';
import '../../domain/entities/recurrence_rule.dart';
import '../../domain/entities/reminder_config.dart';
import '../../domain/repositories/i_file_storage_service.dart';
import '../controllers/agenda_controller.dart';
import '../controllers/groups_controller.dart';
import '../widgets/primary_button.dart';
import '../widgets/section_header.dart';

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
    final dateFmt = DateFormat('dd/MM/yyyy HH:mm');
    final bottomInset = MediaQuery.of(context).padding.bottom;
    return Scaffold(
      appBar: AppBar(
        title: Text(editingItem == null ? 'Novo evento' : 'Editar evento'),
        actions: [
          if (editingItem != null)
            IconButton(
              onPressed: () async {
                await Get.find<AgendaController>()
                    .duplicateItem(editingItem!.id);
                if (mounted) Get.back();
              },
              icon: const Icon(Icons.copy),
              tooltip: 'Duplicar',
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(16, 8, 16, 20 + bottomInset),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionHeader(
              title: 'Detalhes do evento',
              subtitle: 'Defina titulo, horario e regras',
            ),
            _sectionCard(
              context,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(labelText: 'Titulo *'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(labelText: 'Descricao'),
                  minLines: 2,
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _pickStartDateTime,
                        icon: const Icon(Icons.schedule),
                        label: Text('Inicio\n${dateFmt.format(startAt)}'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _pickEndDateTime,
                        icon: const Icon(Icons.event_available_outlined),
                        label: Text(
                          endAt == null
                              ? 'Definir fim'
                              : 'Fim\n${dateFmt.format(endAt!)}',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Dia inteiro'),
                  value: allDay,
                  onChanged: (value) => setState(() => allDay = value),
                ),
                DropdownButtonFormField<AgendaStatus>(
                  initialValue: status,
                  decoration: const InputDecoration(labelText: 'Status'),
                  items: AgendaStatus.values
                      .map((e) =>
                          DropdownMenuItem(value: e, child: Text(e.name)))
                      .toList(),
                  onChanged: (value) {
                    if (value != null) setState(() => status = value);
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),
            _sectionCard(
              context,
              children: [
                Obx(
                  () => DropdownButtonFormField<String?>(
                    initialValue: groupId,
                    decoration: const InputDecoration(labelText: 'Grupo'),
                    items: [
                      const DropdownMenuItem(
                          value: null, child: Text('Sem grupo')),
                      ...groupsController.groups.map((g) =>
                          DropdownMenuItem(value: g.id, child: Text(g.name))),
                    ],
                    onChanged: (value) => setState(() => groupId = value),
                  ),
                ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: () => Get.toNamed(AppRoutes.groups),
                    icon: const Icon(Icons.group_work_outlined),
                    label: const Text('Gerenciar grupos'),
                  ),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Lembrete'),
                  value: reminderEnabled,
                  onChanged: (value) => setState(() => reminderEnabled = value),
                ),
                if (reminderEnabled)
                  DropdownButtonFormField<int>(
                    initialValue: reminderMinutes,
                    decoration:
                        const InputDecoration(labelText: 'Minutos antes'),
                    items: const [5, 10, 30, 60]
                        .map((e) =>
                            DropdownMenuItem(value: e, child: Text('$e min')))
                        .toList(),
                    onChanged: (value) =>
                        setState(() => reminderMinutes = value),
                  ),
                const SizedBox(height: 8),
                DropdownButtonFormField<RecurrenceType>(
                  initialValue: recurrenceType,
                  decoration: const InputDecoration(labelText: 'Recorrencia'),
                  items: RecurrenceType.values
                      .map((e) =>
                          DropdownMenuItem(value: e, child: Text(e.name)))
                      .toList(),
                  onChanged: (value) {
                    if (value != null) setState(() => recurrenceType = value);
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),
            _sectionCard(
              context,
              children: [_buildAttachmentsSection(context)],
            ),
            const SizedBox(height: 20),
            PrimaryButton(
              label: 'Salvar evento',
              icon: Icons.save_outlined,
              onPressed: _save,
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionCard(BuildContext context, {required List<Widget> children}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20),
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
            Text('Anexos', style: Theme.of(context).textTheme.titleMedium),
            const Spacer(),
            FilledButton.tonalIcon(
              onPressed: _addImageAttachment,
              icon: const Icon(Icons.add_photo_alternate_outlined),
              label: const Text('Adicionar'),
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
            height: 132,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: attachments.length,
              separatorBuilder: (_, separatorIndex) =>
                  const SizedBox(width: 10),
              itemBuilder: (context, index) {
                final attachment = attachments[index];
                final path = attachment.localPath;
                final hasFile = path != null && File(path).existsSync();
                return Container(
                  width: 118,
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
}

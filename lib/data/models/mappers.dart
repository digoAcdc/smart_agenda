import 'dart:convert';

import 'package:drift/drift.dart';

import '../../domain/entities/agenda_enums.dart';
import '../../domain/entities/agenda_group.dart';
import '../../domain/entities/agenda_item.dart';
import '../../domain/entities/attachment_ref.dart';
import '../../domain/entities/recurrence_rule.dart';
import '../../domain/entities/reminder_config.dart';
import '../local/app_database.dart';

AgendaItemsTableCompanion agendaItemToCompanion(AgendaItem item) {
  return AgendaItemsTableCompanion(
    id: Value(item.id),
    title: Value(item.title),
    description: Value(item.description),
    startAt: Value(item.startAt),
    endAt: Value(item.endAt),
    allDay: Value(item.allDay),
    timezone: Value(item.timezone),
    groupId: Value(item.groupId),
    status: Value(item.status.name),
    locationText: Value(item.locationText),
    reminderJson: Value(
      item.reminder == null ? null : jsonEncode(item.reminder!.toJson()),
    ),
    recurrenceJson: Value(
      item.recurrence == null ? null : jsonEncode(item.recurrence!.toJson()),
    ),
    source: Value(item.source.name),
    syncState: Value(item.syncState.name),
    createdAt: Value(item.createdAt),
    updatedAt: Value(item.updatedAt),
    deletedAt: Value(item.deletedAt),
  );
}

AttachmentsTableCompanion attachmentToCompanion(AttachmentRef a) {
  return AttachmentsTableCompanion(
    id: Value(a.id),
    itemId: Value(a.itemId),
    type: Value(a.type.name),
    localPath: Value(a.localPath),
    remoteUrl: Value(a.remoteUrl),
    thumbPath: Value(a.thumbPath),
    title: Value(a.title),
    mimeType: Value(a.mimeType),
    sizeBytes: Value(a.sizeBytes),
    createdAt: Value(a.createdAt),
  );
}

AgendaItem itemFromDb(
  AgendaItemsTableData row,
  List<AttachmentsTableData> attachments,
) {
  final reminderMap = _decodeJson(row.reminderJson);
  final recurrenceMap = _decodeJson(row.recurrenceJson);
  return AgendaItem(
    id: row.id,
    title: row.title,
    description: row.description,
    startAt: row.startAt,
    endAt: row.endAt,
    allDay: row.allDay,
    timezone: row.timezone,
    groupId: row.groupId,
    status: AgendaStatus.values.firstWhere(
      (e) => e.name == row.status,
      orElse: () => AgendaStatus.pending,
    ),
    locationText: row.locationText,
    reminder: reminderMap == null ? null : ReminderConfig.fromJson(reminderMap),
    recurrence:
        recurrenceMap == null ? null : RecurrenceRule.fromJson(recurrenceMap),
    attachments: attachments.map(attachmentFromDb).toList(),
    ownerEmail: null,
    source: ItemSource.values.firstWhere(
      (e) => e.name == row.source,
      orElse: () => ItemSource.local,
    ),
    syncState: SyncState.values.firstWhere(
      (e) => e.name == row.syncState,
      orElse: () => SyncState.pending,
    ),
    createdAt: row.createdAt,
    updatedAt: row.updatedAt,
    deletedAt: row.deletedAt,
  );
}

AttachmentRef attachmentFromDb(AttachmentsTableData row) {
  return AttachmentRef(
    id: row.id,
    itemId: row.itemId,
    type: AttachmentType.values.firstWhere(
      (e) => e.name == row.type,
      orElse: () => AttachmentType.file,
    ),
    localPath: row.localPath,
    remoteUrl: row.remoteUrl,
    thumbPath: row.thumbPath,
    title: row.title,
    mimeType: row.mimeType,
    sizeBytes: row.sizeBytes,
    createdAt: row.createdAt,
  );
}

AgendaGroupsTableCompanion groupToCompanion(AgendaGroup group) {
  return AgendaGroupsTableCompanion(
    id: Value(group.id),
    name: Value(group.name),
    colorHex: Value(group.colorHex),
    iconCode: Value(group.iconCode),
    syncState: const Value('pending'),
    createdAt: Value(group.createdAt),
    updatedAt: Value(group.updatedAt),
    deletedAt: Value(group.deletedAt),
  );
}

AgendaGroup groupFromDb(AgendaGroupsTableData row) {
  return AgendaGroup(
    id: row.id,
    name: row.name,
    colorHex: row.colorHex,
    iconCode: row.iconCode,
    createdAt: row.createdAt,
    updatedAt: row.updatedAt,
    deletedAt: row.deletedAt,
  );
}

Map<String, dynamic>? _decodeJson(String? raw) {
  if (raw == null || raw.isEmpty) return null;
  return jsonDecode(raw) as Map<String, dynamic>;
}

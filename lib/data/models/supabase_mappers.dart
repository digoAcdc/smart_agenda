import 'dart:convert';

import '../../domain/entities/agenda_enums.dart';
import '../../domain/entities/agenda_group.dart';
import '../../domain/entities/agenda_item.dart';
import '../../domain/entities/attachment_ref.dart';
import '../../domain/entities/recurrence_rule.dart';
import '../../domain/entities/reminder_config.dart';

Map<String, dynamic>? _decodeJson(String? raw) {
  if (raw == null || raw.isEmpty) return null;
  return jsonDecode(raw) as Map<String, dynamic>;
}

AgendaItem agendaItemFromSupabase(
  Map<String, dynamic> row,
  List<Map<String, dynamic>> attachmentsRows,
) {
  final reminderMap = _decodeJson(row['reminder_json'] as String?);
  final recurrenceMap = _decodeJson(row['recurrence_json'] as String?);
  return AgendaItem(
    id: row['id'] as String,
    title: row['title'] as String,
    description: row['description'] as String?,
    startAt: DateTime.parse(row['start_at'] as String),
    endAt: row['end_at'] == null
        ? null
        : DateTime.parse(row['end_at'] as String),
    allDay: row['all_day'] as bool? ?? false,
    timezone: row['timezone'] as String?,
    groupId: row['group_id'] as String?,
    status: AgendaStatus.values.firstWhere(
      (e) => e.name == row['status'],
      orElse: () => AgendaStatus.pending,
    ),
    locationText: row['location_text'] as String?,
    reminder: reminderMap == null ? null : ReminderConfig.fromJson(reminderMap),
    recurrence:
        recurrenceMap == null ? null : RecurrenceRule.fromJson(recurrenceMap),
    attachments: attachmentsRows.map(attachmentFromSupabase).toList(),
    source: ItemSource.values.firstWhere(
      (e) => e.name == (row['source'] ?? 'local'),
      orElse: () => ItemSource.cloud,
    ),
    syncState: SyncState.values.firstWhere(
      (e) => e.name == (row['sync_state'] ?? 'pending'),
      orElse: () => SyncState.synced,
    ),
    createdAt: DateTime.parse(row['created_at'] as String),
    updatedAt: DateTime.parse(row['updated_at'] as String),
    deletedAt: row['deleted_at'] == null
        ? null
        : DateTime.parse(row['deleted_at'] as String),
  );
}

AttachmentRef attachmentFromSupabase(Map<String, dynamic> row) {
  return AttachmentRef(
    id: row['id'] as String,
    itemId: row['item_id'] as String,
    type: AttachmentType.values.firstWhere(
      (e) => e.name == row['type'],
      orElse: () => AttachmentType.file,
    ),
    localPath: row['local_path'] as String?,
    remoteUrl: row['remote_url'] as String?,
    thumbPath: row['thumb_path'] as String?,
    title: row['title'] as String?,
    mimeType: row['mime_type'] as String?,
    sizeBytes: row['size_bytes'] as int?,
    createdAt: DateTime.parse(row['created_at'] as String),
  );
}

AgendaGroup groupFromSupabase(Map<String, dynamic> row) {
  return AgendaGroup(
    id: row['id'] as String,
    name: row['name'] as String,
    colorHex: row['color_hex'] as String?,
    iconCode: row['icon_code'] as int?,
    createdAt: DateTime.parse(row['created_at'] as String),
    updatedAt: DateTime.parse(row['updated_at'] as String),
    deletedAt: row['deleted_at'] == null
        ? null
        : DateTime.parse(row['deleted_at'] as String),
  );
}

Map<String, dynamic> agendaItemToSupabase(AgendaItem item, String userId) {
  return {
    'id': item.id,
    'user_id': userId,
    'title': item.title,
    'description': item.description,
    'start_at': item.startAt.toIso8601String(),
    'end_at': item.endAt?.toIso8601String(),
    'all_day': item.allDay,
    'timezone': item.timezone,
    'group_id': item.groupId,
    'status': item.status.name,
    'location_text': item.locationText,
    'reminder_json':
        item.reminder == null ? null : jsonEncode(item.reminder!.toJson()),
    'recurrence_json':
        item.recurrence == null ? null : jsonEncode(item.recurrence!.toJson()),
    'source': item.source.name,
    'sync_state': item.syncState.name,
    'created_at': item.createdAt.toIso8601String(),
    'updated_at': item.updatedAt.toIso8601String(),
    'deleted_at': item.deletedAt?.toIso8601String(),
  };
}

Map<String, dynamic> attachmentToSupabase(AttachmentRef a, String userId) {
  return {
    'id': a.id,
    'user_id': userId,
    'item_id': a.itemId,
    'type': a.type.name,
    'local_path': a.localPath,
    'remote_url': a.remoteUrl,
    'thumb_path': a.thumbPath,
    'title': a.title,
    'mime_type': a.mimeType,
    'size_bytes': a.sizeBytes,
    'created_at': a.createdAt.toIso8601String(),
  };
}

Map<String, dynamic> groupToSupabase(AgendaGroup group, String userId) {
  return {
    'id': group.id,
    'user_id': userId,
    'name': group.name,
    'color_hex': group.colorHex,
    'icon_code': group.iconCode,
    'created_at': group.createdAt.toIso8601String(),
    'updated_at': group.updatedAt.toIso8601String(),
    'deleted_at': group.deletedAt?.toIso8601String(),
  };
}

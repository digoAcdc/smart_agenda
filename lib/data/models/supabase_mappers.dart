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

DateTime? _parseDate(Object? raw) =>
    raw == null ? null : DateTime.parse(raw as String).toLocal();

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
    startAt: _parseDate(row['start_at'])!,
    endAt: _parseDate(row['end_at']),
    allDay: row['all_day'] as bool? ?? false,
    timezone: row['timezone'] as String?,
    groupId: row['group_id'] as String?,
    status: enumByName(
      AgendaStatus.values,
      row['status'] as String?,
      AgendaStatus.pending,
    ),
    locationText: row['location_text'] as String?,
    reminder: reminderMap == null ? null : ReminderConfig.fromJson(reminderMap),
    recurrence: recurrenceMap == null
        ? null
        : RecurrenceRule.fromJson(recurrenceMap),
    attachments: attachmentsRows.map(attachmentFromSupabase).toList(),
    familyId: row['family_id'] as String?,
    kind: enumByName(
      AgendaItemKind.values,
      row['kind'] as String?,
      AgendaItemKind.event,
    ),
    schoolSubject: row['school_subject'] as String?,
    subjectType: enumByName(
      AgendaSubjectType.values,
      row['subject_type'] as String?,
      AgendaSubjectType.none,
    ),
    subjectChildId: row['subject_child_id'] as String?,
    subjectUserId: row['subject_user_id'] as String?,
    assigneeType: enumByName(
      AgendaAssigneeType.values,
      row['assignee_type'] as String?,
      AgendaAssigneeType.none,
    ),
    assigneeUserId: row['assignee_user_id'] as String?,
    createdBy: row['created_by'] as String?,
    updatedBy: row['updated_by'] as String?,
    completedBy: row['completed_by'] as String?,
    source: ItemSource.cloud,
    syncState: SyncState.synced,
    createdAt: _parseDate(row['created_at'])!,
    updatedAt: _parseDate(row['updated_at'])!,
    deletedAt: _parseDate(row['deleted_at']),
  );
}

AttachmentRef attachmentFromSupabase(Map<String, dynamic> row) {
  return AttachmentRef(
    id: row['id'] as String,
    itemId: row['item_id'] as String,
    type: enumByName(
      AttachmentType.values,
      row['type'] as String?,
      AttachmentType.file,
    ),
    remoteUrl: row['remote_url'] as String?,
    thumbPath: row['thumb_path'] as String?,
    title: row['title'] as String?,
    mimeType: row['mime_type'] as String?,
    sizeBytes: row['size_bytes'] as int?,
    createdAt: _parseDate(row['created_at'])!,
  );
}

AgendaGroup groupFromSupabase(Map<String, dynamic> row) {
  return AgendaGroup(
    id: row['id'] as String,
    familyId: row['family_id'] as String?,
    name: row['name'] as String,
    colorHex: row['color_hex'] as String?,
    iconCode: row['icon_code'] as int?,
    createdAt: _parseDate(row['created_at'])!,
    updatedAt: _parseDate(row['updated_at'])!,
    deletedAt: _parseDate(row['deleted_at']),
  );
}

/// Payload de upsert. Autoria (created_by/updated_by/completed_by) e
/// updated_at sao definidos pelo servidor; family_id/owner_user_id nao mudam
/// depois de criados.
Map<String, dynamic> agendaItemToSupabase(AgendaItem item, String userId) {
  final isFamily = item.familyId != null;
  return {
    'id': item.id,
    'family_id': item.familyId,
    'owner_user_id': isFamily ? null : userId,
    'kind': item.kind.name,
    'school_subject': item.schoolSubject,
    'title': item.title,
    'description': item.description,
    'start_at': item.startAt.toUtc().toIso8601String(),
    'end_at': item.endAt?.toUtc().toIso8601String(),
    'all_day': item.allDay,
    'timezone': item.timezone,
    // V1: categorias sao pessoais; itens da familia nao levam categoria.
    'group_id': isFamily ? null : item.groupId,
    'status': item.status.name,
    'location_text': item.locationText,
    'reminder_json': item.reminder == null
        ? null
        : jsonEncode(item.reminder!.toJson()),
    'recurrence_json': item.recurrence == null
        ? null
        : jsonEncode(item.recurrence!.toJson()),
    'subject_type': item.subjectType.name,
    'subject_child_id': item.subjectChildId,
    'subject_user_id': item.subjectUserId,
    'assignee_type': item.assigneeType.name,
    'assignee_user_id': item.assigneeUserId,
    'created_at': item.createdAt.toUtc().toIso8601String(),
    'deleted_at': item.deletedAt?.toUtc().toIso8601String(),
  };
}

Map<String, dynamic> attachmentToSupabase(AttachmentRef a) {
  return {
    'id': a.id,
    'item_id': a.itemId,
    'type': a.type.name,
    'remote_url': a.remoteUrl,
    'thumb_path': a.thumbPath,
    'title': a.title,
    'mime_type': a.mimeType,
    'size_bytes': a.sizeBytes,
    'created_at': a.createdAt.toUtc().toIso8601String(),
  };
}

Map<String, dynamic> groupToSupabase(AgendaGroup group, String userId) {
  return {
    'id': group.id,
    'family_id': group.familyId,
    'owner_user_id': group.familyId == null ? userId : null,
    'name': group.name,
    'color_hex': group.colorHex,
    'icon_code': group.iconCode,
    'created_at': group.createdAt.toUtc().toIso8601String(),
    'deleted_at': group.deletedAt?.toUtc().toIso8601String(),
  };
}

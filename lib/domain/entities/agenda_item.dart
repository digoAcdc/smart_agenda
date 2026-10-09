import 'package:equatable/equatable.dart';

import 'agenda_enums.dart';
import 'attachment_ref.dart';
import 'recurrence_rule.dart';
import 'reminder_config.dart';

class AgendaItem extends Equatable {
  const AgendaItem({
    required this.id,
    required this.title,
    this.description,
    required this.startAt,
    this.endAt,
    this.allDay = false,
    this.timezone,
    this.groupId,
    this.status = AgendaStatus.pending,
    this.locationText,
    this.reminder,
    this.recurrence,
    this.attachments = const [],
    this.familyId,
    this.kind = AgendaItemKind.event,
    this.subjectType = AgendaSubjectType.none,
    this.subjectChildId,
    this.subjectUserId,
    this.assigneeType = AgendaAssigneeType.none,
    this.assigneeUserId,
    this.createdBy,
    this.updatedBy,
    this.completedBy,
    this.source = ItemSource.local,
    this.syncState = SyncState.pending,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    this.occurrenceDate,
  }) : assert(title != '');

  final String id;
  final String title;
  final String? description;
  final DateTime startAt;
  final DateTime? endAt;
  final bool allDay;
  final String? timezone;
  final String? groupId;
  final AgendaStatus status;
  final String? locationText;
  final ReminderConfig? reminder;
  final RecurrenceRule? recurrence;
  final List<AttachmentRef> attachments;

  /// Dia desta ocorrencia quando o item vem de um evento que se repete
  /// (gerado na leitura, nao e salvo). Nulo = o proprio evento salvo.
  final DateTime? occurrenceDate;

  bool get isRecurring => recurrence?.repeats ?? false;
  bool get isOccurrence => occurrenceDate != null;

  /// Familia dona do item. Nulo = agenda pessoal.
  final String? familyId;
  final AgendaItemKind kind;

  /// De quem e o item (familia toda, filho ou membro). So vale na familia.
  final AgendaSubjectType subjectType;
  final String? subjectChildId;
  final String? subjectUserId;

  /// Responsavel (ninguem, todos ou um membro). So vale na familia.
  final AgendaAssigneeType assigneeType;
  final String? assigneeUserId;

  /// Autoria registrada pelo servidor.
  final String? createdBy;
  final String? updatedBy;
  final String? completedBy;

  final ItemSource source;
  final SyncState syncState;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  bool get isFamilyItem => familyId != null;

  AgendaItem copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? startAt,
    DateTime? endAt,
    bool? allDay,
    String? timezone,
    String? groupId,
    AgendaStatus? status,
    String? locationText,
    ReminderConfig? reminder,
    RecurrenceRule? recurrence,
    List<AttachmentRef>? attachments,
    String? familyId,
    AgendaItemKind? kind,
    AgendaSubjectType? subjectType,
    String? subjectChildId,
    String? subjectUserId,
    AgendaAssigneeType? assigneeType,
    String? assigneeUserId,
    String? createdBy,
    String? updatedBy,
    String? completedBy,
    ItemSource? source,
    SyncState? syncState,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
    DateTime? occurrenceDate,
    bool clearRecurrence = false,
  }) {
    return AgendaItem(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      startAt: startAt ?? this.startAt,
      endAt: endAt ?? this.endAt,
      allDay: allDay ?? this.allDay,
      timezone: timezone ?? this.timezone,
      groupId: groupId ?? this.groupId,
      status: status ?? this.status,
      locationText: locationText ?? this.locationText,
      reminder: reminder ?? this.reminder,
      recurrence: clearRecurrence ? null : (recurrence ?? this.recurrence),
      attachments: attachments ?? this.attachments,
      familyId: familyId ?? this.familyId,
      kind: kind ?? this.kind,
      subjectType: subjectType ?? this.subjectType,
      subjectChildId: subjectChildId ?? this.subjectChildId,
      subjectUserId: subjectUserId ?? this.subjectUserId,
      assigneeType: assigneeType ?? this.assigneeType,
      assigneeUserId: assigneeUserId ?? this.assigneeUserId,
      createdBy: createdBy ?? this.createdBy,
      updatedBy: updatedBy ?? this.updatedBy,
      completedBy: completedBy ?? this.completedBy,
      source: source ?? this.source,
      syncState: syncState ?? this.syncState,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      occurrenceDate: occurrenceDate ?? this.occurrenceDate,
    );
  }

  @override
  List<Object?> get props => [
    id,
    title,
    description,
    startAt,
    endAt,
    allDay,
    timezone,
    groupId,
    status,
    locationText,
    reminder,
    recurrence,
    attachments,
    familyId,
    kind,
    subjectType,
    subjectChildId,
    subjectUserId,
    assigneeType,
    assigneeUserId,
    createdBy,
    updatedBy,
    completedBy,
    source,
    syncState,
    createdAt,
    updatedAt,
    occurrenceDate,
    deletedAt,
  ];
}

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
    this.source = ItemSource.local,
    this.syncState = SyncState.pending,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
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
  final ItemSource source;
  final SyncState syncState;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;

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
    ItemSource? source,
    SyncState? syncState,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
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
      recurrence: recurrence ?? this.recurrence,
      attachments: attachments ?? this.attachments,
      source: source ?? this.source,
      syncState: syncState ?? this.syncState,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
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
        source,
        syncState,
        createdAt,
        updatedAt,
        deletedAt,
      ];
}

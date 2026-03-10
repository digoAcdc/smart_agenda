import 'package:equatable/equatable.dart';

import 'agenda_enums.dart';
import 'agenda_group.dart';
import 'agenda_item.dart';
import 'attachment_ref.dart';
import 'recurrence_rule.dart';
import 'reminder_config.dart';

class AgendaTransferBundle extends Equatable {
  const AgendaTransferBundle({
    required this.schemaVersion,
    required this.exportedAt,
    required this.appName,
    required this.groups,
    required this.items,
    this.classScheduleSlots = const [],
  });

  static const int currentSchemaVersion = 2;

  final int schemaVersion;
  final DateTime exportedAt;
  final String appName;
  final List<AgendaGroup> groups;
  final List<AgendaItem> items;
  final List<ClassScheduleTransferSlot> classScheduleSlots;

  String? validate() {
    if (schemaVersion <= 0) return 'Versao do schema invalida.';
    if (schemaVersion > currentSchemaVersion) {
      return 'Arquivo de agenda usa uma versao mais nova do formato.';
    }

    final groupIds = groups.map((e) => e.id).toSet();
    for (final item in items) {
      if (item.title.trim().isEmpty) {
        return 'Evento com titulo vazio encontrado no arquivo.';
      }
      if (item.groupId != null && !groupIds.contains(item.groupId)) {
        return 'Evento referencia grupo inexistente.';
      }
    }
    for (final slot in classScheduleSlots) {
      if (slot.dayOfWeek < 1 || slot.dayOfWeek > 7) {
        return 'Slot da grade horaria com dia da semana invalido.';
      }
      if (slot.endMinutes <= slot.startMinutes) {
        return 'Slot da grade horaria com horario invalido.';
      }
    }
    return null;
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'schemaVersion': schemaVersion,
      'exportedAt': exportedAt.toIso8601String(),
      'appName': appName,
      'groups': groups.map(AgendaTransferCodec.groupToJson).toList(),
      'items': items.map(AgendaTransferCodec.itemToJson).toList(),
      'classScheduleSlots':
          classScheduleSlots.map(AgendaTransferCodec.classSlotToJson).toList(),
    };
  }

  factory AgendaTransferBundle.fromJson(Map<String, dynamic> json) {
    final rawGroups = (json['groups'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>();
    final rawItems = (json['items'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>();
    final rawClassSlots = (json['classScheduleSlots'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>();

    return AgendaTransferBundle(
      schemaVersion: json['schemaVersion'] as int? ?? 1,
      exportedAt: DateTime.tryParse(json['exportedAt'] as String? ?? '') ??
          DateTime.now(),
      appName: json['appName'] as String? ?? 'smart_agenda',
      groups: rawGroups.map(AgendaTransferCodec.groupFromJson).toList(),
      items: rawItems.map(AgendaTransferCodec.itemFromJson).toList(),
      classScheduleSlots:
          rawClassSlots.map(AgendaTransferCodec.classSlotFromJson).toList(),
    );
  }

  @override
  List<Object?> get props => [
        schemaVersion,
        exportedAt,
        appName,
        groups,
        items,
        classScheduleSlots,
      ];
}

class ClassScheduleTransferSlot extends Equatable {
  const ClassScheduleTransferSlot({
    required this.id,
    required this.dayOfWeek,
    required this.startMinutes,
    required this.endMinutes,
    this.subject,
    this.professorName,
    this.professorEmail,
    this.professorPhone,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final int dayOfWeek;
  final int startMinutes;
  final int endMinutes;
  final String? subject;
  final String? professorName;
  final String? professorEmail;
  final String? professorPhone;
  final DateTime createdAt;
  final DateTime updatedAt;

  @override
  List<Object?> get props => [
        id,
        dayOfWeek,
        startMinutes,
        endMinutes,
        subject,
        professorName,
        professorEmail,
        professorPhone,
        createdAt,
        updatedAt,
      ];
}

class AgendaTransferImportReport extends Equatable {
  const AgendaTransferImportReport({
    required this.createdGroups,
    required this.updatedGroups,
    required this.skippedGroups,
    required this.createdItems,
    required this.updatedItems,
    required this.skippedItems,
    required this.reScheduledReminders,
    required this.createdClassSlots,
    required this.updatedClassSlots,
    required this.skippedClassSlots,
  });

  final int createdGroups;
  final int updatedGroups;
  final int skippedGroups;
  final int createdItems;
  final int updatedItems;
  final int skippedItems;
  final int reScheduledReminders;
  final int createdClassSlots;
  final int updatedClassSlots;
  final int skippedClassSlots;

  @override
  List<Object?> get props => [
        createdGroups,
        updatedGroups,
        skippedGroups,
        createdItems,
        updatedItems,
        skippedItems,
        reScheduledReminders,
        createdClassSlots,
        updatedClassSlots,
        skippedClassSlots,
      ];
}

class AgendaTransferExportData extends Equatable {
  const AgendaTransferExportData({
    required this.filePath,
    required this.itemCount,
    required this.groupCount,
    required this.classSlotCount,
  });

  final String filePath;
  final int itemCount;
  final int groupCount;
  final int classSlotCount;

  @override
  List<Object?> get props => [filePath, itemCount, groupCount, classSlotCount];
}

class AgendaTransferCodec {
  static Map<String, dynamic> groupToJson(AgendaGroup group) {
    return <String, dynamic>{
      'id': group.id,
      'name': group.name,
      'colorHex': group.colorHex,
      'iconCode': group.iconCode,
      'createdAt': group.createdAt.toIso8601String(),
      'updatedAt': group.updatedAt.toIso8601String(),
      'deletedAt': group.deletedAt?.toIso8601String(),
    };
  }

  static AgendaGroup groupFromJson(Map<String, dynamic> json) {
    return AgendaGroup(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      colorHex: json['colorHex'] as String?,
      iconCode: json['iconCode'] as int?,
      createdAt:
          DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
      updatedAt:
          DateTime.tryParse(json['updatedAt'] as String? ?? '') ?? DateTime.now(),
      deletedAt: json['deletedAt'] == null
          ? null
          : DateTime.tryParse(json['deletedAt'] as String),
    );
  }

  static Map<String, dynamic> itemToJson(AgendaItem item) {
    return <String, dynamic>{
      'id': item.id,
      'title': item.title,
      'description': item.description,
      'startAt': item.startAt.toIso8601String(),
      'endAt': item.endAt?.toIso8601String(),
      'allDay': item.allDay,
      'timezone': item.timezone,
      'groupId': item.groupId,
      'status': item.status.name,
      'locationText': item.locationText,
      'source': item.source.name,
      'syncState': item.syncState.name,
      'createdAt': item.createdAt.toIso8601String(),
      'updatedAt': item.updatedAt.toIso8601String(),
      'deletedAt': item.deletedAt?.toIso8601String(),
      'reminder': item.reminder?.toJson(),
      'recurrence': item.recurrence?.toJson(),
      'attachments': item.attachments.map(attachmentToJson).toList(),
    };
  }

  static AgendaItem itemFromJson(Map<String, dynamic> json) {
    final rawAttachments = (json['attachments'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>();

    return AgendaItem(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String?,
      startAt:
          DateTime.tryParse(json['startAt'] as String? ?? '') ?? DateTime.now(),
      endAt: json['endAt'] == null
          ? null
          : DateTime.tryParse(json['endAt'] as String),
      allDay: json['allDay'] as bool? ?? false,
      timezone: json['timezone'] as String?,
      groupId: json['groupId'] as String?,
      status: AgendaStatus.values.firstWhere(
        (e) => e.name == (json['status'] as String?),
        orElse: () => AgendaStatus.pending,
      ),
      locationText: json['locationText'] as String?,
      source: ItemSource.values.firstWhere(
        (e) => e.name == (json['source'] as String?),
        orElse: () => ItemSource.local,
      ),
      syncState: SyncState.values.firstWhere(
        (e) => e.name == (json['syncState'] as String?),
        orElse: () => SyncState.pending,
      ),
      createdAt:
          DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
      updatedAt:
          DateTime.tryParse(json['updatedAt'] as String? ?? '') ?? DateTime.now(),
      deletedAt: json['deletedAt'] == null
          ? null
          : DateTime.tryParse(json['deletedAt'] as String),
      reminder: json['reminder'] is Map<String, dynamic>
          ? ReminderConfig.fromJson(json['reminder'] as Map<String, dynamic>)
          : null,
      recurrence: json['recurrence'] is Map<String, dynamic>
          ? RecurrenceRule.fromJson(json['recurrence'] as Map<String, dynamic>)
          : null,
      attachments: rawAttachments.map(attachmentFromJson).toList(),
    );
  }

  static Map<String, dynamic> attachmentToJson(AttachmentRef attachment) {
    return <String, dynamic>{
      'id': attachment.id,
      'itemId': attachment.itemId,
      'type': attachment.type.name,
      'localPath': attachment.localPath,
      'remoteUrl': attachment.remoteUrl,
      'thumbPath': attachment.thumbPath,
      'title': attachment.title,
      'mimeType': attachment.mimeType,
      'sizeBytes': attachment.sizeBytes,
      'createdAt': attachment.createdAt.toIso8601String(),
    };
  }

  static AttachmentRef attachmentFromJson(Map<String, dynamic> json) {
    return AttachmentRef(
      id: json['id'] as String? ?? '',
      itemId: json['itemId'] as String? ?? '',
      type: AttachmentType.values.firstWhere(
        (e) => e.name == (json['type'] as String?),
        orElse: () => AttachmentType.file,
      ),
      localPath: json['localPath'] as String?,
      remoteUrl: json['remoteUrl'] as String?,
      thumbPath: json['thumbPath'] as String?,
      title: json['title'] as String?,
      mimeType: json['mimeType'] as String?,
      sizeBytes: json['sizeBytes'] as int?,
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }

  static Map<String, dynamic> classSlotToJson(ClassScheduleTransferSlot slot) {
    return <String, dynamic>{
      'id': slot.id,
      'dayOfWeek': slot.dayOfWeek,
      'startMinutes': slot.startMinutes,
      'endMinutes': slot.endMinutes,
      'subject': slot.subject,
      'professorName': slot.professorName,
      'professorEmail': slot.professorEmail,
      'professorPhone': slot.professorPhone,
      'createdAt': slot.createdAt.toIso8601String(),
      'updatedAt': slot.updatedAt.toIso8601String(),
    };
  }

  static ClassScheduleTransferSlot classSlotFromJson(Map<String, dynamic> json) {
    return ClassScheduleTransferSlot(
      id: json['id'] as String? ?? '',
      dayOfWeek: json['dayOfWeek'] as int? ?? 1,
      startMinutes: json['startMinutes'] as int? ?? 0,
      endMinutes: json['endMinutes'] as int? ?? 0,
      subject: json['subject'] as String?,
      professorName: json['professorName'] as String?,
      professorEmail: json['professorEmail'] as String?,
      professorPhone: json['professorPhone'] as String?,
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
      updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}

// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $AgendaItemsTableTable extends AgendaItemsTable
    with TableInfo<$AgendaItemsTableTable, AgendaItemsTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AgendaItemsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _startAtMeta = const VerificationMeta(
    'startAt',
  );
  @override
  late final GeneratedColumn<DateTime> startAt = GeneratedColumn<DateTime>(
    'start_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _endAtMeta = const VerificationMeta('endAt');
  @override
  late final GeneratedColumn<DateTime> endAt = GeneratedColumn<DateTime>(
    'end_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _allDayMeta = const VerificationMeta('allDay');
  @override
  late final GeneratedColumn<bool> allDay = GeneratedColumn<bool>(
    'all_day',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("all_day" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _timezoneMeta = const VerificationMeta(
    'timezone',
  );
  @override
  late final GeneratedColumn<String> timezone = GeneratedColumn<String>(
    'timezone',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _groupIdMeta = const VerificationMeta(
    'groupId',
  );
  @override
  late final GeneratedColumn<String> groupId = GeneratedColumn<String>(
    'group_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('pending'),
  );
  static const VerificationMeta _locationTextMeta = const VerificationMeta(
    'locationText',
  );
  @override
  late final GeneratedColumn<String> locationText = GeneratedColumn<String>(
    'location_text',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _reminderJsonMeta = const VerificationMeta(
    'reminderJson',
  );
  @override
  late final GeneratedColumn<String> reminderJson = GeneratedColumn<String>(
    'reminder_json',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _recurrenceJsonMeta = const VerificationMeta(
    'recurrenceJson',
  );
  @override
  late final GeneratedColumn<String> recurrenceJson = GeneratedColumn<String>(
    'recurrence_json',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sourceMeta = const VerificationMeta('source');
  @override
  late final GeneratedColumn<String> source = GeneratedColumn<String>(
    'source',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('local'),
  );
  static const VerificationMeta _syncStateMeta = const VerificationMeta(
    'syncState',
  );
  @override
  late final GeneratedColumn<String> syncState = GeneratedColumn<String>(
    'sync_state',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('pending'),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
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
    reminderJson,
    recurrenceJson,
    source,
    syncState,
    createdAt,
    updatedAt,
    deletedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'agenda_items_table';
  @override
  VerificationContext validateIntegrity(
    Insertable<AgendaItemsTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    }
    if (data.containsKey('start_at')) {
      context.handle(
        _startAtMeta,
        startAt.isAcceptableOrUnknown(data['start_at']!, _startAtMeta),
      );
    } else if (isInserting) {
      context.missing(_startAtMeta);
    }
    if (data.containsKey('end_at')) {
      context.handle(
        _endAtMeta,
        endAt.isAcceptableOrUnknown(data['end_at']!, _endAtMeta),
      );
    }
    if (data.containsKey('all_day')) {
      context.handle(
        _allDayMeta,
        allDay.isAcceptableOrUnknown(data['all_day']!, _allDayMeta),
      );
    }
    if (data.containsKey('timezone')) {
      context.handle(
        _timezoneMeta,
        timezone.isAcceptableOrUnknown(data['timezone']!, _timezoneMeta),
      );
    }
    if (data.containsKey('group_id')) {
      context.handle(
        _groupIdMeta,
        groupId.isAcceptableOrUnknown(data['group_id']!, _groupIdMeta),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('location_text')) {
      context.handle(
        _locationTextMeta,
        locationText.isAcceptableOrUnknown(
          data['location_text']!,
          _locationTextMeta,
        ),
      );
    }
    if (data.containsKey('reminder_json')) {
      context.handle(
        _reminderJsonMeta,
        reminderJson.isAcceptableOrUnknown(
          data['reminder_json']!,
          _reminderJsonMeta,
        ),
      );
    }
    if (data.containsKey('recurrence_json')) {
      context.handle(
        _recurrenceJsonMeta,
        recurrenceJson.isAcceptableOrUnknown(
          data['recurrence_json']!,
          _recurrenceJsonMeta,
        ),
      );
    }
    if (data.containsKey('source')) {
      context.handle(
        _sourceMeta,
        source.isAcceptableOrUnknown(data['source']!, _sourceMeta),
      );
    }
    if (data.containsKey('sync_state')) {
      context.handle(
        _syncStateMeta,
        syncState.isAcceptableOrUnknown(data['sync_state']!, _syncStateMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  AgendaItemsTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AgendaItemsTableData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      ),
      startAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}start_at'],
      )!,
      endAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}end_at'],
      ),
      allDay: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}all_day'],
      )!,
      timezone: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}timezone'],
      ),
      groupId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}group_id'],
      ),
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      locationText: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}location_text'],
      ),
      reminderJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}reminder_json'],
      ),
      recurrenceJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}recurrence_json'],
      ),
      source: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source'],
      )!,
      syncState: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sync_state'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
    );
  }

  @override
  $AgendaItemsTableTable createAlias(String alias) {
    return $AgendaItemsTableTable(attachedDatabase, alias);
  }
}

class AgendaItemsTableData extends DataClass
    implements Insertable<AgendaItemsTableData> {
  final String id;
  final String title;
  final String? description;
  final DateTime startAt;
  final DateTime? endAt;
  final bool allDay;
  final String? timezone;
  final String? groupId;
  final String status;
  final String? locationText;
  final String? reminderJson;
  final String? recurrenceJson;
  final String source;
  final String syncState;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  const AgendaItemsTableData({
    required this.id,
    required this.title,
    this.description,
    required this.startAt,
    this.endAt,
    required this.allDay,
    this.timezone,
    this.groupId,
    required this.status,
    this.locationText,
    this.reminderJson,
    this.recurrenceJson,
    required this.source,
    required this.syncState,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['title'] = Variable<String>(title);
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    map['start_at'] = Variable<DateTime>(startAt);
    if (!nullToAbsent || endAt != null) {
      map['end_at'] = Variable<DateTime>(endAt);
    }
    map['all_day'] = Variable<bool>(allDay);
    if (!nullToAbsent || timezone != null) {
      map['timezone'] = Variable<String>(timezone);
    }
    if (!nullToAbsent || groupId != null) {
      map['group_id'] = Variable<String>(groupId);
    }
    map['status'] = Variable<String>(status);
    if (!nullToAbsent || locationText != null) {
      map['location_text'] = Variable<String>(locationText);
    }
    if (!nullToAbsent || reminderJson != null) {
      map['reminder_json'] = Variable<String>(reminderJson);
    }
    if (!nullToAbsent || recurrenceJson != null) {
      map['recurrence_json'] = Variable<String>(recurrenceJson);
    }
    map['source'] = Variable<String>(source);
    map['sync_state'] = Variable<String>(syncState);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    return map;
  }

  AgendaItemsTableCompanion toCompanion(bool nullToAbsent) {
    return AgendaItemsTableCompanion(
      id: Value(id),
      title: Value(title),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      startAt: Value(startAt),
      endAt: endAt == null && nullToAbsent
          ? const Value.absent()
          : Value(endAt),
      allDay: Value(allDay),
      timezone: timezone == null && nullToAbsent
          ? const Value.absent()
          : Value(timezone),
      groupId: groupId == null && nullToAbsent
          ? const Value.absent()
          : Value(groupId),
      status: Value(status),
      locationText: locationText == null && nullToAbsent
          ? const Value.absent()
          : Value(locationText),
      reminderJson: reminderJson == null && nullToAbsent
          ? const Value.absent()
          : Value(reminderJson),
      recurrenceJson: recurrenceJson == null && nullToAbsent
          ? const Value.absent()
          : Value(recurrenceJson),
      source: Value(source),
      syncState: Value(syncState),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
    );
  }

  factory AgendaItemsTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AgendaItemsTableData(
      id: serializer.fromJson<String>(json['id']),
      title: serializer.fromJson<String>(json['title']),
      description: serializer.fromJson<String?>(json['description']),
      startAt: serializer.fromJson<DateTime>(json['startAt']),
      endAt: serializer.fromJson<DateTime?>(json['endAt']),
      allDay: serializer.fromJson<bool>(json['allDay']),
      timezone: serializer.fromJson<String?>(json['timezone']),
      groupId: serializer.fromJson<String?>(json['groupId']),
      status: serializer.fromJson<String>(json['status']),
      locationText: serializer.fromJson<String?>(json['locationText']),
      reminderJson: serializer.fromJson<String?>(json['reminderJson']),
      recurrenceJson: serializer.fromJson<String?>(json['recurrenceJson']),
      source: serializer.fromJson<String>(json['source']),
      syncState: serializer.fromJson<String>(json['syncState']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'title': serializer.toJson<String>(title),
      'description': serializer.toJson<String?>(description),
      'startAt': serializer.toJson<DateTime>(startAt),
      'endAt': serializer.toJson<DateTime?>(endAt),
      'allDay': serializer.toJson<bool>(allDay),
      'timezone': serializer.toJson<String?>(timezone),
      'groupId': serializer.toJson<String?>(groupId),
      'status': serializer.toJson<String>(status),
      'locationText': serializer.toJson<String?>(locationText),
      'reminderJson': serializer.toJson<String?>(reminderJson),
      'recurrenceJson': serializer.toJson<String?>(recurrenceJson),
      'source': serializer.toJson<String>(source),
      'syncState': serializer.toJson<String>(syncState),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
    };
  }

  AgendaItemsTableData copyWith({
    String? id,
    String? title,
    Value<String?> description = const Value.absent(),
    DateTime? startAt,
    Value<DateTime?> endAt = const Value.absent(),
    bool? allDay,
    Value<String?> timezone = const Value.absent(),
    Value<String?> groupId = const Value.absent(),
    String? status,
    Value<String?> locationText = const Value.absent(),
    Value<String?> reminderJson = const Value.absent(),
    Value<String?> recurrenceJson = const Value.absent(),
    String? source,
    String? syncState,
    DateTime? createdAt,
    DateTime? updatedAt,
    Value<DateTime?> deletedAt = const Value.absent(),
  }) => AgendaItemsTableData(
    id: id ?? this.id,
    title: title ?? this.title,
    description: description.present ? description.value : this.description,
    startAt: startAt ?? this.startAt,
    endAt: endAt.present ? endAt.value : this.endAt,
    allDay: allDay ?? this.allDay,
    timezone: timezone.present ? timezone.value : this.timezone,
    groupId: groupId.present ? groupId.value : this.groupId,
    status: status ?? this.status,
    locationText: locationText.present ? locationText.value : this.locationText,
    reminderJson: reminderJson.present ? reminderJson.value : this.reminderJson,
    recurrenceJson: recurrenceJson.present
        ? recurrenceJson.value
        : this.recurrenceJson,
    source: source ?? this.source,
    syncState: syncState ?? this.syncState,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
  );
  AgendaItemsTableData copyWithCompanion(AgendaItemsTableCompanion data) {
    return AgendaItemsTableData(
      id: data.id.present ? data.id.value : this.id,
      title: data.title.present ? data.title.value : this.title,
      description: data.description.present
          ? data.description.value
          : this.description,
      startAt: data.startAt.present ? data.startAt.value : this.startAt,
      endAt: data.endAt.present ? data.endAt.value : this.endAt,
      allDay: data.allDay.present ? data.allDay.value : this.allDay,
      timezone: data.timezone.present ? data.timezone.value : this.timezone,
      groupId: data.groupId.present ? data.groupId.value : this.groupId,
      status: data.status.present ? data.status.value : this.status,
      locationText: data.locationText.present
          ? data.locationText.value
          : this.locationText,
      reminderJson: data.reminderJson.present
          ? data.reminderJson.value
          : this.reminderJson,
      recurrenceJson: data.recurrenceJson.present
          ? data.recurrenceJson.value
          : this.recurrenceJson,
      source: data.source.present ? data.source.value : this.source,
      syncState: data.syncState.present ? data.syncState.value : this.syncState,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AgendaItemsTableData(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('description: $description, ')
          ..write('startAt: $startAt, ')
          ..write('endAt: $endAt, ')
          ..write('allDay: $allDay, ')
          ..write('timezone: $timezone, ')
          ..write('groupId: $groupId, ')
          ..write('status: $status, ')
          ..write('locationText: $locationText, ')
          ..write('reminderJson: $reminderJson, ')
          ..write('recurrenceJson: $recurrenceJson, ')
          ..write('source: $source, ')
          ..write('syncState: $syncState, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
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
    reminderJson,
    recurrenceJson,
    source,
    syncState,
    createdAt,
    updatedAt,
    deletedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AgendaItemsTableData &&
          other.id == this.id &&
          other.title == this.title &&
          other.description == this.description &&
          other.startAt == this.startAt &&
          other.endAt == this.endAt &&
          other.allDay == this.allDay &&
          other.timezone == this.timezone &&
          other.groupId == this.groupId &&
          other.status == this.status &&
          other.locationText == this.locationText &&
          other.reminderJson == this.reminderJson &&
          other.recurrenceJson == this.recurrenceJson &&
          other.source == this.source &&
          other.syncState == this.syncState &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt);
}

class AgendaItemsTableCompanion extends UpdateCompanion<AgendaItemsTableData> {
  final Value<String> id;
  final Value<String> title;
  final Value<String?> description;
  final Value<DateTime> startAt;
  final Value<DateTime?> endAt;
  final Value<bool> allDay;
  final Value<String?> timezone;
  final Value<String?> groupId;
  final Value<String> status;
  final Value<String?> locationText;
  final Value<String?> reminderJson;
  final Value<String?> recurrenceJson;
  final Value<String> source;
  final Value<String> syncState;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> deletedAt;
  final Value<int> rowid;
  const AgendaItemsTableCompanion({
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    this.description = const Value.absent(),
    this.startAt = const Value.absent(),
    this.endAt = const Value.absent(),
    this.allDay = const Value.absent(),
    this.timezone = const Value.absent(),
    this.groupId = const Value.absent(),
    this.status = const Value.absent(),
    this.locationText = const Value.absent(),
    this.reminderJson = const Value.absent(),
    this.recurrenceJson = const Value.absent(),
    this.source = const Value.absent(),
    this.syncState = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AgendaItemsTableCompanion.insert({
    required String id,
    required String title,
    this.description = const Value.absent(),
    required DateTime startAt,
    this.endAt = const Value.absent(),
    this.allDay = const Value.absent(),
    this.timezone = const Value.absent(),
    this.groupId = const Value.absent(),
    this.status = const Value.absent(),
    this.locationText = const Value.absent(),
    this.reminderJson = const Value.absent(),
    this.recurrenceJson = const Value.absent(),
    this.source = const Value.absent(),
    this.syncState = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       title = Value(title),
       startAt = Value(startAt),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<AgendaItemsTableData> custom({
    Expression<String>? id,
    Expression<String>? title,
    Expression<String>? description,
    Expression<DateTime>? startAt,
    Expression<DateTime>? endAt,
    Expression<bool>? allDay,
    Expression<String>? timezone,
    Expression<String>? groupId,
    Expression<String>? status,
    Expression<String>? locationText,
    Expression<String>? reminderJson,
    Expression<String>? recurrenceJson,
    Expression<String>? source,
    Expression<String>? syncState,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? deletedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (title != null) 'title': title,
      if (description != null) 'description': description,
      if (startAt != null) 'start_at': startAt,
      if (endAt != null) 'end_at': endAt,
      if (allDay != null) 'all_day': allDay,
      if (timezone != null) 'timezone': timezone,
      if (groupId != null) 'group_id': groupId,
      if (status != null) 'status': status,
      if (locationText != null) 'location_text': locationText,
      if (reminderJson != null) 'reminder_json': reminderJson,
      if (recurrenceJson != null) 'recurrence_json': recurrenceJson,
      if (source != null) 'source': source,
      if (syncState != null) 'sync_state': syncState,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AgendaItemsTableCompanion copyWith({
    Value<String>? id,
    Value<String>? title,
    Value<String?>? description,
    Value<DateTime>? startAt,
    Value<DateTime?>? endAt,
    Value<bool>? allDay,
    Value<String?>? timezone,
    Value<String?>? groupId,
    Value<String>? status,
    Value<String?>? locationText,
    Value<String?>? reminderJson,
    Value<String?>? recurrenceJson,
    Value<String>? source,
    Value<String>? syncState,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<DateTime?>? deletedAt,
    Value<int>? rowid,
  }) {
    return AgendaItemsTableCompanion(
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
      reminderJson: reminderJson ?? this.reminderJson,
      recurrenceJson: recurrenceJson ?? this.recurrenceJson,
      source: source ?? this.source,
      syncState: syncState ?? this.syncState,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (startAt.present) {
      map['start_at'] = Variable<DateTime>(startAt.value);
    }
    if (endAt.present) {
      map['end_at'] = Variable<DateTime>(endAt.value);
    }
    if (allDay.present) {
      map['all_day'] = Variable<bool>(allDay.value);
    }
    if (timezone.present) {
      map['timezone'] = Variable<String>(timezone.value);
    }
    if (groupId.present) {
      map['group_id'] = Variable<String>(groupId.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (locationText.present) {
      map['location_text'] = Variable<String>(locationText.value);
    }
    if (reminderJson.present) {
      map['reminder_json'] = Variable<String>(reminderJson.value);
    }
    if (recurrenceJson.present) {
      map['recurrence_json'] = Variable<String>(recurrenceJson.value);
    }
    if (source.present) {
      map['source'] = Variable<String>(source.value);
    }
    if (syncState.present) {
      map['sync_state'] = Variable<String>(syncState.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AgendaItemsTableCompanion(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('description: $description, ')
          ..write('startAt: $startAt, ')
          ..write('endAt: $endAt, ')
          ..write('allDay: $allDay, ')
          ..write('timezone: $timezone, ')
          ..write('groupId: $groupId, ')
          ..write('status: $status, ')
          ..write('locationText: $locationText, ')
          ..write('reminderJson: $reminderJson, ')
          ..write('recurrenceJson: $recurrenceJson, ')
          ..write('source: $source, ')
          ..write('syncState: $syncState, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AgendaGroupsTableTable extends AgendaGroupsTable
    with TableInfo<$AgendaGroupsTableTable, AgendaGroupsTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AgendaGroupsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _colorHexMeta = const VerificationMeta(
    'colorHex',
  );
  @override
  late final GeneratedColumn<String> colorHex = GeneratedColumn<String>(
    'color_hex',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _iconCodeMeta = const VerificationMeta(
    'iconCode',
  );
  @override
  late final GeneratedColumn<int> iconCode = GeneratedColumn<int>(
    'icon_code',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _syncStateMeta = const VerificationMeta(
    'syncState',
  );
  @override
  late final GeneratedColumn<String> syncState = GeneratedColumn<String>(
    'sync_state',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('pending'),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    colorHex,
    iconCode,
    syncState,
    createdAt,
    updatedAt,
    deletedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'agenda_groups_table';
  @override
  VerificationContext validateIntegrity(
    Insertable<AgendaGroupsTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('color_hex')) {
      context.handle(
        _colorHexMeta,
        colorHex.isAcceptableOrUnknown(data['color_hex']!, _colorHexMeta),
      );
    }
    if (data.containsKey('icon_code')) {
      context.handle(
        _iconCodeMeta,
        iconCode.isAcceptableOrUnknown(data['icon_code']!, _iconCodeMeta),
      );
    }
    if (data.containsKey('sync_state')) {
      context.handle(
        _syncStateMeta,
        syncState.isAcceptableOrUnknown(data['sync_state']!, _syncStateMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  AgendaGroupsTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AgendaGroupsTableData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      colorHex: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}color_hex'],
      ),
      iconCode: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}icon_code'],
      ),
      syncState: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sync_state'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
    );
  }

  @override
  $AgendaGroupsTableTable createAlias(String alias) {
    return $AgendaGroupsTableTable(attachedDatabase, alias);
  }
}

class AgendaGroupsTableData extends DataClass
    implements Insertable<AgendaGroupsTableData> {
  final String id;
  final String name;
  final String? colorHex;
  final int? iconCode;
  final String syncState;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  const AgendaGroupsTableData({
    required this.id,
    required this.name,
    this.colorHex,
    this.iconCode,
    required this.syncState,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || colorHex != null) {
      map['color_hex'] = Variable<String>(colorHex);
    }
    if (!nullToAbsent || iconCode != null) {
      map['icon_code'] = Variable<int>(iconCode);
    }
    map['sync_state'] = Variable<String>(syncState);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    return map;
  }

  AgendaGroupsTableCompanion toCompanion(bool nullToAbsent) {
    return AgendaGroupsTableCompanion(
      id: Value(id),
      name: Value(name),
      colorHex: colorHex == null && nullToAbsent
          ? const Value.absent()
          : Value(colorHex),
      iconCode: iconCode == null && nullToAbsent
          ? const Value.absent()
          : Value(iconCode),
      syncState: Value(syncState),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
    );
  }

  factory AgendaGroupsTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AgendaGroupsTableData(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      colorHex: serializer.fromJson<String?>(json['colorHex']),
      iconCode: serializer.fromJson<int?>(json['iconCode']),
      syncState: serializer.fromJson<String>(json['syncState']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'colorHex': serializer.toJson<String?>(colorHex),
      'iconCode': serializer.toJson<int?>(iconCode),
      'syncState': serializer.toJson<String>(syncState),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
    };
  }

  AgendaGroupsTableData copyWith({
    String? id,
    String? name,
    Value<String?> colorHex = const Value.absent(),
    Value<int?> iconCode = const Value.absent(),
    String? syncState,
    DateTime? createdAt,
    DateTime? updatedAt,
    Value<DateTime?> deletedAt = const Value.absent(),
  }) => AgendaGroupsTableData(
    id: id ?? this.id,
    name: name ?? this.name,
    colorHex: colorHex.present ? colorHex.value : this.colorHex,
    iconCode: iconCode.present ? iconCode.value : this.iconCode,
    syncState: syncState ?? this.syncState,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
  );
  AgendaGroupsTableData copyWithCompanion(AgendaGroupsTableCompanion data) {
    return AgendaGroupsTableData(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      colorHex: data.colorHex.present ? data.colorHex.value : this.colorHex,
      iconCode: data.iconCode.present ? data.iconCode.value : this.iconCode,
      syncState: data.syncState.present ? data.syncState.value : this.syncState,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AgendaGroupsTableData(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('colorHex: $colorHex, ')
          ..write('iconCode: $iconCode, ')
          ..write('syncState: $syncState, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    colorHex,
    iconCode,
    syncState,
    createdAt,
    updatedAt,
    deletedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AgendaGroupsTableData &&
          other.id == this.id &&
          other.name == this.name &&
          other.colorHex == this.colorHex &&
          other.iconCode == this.iconCode &&
          other.syncState == this.syncState &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt);
}

class AgendaGroupsTableCompanion
    extends UpdateCompanion<AgendaGroupsTableData> {
  final Value<String> id;
  final Value<String> name;
  final Value<String?> colorHex;
  final Value<int?> iconCode;
  final Value<String> syncState;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> deletedAt;
  final Value<int> rowid;
  const AgendaGroupsTableCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.colorHex = const Value.absent(),
    this.iconCode = const Value.absent(),
    this.syncState = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AgendaGroupsTableCompanion.insert({
    required String id,
    required String name,
    this.colorHex = const Value.absent(),
    this.iconCode = const Value.absent(),
    this.syncState = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<AgendaGroupsTableData> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? colorHex,
    Expression<int>? iconCode,
    Expression<String>? syncState,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? deletedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (colorHex != null) 'color_hex': colorHex,
      if (iconCode != null) 'icon_code': iconCode,
      if (syncState != null) 'sync_state': syncState,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AgendaGroupsTableCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String?>? colorHex,
    Value<int?>? iconCode,
    Value<String>? syncState,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<DateTime?>? deletedAt,
    Value<int>? rowid,
  }) {
    return AgendaGroupsTableCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      colorHex: colorHex ?? this.colorHex,
      iconCode: iconCode ?? this.iconCode,
      syncState: syncState ?? this.syncState,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (colorHex.present) {
      map['color_hex'] = Variable<String>(colorHex.value);
    }
    if (iconCode.present) {
      map['icon_code'] = Variable<int>(iconCode.value);
    }
    if (syncState.present) {
      map['sync_state'] = Variable<String>(syncState.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AgendaGroupsTableCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('colorHex: $colorHex, ')
          ..write('iconCode: $iconCode, ')
          ..write('syncState: $syncState, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AttachmentsTableTable extends AttachmentsTable
    with TableInfo<$AttachmentsTableTable, AttachmentsTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AttachmentsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _itemIdMeta = const VerificationMeta('itemId');
  @override
  late final GeneratedColumn<String> itemId = GeneratedColumn<String>(
    'item_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
    'type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _localPathMeta = const VerificationMeta(
    'localPath',
  );
  @override
  late final GeneratedColumn<String> localPath = GeneratedColumn<String>(
    'local_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _remoteUrlMeta = const VerificationMeta(
    'remoteUrl',
  );
  @override
  late final GeneratedColumn<String> remoteUrl = GeneratedColumn<String>(
    'remote_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _thumbPathMeta = const VerificationMeta(
    'thumbPath',
  );
  @override
  late final GeneratedColumn<String> thumbPath = GeneratedColumn<String>(
    'thumb_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _mimeTypeMeta = const VerificationMeta(
    'mimeType',
  );
  @override
  late final GeneratedColumn<String> mimeType = GeneratedColumn<String>(
    'mime_type',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sizeBytesMeta = const VerificationMeta(
    'sizeBytes',
  );
  @override
  late final GeneratedColumn<int> sizeBytes = GeneratedColumn<int>(
    'size_bytes',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    itemId,
    type,
    localPath,
    remoteUrl,
    thumbPath,
    title,
    mimeType,
    sizeBytes,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'attachments_table';
  @override
  VerificationContext validateIntegrity(
    Insertable<AttachmentsTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('item_id')) {
      context.handle(
        _itemIdMeta,
        itemId.isAcceptableOrUnknown(data['item_id']!, _itemIdMeta),
      );
    } else if (isInserting) {
      context.missing(_itemIdMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('local_path')) {
      context.handle(
        _localPathMeta,
        localPath.isAcceptableOrUnknown(data['local_path']!, _localPathMeta),
      );
    }
    if (data.containsKey('remote_url')) {
      context.handle(
        _remoteUrlMeta,
        remoteUrl.isAcceptableOrUnknown(data['remote_url']!, _remoteUrlMeta),
      );
    }
    if (data.containsKey('thumb_path')) {
      context.handle(
        _thumbPathMeta,
        thumbPath.isAcceptableOrUnknown(data['thumb_path']!, _thumbPathMeta),
      );
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    }
    if (data.containsKey('mime_type')) {
      context.handle(
        _mimeTypeMeta,
        mimeType.isAcceptableOrUnknown(data['mime_type']!, _mimeTypeMeta),
      );
    }
    if (data.containsKey('size_bytes')) {
      context.handle(
        _sizeBytesMeta,
        sizeBytes.isAcceptableOrUnknown(data['size_bytes']!, _sizeBytesMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  AttachmentsTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AttachmentsTableData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      itemId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}item_id'],
      )!,
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      )!,
      localPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}local_path'],
      ),
      remoteUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}remote_url'],
      ),
      thumbPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}thumb_path'],
      ),
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      ),
      mimeType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}mime_type'],
      ),
      sizeBytes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}size_bytes'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $AttachmentsTableTable createAlias(String alias) {
    return $AttachmentsTableTable(attachedDatabase, alias);
  }
}

class AttachmentsTableData extends DataClass
    implements Insertable<AttachmentsTableData> {
  final String id;
  final String itemId;
  final String type;
  final String? localPath;
  final String? remoteUrl;
  final String? thumbPath;
  final String? title;
  final String? mimeType;
  final int? sizeBytes;
  final DateTime createdAt;
  const AttachmentsTableData({
    required this.id,
    required this.itemId,
    required this.type,
    this.localPath,
    this.remoteUrl,
    this.thumbPath,
    this.title,
    this.mimeType,
    this.sizeBytes,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['item_id'] = Variable<String>(itemId);
    map['type'] = Variable<String>(type);
    if (!nullToAbsent || localPath != null) {
      map['local_path'] = Variable<String>(localPath);
    }
    if (!nullToAbsent || remoteUrl != null) {
      map['remote_url'] = Variable<String>(remoteUrl);
    }
    if (!nullToAbsent || thumbPath != null) {
      map['thumb_path'] = Variable<String>(thumbPath);
    }
    if (!nullToAbsent || title != null) {
      map['title'] = Variable<String>(title);
    }
    if (!nullToAbsent || mimeType != null) {
      map['mime_type'] = Variable<String>(mimeType);
    }
    if (!nullToAbsent || sizeBytes != null) {
      map['size_bytes'] = Variable<int>(sizeBytes);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  AttachmentsTableCompanion toCompanion(bool nullToAbsent) {
    return AttachmentsTableCompanion(
      id: Value(id),
      itemId: Value(itemId),
      type: Value(type),
      localPath: localPath == null && nullToAbsent
          ? const Value.absent()
          : Value(localPath),
      remoteUrl: remoteUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(remoteUrl),
      thumbPath: thumbPath == null && nullToAbsent
          ? const Value.absent()
          : Value(thumbPath),
      title: title == null && nullToAbsent
          ? const Value.absent()
          : Value(title),
      mimeType: mimeType == null && nullToAbsent
          ? const Value.absent()
          : Value(mimeType),
      sizeBytes: sizeBytes == null && nullToAbsent
          ? const Value.absent()
          : Value(sizeBytes),
      createdAt: Value(createdAt),
    );
  }

  factory AttachmentsTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AttachmentsTableData(
      id: serializer.fromJson<String>(json['id']),
      itemId: serializer.fromJson<String>(json['itemId']),
      type: serializer.fromJson<String>(json['type']),
      localPath: serializer.fromJson<String?>(json['localPath']),
      remoteUrl: serializer.fromJson<String?>(json['remoteUrl']),
      thumbPath: serializer.fromJson<String?>(json['thumbPath']),
      title: serializer.fromJson<String?>(json['title']),
      mimeType: serializer.fromJson<String?>(json['mimeType']),
      sizeBytes: serializer.fromJson<int?>(json['sizeBytes']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'itemId': serializer.toJson<String>(itemId),
      'type': serializer.toJson<String>(type),
      'localPath': serializer.toJson<String?>(localPath),
      'remoteUrl': serializer.toJson<String?>(remoteUrl),
      'thumbPath': serializer.toJson<String?>(thumbPath),
      'title': serializer.toJson<String?>(title),
      'mimeType': serializer.toJson<String?>(mimeType),
      'sizeBytes': serializer.toJson<int?>(sizeBytes),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  AttachmentsTableData copyWith({
    String? id,
    String? itemId,
    String? type,
    Value<String?> localPath = const Value.absent(),
    Value<String?> remoteUrl = const Value.absent(),
    Value<String?> thumbPath = const Value.absent(),
    Value<String?> title = const Value.absent(),
    Value<String?> mimeType = const Value.absent(),
    Value<int?> sizeBytes = const Value.absent(),
    DateTime? createdAt,
  }) => AttachmentsTableData(
    id: id ?? this.id,
    itemId: itemId ?? this.itemId,
    type: type ?? this.type,
    localPath: localPath.present ? localPath.value : this.localPath,
    remoteUrl: remoteUrl.present ? remoteUrl.value : this.remoteUrl,
    thumbPath: thumbPath.present ? thumbPath.value : this.thumbPath,
    title: title.present ? title.value : this.title,
    mimeType: mimeType.present ? mimeType.value : this.mimeType,
    sizeBytes: sizeBytes.present ? sizeBytes.value : this.sizeBytes,
    createdAt: createdAt ?? this.createdAt,
  );
  AttachmentsTableData copyWithCompanion(AttachmentsTableCompanion data) {
    return AttachmentsTableData(
      id: data.id.present ? data.id.value : this.id,
      itemId: data.itemId.present ? data.itemId.value : this.itemId,
      type: data.type.present ? data.type.value : this.type,
      localPath: data.localPath.present ? data.localPath.value : this.localPath,
      remoteUrl: data.remoteUrl.present ? data.remoteUrl.value : this.remoteUrl,
      thumbPath: data.thumbPath.present ? data.thumbPath.value : this.thumbPath,
      title: data.title.present ? data.title.value : this.title,
      mimeType: data.mimeType.present ? data.mimeType.value : this.mimeType,
      sizeBytes: data.sizeBytes.present ? data.sizeBytes.value : this.sizeBytes,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AttachmentsTableData(')
          ..write('id: $id, ')
          ..write('itemId: $itemId, ')
          ..write('type: $type, ')
          ..write('localPath: $localPath, ')
          ..write('remoteUrl: $remoteUrl, ')
          ..write('thumbPath: $thumbPath, ')
          ..write('title: $title, ')
          ..write('mimeType: $mimeType, ')
          ..write('sizeBytes: $sizeBytes, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    itemId,
    type,
    localPath,
    remoteUrl,
    thumbPath,
    title,
    mimeType,
    sizeBytes,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AttachmentsTableData &&
          other.id == this.id &&
          other.itemId == this.itemId &&
          other.type == this.type &&
          other.localPath == this.localPath &&
          other.remoteUrl == this.remoteUrl &&
          other.thumbPath == this.thumbPath &&
          other.title == this.title &&
          other.mimeType == this.mimeType &&
          other.sizeBytes == this.sizeBytes &&
          other.createdAt == this.createdAt);
}

class AttachmentsTableCompanion extends UpdateCompanion<AttachmentsTableData> {
  final Value<String> id;
  final Value<String> itemId;
  final Value<String> type;
  final Value<String?> localPath;
  final Value<String?> remoteUrl;
  final Value<String?> thumbPath;
  final Value<String?> title;
  final Value<String?> mimeType;
  final Value<int?> sizeBytes;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const AttachmentsTableCompanion({
    this.id = const Value.absent(),
    this.itemId = const Value.absent(),
    this.type = const Value.absent(),
    this.localPath = const Value.absent(),
    this.remoteUrl = const Value.absent(),
    this.thumbPath = const Value.absent(),
    this.title = const Value.absent(),
    this.mimeType = const Value.absent(),
    this.sizeBytes = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AttachmentsTableCompanion.insert({
    required String id,
    required String itemId,
    required String type,
    this.localPath = const Value.absent(),
    this.remoteUrl = const Value.absent(),
    this.thumbPath = const Value.absent(),
    this.title = const Value.absent(),
    this.mimeType = const Value.absent(),
    this.sizeBytes = const Value.absent(),
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       itemId = Value(itemId),
       type = Value(type),
       createdAt = Value(createdAt);
  static Insertable<AttachmentsTableData> custom({
    Expression<String>? id,
    Expression<String>? itemId,
    Expression<String>? type,
    Expression<String>? localPath,
    Expression<String>? remoteUrl,
    Expression<String>? thumbPath,
    Expression<String>? title,
    Expression<String>? mimeType,
    Expression<int>? sizeBytes,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (itemId != null) 'item_id': itemId,
      if (type != null) 'type': type,
      if (localPath != null) 'local_path': localPath,
      if (remoteUrl != null) 'remote_url': remoteUrl,
      if (thumbPath != null) 'thumb_path': thumbPath,
      if (title != null) 'title': title,
      if (mimeType != null) 'mime_type': mimeType,
      if (sizeBytes != null) 'size_bytes': sizeBytes,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AttachmentsTableCompanion copyWith({
    Value<String>? id,
    Value<String>? itemId,
    Value<String>? type,
    Value<String?>? localPath,
    Value<String?>? remoteUrl,
    Value<String?>? thumbPath,
    Value<String?>? title,
    Value<String?>? mimeType,
    Value<int?>? sizeBytes,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return AttachmentsTableCompanion(
      id: id ?? this.id,
      itemId: itemId ?? this.itemId,
      type: type ?? this.type,
      localPath: localPath ?? this.localPath,
      remoteUrl: remoteUrl ?? this.remoteUrl,
      thumbPath: thumbPath ?? this.thumbPath,
      title: title ?? this.title,
      mimeType: mimeType ?? this.mimeType,
      sizeBytes: sizeBytes ?? this.sizeBytes,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (itemId.present) {
      map['item_id'] = Variable<String>(itemId.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (localPath.present) {
      map['local_path'] = Variable<String>(localPath.value);
    }
    if (remoteUrl.present) {
      map['remote_url'] = Variable<String>(remoteUrl.value);
    }
    if (thumbPath.present) {
      map['thumb_path'] = Variable<String>(thumbPath.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (mimeType.present) {
      map['mime_type'] = Variable<String>(mimeType.value);
    }
    if (sizeBytes.present) {
      map['size_bytes'] = Variable<int>(sizeBytes.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AttachmentsTableCompanion(')
          ..write('id: $id, ')
          ..write('itemId: $itemId, ')
          ..write('type: $type, ')
          ..write('localPath: $localPath, ')
          ..write('remoteUrl: $remoteUrl, ')
          ..write('thumbPath: $thumbPath, ')
          ..write('title: $title, ')
          ..write('mimeType: $mimeType, ')
          ..write('sizeBytes: $sizeBytes, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ClassGroupsTableTable extends ClassGroupsTable
    with TableInfo<$ClassGroupsTableTable, ClassGroupsTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ClassGroupsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    description,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'class_groups_table';
  @override
  VerificationContext validateIntegrity(
    Insertable<ClassGroupsTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ClassGroupsTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ClassGroupsTableData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $ClassGroupsTableTable createAlias(String alias) {
    return $ClassGroupsTableTable(attachedDatabase, alias);
  }
}

class ClassGroupsTableData extends DataClass
    implements Insertable<ClassGroupsTableData> {
  final String id;
  final String name;
  final String? description;
  final DateTime createdAt;
  final DateTime updatedAt;
  const ClassGroupsTableData({
    required this.id,
    required this.name,
    this.description,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  ClassGroupsTableCompanion toCompanion(bool nullToAbsent) {
    return ClassGroupsTableCompanion(
      id: Value(id),
      name: Value(name),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory ClassGroupsTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ClassGroupsTableData(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      description: serializer.fromJson<String?>(json['description']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'description': serializer.toJson<String?>(description),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  ClassGroupsTableData copyWith({
    String? id,
    String? name,
    Value<String?> description = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => ClassGroupsTableData(
    id: id ?? this.id,
    name: name ?? this.name,
    description: description.present ? description.value : this.description,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  ClassGroupsTableData copyWithCompanion(ClassGroupsTableCompanion data) {
    return ClassGroupsTableData(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      description: data.description.present
          ? data.description.value
          : this.description,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ClassGroupsTableData(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('description: $description, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, description, createdAt, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ClassGroupsTableData &&
          other.id == this.id &&
          other.name == this.name &&
          other.description == this.description &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class ClassGroupsTableCompanion extends UpdateCompanion<ClassGroupsTableData> {
  final Value<String> id;
  final Value<String> name;
  final Value<String?> description;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const ClassGroupsTableCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.description = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ClassGroupsTableCompanion.insert({
    required String id,
    required String name,
    this.description = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<ClassGroupsTableData> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? description,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (description != null) 'description': description,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ClassGroupsTableCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String?>? description,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return ClassGroupsTableCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ClassGroupsTableCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('description: $description, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $StudentsTableTable extends StudentsTable
    with TableInfo<$StudentsTableTable, StudentsTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $StudentsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _groupIdMeta = const VerificationMeta(
    'groupId',
  );
  @override
  late final GeneratedColumn<String> groupId = GeneratedColumn<String>(
    'group_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _emailMeta = const VerificationMeta('email');
  @override
  late final GeneratedColumn<String> email = GeneratedColumn<String>(
    'email',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _phoneMeta = const VerificationMeta('phone');
  @override
  late final GeneratedColumn<String> phone = GeneratedColumn<String>(
    'phone',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _guardianNameMeta = const VerificationMeta(
    'guardianName',
  );
  @override
  late final GeneratedColumn<String> guardianName = GeneratedColumn<String>(
    'guardian_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _guardianEmailMeta = const VerificationMeta(
    'guardianEmail',
  );
  @override
  late final GeneratedColumn<String> guardianEmail = GeneratedColumn<String>(
    'guardian_email',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _guardianPhoneMeta = const VerificationMeta(
    'guardianPhone',
  );
  @override
  late final GeneratedColumn<String> guardianPhone = GeneratedColumn<String>(
    'guardian_phone',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    groupId,
    name,
    email,
    phone,
    guardianName,
    guardianEmail,
    guardianPhone,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'students_table';
  @override
  VerificationContext validateIntegrity(
    Insertable<StudentsTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('group_id')) {
      context.handle(
        _groupIdMeta,
        groupId.isAcceptableOrUnknown(data['group_id']!, _groupIdMeta),
      );
    } else if (isInserting) {
      context.missing(_groupIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('email')) {
      context.handle(
        _emailMeta,
        email.isAcceptableOrUnknown(data['email']!, _emailMeta),
      );
    }
    if (data.containsKey('phone')) {
      context.handle(
        _phoneMeta,
        phone.isAcceptableOrUnknown(data['phone']!, _phoneMeta),
      );
    }
    if (data.containsKey('guardian_name')) {
      context.handle(
        _guardianNameMeta,
        guardianName.isAcceptableOrUnknown(
          data['guardian_name']!,
          _guardianNameMeta,
        ),
      );
    }
    if (data.containsKey('guardian_email')) {
      context.handle(
        _guardianEmailMeta,
        guardianEmail.isAcceptableOrUnknown(
          data['guardian_email']!,
          _guardianEmailMeta,
        ),
      );
    }
    if (data.containsKey('guardian_phone')) {
      context.handle(
        _guardianPhoneMeta,
        guardianPhone.isAcceptableOrUnknown(
          data['guardian_phone']!,
          _guardianPhoneMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  StudentsTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return StudentsTableData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      groupId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}group_id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      email: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}email'],
      ),
      phone: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}phone'],
      ),
      guardianName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}guardian_name'],
      ),
      guardianEmail: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}guardian_email'],
      ),
      guardianPhone: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}guardian_phone'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $StudentsTableTable createAlias(String alias) {
    return $StudentsTableTable(attachedDatabase, alias);
  }
}

class StudentsTableData extends DataClass
    implements Insertable<StudentsTableData> {
  final String id;
  final String groupId;
  final String name;
  final String? email;
  final String? phone;
  final String? guardianName;
  final String? guardianEmail;
  final String? guardianPhone;
  final DateTime createdAt;
  final DateTime updatedAt;
  const StudentsTableData({
    required this.id,
    required this.groupId,
    required this.name,
    this.email,
    this.phone,
    this.guardianName,
    this.guardianEmail,
    this.guardianPhone,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['group_id'] = Variable<String>(groupId);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || email != null) {
      map['email'] = Variable<String>(email);
    }
    if (!nullToAbsent || phone != null) {
      map['phone'] = Variable<String>(phone);
    }
    if (!nullToAbsent || guardianName != null) {
      map['guardian_name'] = Variable<String>(guardianName);
    }
    if (!nullToAbsent || guardianEmail != null) {
      map['guardian_email'] = Variable<String>(guardianEmail);
    }
    if (!nullToAbsent || guardianPhone != null) {
      map['guardian_phone'] = Variable<String>(guardianPhone);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  StudentsTableCompanion toCompanion(bool nullToAbsent) {
    return StudentsTableCompanion(
      id: Value(id),
      groupId: Value(groupId),
      name: Value(name),
      email: email == null && nullToAbsent
          ? const Value.absent()
          : Value(email),
      phone: phone == null && nullToAbsent
          ? const Value.absent()
          : Value(phone),
      guardianName: guardianName == null && nullToAbsent
          ? const Value.absent()
          : Value(guardianName),
      guardianEmail: guardianEmail == null && nullToAbsent
          ? const Value.absent()
          : Value(guardianEmail),
      guardianPhone: guardianPhone == null && nullToAbsent
          ? const Value.absent()
          : Value(guardianPhone),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory StudentsTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return StudentsTableData(
      id: serializer.fromJson<String>(json['id']),
      groupId: serializer.fromJson<String>(json['groupId']),
      name: serializer.fromJson<String>(json['name']),
      email: serializer.fromJson<String?>(json['email']),
      phone: serializer.fromJson<String?>(json['phone']),
      guardianName: serializer.fromJson<String?>(json['guardianName']),
      guardianEmail: serializer.fromJson<String?>(json['guardianEmail']),
      guardianPhone: serializer.fromJson<String?>(json['guardianPhone']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'groupId': serializer.toJson<String>(groupId),
      'name': serializer.toJson<String>(name),
      'email': serializer.toJson<String?>(email),
      'phone': serializer.toJson<String?>(phone),
      'guardianName': serializer.toJson<String?>(guardianName),
      'guardianEmail': serializer.toJson<String?>(guardianEmail),
      'guardianPhone': serializer.toJson<String?>(guardianPhone),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  StudentsTableData copyWith({
    String? id,
    String? groupId,
    String? name,
    Value<String?> email = const Value.absent(),
    Value<String?> phone = const Value.absent(),
    Value<String?> guardianName = const Value.absent(),
    Value<String?> guardianEmail = const Value.absent(),
    Value<String?> guardianPhone = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => StudentsTableData(
    id: id ?? this.id,
    groupId: groupId ?? this.groupId,
    name: name ?? this.name,
    email: email.present ? email.value : this.email,
    phone: phone.present ? phone.value : this.phone,
    guardianName: guardianName.present ? guardianName.value : this.guardianName,
    guardianEmail: guardianEmail.present
        ? guardianEmail.value
        : this.guardianEmail,
    guardianPhone: guardianPhone.present
        ? guardianPhone.value
        : this.guardianPhone,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  StudentsTableData copyWithCompanion(StudentsTableCompanion data) {
    return StudentsTableData(
      id: data.id.present ? data.id.value : this.id,
      groupId: data.groupId.present ? data.groupId.value : this.groupId,
      name: data.name.present ? data.name.value : this.name,
      email: data.email.present ? data.email.value : this.email,
      phone: data.phone.present ? data.phone.value : this.phone,
      guardianName: data.guardianName.present
          ? data.guardianName.value
          : this.guardianName,
      guardianEmail: data.guardianEmail.present
          ? data.guardianEmail.value
          : this.guardianEmail,
      guardianPhone: data.guardianPhone.present
          ? data.guardianPhone.value
          : this.guardianPhone,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('StudentsTableData(')
          ..write('id: $id, ')
          ..write('groupId: $groupId, ')
          ..write('name: $name, ')
          ..write('email: $email, ')
          ..write('phone: $phone, ')
          ..write('guardianName: $guardianName, ')
          ..write('guardianEmail: $guardianEmail, ')
          ..write('guardianPhone: $guardianPhone, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    groupId,
    name,
    email,
    phone,
    guardianName,
    guardianEmail,
    guardianPhone,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is StudentsTableData &&
          other.id == this.id &&
          other.groupId == this.groupId &&
          other.name == this.name &&
          other.email == this.email &&
          other.phone == this.phone &&
          other.guardianName == this.guardianName &&
          other.guardianEmail == this.guardianEmail &&
          other.guardianPhone == this.guardianPhone &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class StudentsTableCompanion extends UpdateCompanion<StudentsTableData> {
  final Value<String> id;
  final Value<String> groupId;
  final Value<String> name;
  final Value<String?> email;
  final Value<String?> phone;
  final Value<String?> guardianName;
  final Value<String?> guardianEmail;
  final Value<String?> guardianPhone;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const StudentsTableCompanion({
    this.id = const Value.absent(),
    this.groupId = const Value.absent(),
    this.name = const Value.absent(),
    this.email = const Value.absent(),
    this.phone = const Value.absent(),
    this.guardianName = const Value.absent(),
    this.guardianEmail = const Value.absent(),
    this.guardianPhone = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  StudentsTableCompanion.insert({
    required String id,
    required String groupId,
    required String name,
    this.email = const Value.absent(),
    this.phone = const Value.absent(),
    this.guardianName = const Value.absent(),
    this.guardianEmail = const Value.absent(),
    this.guardianPhone = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       groupId = Value(groupId),
       name = Value(name),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<StudentsTableData> custom({
    Expression<String>? id,
    Expression<String>? groupId,
    Expression<String>? name,
    Expression<String>? email,
    Expression<String>? phone,
    Expression<String>? guardianName,
    Expression<String>? guardianEmail,
    Expression<String>? guardianPhone,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (groupId != null) 'group_id': groupId,
      if (name != null) 'name': name,
      if (email != null) 'email': email,
      if (phone != null) 'phone': phone,
      if (guardianName != null) 'guardian_name': guardianName,
      if (guardianEmail != null) 'guardian_email': guardianEmail,
      if (guardianPhone != null) 'guardian_phone': guardianPhone,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  StudentsTableCompanion copyWith({
    Value<String>? id,
    Value<String>? groupId,
    Value<String>? name,
    Value<String?>? email,
    Value<String?>? phone,
    Value<String?>? guardianName,
    Value<String?>? guardianEmail,
    Value<String?>? guardianPhone,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return StudentsTableCompanion(
      id: id ?? this.id,
      groupId: groupId ?? this.groupId,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      guardianName: guardianName ?? this.guardianName,
      guardianEmail: guardianEmail ?? this.guardianEmail,
      guardianPhone: guardianPhone ?? this.guardianPhone,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (groupId.present) {
      map['group_id'] = Variable<String>(groupId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (email.present) {
      map['email'] = Variable<String>(email.value);
    }
    if (phone.present) {
      map['phone'] = Variable<String>(phone.value);
    }
    if (guardianName.present) {
      map['guardian_name'] = Variable<String>(guardianName.value);
    }
    if (guardianEmail.present) {
      map['guardian_email'] = Variable<String>(guardianEmail.value);
    }
    if (guardianPhone.present) {
      map['guardian_phone'] = Variable<String>(guardianPhone.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('StudentsTableCompanion(')
          ..write('id: $id, ')
          ..write('groupId: $groupId, ')
          ..write('name: $name, ')
          ..write('email: $email, ')
          ..write('phone: $phone, ')
          ..write('guardianName: $guardianName, ')
          ..write('guardianEmail: $guardianEmail, ')
          ..write('guardianPhone: $guardianPhone, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ClassScheduleSlotsTableTable extends ClassScheduleSlotsTable
    with TableInfo<$ClassScheduleSlotsTableTable, ClassScheduleSlotsTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ClassScheduleSlotsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dayOfWeekMeta = const VerificationMeta(
    'dayOfWeek',
  );
  @override
  late final GeneratedColumn<int> dayOfWeek = GeneratedColumn<int>(
    'day_of_week',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _startMinutesMeta = const VerificationMeta(
    'startMinutes',
  );
  @override
  late final GeneratedColumn<int> startMinutes = GeneratedColumn<int>(
    'start_minutes',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _endMinutesMeta = const VerificationMeta(
    'endMinutes',
  );
  @override
  late final GeneratedColumn<int> endMinutes = GeneratedColumn<int>(
    'end_minutes',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _subjectMeta = const VerificationMeta(
    'subject',
  );
  @override
  late final GeneratedColumn<String> subject = GeneratedColumn<String>(
    'subject',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _professorNameMeta = const VerificationMeta(
    'professorName',
  );
  @override
  late final GeneratedColumn<String> professorName = GeneratedColumn<String>(
    'professor_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _professorEmailMeta = const VerificationMeta(
    'professorEmail',
  );
  @override
  late final GeneratedColumn<String> professorEmail = GeneratedColumn<String>(
    'professor_email',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _professorPhoneMeta = const VerificationMeta(
    'professorPhone',
  );
  @override
  late final GeneratedColumn<String> professorPhone = GeneratedColumn<String>(
    'professor_phone',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _syncStateMeta = const VerificationMeta(
    'syncState',
  );
  @override
  late final GeneratedColumn<String> syncState = GeneratedColumn<String>(
    'sync_state',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('pending'),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    dayOfWeek,
    startMinutes,
    endMinutes,
    subject,
    professorName,
    professorEmail,
    professorPhone,
    syncState,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'class_schedule_slots_table';
  @override
  VerificationContext validateIntegrity(
    Insertable<ClassScheduleSlotsTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('day_of_week')) {
      context.handle(
        _dayOfWeekMeta,
        dayOfWeek.isAcceptableOrUnknown(data['day_of_week']!, _dayOfWeekMeta),
      );
    } else if (isInserting) {
      context.missing(_dayOfWeekMeta);
    }
    if (data.containsKey('start_minutes')) {
      context.handle(
        _startMinutesMeta,
        startMinutes.isAcceptableOrUnknown(
          data['start_minutes']!,
          _startMinutesMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_startMinutesMeta);
    }
    if (data.containsKey('end_minutes')) {
      context.handle(
        _endMinutesMeta,
        endMinutes.isAcceptableOrUnknown(data['end_minutes']!, _endMinutesMeta),
      );
    } else if (isInserting) {
      context.missing(_endMinutesMeta);
    }
    if (data.containsKey('subject')) {
      context.handle(
        _subjectMeta,
        subject.isAcceptableOrUnknown(data['subject']!, _subjectMeta),
      );
    }
    if (data.containsKey('professor_name')) {
      context.handle(
        _professorNameMeta,
        professorName.isAcceptableOrUnknown(
          data['professor_name']!,
          _professorNameMeta,
        ),
      );
    }
    if (data.containsKey('professor_email')) {
      context.handle(
        _professorEmailMeta,
        professorEmail.isAcceptableOrUnknown(
          data['professor_email']!,
          _professorEmailMeta,
        ),
      );
    }
    if (data.containsKey('professor_phone')) {
      context.handle(
        _professorPhoneMeta,
        professorPhone.isAcceptableOrUnknown(
          data['professor_phone']!,
          _professorPhoneMeta,
        ),
      );
    }
    if (data.containsKey('sync_state')) {
      context.handle(
        _syncStateMeta,
        syncState.isAcceptableOrUnknown(data['sync_state']!, _syncStateMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ClassScheduleSlotsTableData map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ClassScheduleSlotsTableData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      dayOfWeek: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}day_of_week'],
      )!,
      startMinutes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}start_minutes'],
      )!,
      endMinutes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}end_minutes'],
      )!,
      subject: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}subject'],
      ),
      professorName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}professor_name'],
      ),
      professorEmail: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}professor_email'],
      ),
      professorPhone: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}professor_phone'],
      ),
      syncState: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sync_state'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $ClassScheduleSlotsTableTable createAlias(String alias) {
    return $ClassScheduleSlotsTableTable(attachedDatabase, alias);
  }
}

class ClassScheduleSlotsTableData extends DataClass
    implements Insertable<ClassScheduleSlotsTableData> {
  final String id;
  final int dayOfWeek;
  final int startMinutes;
  final int endMinutes;
  final String? subject;
  final String? professorName;
  final String? professorEmail;
  final String? professorPhone;
  final String syncState;
  final DateTime createdAt;
  final DateTime updatedAt;
  const ClassScheduleSlotsTableData({
    required this.id,
    required this.dayOfWeek,
    required this.startMinutes,
    required this.endMinutes,
    this.subject,
    this.professorName,
    this.professorEmail,
    this.professorPhone,
    required this.syncState,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['day_of_week'] = Variable<int>(dayOfWeek);
    map['start_minutes'] = Variable<int>(startMinutes);
    map['end_minutes'] = Variable<int>(endMinutes);
    if (!nullToAbsent || subject != null) {
      map['subject'] = Variable<String>(subject);
    }
    if (!nullToAbsent || professorName != null) {
      map['professor_name'] = Variable<String>(professorName);
    }
    if (!nullToAbsent || professorEmail != null) {
      map['professor_email'] = Variable<String>(professorEmail);
    }
    if (!nullToAbsent || professorPhone != null) {
      map['professor_phone'] = Variable<String>(professorPhone);
    }
    map['sync_state'] = Variable<String>(syncState);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  ClassScheduleSlotsTableCompanion toCompanion(bool nullToAbsent) {
    return ClassScheduleSlotsTableCompanion(
      id: Value(id),
      dayOfWeek: Value(dayOfWeek),
      startMinutes: Value(startMinutes),
      endMinutes: Value(endMinutes),
      subject: subject == null && nullToAbsent
          ? const Value.absent()
          : Value(subject),
      professorName: professorName == null && nullToAbsent
          ? const Value.absent()
          : Value(professorName),
      professorEmail: professorEmail == null && nullToAbsent
          ? const Value.absent()
          : Value(professorEmail),
      professorPhone: professorPhone == null && nullToAbsent
          ? const Value.absent()
          : Value(professorPhone),
      syncState: Value(syncState),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory ClassScheduleSlotsTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ClassScheduleSlotsTableData(
      id: serializer.fromJson<String>(json['id']),
      dayOfWeek: serializer.fromJson<int>(json['dayOfWeek']),
      startMinutes: serializer.fromJson<int>(json['startMinutes']),
      endMinutes: serializer.fromJson<int>(json['endMinutes']),
      subject: serializer.fromJson<String?>(json['subject']),
      professorName: serializer.fromJson<String?>(json['professorName']),
      professorEmail: serializer.fromJson<String?>(json['professorEmail']),
      professorPhone: serializer.fromJson<String?>(json['professorPhone']),
      syncState: serializer.fromJson<String>(json['syncState']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'dayOfWeek': serializer.toJson<int>(dayOfWeek),
      'startMinutes': serializer.toJson<int>(startMinutes),
      'endMinutes': serializer.toJson<int>(endMinutes),
      'subject': serializer.toJson<String?>(subject),
      'professorName': serializer.toJson<String?>(professorName),
      'professorEmail': serializer.toJson<String?>(professorEmail),
      'professorPhone': serializer.toJson<String?>(professorPhone),
      'syncState': serializer.toJson<String>(syncState),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  ClassScheduleSlotsTableData copyWith({
    String? id,
    int? dayOfWeek,
    int? startMinutes,
    int? endMinutes,
    Value<String?> subject = const Value.absent(),
    Value<String?> professorName = const Value.absent(),
    Value<String?> professorEmail = const Value.absent(),
    Value<String?> professorPhone = const Value.absent(),
    String? syncState,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => ClassScheduleSlotsTableData(
    id: id ?? this.id,
    dayOfWeek: dayOfWeek ?? this.dayOfWeek,
    startMinutes: startMinutes ?? this.startMinutes,
    endMinutes: endMinutes ?? this.endMinutes,
    subject: subject.present ? subject.value : this.subject,
    professorName: professorName.present
        ? professorName.value
        : this.professorName,
    professorEmail: professorEmail.present
        ? professorEmail.value
        : this.professorEmail,
    professorPhone: professorPhone.present
        ? professorPhone.value
        : this.professorPhone,
    syncState: syncState ?? this.syncState,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  ClassScheduleSlotsTableData copyWithCompanion(
    ClassScheduleSlotsTableCompanion data,
  ) {
    return ClassScheduleSlotsTableData(
      id: data.id.present ? data.id.value : this.id,
      dayOfWeek: data.dayOfWeek.present ? data.dayOfWeek.value : this.dayOfWeek,
      startMinutes: data.startMinutes.present
          ? data.startMinutes.value
          : this.startMinutes,
      endMinutes: data.endMinutes.present
          ? data.endMinutes.value
          : this.endMinutes,
      subject: data.subject.present ? data.subject.value : this.subject,
      professorName: data.professorName.present
          ? data.professorName.value
          : this.professorName,
      professorEmail: data.professorEmail.present
          ? data.professorEmail.value
          : this.professorEmail,
      professorPhone: data.professorPhone.present
          ? data.professorPhone.value
          : this.professorPhone,
      syncState: data.syncState.present ? data.syncState.value : this.syncState,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ClassScheduleSlotsTableData(')
          ..write('id: $id, ')
          ..write('dayOfWeek: $dayOfWeek, ')
          ..write('startMinutes: $startMinutes, ')
          ..write('endMinutes: $endMinutes, ')
          ..write('subject: $subject, ')
          ..write('professorName: $professorName, ')
          ..write('professorEmail: $professorEmail, ')
          ..write('professorPhone: $professorPhone, ')
          ..write('syncState: $syncState, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    dayOfWeek,
    startMinutes,
    endMinutes,
    subject,
    professorName,
    professorEmail,
    professorPhone,
    syncState,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ClassScheduleSlotsTableData &&
          other.id == this.id &&
          other.dayOfWeek == this.dayOfWeek &&
          other.startMinutes == this.startMinutes &&
          other.endMinutes == this.endMinutes &&
          other.subject == this.subject &&
          other.professorName == this.professorName &&
          other.professorEmail == this.professorEmail &&
          other.professorPhone == this.professorPhone &&
          other.syncState == this.syncState &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class ClassScheduleSlotsTableCompanion
    extends UpdateCompanion<ClassScheduleSlotsTableData> {
  final Value<String> id;
  final Value<int> dayOfWeek;
  final Value<int> startMinutes;
  final Value<int> endMinutes;
  final Value<String?> subject;
  final Value<String?> professorName;
  final Value<String?> professorEmail;
  final Value<String?> professorPhone;
  final Value<String> syncState;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const ClassScheduleSlotsTableCompanion({
    this.id = const Value.absent(),
    this.dayOfWeek = const Value.absent(),
    this.startMinutes = const Value.absent(),
    this.endMinutes = const Value.absent(),
    this.subject = const Value.absent(),
    this.professorName = const Value.absent(),
    this.professorEmail = const Value.absent(),
    this.professorPhone = const Value.absent(),
    this.syncState = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ClassScheduleSlotsTableCompanion.insert({
    required String id,
    required int dayOfWeek,
    required int startMinutes,
    required int endMinutes,
    this.subject = const Value.absent(),
    this.professorName = const Value.absent(),
    this.professorEmail = const Value.absent(),
    this.professorPhone = const Value.absent(),
    this.syncState = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       dayOfWeek = Value(dayOfWeek),
       startMinutes = Value(startMinutes),
       endMinutes = Value(endMinutes),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<ClassScheduleSlotsTableData> custom({
    Expression<String>? id,
    Expression<int>? dayOfWeek,
    Expression<int>? startMinutes,
    Expression<int>? endMinutes,
    Expression<String>? subject,
    Expression<String>? professorName,
    Expression<String>? professorEmail,
    Expression<String>? professorPhone,
    Expression<String>? syncState,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (dayOfWeek != null) 'day_of_week': dayOfWeek,
      if (startMinutes != null) 'start_minutes': startMinutes,
      if (endMinutes != null) 'end_minutes': endMinutes,
      if (subject != null) 'subject': subject,
      if (professorName != null) 'professor_name': professorName,
      if (professorEmail != null) 'professor_email': professorEmail,
      if (professorPhone != null) 'professor_phone': professorPhone,
      if (syncState != null) 'sync_state': syncState,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ClassScheduleSlotsTableCompanion copyWith({
    Value<String>? id,
    Value<int>? dayOfWeek,
    Value<int>? startMinutes,
    Value<int>? endMinutes,
    Value<String?>? subject,
    Value<String?>? professorName,
    Value<String?>? professorEmail,
    Value<String?>? professorPhone,
    Value<String>? syncState,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return ClassScheduleSlotsTableCompanion(
      id: id ?? this.id,
      dayOfWeek: dayOfWeek ?? this.dayOfWeek,
      startMinutes: startMinutes ?? this.startMinutes,
      endMinutes: endMinutes ?? this.endMinutes,
      subject: subject ?? this.subject,
      professorName: professorName ?? this.professorName,
      professorEmail: professorEmail ?? this.professorEmail,
      professorPhone: professorPhone ?? this.professorPhone,
      syncState: syncState ?? this.syncState,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (dayOfWeek.present) {
      map['day_of_week'] = Variable<int>(dayOfWeek.value);
    }
    if (startMinutes.present) {
      map['start_minutes'] = Variable<int>(startMinutes.value);
    }
    if (endMinutes.present) {
      map['end_minutes'] = Variable<int>(endMinutes.value);
    }
    if (subject.present) {
      map['subject'] = Variable<String>(subject.value);
    }
    if (professorName.present) {
      map['professor_name'] = Variable<String>(professorName.value);
    }
    if (professorEmail.present) {
      map['professor_email'] = Variable<String>(professorEmail.value);
    }
    if (professorPhone.present) {
      map['professor_phone'] = Variable<String>(professorPhone.value);
    }
    if (syncState.present) {
      map['sync_state'] = Variable<String>(syncState.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ClassScheduleSlotsTableCompanion(')
          ..write('id: $id, ')
          ..write('dayOfWeek: $dayOfWeek, ')
          ..write('startMinutes: $startMinutes, ')
          ..write('endMinutes: $endMinutes, ')
          ..write('subject: $subject, ')
          ..write('professorName: $professorName, ')
          ..write('professorEmail: $professorEmail, ')
          ..write('professorPhone: $professorPhone, ')
          ..write('syncState: $syncState, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $AgendaItemsTableTable agendaItemsTable = $AgendaItemsTableTable(
    this,
  );
  late final $AgendaGroupsTableTable agendaGroupsTable =
      $AgendaGroupsTableTable(this);
  late final $AttachmentsTableTable attachmentsTable = $AttachmentsTableTable(
    this,
  );
  late final $ClassGroupsTableTable classGroupsTable = $ClassGroupsTableTable(
    this,
  );
  late final $StudentsTableTable studentsTable = $StudentsTableTable(this);
  late final $ClassScheduleSlotsTableTable classScheduleSlotsTable =
      $ClassScheduleSlotsTableTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    agendaItemsTable,
    agendaGroupsTable,
    attachmentsTable,
    classGroupsTable,
    studentsTable,
    classScheduleSlotsTable,
  ];
}

typedef $$AgendaItemsTableTableCreateCompanionBuilder =
    AgendaItemsTableCompanion Function({
      required String id,
      required String title,
      Value<String?> description,
      required DateTime startAt,
      Value<DateTime?> endAt,
      Value<bool> allDay,
      Value<String?> timezone,
      Value<String?> groupId,
      Value<String> status,
      Value<String?> locationText,
      Value<String?> reminderJson,
      Value<String?> recurrenceJson,
      Value<String> source,
      Value<String> syncState,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<DateTime?> deletedAt,
      Value<int> rowid,
    });
typedef $$AgendaItemsTableTableUpdateCompanionBuilder =
    AgendaItemsTableCompanion Function({
      Value<String> id,
      Value<String> title,
      Value<String?> description,
      Value<DateTime> startAt,
      Value<DateTime?> endAt,
      Value<bool> allDay,
      Value<String?> timezone,
      Value<String?> groupId,
      Value<String> status,
      Value<String?> locationText,
      Value<String?> reminderJson,
      Value<String?> recurrenceJson,
      Value<String> source,
      Value<String> syncState,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<DateTime?> deletedAt,
      Value<int> rowid,
    });

class $$AgendaItemsTableTableFilterComposer
    extends Composer<_$AppDatabase, $AgendaItemsTableTable> {
  $$AgendaItemsTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get startAt => $composableBuilder(
    column: $table.startAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get endAt => $composableBuilder(
    column: $table.endAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get allDay => $composableBuilder(
    column: $table.allDay,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get timezone => $composableBuilder(
    column: $table.timezone,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get groupId => $composableBuilder(
    column: $table.groupId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get locationText => $composableBuilder(
    column: $table.locationText,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get reminderJson => $composableBuilder(
    column: $table.reminderJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get recurrenceJson => $composableBuilder(
    column: $table.recurrenceJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get syncState => $composableBuilder(
    column: $table.syncState,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$AgendaItemsTableTableOrderingComposer
    extends Composer<_$AppDatabase, $AgendaItemsTableTable> {
  $$AgendaItemsTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get startAt => $composableBuilder(
    column: $table.startAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get endAt => $composableBuilder(
    column: $table.endAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get allDay => $composableBuilder(
    column: $table.allDay,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get timezone => $composableBuilder(
    column: $table.timezone,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get groupId => $composableBuilder(
    column: $table.groupId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get locationText => $composableBuilder(
    column: $table.locationText,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get reminderJson => $composableBuilder(
    column: $table.reminderJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get recurrenceJson => $composableBuilder(
    column: $table.recurrenceJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get syncState => $composableBuilder(
    column: $table.syncState,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AgendaItemsTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $AgendaItemsTableTable> {
  $$AgendaItemsTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get startAt =>
      $composableBuilder(column: $table.startAt, builder: (column) => column);

  GeneratedColumn<DateTime> get endAt =>
      $composableBuilder(column: $table.endAt, builder: (column) => column);

  GeneratedColumn<bool> get allDay =>
      $composableBuilder(column: $table.allDay, builder: (column) => column);

  GeneratedColumn<String> get timezone =>
      $composableBuilder(column: $table.timezone, builder: (column) => column);

  GeneratedColumn<String> get groupId =>
      $composableBuilder(column: $table.groupId, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get locationText => $composableBuilder(
    column: $table.locationText,
    builder: (column) => column,
  );

  GeneratedColumn<String> get reminderJson => $composableBuilder(
    column: $table.reminderJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get recurrenceJson => $composableBuilder(
    column: $table.recurrenceJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get source =>
      $composableBuilder(column: $table.source, builder: (column) => column);

  GeneratedColumn<String> get syncState =>
      $composableBuilder(column: $table.syncState, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);
}

class $$AgendaItemsTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AgendaItemsTableTable,
          AgendaItemsTableData,
          $$AgendaItemsTableTableFilterComposer,
          $$AgendaItemsTableTableOrderingComposer,
          $$AgendaItemsTableTableAnnotationComposer,
          $$AgendaItemsTableTableCreateCompanionBuilder,
          $$AgendaItemsTableTableUpdateCompanionBuilder,
          (
            AgendaItemsTableData,
            BaseReferences<
              _$AppDatabase,
              $AgendaItemsTableTable,
              AgendaItemsTableData
            >,
          ),
          AgendaItemsTableData,
          PrefetchHooks Function()
        > {
  $$AgendaItemsTableTableTableManager(
    _$AppDatabase db,
    $AgendaItemsTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AgendaItemsTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AgendaItemsTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AgendaItemsTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<DateTime> startAt = const Value.absent(),
                Value<DateTime?> endAt = const Value.absent(),
                Value<bool> allDay = const Value.absent(),
                Value<String?> timezone = const Value.absent(),
                Value<String?> groupId = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String?> locationText = const Value.absent(),
                Value<String?> reminderJson = const Value.absent(),
                Value<String?> recurrenceJson = const Value.absent(),
                Value<String> source = const Value.absent(),
                Value<String> syncState = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AgendaItemsTableCompanion(
                id: id,
                title: title,
                description: description,
                startAt: startAt,
                endAt: endAt,
                allDay: allDay,
                timezone: timezone,
                groupId: groupId,
                status: status,
                locationText: locationText,
                reminderJson: reminderJson,
                recurrenceJson: recurrenceJson,
                source: source,
                syncState: syncState,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String title,
                Value<String?> description = const Value.absent(),
                required DateTime startAt,
                Value<DateTime?> endAt = const Value.absent(),
                Value<bool> allDay = const Value.absent(),
                Value<String?> timezone = const Value.absent(),
                Value<String?> groupId = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String?> locationText = const Value.absent(),
                Value<String?> reminderJson = const Value.absent(),
                Value<String?> recurrenceJson = const Value.absent(),
                Value<String> source = const Value.absent(),
                Value<String> syncState = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AgendaItemsTableCompanion.insert(
                id: id,
                title: title,
                description: description,
                startAt: startAt,
                endAt: endAt,
                allDay: allDay,
                timezone: timezone,
                groupId: groupId,
                status: status,
                locationText: locationText,
                reminderJson: reminderJson,
                recurrenceJson: recurrenceJson,
                source: source,
                syncState: syncState,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AgendaItemsTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AgendaItemsTableTable,
      AgendaItemsTableData,
      $$AgendaItemsTableTableFilterComposer,
      $$AgendaItemsTableTableOrderingComposer,
      $$AgendaItemsTableTableAnnotationComposer,
      $$AgendaItemsTableTableCreateCompanionBuilder,
      $$AgendaItemsTableTableUpdateCompanionBuilder,
      (
        AgendaItemsTableData,
        BaseReferences<
          _$AppDatabase,
          $AgendaItemsTableTable,
          AgendaItemsTableData
        >,
      ),
      AgendaItemsTableData,
      PrefetchHooks Function()
    >;
typedef $$AgendaGroupsTableTableCreateCompanionBuilder =
    AgendaGroupsTableCompanion Function({
      required String id,
      required String name,
      Value<String?> colorHex,
      Value<int?> iconCode,
      Value<String> syncState,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<DateTime?> deletedAt,
      Value<int> rowid,
    });
typedef $$AgendaGroupsTableTableUpdateCompanionBuilder =
    AgendaGroupsTableCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<String?> colorHex,
      Value<int?> iconCode,
      Value<String> syncState,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<DateTime?> deletedAt,
      Value<int> rowid,
    });

class $$AgendaGroupsTableTableFilterComposer
    extends Composer<_$AppDatabase, $AgendaGroupsTableTable> {
  $$AgendaGroupsTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get colorHex => $composableBuilder(
    column: $table.colorHex,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get iconCode => $composableBuilder(
    column: $table.iconCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get syncState => $composableBuilder(
    column: $table.syncState,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$AgendaGroupsTableTableOrderingComposer
    extends Composer<_$AppDatabase, $AgendaGroupsTableTable> {
  $$AgendaGroupsTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get colorHex => $composableBuilder(
    column: $table.colorHex,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get iconCode => $composableBuilder(
    column: $table.iconCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get syncState => $composableBuilder(
    column: $table.syncState,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AgendaGroupsTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $AgendaGroupsTableTable> {
  $$AgendaGroupsTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get colorHex =>
      $composableBuilder(column: $table.colorHex, builder: (column) => column);

  GeneratedColumn<int> get iconCode =>
      $composableBuilder(column: $table.iconCode, builder: (column) => column);

  GeneratedColumn<String> get syncState =>
      $composableBuilder(column: $table.syncState, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);
}

class $$AgendaGroupsTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AgendaGroupsTableTable,
          AgendaGroupsTableData,
          $$AgendaGroupsTableTableFilterComposer,
          $$AgendaGroupsTableTableOrderingComposer,
          $$AgendaGroupsTableTableAnnotationComposer,
          $$AgendaGroupsTableTableCreateCompanionBuilder,
          $$AgendaGroupsTableTableUpdateCompanionBuilder,
          (
            AgendaGroupsTableData,
            BaseReferences<
              _$AppDatabase,
              $AgendaGroupsTableTable,
              AgendaGroupsTableData
            >,
          ),
          AgendaGroupsTableData,
          PrefetchHooks Function()
        > {
  $$AgendaGroupsTableTableTableManager(
    _$AppDatabase db,
    $AgendaGroupsTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AgendaGroupsTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AgendaGroupsTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AgendaGroupsTableTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> colorHex = const Value.absent(),
                Value<int?> iconCode = const Value.absent(),
                Value<String> syncState = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AgendaGroupsTableCompanion(
                id: id,
                name: name,
                colorHex: colorHex,
                iconCode: iconCode,
                syncState: syncState,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                Value<String?> colorHex = const Value.absent(),
                Value<int?> iconCode = const Value.absent(),
                Value<String> syncState = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AgendaGroupsTableCompanion.insert(
                id: id,
                name: name,
                colorHex: colorHex,
                iconCode: iconCode,
                syncState: syncState,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AgendaGroupsTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AgendaGroupsTableTable,
      AgendaGroupsTableData,
      $$AgendaGroupsTableTableFilterComposer,
      $$AgendaGroupsTableTableOrderingComposer,
      $$AgendaGroupsTableTableAnnotationComposer,
      $$AgendaGroupsTableTableCreateCompanionBuilder,
      $$AgendaGroupsTableTableUpdateCompanionBuilder,
      (
        AgendaGroupsTableData,
        BaseReferences<
          _$AppDatabase,
          $AgendaGroupsTableTable,
          AgendaGroupsTableData
        >,
      ),
      AgendaGroupsTableData,
      PrefetchHooks Function()
    >;
typedef $$AttachmentsTableTableCreateCompanionBuilder =
    AttachmentsTableCompanion Function({
      required String id,
      required String itemId,
      required String type,
      Value<String?> localPath,
      Value<String?> remoteUrl,
      Value<String?> thumbPath,
      Value<String?> title,
      Value<String?> mimeType,
      Value<int?> sizeBytes,
      required DateTime createdAt,
      Value<int> rowid,
    });
typedef $$AttachmentsTableTableUpdateCompanionBuilder =
    AttachmentsTableCompanion Function({
      Value<String> id,
      Value<String> itemId,
      Value<String> type,
      Value<String?> localPath,
      Value<String?> remoteUrl,
      Value<String?> thumbPath,
      Value<String?> title,
      Value<String?> mimeType,
      Value<int?> sizeBytes,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });

class $$AttachmentsTableTableFilterComposer
    extends Composer<_$AppDatabase, $AttachmentsTableTable> {
  $$AttachmentsTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get itemId => $composableBuilder(
    column: $table.itemId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get localPath => $composableBuilder(
    column: $table.localPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get remoteUrl => $composableBuilder(
    column: $table.remoteUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get thumbPath => $composableBuilder(
    column: $table.thumbPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get mimeType => $composableBuilder(
    column: $table.mimeType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sizeBytes => $composableBuilder(
    column: $table.sizeBytes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$AttachmentsTableTableOrderingComposer
    extends Composer<_$AppDatabase, $AttachmentsTableTable> {
  $$AttachmentsTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get itemId => $composableBuilder(
    column: $table.itemId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get localPath => $composableBuilder(
    column: $table.localPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get remoteUrl => $composableBuilder(
    column: $table.remoteUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get thumbPath => $composableBuilder(
    column: $table.thumbPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get mimeType => $composableBuilder(
    column: $table.mimeType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sizeBytes => $composableBuilder(
    column: $table.sizeBytes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AttachmentsTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $AttachmentsTableTable> {
  $$AttachmentsTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get itemId =>
      $composableBuilder(column: $table.itemId, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<String> get localPath =>
      $composableBuilder(column: $table.localPath, builder: (column) => column);

  GeneratedColumn<String> get remoteUrl =>
      $composableBuilder(column: $table.remoteUrl, builder: (column) => column);

  GeneratedColumn<String> get thumbPath =>
      $composableBuilder(column: $table.thumbPath, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get mimeType =>
      $composableBuilder(column: $table.mimeType, builder: (column) => column);

  GeneratedColumn<int> get sizeBytes =>
      $composableBuilder(column: $table.sizeBytes, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$AttachmentsTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AttachmentsTableTable,
          AttachmentsTableData,
          $$AttachmentsTableTableFilterComposer,
          $$AttachmentsTableTableOrderingComposer,
          $$AttachmentsTableTableAnnotationComposer,
          $$AttachmentsTableTableCreateCompanionBuilder,
          $$AttachmentsTableTableUpdateCompanionBuilder,
          (
            AttachmentsTableData,
            BaseReferences<
              _$AppDatabase,
              $AttachmentsTableTable,
              AttachmentsTableData
            >,
          ),
          AttachmentsTableData,
          PrefetchHooks Function()
        > {
  $$AttachmentsTableTableTableManager(
    _$AppDatabase db,
    $AttachmentsTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AttachmentsTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AttachmentsTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AttachmentsTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> itemId = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<String?> localPath = const Value.absent(),
                Value<String?> remoteUrl = const Value.absent(),
                Value<String?> thumbPath = const Value.absent(),
                Value<String?> title = const Value.absent(),
                Value<String?> mimeType = const Value.absent(),
                Value<int?> sizeBytes = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AttachmentsTableCompanion(
                id: id,
                itemId: itemId,
                type: type,
                localPath: localPath,
                remoteUrl: remoteUrl,
                thumbPath: thumbPath,
                title: title,
                mimeType: mimeType,
                sizeBytes: sizeBytes,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String itemId,
                required String type,
                Value<String?> localPath = const Value.absent(),
                Value<String?> remoteUrl = const Value.absent(),
                Value<String?> thumbPath = const Value.absent(),
                Value<String?> title = const Value.absent(),
                Value<String?> mimeType = const Value.absent(),
                Value<int?> sizeBytes = const Value.absent(),
                required DateTime createdAt,
                Value<int> rowid = const Value.absent(),
              }) => AttachmentsTableCompanion.insert(
                id: id,
                itemId: itemId,
                type: type,
                localPath: localPath,
                remoteUrl: remoteUrl,
                thumbPath: thumbPath,
                title: title,
                mimeType: mimeType,
                sizeBytes: sizeBytes,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AttachmentsTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AttachmentsTableTable,
      AttachmentsTableData,
      $$AttachmentsTableTableFilterComposer,
      $$AttachmentsTableTableOrderingComposer,
      $$AttachmentsTableTableAnnotationComposer,
      $$AttachmentsTableTableCreateCompanionBuilder,
      $$AttachmentsTableTableUpdateCompanionBuilder,
      (
        AttachmentsTableData,
        BaseReferences<
          _$AppDatabase,
          $AttachmentsTableTable,
          AttachmentsTableData
        >,
      ),
      AttachmentsTableData,
      PrefetchHooks Function()
    >;
typedef $$ClassGroupsTableTableCreateCompanionBuilder =
    ClassGroupsTableCompanion Function({
      required String id,
      required String name,
      Value<String?> description,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$ClassGroupsTableTableUpdateCompanionBuilder =
    ClassGroupsTableCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<String?> description,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$ClassGroupsTableTableFilterComposer
    extends Composer<_$AppDatabase, $ClassGroupsTableTable> {
  $$ClassGroupsTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ClassGroupsTableTableOrderingComposer
    extends Composer<_$AppDatabase, $ClassGroupsTableTable> {
  $$ClassGroupsTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ClassGroupsTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $ClassGroupsTableTable> {
  $$ClassGroupsTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$ClassGroupsTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ClassGroupsTableTable,
          ClassGroupsTableData,
          $$ClassGroupsTableTableFilterComposer,
          $$ClassGroupsTableTableOrderingComposer,
          $$ClassGroupsTableTableAnnotationComposer,
          $$ClassGroupsTableTableCreateCompanionBuilder,
          $$ClassGroupsTableTableUpdateCompanionBuilder,
          (
            ClassGroupsTableData,
            BaseReferences<
              _$AppDatabase,
              $ClassGroupsTableTable,
              ClassGroupsTableData
            >,
          ),
          ClassGroupsTableData,
          PrefetchHooks Function()
        > {
  $$ClassGroupsTableTableTableManager(
    _$AppDatabase db,
    $ClassGroupsTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ClassGroupsTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ClassGroupsTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ClassGroupsTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ClassGroupsTableCompanion(
                id: id,
                name: name,
                description: description,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                Value<String?> description = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => ClassGroupsTableCompanion.insert(
                id: id,
                name: name,
                description: description,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ClassGroupsTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ClassGroupsTableTable,
      ClassGroupsTableData,
      $$ClassGroupsTableTableFilterComposer,
      $$ClassGroupsTableTableOrderingComposer,
      $$ClassGroupsTableTableAnnotationComposer,
      $$ClassGroupsTableTableCreateCompanionBuilder,
      $$ClassGroupsTableTableUpdateCompanionBuilder,
      (
        ClassGroupsTableData,
        BaseReferences<
          _$AppDatabase,
          $ClassGroupsTableTable,
          ClassGroupsTableData
        >,
      ),
      ClassGroupsTableData,
      PrefetchHooks Function()
    >;
typedef $$StudentsTableTableCreateCompanionBuilder =
    StudentsTableCompanion Function({
      required String id,
      required String groupId,
      required String name,
      Value<String?> email,
      Value<String?> phone,
      Value<String?> guardianName,
      Value<String?> guardianEmail,
      Value<String?> guardianPhone,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$StudentsTableTableUpdateCompanionBuilder =
    StudentsTableCompanion Function({
      Value<String> id,
      Value<String> groupId,
      Value<String> name,
      Value<String?> email,
      Value<String?> phone,
      Value<String?> guardianName,
      Value<String?> guardianEmail,
      Value<String?> guardianPhone,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$StudentsTableTableFilterComposer
    extends Composer<_$AppDatabase, $StudentsTableTable> {
  $$StudentsTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get groupId => $composableBuilder(
    column: $table.groupId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get email => $composableBuilder(
    column: $table.email,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get phone => $composableBuilder(
    column: $table.phone,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get guardianName => $composableBuilder(
    column: $table.guardianName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get guardianEmail => $composableBuilder(
    column: $table.guardianEmail,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get guardianPhone => $composableBuilder(
    column: $table.guardianPhone,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$StudentsTableTableOrderingComposer
    extends Composer<_$AppDatabase, $StudentsTableTable> {
  $$StudentsTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get groupId => $composableBuilder(
    column: $table.groupId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get email => $composableBuilder(
    column: $table.email,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get phone => $composableBuilder(
    column: $table.phone,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get guardianName => $composableBuilder(
    column: $table.guardianName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get guardianEmail => $composableBuilder(
    column: $table.guardianEmail,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get guardianPhone => $composableBuilder(
    column: $table.guardianPhone,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$StudentsTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $StudentsTableTable> {
  $$StudentsTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get groupId =>
      $composableBuilder(column: $table.groupId, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get email =>
      $composableBuilder(column: $table.email, builder: (column) => column);

  GeneratedColumn<String> get phone =>
      $composableBuilder(column: $table.phone, builder: (column) => column);

  GeneratedColumn<String> get guardianName => $composableBuilder(
    column: $table.guardianName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get guardianEmail => $composableBuilder(
    column: $table.guardianEmail,
    builder: (column) => column,
  );

  GeneratedColumn<String> get guardianPhone => $composableBuilder(
    column: $table.guardianPhone,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$StudentsTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $StudentsTableTable,
          StudentsTableData,
          $$StudentsTableTableFilterComposer,
          $$StudentsTableTableOrderingComposer,
          $$StudentsTableTableAnnotationComposer,
          $$StudentsTableTableCreateCompanionBuilder,
          $$StudentsTableTableUpdateCompanionBuilder,
          (
            StudentsTableData,
            BaseReferences<
              _$AppDatabase,
              $StudentsTableTable,
              StudentsTableData
            >,
          ),
          StudentsTableData,
          PrefetchHooks Function()
        > {
  $$StudentsTableTableTableManager(_$AppDatabase db, $StudentsTableTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$StudentsTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$StudentsTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$StudentsTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> groupId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> email = const Value.absent(),
                Value<String?> phone = const Value.absent(),
                Value<String?> guardianName = const Value.absent(),
                Value<String?> guardianEmail = const Value.absent(),
                Value<String?> guardianPhone = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => StudentsTableCompanion(
                id: id,
                groupId: groupId,
                name: name,
                email: email,
                phone: phone,
                guardianName: guardianName,
                guardianEmail: guardianEmail,
                guardianPhone: guardianPhone,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String groupId,
                required String name,
                Value<String?> email = const Value.absent(),
                Value<String?> phone = const Value.absent(),
                Value<String?> guardianName = const Value.absent(),
                Value<String?> guardianEmail = const Value.absent(),
                Value<String?> guardianPhone = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => StudentsTableCompanion.insert(
                id: id,
                groupId: groupId,
                name: name,
                email: email,
                phone: phone,
                guardianName: guardianName,
                guardianEmail: guardianEmail,
                guardianPhone: guardianPhone,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$StudentsTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $StudentsTableTable,
      StudentsTableData,
      $$StudentsTableTableFilterComposer,
      $$StudentsTableTableOrderingComposer,
      $$StudentsTableTableAnnotationComposer,
      $$StudentsTableTableCreateCompanionBuilder,
      $$StudentsTableTableUpdateCompanionBuilder,
      (
        StudentsTableData,
        BaseReferences<_$AppDatabase, $StudentsTableTable, StudentsTableData>,
      ),
      StudentsTableData,
      PrefetchHooks Function()
    >;
typedef $$ClassScheduleSlotsTableTableCreateCompanionBuilder =
    ClassScheduleSlotsTableCompanion Function({
      required String id,
      required int dayOfWeek,
      required int startMinutes,
      required int endMinutes,
      Value<String?> subject,
      Value<String?> professorName,
      Value<String?> professorEmail,
      Value<String?> professorPhone,
      Value<String> syncState,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$ClassScheduleSlotsTableTableUpdateCompanionBuilder =
    ClassScheduleSlotsTableCompanion Function({
      Value<String> id,
      Value<int> dayOfWeek,
      Value<int> startMinutes,
      Value<int> endMinutes,
      Value<String?> subject,
      Value<String?> professorName,
      Value<String?> professorEmail,
      Value<String?> professorPhone,
      Value<String> syncState,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$ClassScheduleSlotsTableTableFilterComposer
    extends Composer<_$AppDatabase, $ClassScheduleSlotsTableTable> {
  $$ClassScheduleSlotsTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get dayOfWeek => $composableBuilder(
    column: $table.dayOfWeek,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get startMinutes => $composableBuilder(
    column: $table.startMinutes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get endMinutes => $composableBuilder(
    column: $table.endMinutes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get subject => $composableBuilder(
    column: $table.subject,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get professorName => $composableBuilder(
    column: $table.professorName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get professorEmail => $composableBuilder(
    column: $table.professorEmail,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get professorPhone => $composableBuilder(
    column: $table.professorPhone,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get syncState => $composableBuilder(
    column: $table.syncState,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ClassScheduleSlotsTableTableOrderingComposer
    extends Composer<_$AppDatabase, $ClassScheduleSlotsTableTable> {
  $$ClassScheduleSlotsTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get dayOfWeek => $composableBuilder(
    column: $table.dayOfWeek,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get startMinutes => $composableBuilder(
    column: $table.startMinutes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get endMinutes => $composableBuilder(
    column: $table.endMinutes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get subject => $composableBuilder(
    column: $table.subject,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get professorName => $composableBuilder(
    column: $table.professorName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get professorEmail => $composableBuilder(
    column: $table.professorEmail,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get professorPhone => $composableBuilder(
    column: $table.professorPhone,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get syncState => $composableBuilder(
    column: $table.syncState,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ClassScheduleSlotsTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $ClassScheduleSlotsTableTable> {
  $$ClassScheduleSlotsTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get dayOfWeek =>
      $composableBuilder(column: $table.dayOfWeek, builder: (column) => column);

  GeneratedColumn<int> get startMinutes => $composableBuilder(
    column: $table.startMinutes,
    builder: (column) => column,
  );

  GeneratedColumn<int> get endMinutes => $composableBuilder(
    column: $table.endMinutes,
    builder: (column) => column,
  );

  GeneratedColumn<String> get subject =>
      $composableBuilder(column: $table.subject, builder: (column) => column);

  GeneratedColumn<String> get professorName => $composableBuilder(
    column: $table.professorName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get professorEmail => $composableBuilder(
    column: $table.professorEmail,
    builder: (column) => column,
  );

  GeneratedColumn<String> get professorPhone => $composableBuilder(
    column: $table.professorPhone,
    builder: (column) => column,
  );

  GeneratedColumn<String> get syncState =>
      $composableBuilder(column: $table.syncState, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$ClassScheduleSlotsTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ClassScheduleSlotsTableTable,
          ClassScheduleSlotsTableData,
          $$ClassScheduleSlotsTableTableFilterComposer,
          $$ClassScheduleSlotsTableTableOrderingComposer,
          $$ClassScheduleSlotsTableTableAnnotationComposer,
          $$ClassScheduleSlotsTableTableCreateCompanionBuilder,
          $$ClassScheduleSlotsTableTableUpdateCompanionBuilder,
          (
            ClassScheduleSlotsTableData,
            BaseReferences<
              _$AppDatabase,
              $ClassScheduleSlotsTableTable,
              ClassScheduleSlotsTableData
            >,
          ),
          ClassScheduleSlotsTableData,
          PrefetchHooks Function()
        > {
  $$ClassScheduleSlotsTableTableTableManager(
    _$AppDatabase db,
    $ClassScheduleSlotsTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ClassScheduleSlotsTableTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$ClassScheduleSlotsTableTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$ClassScheduleSlotsTableTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<int> dayOfWeek = const Value.absent(),
                Value<int> startMinutes = const Value.absent(),
                Value<int> endMinutes = const Value.absent(),
                Value<String?> subject = const Value.absent(),
                Value<String?> professorName = const Value.absent(),
                Value<String?> professorEmail = const Value.absent(),
                Value<String?> professorPhone = const Value.absent(),
                Value<String> syncState = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ClassScheduleSlotsTableCompanion(
                id: id,
                dayOfWeek: dayOfWeek,
                startMinutes: startMinutes,
                endMinutes: endMinutes,
                subject: subject,
                professorName: professorName,
                professorEmail: professorEmail,
                professorPhone: professorPhone,
                syncState: syncState,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required int dayOfWeek,
                required int startMinutes,
                required int endMinutes,
                Value<String?> subject = const Value.absent(),
                Value<String?> professorName = const Value.absent(),
                Value<String?> professorEmail = const Value.absent(),
                Value<String?> professorPhone = const Value.absent(),
                Value<String> syncState = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => ClassScheduleSlotsTableCompanion.insert(
                id: id,
                dayOfWeek: dayOfWeek,
                startMinutes: startMinutes,
                endMinutes: endMinutes,
                subject: subject,
                professorName: professorName,
                professorEmail: professorEmail,
                professorPhone: professorPhone,
                syncState: syncState,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ClassScheduleSlotsTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ClassScheduleSlotsTableTable,
      ClassScheduleSlotsTableData,
      $$ClassScheduleSlotsTableTableFilterComposer,
      $$ClassScheduleSlotsTableTableOrderingComposer,
      $$ClassScheduleSlotsTableTableAnnotationComposer,
      $$ClassScheduleSlotsTableTableCreateCompanionBuilder,
      $$ClassScheduleSlotsTableTableUpdateCompanionBuilder,
      (
        ClassScheduleSlotsTableData,
        BaseReferences<
          _$AppDatabase,
          $ClassScheduleSlotsTableTable,
          ClassScheduleSlotsTableData
        >,
      ),
      ClassScheduleSlotsTableData,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$AgendaItemsTableTableTableManager get agendaItemsTable =>
      $$AgendaItemsTableTableTableManager(_db, _db.agendaItemsTable);
  $$AgendaGroupsTableTableTableManager get agendaGroupsTable =>
      $$AgendaGroupsTableTableTableManager(_db, _db.agendaGroupsTable);
  $$AttachmentsTableTableTableManager get attachmentsTable =>
      $$AttachmentsTableTableTableManager(_db, _db.attachmentsTable);
  $$ClassGroupsTableTableTableManager get classGroupsTable =>
      $$ClassGroupsTableTableTableManager(_db, _db.classGroupsTable);
  $$StudentsTableTableTableManager get studentsTable =>
      $$StudentsTableTableTableManager(_db, _db.studentsTable);
  $$ClassScheduleSlotsTableTableTableManager get classScheduleSlotsTable =>
      $$ClassScheduleSlotsTableTableTableManager(
        _db,
        _db.classScheduleSlotsTable,
      );
}

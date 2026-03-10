import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:path_provider/path_provider.dart';

import '../../core/constants/app_constants.dart';
import '../../core/result/result.dart';
import '../../data/local/app_database.dart';
import '../../domain/entities/agenda_item.dart';
import '../../domain/entities/agenda_transfer_bundle.dart';
import '../../domain/entities/attachment_ref.dart';
import '../../domain/entities/reminder_config.dart';
import '../../domain/repositories/i_agenda_repository.dart';
import '../../domain/repositories/i_agenda_transfer_service.dart';
import '../../domain/repositories/i_groups_repository.dart';
import '../../domain/repositories/i_notification_service.dart';
import '../../domain/value_objects/search_filters.dart';

class AgendaTransferServiceImpl implements IAgendaTransferService {
  const AgendaTransferServiceImpl({
    required AppDatabase database,
    required IAgendaRepository agendaRepository,
    required IGroupsRepository groupsRepository,
    required INotificationService notificationService,
  })  : _database = database,
        _agendaRepository = agendaRepository,
        _groupsRepository = groupsRepository,
        _notificationService = notificationService;

  final AppDatabase _database;
  final IAgendaRepository _agendaRepository;
  final IGroupsRepository _groupsRepository;
  final INotificationService _notificationService;

  @override
  Future<Result<AgendaTransferExportData>> exportToFile() async {
    try {
      final groupsResult = await _groupsRepository.getGroups();
      if (!groupsResult.isSuccess || groupsResult.data == null) {
        return Result.failure(
          groupsResult.errorMessage ?? 'Falha ao carregar grupos para exportar.',
        );
      }

      final allItemsResult = await _agendaRepository.searchItems(
        '',
        const SearchFilters(),
      );
      if (!allItemsResult.isSuccess || allItemsResult.data == null) {
        return Result.failure(
          allItemsResult.errorMessage ?? 'Falha ao carregar eventos para exportar.',
        );
      }

      final bundle = AgendaTransferBundle(
        schemaVersion: AgendaTransferBundle.currentSchemaVersion,
        exportedAt: DateTime.now(),
        appName: AppConstants.appName,
        groups: groupsResult.data!,
        items: allItemsResult.data!,
        classScheduleSlots: await _readClassScheduleSlots(),
      );

      final docDir = await getApplicationDocumentsDirectory();
      final filename =
          'smart_agenda_export_${DateTime.now().millisecondsSinceEpoch}.json';
      final file = File('${docDir.path}/$filename');
      await file.writeAsString(
        const JsonEncoder.withIndent('  ').convert(bundle.toJson()),
      );

      return Result.success(
        AgendaTransferExportData(
          filePath: file.path,
          groupCount: bundle.groups.length,
          itemCount: bundle.items.length,
          classSlotCount: bundle.classScheduleSlots.length,
        ),
      );
    } catch (e) {
      return Result.failure('Falha ao exportar agenda: $e');
    }
  }

  @override
  Future<Result<AgendaTransferImportReport>> importFromFile(
    String filePath,
  ) async {
    try {
      final file = File(filePath);
      if (!file.existsSync()) {
        return Result.failure('Arquivo selecionado nao existe.');
      }

      final raw = await file.readAsString();
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) {
        return Result.failure('Arquivo invalido para importacao.');
      }

      final bundle = AgendaTransferBundle.fromJson(decoded);
      final validationError = bundle.validate();
      if (validationError != null) {
        return Result.failure(validationError);
      }

      var createdGroups = 0;
      var updatedGroups = 0;
      var skippedGroups = 0;
      var createdItems = 0;
      var updatedItems = 0;
      var skippedItems = 0;
      var reScheduledReminders = 0;
      var createdClassSlots = 0;
      var updatedClassSlots = 0;
      var skippedClassSlots = 0;

      final existingGroupsResult = await _groupsRepository.getGroups();
      if (!existingGroupsResult.isSuccess || existingGroupsResult.data == null) {
        return Result.failure(
          existingGroupsResult.errorMessage ??
              'Falha ao carregar grupos para importar.',
        );
      }

      final groupsById = {
        for (final group in existingGroupsResult.data!) group.id: group,
      };

      for (final incoming in bundle.groups) {
        if (incoming.id.trim().isEmpty || incoming.name.trim().isEmpty) {
          skippedGroups++;
          continue;
        }

        final existing = groupsById[incoming.id];
        if (existing == null) {
          final createResult = await _groupsRepository.createGroup(incoming);
          if (createResult.isSuccess) {
            createdGroups++;
            groupsById[incoming.id] = incoming;
          } else {
            skippedGroups++;
          }
          continue;
        }

        if (incoming.updatedAt.isAfter(existing.updatedAt)) {
          final updateResult = await _groupsRepository.updateGroup(incoming);
          if (updateResult.isSuccess) {
            updatedGroups++;
            groupsById[incoming.id] = incoming;
          } else {
            skippedGroups++;
          }
        } else {
          skippedGroups++;
        }
      }

      var reminderSeed =
          DateTime.now().millisecondsSinceEpoch.remainder(1000000);
      for (final incoming in bundle.items) {
        if (incoming.id.trim().isEmpty || incoming.title.trim().isEmpty) {
          skippedItems++;
          continue;
        }

        final normalized = _normalizeItemForImport(
          incoming,
          validGroupIds: groupsById.keys.toSet(),
          nextNotificationId: ++reminderSeed,
        );

        final existingResult = await _agendaRepository.getItemById(normalized.id);
        if (!existingResult.isSuccess) {
          skippedItems++;
          continue;
        }

        final existing = existingResult.data;
        if (existing == null) {
          final createResult = await _agendaRepository.createItem(normalized);
          if (!createResult.isSuccess) {
            skippedItems++;
            continue;
          }
          createdItems++;
          final scheduleResult = await _notificationService.scheduleForItem(
            normalized,
          );
          if (scheduleResult.isSuccess && normalized.reminder?.enabled == true) {
            reScheduledReminders++;
          }
          continue;
        }

        if (normalized.updatedAt.isAfter(existing.updatedAt)) {
          await _notificationService.cancelForItem(existing);
          final updateResult = await _agendaRepository.updateItem(normalized);
          if (!updateResult.isSuccess) {
            skippedItems++;
            continue;
          }
          updatedItems++;
          final scheduleResult = await _notificationService.scheduleForItem(
            normalized,
          );
          if (scheduleResult.isSuccess && normalized.reminder?.enabled == true) {
            reScheduledReminders++;
          }
        } else {
          skippedItems++;
        }
      }

      final existingClassSlots = await (_database
            .select(_database.classScheduleSlotsTable)
          ..orderBy([(t) => OrderingTerm(expression: t.updatedAt)]))
          .get();
      final classSlotsById = {
        for (final slot in existingClassSlots) slot.id: slot,
      };
      for (final incoming in bundle.classScheduleSlots) {
        if (incoming.id.trim().isEmpty) {
          skippedClassSlots++;
          continue;
        }
        final existing = classSlotsById[incoming.id];
        if (existing == null) {
          await _database.into(_database.classScheduleSlotsTable).insert(
                ClassScheduleSlotsTableCompanion.insert(
                  id: incoming.id,
                  dayOfWeek: incoming.dayOfWeek,
                  startMinutes: incoming.startMinutes,
                  endMinutes: incoming.endMinutes,
                  createdAt: incoming.createdAt,
                  updatedAt: incoming.updatedAt,
                  subject: Value(incoming.subject),
                  professorName: Value(incoming.professorName),
                  professorEmail: Value(incoming.professorEmail),
                  professorPhone: Value(incoming.professorPhone),
                ),
              );
          createdClassSlots++;
          continue;
        }
        if (incoming.updatedAt.isAfter(existing.updatedAt)) {
          await (_database.update(_database.classScheduleSlotsTable)
                ..where((t) => t.id.equals(incoming.id)))
              .write(
            ClassScheduleSlotsTableCompanion(
              dayOfWeek: Value(incoming.dayOfWeek),
              startMinutes: Value(incoming.startMinutes),
              endMinutes: Value(incoming.endMinutes),
              subject: Value(incoming.subject),
              professorName: Value(incoming.professorName),
              professorEmail: Value(incoming.professorEmail),
              professorPhone: Value(incoming.professorPhone),
              updatedAt: Value(incoming.updatedAt),
            ),
          );
          updatedClassSlots++;
        } else {
          skippedClassSlots++;
        }
      }

      return Result.success(
        AgendaTransferImportReport(
          createdGroups: createdGroups,
          updatedGroups: updatedGroups,
          skippedGroups: skippedGroups,
          createdItems: createdItems,
          updatedItems: updatedItems,
          skippedItems: skippedItems,
          reScheduledReminders: reScheduledReminders,
          createdClassSlots: createdClassSlots,
          updatedClassSlots: updatedClassSlots,
          skippedClassSlots: skippedClassSlots,
        ),
      );
    } catch (e) {
      return Result.failure('Falha ao importar agenda: $e');
    }
  }

  AgendaItem _normalizeItemForImport(
    AgendaItem source, {
    required Set<String> validGroupIds,
    required int nextNotificationId,
  }) {
    final normalizedAttachments = source.attachments
        .map(
          (a) => AttachmentRef(
            id: a.id,
            itemId: source.id,
            type: a.type,
            localPath: null,
            remoteUrl: a.remoteUrl,
            thumbPath: null,
            title: a.title,
            mimeType: a.mimeType,
            sizeBytes: a.sizeBytes,
            createdAt: a.createdAt,
          ),
        )
        .toList();

    final normalizedReminder = _normalizeReminder(
      source.reminder,
      nextNotificationId,
    );

    return source.copyWith(
      groupId: source.groupId != null && !validGroupIds.contains(source.groupId)
          ? null
          : source.groupId,
      reminder: normalizedReminder,
      attachments: normalizedAttachments,
    );
  }

  ReminderConfig? _normalizeReminder(ReminderConfig? reminder, int notificationId) {
    if (reminder == null) return null;
    if (!reminder.enabled) {
      return reminder.copyWith(
        enabled: false,
        minutesBefore: null,
        notificationId: notificationId,
      );
    }
    return reminder.copyWith(
      enabled: true,
      minutesBefore: reminder.minutesBefore ?? 10,
      notificationId: notificationId,
    );
  }

  Future<List<ClassScheduleTransferSlot>> _readClassScheduleSlots() async {
    final slots = await (_database.select(_database.classScheduleSlotsTable)
          ..orderBy([
            (t) => OrderingTerm(expression: t.dayOfWeek),
            (t) => OrderingTerm(expression: t.startMinutes),
          ]))
        .get();
    return slots
        .map(
          (slot) => ClassScheduleTransferSlot(
            id: slot.id,
            dayOfWeek: slot.dayOfWeek,
            startMinutes: slot.startMinutes,
            endMinutes: slot.endMinutes,
            subject: slot.subject,
            professorName: slot.professorName,
            professorEmail: slot.professorEmail,
            professorPhone: slot.professorPhone,
            createdAt: slot.createdAt,
            updatedAt: slot.updatedAt,
          ),
        )
        .toList();
  }
}

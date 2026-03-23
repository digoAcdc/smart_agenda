import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/attachment_ref.dart';
import '../../domain/repositories/i_file_storage_service.dart';
import '../../domain/repositories/i_local_to_cloud_migration_service.dart';
import '../datasources/agenda_local_datasource.dart';
import '../datasources/agenda_supabase_datasource.dart';
import '../datasources/class_schedule_local_datasource.dart';
import '../datasources/groups_local_datasource.dart';
import '../datasources/groups_supabase_datasource.dart';
import '../models/mappers.dart';

/// Migra dados locais para Supabase quando um usuario autenticado entra no app.
class LocalToCloudMigrationServiceImpl implements ILocalToCloudMigrationService {
  LocalToCloudMigrationServiceImpl(
    this._localAgenda,
    this._localGroups,
    this._localSchedule,
    this._supabaseAgenda,
    this._supabaseGroups,
    this._fileStorage,
    this._client,
  );

  final AgendaLocalDataSource _localAgenda;
  final GroupsLocalDataSource _localGroups;
  final ClassScheduleLocalDataSource _localSchedule;
  final AgendaSupabaseDataSource _supabaseAgenda;
  final GroupsSupabaseDataSource _supabaseGroups;
  final IFileStorageService _fileStorage;
  final SupabaseClient _client;

  static const _keyPrefix = 'local_migrated_';

  bool _isHttpUrl(String? value) {
    if (value == null) return false;
    return value.startsWith('http://') || value.startsWith('https://');
  }

  @override
  Future<bool> migrateIfNeeded() async {
    final user = _client.auth.currentUser;
    if (user == null) return false;

    final prefs = await SharedPreferences.getInstance();
    final key = '$_keyPrefix${user.id}';
    if (prefs.getBool(key) == true) return false;

    debugPrint('[LocalToCloudMigration] Iniciando migracao para ${user.email}');
    try {
      await _migrateGroups();
      await _migrateAgendaItems();
      await _migrateClassSchedule();
      await prefs.setBool(key, true);
      debugPrint('[LocalToCloudMigration] Migracao concluida');
      return true;
    } catch (e) {
      debugPrint('[LocalToCloudMigration] Erro: $e');
      rethrow;
    }
  }

  Future<void> _migrateGroups() async {
    final rows = await _localGroups.getAll();
    if (rows.isEmpty) return;

    for (final row in rows) {
      final group = groupFromDb(row);
      await _supabaseGroups.update(group);
    }
    debugPrint('[LocalToCloudMigration] ${rows.length} grupos migrados');
  }

  Future<void> _migrateAgendaItems() async {
    final records = await _localAgenda.search('');
    if (records.isEmpty) return;

    for (final rec in records) {
      var item = itemFromDb(rec.item, rec.attachments);
      final attachmentsWithUrls = <AttachmentRef>[];
      for (final att in item.attachments) {
        String? remoteUrl = att.remoteUrl;
        if (att.localPath != null) {
          final path = att.localPath!;
          if (File(path).existsSync()) {
            final result = await _fileStorage.copyImageToAppStorage(path);
            if (result.isSuccess && _isHttpUrl(result.data)) {
              remoteUrl = result.data;
            }
          }
        }
        attachmentsWithUrls.add(
          AttachmentRef(
            id: att.id,
            itemId: att.itemId,
            type: att.type,
            localPath: null,
            remoteUrl: remoteUrl,
            thumbPath: att.thumbPath,
            title: att.title,
            mimeType: att.mimeType,
            sizeBytes: att.sizeBytes,
            createdAt: att.createdAt,
          ),
        );
      }
      item = item.copyWith(attachments: attachmentsWithUrls);

      await _supabaseAgenda.updateItem(item);
    }
    debugPrint('[LocalToCloudMigration] ${records.length} itens migrados');
  }

  Future<void> _migrateClassSchedule() async {
    final slots = await _localSchedule.getSlots();
    if (slots.isEmpty) return;

    final uid = _client.auth.currentUser?.id;
    if (uid == null) return;

    for (final slot in slots) {
      await _client.from('class_schedule_slots').upsert({
        'id': slot.id,
        'user_id': uid,
        'day_of_week': slot.dayOfWeek,
        'start_minutes': slot.startMinutes,
        'end_minutes': slot.endMinutes,
        'subject': slot.subject,
        'professor_name': slot.professorName,
        'professor_email': slot.professorEmail,
        'professor_phone': slot.professorPhone,
        'created_at': slot.createdAt.toIso8601String(),
        'updated_at': slot.updatedAt.toIso8601String(),
      }, onConflict: 'id');
    }
    debugPrint('[LocalToCloudMigration] ${slots.length} slots migrados');
  }
}


import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/attachment_ref.dart';
import '../../domain/repositories/i_connectivity_service.dart';
import '../../domain/repositories/i_file_storage_service.dart';
import '../../domain/repositories/i_plan_service.dart';
import '../../domain/repositories/i_sync_service.dart';
import '../../core/result/result.dart';
import '../datasources/agenda_local_datasource.dart';
import '../datasources/agenda_supabase_datasource.dart';
import '../datasources/class_schedule_local_datasource.dart';
import '../datasources/groups_local_datasource.dart';
import '../datasources/groups_supabase_datasource.dart';
import '../models/mappers.dart';

/// Motor de sincronizacao: push de dados locais pendentes para Supabase.
class SyncEngineImpl implements ISyncService {
  SyncEngineImpl(
    this._planService,
    this._connectivity,
    this._localAgenda,
    this._localGroups,
    this._localSchedule,
    this._supabaseAgenda,
    this._supabaseGroups,
    this._fileStorage,
    this._client,
  );

  final IPlanService _planService;
  final IConnectivityService _connectivity;
  final AgendaLocalDataSource _localAgenda;
  final GroupsLocalDataSource _localGroups;
  final ClassScheduleLocalDataSource _localSchedule;
  final AgendaSupabaseDataSource _supabaseAgenda;
  final GroupsSupabaseDataSource _supabaseGroups;
  final IFileStorageService _fileStorage;
  final SupabaseClient _client;

  @override
  Future<Result<void>> syncNow() async {
    if (!await _planService.isPremium()) {
      return Result.success(null);
    }
    if (!await _connectivity.isOnline) {
      debugPrint('[SyncEngine] Offline - sync adiado');
      return Result.success(null);
    }
    if (_client.auth.currentUser == null) {
      return Result.success(null);
    }

    try {
      await _pushGroups();
      await _pushAgendaItems();
      await _pushClassSchedule();
      debugPrint('[SyncEngine] Sync concluido');
      return Result.success(null);
    } catch (e) {
      debugPrint('[SyncEngine] Erro: $e');
      return Result.failure('Falha ao sincronizar: $e');
    }
  }

  Future<void> _pushGroups() async {
    final pending = await _localGroups.getPending();
    for (final row in pending) {
      final group = groupFromDb(row);
      await _supabaseGroups.update(group);
      await _localGroups.markSynced(row.id);
    }
    if (pending.isNotEmpty) {
      debugPrint('[SyncEngine] ${pending.length} grupos enviados');
    }
  }

  Future<void> _pushAgendaItems() async {
    final records = await _localAgenda.getPending();
    for (final rec in records) {
      var item = itemFromDb(rec.item, rec.attachments);
      final attachmentsWithUrls = <AttachmentRef>[];
      for (final att in item.attachments) {
        String? remoteUrl = att.remoteUrl;
        if (att.localPath != null) {
          final path = att.localPath!;
          if (File(path).existsSync()) {
            final result = await _fileStorage.copyImageToAppStorage(path);
            if (result.isSuccess) remoteUrl = result.data;
          }
        }
        attachmentsWithUrls.add(att.copyWith(remoteUrl: remoteUrl));
      }
      item = item.copyWith(attachments: attachmentsWithUrls);

      if (rec.item.deletedAt != null) {
        await _supabaseAgenda.deleteItemSoft(rec.item.id, rec.item.deletedAt!);
      } else {
        await _supabaseAgenda.updateItem(item);
      }
      await _localAgenda.markSynced(rec.item.id);
    }
    if (records.isNotEmpty) {
      debugPrint('[SyncEngine] ${records.length} itens enviados');
    }
  }

  Future<void> _pushClassSchedule() async {
    final allSlots = await _localSchedule.getAllSlots();
    final pending = await _localSchedule.getPendingSlots();
    if (pending.isEmpty && allSlots.isNotEmpty) return;

    final uid = _client.auth.currentUser?.id;
    if (uid == null) return;

    await _client
        .from('class_schedule_slots')
        .delete()
        .eq('user_id', uid);
    for (final row in allSlots) {
      await _client.from('class_schedule_slots').insert({
        'id': row.id,
        'user_id': uid,
        'day_of_week': row.dayOfWeek,
        'start_minutes': row.startMinutes,
        'end_minutes': row.endMinutes,
        'subject': row.subject,
        'professor_name': row.professorName,
        'professor_email': row.professorEmail,
        'professor_phone': row.professorPhone,
        'created_at': row.createdAt.toIso8601String(),
        'updated_at': row.updatedAt.toIso8601String(),
      });
    }
    await _localSchedule.markSlotsSynced();
    debugPrint('[SyncEngine] ${allSlots.length} slots sincronizados');
  }
}

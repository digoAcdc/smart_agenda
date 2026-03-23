import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/config/supabase_config.dart';
import '../../core/result/result.dart';
import '../../domain/repositories/i_user_data_deletion_service.dart';
import '../local/app_database.dart';

/// Ordem: nuvem primeiro (se logado); se falhar, não apaga local.
/// Assinaturas (`user_subscriptions` / `purchase_validations`) não são apagadas.
class UserDataDeletionServiceImpl implements IUserDataDeletionService {
  UserDataDeletionServiceImpl(
    this._db,
    this._client,
  );

  final AppDatabase _db;
  final SupabaseClient? _client;

  static const _migrationKeyPrefix = 'local_migrated_';

  @override
  Future<Result<void>> deleteAllUserData() async {
    final client = _client;
    if (SupabaseConfig.isConfigured && client != null) {
      final uid = client.auth.currentUser?.id;
      if (uid != null) {
        try {
          await _deleteRemoteUserData(client, uid);
        } catch (e, st) {
          debugPrint('[UserDataDeletion] Remoto falhou: $e\n$st');
          return Result.failure(
            'Nao foi possivel apagar os dados na nuvem. Verifique a conexao e tente novamente.',
          );
        }
      }
    }

    try {
      await _deleteAllLocalRows();
      await _clearLocalAttachmentsDirectory();
      await _clearMigrationPrefs();
    } catch (e, st) {
      debugPrint('[UserDataDeletion] Local falhou: $e\n$st');
      return Result.failure(
        'Dados na nuvem foram apagados, mas houve erro ao limpar o aparelho. Tente novamente.',
      );
    }

    return Result.success(null);
  }

  Future<void> _deleteRemoteUserData(SupabaseClient client, String uid) async {
    await _removeStorageAttachments(client, uid);

    await client.from('students').delete().eq('user_id', uid);
    await client.from('class_groups').delete().eq('user_id', uid);

    await client.from('note_checklist_items').delete().eq('user_id', uid);
    await client.from('notes').delete().eq('user_id', uid);

    await client.from('agenda_items').delete().eq('user_id', uid);

    await client.from('agenda_groups').delete().eq('user_id', uid);

    await client.from('class_schedule_slots').delete().eq('user_id', uid);

    await client.from('agenda_shares').delete().eq('owner_id', uid);
    await client.from('agenda_shares').delete().eq('shared_with_id', uid);

    await client.from('user_notifications').delete().eq('user_id', uid);
    await client.from('user_fcm_tokens').delete().eq('user_id', uid);
    await client.from('user_push_preferences').delete().eq('user_id', uid);

    debugPrint('[UserDataDeletion] Remoto concluido para $uid');
  }

  Future<void> _removeStorageAttachments(
    SupabaseClient client,
    String userId,
  ) async {
    final bucket = client.storage.from('attachments');
    await _removeStoragePathRecursive(bucket, userId);
  }

  Future<void> _removeStoragePathRecursive(
    StorageFileApi bucket,
    String pathPrefix,
  ) async {
    final entries = await bucket.list(path: pathPrefix);
    for (final entry in entries) {
      final childPath = '$pathPrefix/${entry.name}';
      if (entry.id == null) {
        await _removeStoragePathRecursive(bucket, childPath);
      } else {
        await bucket.remove([childPath]);
      }
    }
  }

  Future<void> _deleteAllLocalRows() async {
    await _db.transaction(() async {
      await _db.delete(_db.studentsTable).go();
      await _db.delete(_db.classGroupsTable).go();

      await _db.delete(_db.noteChecklistItemsTable).go();
      await _db.delete(_db.notesTable).go();

      await _db.delete(_db.attachmentsTable).go();
      await _db.delete(_db.agendaItemsTable).go();
      await _db.delete(_db.agendaGroupsTable).go();

      await _db.delete(_db.classScheduleSlotsTable).go();
    });
    debugPrint('[UserDataDeletion] Drift limpo');
  }

  Future<void> _clearLocalAttachmentsDirectory() async {
    final dir = await getApplicationDocumentsDirectory();
    final attachmentsDir = Directory('${dir.path}/attachments');
    if (await attachmentsDir.exists()) {
      await attachmentsDir.delete(recursive: true);
      debugPrint('[UserDataDeletion] Pasta attachments local removida');
    }
  }

  Future<void> _clearMigrationPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs
        .getKeys()
        .where((k) => k.startsWith(_migrationKeyPrefix))
        .toList();
    for (final k in keys) {
      await prefs.remove(k);
    }
    if (keys.isNotEmpty) {
      debugPrint('[UserDataDeletion] Prefs migracao removidas: ${keys.length}');
    }
  }
}

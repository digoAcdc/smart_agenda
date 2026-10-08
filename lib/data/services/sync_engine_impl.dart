import 'dart:async';
import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/result/result.dart';
import '../../domain/entities/agenda_item.dart';
import '../../domain/entities/attachment_ref.dart';
import '../../domain/entities/family.dart';
import '../../domain/entities/student.dart';
import '../../domain/repositories/i_connectivity_service.dart';
import '../../domain/repositories/i_family_service.dart';
import '../../domain/repositories/i_file_storage_service.dart';
import '../../domain/repositories/i_plan_service.dart';
import '../../domain/repositories/i_sync_service.dart';
import '../datasources/agenda_local_datasource.dart';
import '../datasources/agenda_supabase_datasource.dart';
import '../datasources/class_group_local_datasource.dart';
import '../datasources/class_schedule_local_datasource.dart';
import '../datasources/groups_local_datasource.dart';
import '../datasources/note_local_datasource.dart';
import '../datasources/note_supabase_datasource.dart';
import '../local/app_database.dart';
import '../models/mappers.dart';

/// Sincronizacao da agenda:
/// - Pessoal: so local no Free; Pro envia e baixa (varios dispositivos).
/// - Familia: a nuvem e a fonte da verdade; o aparelho guarda um cache
///   e recebe alteracoes dos outros membros via Realtime.
/// Leituras da UI sempre vem do banco local.
class SyncEngineImpl implements ISyncService {
  SyncEngineImpl(
    this._connectivity,
    this._localAgenda,
    this._localGroups,
    this._localSchedule,
    this._localClassGroups,
    this._localNotes,
    this._remoteAgenda,
    this._supabaseNotes,
    this._fileStorage,
    this._planService,
    this._familyService,
    this._client,
  );

  final IConnectivityService _connectivity;
  final AgendaLocalDataSource _localAgenda;
  final GroupsLocalDataSource _localGroups;
  final ClassScheduleLocalDataSource _localSchedule;
  final ClassGroupLocalDataSource _localClassGroups;
  final NoteLocalDataSource _localNotes;
  final AgendaSupabaseDataSource _remoteAgenda;
  final NoteSupabaseDataSource _supabaseNotes;
  final IFileStorageService _fileStorage;
  final IPlanService _planService;
  final IFamilyService _familyService;
  final SupabaseClient _client;

  static const _cursorPrefix = 'sync_cursor_';

  final StreamController<void> _changes = StreamController<void>.broadcast();
  Future<Result<void>>? _running;
  bool _again = false;
  RealtimeChannel? _channel;
  String? _channelKey;
  Timer? _debounce;

  @override
  Stream<void> get onDataChanged => _changes.stream;

  @override
  Future<Result<void>> syncNow() {
    final running = _running;
    if (running != null) {
      _again = true;
      return running;
    }
    return _running = _loop().whenComplete(() => _running = null);
  }

  Future<Result<void>> _loop() async {
    Result<void> result;
    do {
      _again = false;
      result = await _syncOnce();
    } while (_again);
    return result;
  }

  Future<Result<void>> _syncOnce() async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return Result.success(null);
    if (!await _connectivity.isOnline) {
      debugPrint('[SyncEngine] Offline - sync adiado');
      return Result.success(null);
    }

    try {
      final ctxResult = await _familyService.refresh();
      final ctx = ctxResult.data ?? _familyService.context;
      final hasPro = await _planService.isPremium();
      var changed = false;

      if (ctxResult.isSuccess) {
        changed |= await _dropStaleFamilyCache(uid, ctx.familyId);
      }

      changed |= await _pushAgendaItems(uid, ctx, hasPro);
      if (hasPro) await _pushGroups();

      changed |= await _pullItems(uid, SyncScope.personal(uid));
      changed |= await _pullGroups(uid, SyncScope.personal(uid));
      if (ctx.familyId != null) {
        changed |= await _pushFamilySchedules(uid, ctx);
        changed |= await _pullItems(uid, SyncScope.family(ctx.familyId!));
        changed |= await _pullFamilySchedules(uid, ctx.familyId!);
      }

      if (hasPro) {
        await _pushClassSchedule(uid);
        await _pushClassGroups(uid);
        await _pushNotes(uid);
      }

      _syncRealtime(uid, ctx.familyId, hasPro);
      if (changed) _changes.add(null);
      debugPrint('[SyncEngine] Sync concluido');
      return Result.success(null);
    } catch (e) {
      debugPrint('[SyncEngine] Erro: $e');
      return Result.failure('Falha ao sincronizar: $e');
    }
  }

  @override
  Future<void> clearCloudCache() async {
    _unsubscribe();
    await _localAgenda.clearFamilyCache();
    await _localGroups.clearFamilyCache();
    await _localSchedule.clearFamilySlots();
    final prefs = await SharedPreferences.getInstance();
    for (final key
        in prefs.getKeys().where((k) => k.startsWith(_cursorPrefix)).toList()) {
      await prefs.remove(key);
    }
    _changes.add(null);
  }

  // ---------------------------------------------------------------------------
  // Agenda
  // ---------------------------------------------------------------------------

  Future<bool> _pushAgendaItems(
    String uid,
    FamilyContext ctx,
    bool hasPro,
  ) async {
    final records = await _localAgenda.getPending();
    var changed = false;
    var pushed = 0;
    for (final rec in records) {
      final item = itemFromDb(rec.item, rec.attachments);

      if (item.isFamilyItem) {
        if (item.familyId != ctx.familyId || !ctx.canEditAgenda) {
          // Sem permissao para gravar: descarta a alteracao local e
          // restaura a versao do servidor.
          await _restoreFromServer(item.id);
          changed = true;
          continue;
        }
      } else if (!hasPro) {
        // Free: agenda pessoal fica so no aparelho.
        continue;
      }

      try {
        final withUploads = await _uploadPendingAttachments(item);
        await _remoteAgenda.upsertItem(withUploads);
        await _localAgenda.markSynced(item.id);
        pushed++;
      } on PostgrestException catch (e) {
        debugPrint(
          '[SyncEngine] push ${item.id} recusado: ${e.code} ${e.message}',
        );
        if (e.code == '42501' && item.isFamilyItem) {
          await _restoreFromServer(item.id);
          changed = true;
        }
      }
    }
    if (pushed > 0) debugPrint('[SyncEngine] $pushed itens enviados');
    return changed;
  }

  Future<void> _restoreFromServer(String itemId) async {
    final remote = await _remoteAgenda.fetchItem(itemId);
    await _localAgenda.discardLocal(itemId);
    if (remote != null) await _applyRemoteItem(remote);
  }

  Future<AgendaItem> _uploadPendingAttachments(AgendaItem item) async {
    if (item.attachments.every(
      (a) => a.localPath == null || a.remoteUrl != null,
    )) {
      return item;
    }
    final updated = <AttachmentRef>[];
    for (final att in item.attachments) {
      final path = att.localPath;
      if (att.remoteUrl == null && path != null && await File(path).exists()) {
        final result = await _fileStorage.uploadToCloud(
          path,
          familyId: item.familyId,
        );
        if (result.isSuccess) {
          updated.add(att.copyWith(remoteUrl: result.data));
          continue;
        }
      }
      updated.add(att);
    }
    final withUrls = item.copyWith(attachments: updated);
    // Guarda a URL localmente para nao reenviar o arquivo.
    await _localAgenda.updateItem(
      agendaItemToCompanion(withUrls),
      updated.map(attachmentToCompanion).toList(),
    );
    return withUrls;
  }

  Future<bool> _pullItems(String uid, SyncScope scope) async {
    final cursorKey = '$_cursorPrefix${uid}_items_${scope.key}';
    final prefs = await SharedPreferences.getInstance();
    final since = prefs.getString(cursorKey);
    final changes = await _remoteAgenda.fetchItemChanges(scope, since: since);
    for (final item in changes.rows) {
      await _applyRemoteItem(item);
    }
    if (changes.maxUpdatedAt != null && changes.maxUpdatedAt != since) {
      await prefs.setString(cursorKey, changes.maxUpdatedAt!);
    }
    if (changes.rows.isNotEmpty) {
      debugPrint(
        '[SyncEngine] ${changes.rows.length} itens recebidos (${scope.key})',
      );
    }
    return changes.rows.isNotEmpty;
  }

  Future<void> _applyRemoteItem(AgendaItem item) {
    return _localAgenda.applyRemote(
      agendaItemToCompanion(item),
      item.attachments.map(attachmentToCompanion).toList(),
      deleted: item.deletedAt != null,
    );
  }

  /// Saiu/foi removido da Familia (ou trocou): limpa o cache antigo.
  Future<bool> _dropStaleFamilyCache(String uid, String? familyId) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '$_cursorPrefix${uid}_family';
    final previous = prefs.getString(key);
    if (previous == familyId) return false;

    await _localAgenda.clearFamilyCache(keepFamilyId: familyId);
    await _localGroups.clearFamilyCache(keepFamilyId: familyId);
    await _localSchedule.clearFamilySlots(keepFamilyId: familyId);
    for (final k
        in prefs.getKeys().where((k) => k.contains('_family_')).toList()) {
      if (k.startsWith(_cursorPrefix)) await prefs.remove(k);
    }
    if (familyId == null) {
      await prefs.remove(key);
    } else {
      await prefs.setString(key, familyId);
    }
    return true;
  }

  // ---------------------------------------------------------------------------
  // Grade dos filhos (Familia)
  // ---------------------------------------------------------------------------

  String _familyCursorKey(String uid, String table, String familyId) =>
      '$_cursorPrefix${uid}_${table}_family_$familyId';

  DateTime? _parseDate(Object? v) =>
      v == null ? null : DateTime.parse(v as String).toLocal();

  /// Envia grades e aulas dos filhos pendentes. Sem permissao, descarta a
  /// alteracao local e forca baixar de novo a versao do servidor.
  Future<bool> _pushFamilySchedules(String uid, FamilyContext ctx) async {
    var changed = false;
    var resetCursors = false;
    bool allowed(String? familyId) =>
        familyId == ctx.familyId && ctx.canEditAgenda;

    for (final row in await _localSchedule.getPendingFamilySchedules()) {
      if (!allowed(row.familyId)) {
        await _localSchedule.deleteLocalSchedule(row.id);
        resetCursors = changed = true;
        continue;
      }
      try {
        await _remoteAgenda.upsertFamilyRow('class_schedules', {
          'id': row.id,
          'family_id': row.familyId,
          'child_id': row.childId,
          'name': row.name,
          'created_at': row.createdAt.toUtc().toIso8601String(),
          'deleted_at': row.deletedAt?.toUtc().toIso8601String(),
        });
        await _localSchedule.markScheduleSynced(row.id);
      } on PostgrestException catch (e) {
        debugPrint('[SyncEngine] grade ${row.id} recusada: ${e.code} ${e.message}');
        if (e.code == '42501') {
          await _localSchedule.deleteLocalSchedule(row.id);
          resetCursors = changed = true;
        }
      }
    }

    for (final row in await _localSchedule.getPendingFamilySlots()) {
      if (!allowed(row.familyId) || row.scheduleId == null) {
        await _localSchedule.deleteLocalSlot(row.id);
        resetCursors = changed = true;
        continue;
      }
      try {
        await _remoteAgenda.upsertFamilyRow('class_schedule_slots', {
          'id': row.id,
          'schedule_id': row.scheduleId,
          'family_id': row.familyId,
          'child_id': row.childId,
          'day_of_week': row.dayOfWeek,
          'start_minutes': row.startMinutes,
          'end_minutes': row.endMinutes,
          'subject': row.subject,
          'professor_name': row.professorName,
          'professor_email': row.professorEmail,
          'professor_phone': row.professorPhone,
          'created_at': row.createdAt.toUtc().toIso8601String(),
          'deleted_at': row.deletedAt?.toUtc().toIso8601String(),
        });
        await _localSchedule.markSlotSynced(row.id);
      } on PostgrestException catch (e) {
        debugPrint('[SyncEngine] aula ${row.id} recusada: ${e.code} ${e.message}');
        if (e.code == '42501' || e.code == '23503' || e.code == '23514') {
          await _localSchedule.deleteLocalSlot(row.id);
          resetCursors = changed = true;
        }
      }
    }

    if (resetCursors && ctx.familyId != null) {
      final prefs = await SharedPreferences.getInstance();
      for (final table in ['class_schedules', 'class_schedule_slots']) {
        await prefs.remove(_familyCursorKey(uid, table, ctx.familyId!));
      }
    }
    return changed;
  }

  Future<bool> _pullFamilySchedules(String uid, String familyId) async {
    final prefs = await SharedPreferences.getInstance();
    var changed = false;

    final schedulesKey = _familyCursorKey(uid, 'class_schedules', familyId);
    final schedules = await _remoteAgenda.fetchFamilyChanges(
      'class_schedules',
      familyId,
      since: prefs.getString(schedulesKey),
    );
    for (final r in schedules.rows) {
      await _localSchedule.applyRemoteFamilySchedule(
        ClassSchedulesTableCompanion(
          id: Value(r['id'] as String),
          name: Value(r['name'] as String),
          familyId: Value(r['family_id'] as String?),
          childId: Value(r['child_id'] as String?),
          createdAt: Value(_parseDate(r['created_at'])!),
          updatedAt: Value(_parseDate(r['updated_at'])!),
          deletedAt: Value(_parseDate(r['deleted_at'])),
        ),
        deleted: r['deleted_at'] != null,
      );
    }
    if (schedules.maxUpdatedAt != null) {
      await prefs.setString(schedulesKey, schedules.maxUpdatedAt!);
    }
    changed |= schedules.rows.isNotEmpty;

    final slotsKey = _familyCursorKey(uid, 'class_schedule_slots', familyId);
    final slots = await _remoteAgenda.fetchFamilyChanges(
      'class_schedule_slots',
      familyId,
      since: prefs.getString(slotsKey),
    );
    for (final r in slots.rows) {
      await _localSchedule.applyRemoteFamilySlot(
        ClassScheduleSlotsTableCompanion(
          id: Value(r['id'] as String),
          scheduleId: Value(r['schedule_id'] as String?),
          familyId: Value(r['family_id'] as String?),
          childId: Value(r['child_id'] as String?),
          dayOfWeek: Value(r['day_of_week'] as int),
          startMinutes: Value(r['start_minutes'] as int),
          endMinutes: Value(r['end_minutes'] as int),
          subject: Value(r['subject'] as String?),
          professorName: Value(r['professor_name'] as String?),
          professorEmail: Value(r['professor_email'] as String?),
          professorPhone: Value(r['professor_phone'] as String?),
          createdAt: Value(_parseDate(r['created_at'])!),
          updatedAt: Value(_parseDate(r['updated_at'])!),
          deletedAt: Value(_parseDate(r['deleted_at'])),
        ),
        deleted: r['deleted_at'] != null,
      );
    }
    if (slots.maxUpdatedAt != null) {
      await prefs.setString(slotsKey, slots.maxUpdatedAt!);
    }
    return changed || slots.rows.isNotEmpty;
  }

  // ---------------------------------------------------------------------------
  // Categorias (pessoais)
  // ---------------------------------------------------------------------------

  Future<void> _pushGroups() async {
    final pending = await _localGroups.getPending();
    for (final row in pending) {
      await _remoteAgenda.upsertGroup(groupFromDb(row));
      await _localGroups.markSynced(row.id);
    }
    if (pending.isNotEmpty) {
      debugPrint('[SyncEngine] ${pending.length} categorias enviadas');
    }
  }

  Future<bool> _pullGroups(String uid, SyncScope scope) async {
    final cursorKey = '$_cursorPrefix${uid}_groups_${scope.key}';
    final prefs = await SharedPreferences.getInstance();
    final since = prefs.getString(cursorKey);
    final changes = await _remoteAgenda.fetchGroupChanges(scope, since: since);
    for (final group in changes.rows) {
      await _localGroups.applyRemote(groupToCompanion(group));
    }
    if (changes.maxUpdatedAt != null && changes.maxUpdatedAt != since) {
      await prefs.setString(cursorKey, changes.maxUpdatedAt!);
    }
    return changes.rows.isNotEmpty;
  }

  // ---------------------------------------------------------------------------
  // Realtime: alteracoes de outros membros/dispositivos disparam um sync.
  // ---------------------------------------------------------------------------

  void _syncRealtime(String uid, String? familyId, bool hasPro) {
    final key = '$uid|${familyId ?? ''}|$hasPro';
    if (key == _channelKey) return;
    _unsubscribe();
    if (familyId == null && !hasPro) return;

    _channelKey = key;
    final channel = _client.channel('agenda-$uid');
    void onChange(PostgresChangePayload _) {
      _debounce?.cancel();
      _debounce = Timer(const Duration(milliseconds: 800), syncNow);
    }

    if (familyId != null) {
      for (final table in ['agenda_items', 'class_schedules', 'class_schedule_slots']) {
        channel.onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: table,
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'family_id',
            value: familyId,
          ),
          callback: onChange,
        );
      }
    }
    if (hasPro) {
      channel.onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'agenda_items',
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'owner_user_id',
          value: uid,
        ),
        callback: onChange,
      );
    }
    _channel = channel.subscribe();
  }

  void _unsubscribe() {
    _debounce?.cancel();
    final ch = _channel;
    _channel = null;
    _channelKey = null;
    if (ch != null) unawaited(_client.removeChannel(ch));
  }

  // ---------------------------------------------------------------------------
  // Modulos pessoais (grade, turmas, anotacoes) - somente Pro.
  // Ainda usam substituicao completa; nunca enviam lista vazia para nao
  // apagar a nuvem a partir de um aparelho sem dados.
  // ---------------------------------------------------------------------------

  /// Grades pessoais (Pro): substituicao completa a partir do aparelho.
  Future<void> _pushClassSchedule(String uid) async {
    if (!await _localSchedule.hasPersonalPending()) return;
    final schedules = await _localSchedule.getAllPersonalSchedules();
    final slots = await _localSchedule.getAllPersonalSlots();
    // Nunca apaga a nuvem a partir de um aparelho sem grades.
    if (schedules.isEmpty) return;

    // Aulas com schedule_id saem em cascata; linhas antigas sem grade tambem.
    await _client.from('class_schedules').delete().eq('owner_user_id', uid);
    await _client.from('class_schedule_slots').delete().eq('user_id', uid);
    await _client.from('class_schedules').insert([
      for (final g in schedules)
        {
          'id': g.id,
          'owner_user_id': uid,
          'name': g.name,
          'created_at': g.createdAt.toUtc().toIso8601String(),
        },
    ]);
    final scheduleIds = schedules.map((g) => g.id).toSet();
    final rows = [
      for (final row in slots.where((r) => scheduleIds.contains(r.scheduleId)))
        {
          'id': row.id,
          'user_id': uid,
          'schedule_id': row.scheduleId,
          'day_of_week': row.dayOfWeek,
          'start_minutes': row.startMinutes,
          'end_minutes': row.endMinutes,
          'subject': row.subject,
          'professor_name': row.professorName,
          'professor_email': row.professorEmail,
          'professor_phone': row.professorPhone,
          'created_at': row.createdAt.toUtc().toIso8601String(),
        },
    ];
    if (rows.isNotEmpty) await _client.from('class_schedule_slots').insert(rows);
    await _localSchedule.markPersonalSynced();
    debugPrint('[SyncEngine] ${schedules.length} grades pessoais sincronizadas');
  }

  Future<void> _pushClassGroups(String uid) async {
    final allGroups = await _localClassGroups.getGroups();
    if (allGroups.isEmpty) return;
    final allStudents = <String, List<Student>>{};
    for (final g in allGroups) {
      allStudents[g.id] = await _localClassGroups.getStudentsByGroup(g.id);
    }

    await _client.from('students').delete().eq('user_id', uid);
    await _client.from('class_groups').delete().eq('user_id', uid);

    for (final g in allGroups) {
      await _client.from('class_groups').insert({
        'id': g.id,
        'user_id': uid,
        'name': g.name,
        'description': g.description,
        'created_at': g.createdAt.toIso8601String(),
        'updated_at': g.updatedAt.toIso8601String(),
      });
    }
    for (final g in allGroups) {
      for (final s in allStudents[g.id]!) {
        await _client.from('students').insert({
          'id': s.id,
          'user_id': uid,
          'group_id': s.groupId,
          'name': s.name,
          'email': s.email,
          'phone': s.phone,
          'guardian_name': s.guardianName,
          'guardian_email': s.guardianEmail,
          'guardian_phone': s.guardianPhone,
          'created_at': s.createdAt.toIso8601String(),
          'updated_at': s.updatedAt.toIso8601String(),
        });
      }
    }
    debugPrint('[SyncEngine] ${allGroups.length} turmas sincronizadas');
  }

  Future<void> _pushNotes(String uid) async {
    final allNotes = await _localNotes.getNotes();
    if (allNotes.isEmpty) return;
    await _supabaseNotes.deleteAllForUser(uid);

    for (final note in allNotes) {
      String? imageUrl = note.imageUrl;
      final path = note.imagePath;
      if (imageUrl == null && path != null && await File(path).exists()) {
        final result = await _fileStorage.uploadToCloud(path);
        if (result.isSuccess) imageUrl = result.data;
      }
      await _supabaseNotes.upsertNote(note.copyWith(imageUrl: imageUrl));
      await _supabaseNotes.upsertChecklistItems(note.id, note.checklistItems);
    }
    debugPrint('[SyncEngine] ${allNotes.length} anotacoes sincronizadas');
  }
}

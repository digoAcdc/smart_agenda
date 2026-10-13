import 'dart:async';
import 'dart:convert';
import 'dart:io' show SocketException;

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/result/result.dart';
import '../../domain/entities/family.dart';
import '../../domain/repositories/i_family_service.dart';
import '../datasources/family_supabase_datasource.dart';

/// Traduz erros das RPCs da Familia (HINT do banco) em mensagens para o usuario.
String familyErrorMessage(Object error) {
  if (error is PostgrestException) {
    switch (error.hint) {
      case 'pro_required':
        return 'Criar uma Família é um recurso do plano Pro.';
      case 'already_in_family':
        return 'Você já participa de uma Família.';
      case 'member_limit':
        return 'A Família já atingiu o limite de pessoas.';
      case 'already_member':
        return 'Esta pessoa já faz parte da Família.';
      case 'invite_invalid':
        return 'Este convite expirou ou já foi usado.';
      case 'family_inactive':
        return 'A assinatura Pro desta Família não está ativa no momento.';
      case 'owner_role':
        return 'O dono da Família é sempre administrador.';
    }
    if (error.code == '42501') {
      return 'Você não tem permissão para fazer isso nesta Família.';
    }
    if (error.code == 'P0002') {
      return 'Não encontrado. Atualize e tente novamente.';
    }
    return error.message;
  }
  if (error is SocketException ||
      error.toString().contains('SocketException')) {
    return 'Sem conexão. Tente novamente quando estiver online.';
  }
  return 'Algo deu errado. Tente novamente.';
}

class FamilyServiceImpl extends GetxController implements IFamilyService {
  FamilyServiceImpl(this._ds);

  final FamilySupabaseDataSource _ds;

  static const _cacheKey = 'family_cache_v1';

  final Rx<FamilyContext> _context = FamilyContext.empty.obs;
  final RxList<FamilyMember> _members = <FamilyMember>[].obs;
  final RxList<FamilyChild> _children = <FamilyChild>[].obs;
  final RxList<FamilyInvite> _familyInvites = <FamilyInvite>[].obs;
  final RxList<FamilyInvite> _myInvites = <FamilyInvite>[].obs;
  final RxBool _loading = false.obs;

  RealtimeChannel? _channel;
  String? _channelFamilyId;
  Timer? _debounce;
  Future<Result<FamilyContext>>? _inFlight;

  @override
  FamilyContext get context => _context.value;
  @override
  String? get currentUserId => _ds.currentUserId;
  @override
  List<FamilyMember> get members => _members;
  @override
  List<FamilyChild> get children =>
      _children.where((c) => !c.isArchived).toList();
  @override
  List<FamilyChild> get allChildren => _children;
  @override
  List<FamilyInvite> get familyInvites => _familyInvites;
  @override
  List<FamilyInvite> get myInvites => _myInvites;
  @override
  bool get loading => _loading.value;

  @override
  FamilyMember? memberById(String? userId) => userId == null
      ? null
      : _members.firstWhereOrNull((m) => m.userId == userId);

  @override
  FamilyChild? childById(String? childId) => childId == null
      ? null
      : _children.firstWhereOrNull((c) => c.id == childId);

  @override
  void onInit() {
    super.onInit();
    _loadCache();
  }

  @override
  void onClose() {
    _debounce?.cancel();
    _unsubscribe();
    super.onClose();
  }

  @override
  Future<Result<FamilyContext>> refresh() {
    return _inFlight ??= _refresh().whenComplete(() => _inFlight = null);
  }

  Future<Result<FamilyContext>> _refresh() async {
    if (_ds.currentUserId == null) {
      await clear();
      return Result.success(FamilyContext.empty);
    }
    _loading.value = true;
    try {
      final ctx = await _ds.getContext();
      final familyId = ctx.familyId;
      final results = await Future.wait([
        familyId == null
            ? Future.value(<FamilyMember>[])
            : _ds.getMembers(familyId),
        familyId == null
            ? Future.value(<FamilyChild>[])
            : _ds.getChildren(familyId),
        familyId != null && ctx.isAdmin
            ? _ds.getFamilyInvites(familyId)
            : Future.value(<FamilyInvite>[]),
        familyId == null ? _ds.getMyInvites() : Future.value(<FamilyInvite>[]),
      ]);
      _context.value = ctx;
      _members.assignAll(results[0] as List<FamilyMember>);
      _children.assignAll(results[1] as List<FamilyChild>);
      _familyInvites.assignAll(results[2] as List<FamilyInvite>);
      _myInvites.assignAll(results[3] as List<FamilyInvite>);
      await _saveCache();
      _syncRealtime(familyId);
      return Result.success(ctx);
    } catch (e) {
      debugPrint('[FamilyService] refresh falhou: $e');
      return Result.failure(familyErrorMessage(e));
    } finally {
      _loading.value = false;
    }
  }

  @override
  Future<void> clear() async {
    _unsubscribe();
    _context.value = FamilyContext.empty;
    _members.clear();
    _children.clear();
    _familyInvites.clear();
    _myInvites.clear();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_cacheKey);
  }

  Future<Result<void>> _run(Future<void> Function() action) async {
    try {
      await action();
      await refresh();
      return Result.success(null);
    } catch (e) {
      debugPrint('[FamilyService] acao falhou: $e');
      return Result.failure(familyErrorMessage(e));
    }
  }

  String? get _familyId => context.familyId;

  Future<void> _requireFamily(Future<void> Function(String id) action) async {
    final id = _familyId;
    if (id == null) throw StateError('Sem família');
    await action(id);
  }

  @override
  Future<Result<void>> createFamily(String name, {String? nickname}) =>
      _run(() => _ds.createFamily(name.trim(), nickname: _clean(nickname)));

  @override
  Future<Result<void>> renameFamily(String name) =>
      _run(() => _requireFamily((id) => _ds.renameFamily(id, name.trim())));

  @override
  Future<Result<void>> deleteFamily() =>
      _run(() => _requireFamily(_ds.deleteFamily));

  @override
  Future<Result<void>> invite(String email, FamilyRole role) => _run(
    () => _requireFamily(
      (id) => _ds.invite(id, email.trim().toLowerCase(), role),
    ),
  );

  @override
  Future<Result<void>> revokeInvite(String inviteId) =>
      _run(() => _ds.revokeInvite(inviteId));

  @override
  Future<Result<void>> acceptInvite(String inviteId, {String? nickname}) =>
      _run(() => _ds.acceptInvite(inviteId, nickname: _clean(nickname)));

  @override
  Future<Result<void>> declineInvite(String inviteId) =>
      _run(() => _ds.declineInvite(inviteId));

  @override
  Future<Result<String>> createInviteLink(FamilyRole role) async {
    final id = _familyId;
    if (id == null) return Result.failure('Você ainda não tem uma Família.');
    try {
      final token = await _ds.createInviteLink(id, role);
      await refresh(); // o convite ocupa vaga e aparece na lista
      return Result.success(token);
    } catch (e) {
      debugPrint('[FamilyService] convite por link falhou: $e');
      return Result.failure(familyErrorMessage(e));
    }
  }

  @override
  Future<Result<FamilyLinkInvite?>> getInviteByToken(String token) async {
    try {
      return Result.success(await _ds.getInviteByToken(token));
    } catch (e) {
      return Result.failure(familyErrorMessage(e));
    }
  }

  @override
  Future<Result<void>> acceptInviteByToken(String token, {String? nickname}) =>
      _run(() => _ds.acceptInviteByToken(token, nickname: _clean(nickname)));

  @override
  Future<Result<void>> changeRole(String userId, FamilyRole role) =>
      _run(() => _requireFamily((id) => _ds.changeRole(id, userId, role)));

  @override
  Future<Result<void>> removeMember(String userId) =>
      _run(() => _requireFamily((id) => _ds.removeMember(id, userId)));

  @override
  Future<Result<void>> leave() => _run(() => _requireFamily(_ds.leave));

  @override
  Future<Result<void>> updateMyNickname(String? nickname) => _run(
    () => _requireFamily((id) => _ds.updateMyNickname(id, _clean(nickname))),
  );

  @override
  Future<Result<void>> saveChild(FamilyChild child, {required bool isNew}) =>
      _run(() => _ds.saveChild(child, isNew: isNew));

  @override
  Future<Result<void>> setChildArchived(String childId, bool archived) =>
      _run(() => _ds.setChildArchived(childId, archived));

  String? _clean(String? v) {
    final t = v?.trim();
    return (t == null || t.isEmpty) ? null : t;
  }

  void _syncRealtime(String? familyId) {
    if (familyId == _channelFamilyId) return;
    _unsubscribe();
    if (familyId == null) return;
    _channelFamilyId = familyId;
    _channel = _ds.subscribeFamily(familyId, () {
      _debounce?.cancel();
      _debounce = Timer(const Duration(milliseconds: 600), refresh);
    });
  }

  void _unsubscribe() {
    final ch = _channel;
    _channel = null;
    _channelFamilyId = null;
    if (ch != null) unawaited(_ds.unsubscribe(ch));
  }

  Future<void> _saveCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _cacheKey,
      jsonEncode({
        'user_id': _ds.currentUserId,
        'context': context.toJson(),
        'members': _members.map((m) => m.toJson()).toList(),
        'children': _children.map((c) => c.toJson()).toList(),
      }),
    );
  }

  Future<void> _loadCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_cacheKey);
      if (raw == null) return;
      final json = jsonDecode(raw) as Map<String, dynamic>;
      if (json['user_id'] != _ds.currentUserId) return;
      _context.value = FamilyContext.fromJson(
        Map<String, dynamic>.from(json['context'] as Map),
      );
      _members.assignAll(
        (json['members'] as List).map(
          (m) => FamilyMember.fromJson(Map<String, dynamic>.from(m as Map)),
        ),
      );
      _children.assignAll(
        (json['children'] as List).map(
          (c) => FamilyChild.fromJson(Map<String, dynamic>.from(c as Map)),
        ),
      );
    } catch (e) {
      debugPrint('[FamilyService] cache invalido: $e');
    }
  }
}

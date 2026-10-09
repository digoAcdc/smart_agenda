import 'dart:async';
import 'dart:io';

import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:play_install_referrer/play_install_referrer.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/routes/app_routes.dart';
import '../../domain/entities/family.dart';
import '../../domain/repositories/i_family_service.dart';
import '../../domain/repositories/i_sync_service.dart';
import '../controllers/auth_controller.dart';
import '../utils/move_to_family_prompt.dart';

/// Convite da Familia por link (rbarbosa.tech/convite/CODIGO).
///
/// O codigo chega por tres caminhos: o link abrindo o app, o botao da pagina
/// (smartagenda://convite/CODIGO) ou, para quem instalou pela pagina, o
/// "install referrer" do Google Play. Fica guardado ate a pessoa estar logada
/// e responder.
class InviteLinkHandler extends GetxService {
  static const _pendingKey = 'pending_family_invite_token';
  static const _referrerCheckedKey = 'install_referrer_checked';
  static final _tokenRe = RegExp(r'^[a-z2-9]{8,64}$');

  final _appLinks = AppLinks();
  StreamSubscription<Uri>? _sub;
  bool _started = false;
  bool _prompting = false;

  static String? tokenFromUri(Uri uri) {
    String? raw;
    if (uri.scheme == 'smartagenda' && uri.host == 'convite') {
      raw = uri.pathSegments.isEmpty ? null : uri.pathSegments.first;
    } else if (uri.host.endsWith('rbarbosa.tech') &&
        uri.pathSegments.length >= 2 &&
        uri.pathSegments.first == 'convite') {
      raw = uri.pathSegments[1];
    }
    final t = raw?.toLowerCase();
    return t != null && _tokenRe.hasMatch(t) ? t : null;
  }

  /// O Play devolve o referrer como "convite=CODIGO" (as vezes codificado).
  static String? tokenFromReferrer(String? referrer) {
    if (referrer == null || referrer.isEmpty) return null;
    final decoded = Uri.decodeComponent(referrer);
    final match = RegExp(r'convite=([a-z2-9]{8,64})').firstMatch(decoded);
    return match?.group(1);
  }

  Future<void> start() async {
    if (_started) return;
    _started = true;
    debugPrint('[InviteLink] iniciado');
    // Link que abriu o app (o stream so traz os que chegam depois).
    try {
      final initial = await _appLinks.getInitialLink();
      if (initial != null) {
        final token = tokenFromUri(initial);
        if (token != null) await _savePending(token);
      }
    } catch (_) {}
    _sub = _appLinks.uriLinkStream.listen(_onUri, onError: (_) {});
    await _checkInstallReferrer();
    await promptIfPending();
  }

  @override
  void onClose() {
    _sub?.cancel();
    super.onClose();
  }

  Future<void> _onUri(Uri uri) async {
    final token = tokenFromUri(uri);
    debugPrint('[InviteLink] link recebido (convite: ${token != null})');
    if (token == null) return;
    await _savePending(token);
    await promptIfPending();
  }

  Future<void> _savePending(String token) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_pendingKey, token);
    } catch (_) {}
  }

  Future<void> _clearPending() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_pendingKey);
    } catch (_) {}
  }

  Future<void> _checkInstallReferrer() async {
    if (!Platform.isAndroid) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      if (prefs.getBool(_referrerCheckedKey) ?? false) return;
      await prefs.setBool(_referrerCheckedKey, true);
      final details = await PlayInstallReferrer.installReferrer;
      final token = tokenFromReferrer(details.installReferrer);
      if (token != null) await prefs.setString(_pendingKey, token);
    } catch (_) {
      // Instalado fora da Play (debug) ou servico indisponivel.
    }
  }

  /// Mostra o convite guardado, se houver. Chamado ao abrir o app, ao
  /// receber um link e depois de entrar na conta.
  Future<void> promptIfPending() async {
    if (_prompting || !Get.isRegistered<IFamilyService>()) return;
    String? token;
    try {
      final prefs = await SharedPreferences.getInstance();
      token = prefs.getString(_pendingKey);
    } catch (_) {}
    if (token == null) return;

    _prompting = true;
    try {
      // Deixa a navegacao (login -> inicio) terminar antes do dialogo.
      await Future<void>.delayed(const Duration(milliseconds: 700));
      final context = Get.context;
      if (context == null || !context.mounted) return;

      final family = Get.find<IFamilyService>();
      final result = await family.getInviteByToken(token);
      if (!result.isSuccess) return; // sem internet: tenta na proxima
      final invite = result.data;
      if (invite == null || !invite.isValid) {
        await _clearPending();
        _snack('Este convite não está mais valendo. Peça um novo.');
        return;
      }

      final auth = Get.find<AuthController>();
      if (!auth.isLoggedIn.value) {
        await _askToLogin(invite);
        return; // continua guardado ate entrar na conta
      }
      if (family.context.hasFamily) {
        await _clearPending();
        _snack('Você já participa de uma Família.');
        return;
      }
      await _askToAccept(invite);
    } finally {
      _prompting = false;
    }
  }

  String _who(FamilyLinkInvite invite) => invite.invitedByName ?? 'Alguém';

  Future<void> _askToLogin(FamilyLinkInvite invite) async {
    final go = await Get.dialog<bool>(
      AlertDialog(
        title: Text('Convite para a Família ${invite.familyName}'),
        content: Text(
          '${_who(invite)} convidou você. Entre na sua conta (ou crie uma '
          'grátis) para aceitar.',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Agora não'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(minimumSize: const Size(0, 44)),
            onPressed: () => Get.back(result: true),
            child: const Text('Entrar'),
          ),
        ],
      ),
    );
    if (go == true) Get.toNamed(AppRoutes.login);
  }

  Future<void> _askToAccept(FamilyLinkInvite invite) async {
    final accept = await Get.dialog<bool>(
      AlertDialog(
        title: Text('Entrar na Família ${invite.familyName}?'),
        content: Text(
          '${_who(invite)} convidou você como ${invite.role.label.toLowerCase()}. '
          '${invite.role == FamilyRole.viewer ? 'Você vai acompanhar a agenda da família.' : 'Vocês vão ver e organizar a mesma agenda.'}',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Recusar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(minimumSize: const Size(0, 44)),
            onPressed: () => Get.back(result: true),
            child: const Text('Aceitar'),
          ),
        ],
      ),
    );
    if (accept == null) return; // fechou: pergunta de novo depois
    await _clearPending();
    if (!accept) return;

    final result = await Get.find<IFamilyService>().acceptInviteByToken(
      invite.token,
    );
    if (!result.isSuccess) {
      _snack(result.errorMessage ?? 'Não foi possível aceitar o convite.');
      return;
    }
    _snack('Bem-vindo(a) à Família ${invite.familyName}!');
    if (Get.isRegistered<ISyncService>()) {
      unawaited(Get.find<ISyncService>().syncNow());
    }
    final context = Get.context;
    if (context != null && context.mounted) await offerMoveToFamily(context);
  }

  void _snack(String message) {
    final context = Get.context;
    if (context == null || !context.mounted) return;
    ScaffoldMessenger.maybeOf(
      context,
    )?.showSnackBar(SnackBar(content: Text(message)));
  }
}

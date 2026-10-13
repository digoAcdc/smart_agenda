import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:uuid/uuid.dart';

import '../../core/result/result.dart';
import '../../core/routes/app_routes.dart';
import '../../core/theme/design_tokens.dart';
import '../../core/utils/form_validators.dart';
import '../../domain/entities/family.dart';
import '../../domain/repositories/i_family_service.dart';
import '../../domain/repositories/i_sync_service.dart';
import '../controllers/auth_controller.dart';
import '../widgets/ui_primitives.dart';
import '../utils/move_to_family_prompt.dart';

/// Familia: pessoas (com papeis), filhos, convites e situacao da assinatura.
class FamilyPage extends StatefulWidget {
  const FamilyPage({super.key});

  @override
  State<FamilyPage> createState() => _FamilyPageState();
}

class _FamilyPageState extends State<FamilyPage> {
  final _family = Get.find<IFamilyService>();
  final _auth = Get.find<AuthController>();
  final _createFormKey = GlobalKey<FormState>();
  final _familyNameCtrl = TextEditingController();
  final _nicknameCtrl = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _familyNameCtrl.dispose();
    _nicknameCtrl.dispose();
    super.dispose();
  }

  String? get _myUserId => _family.currentUserId;

  @override
  void initState() {
    super.initState();
    if (_auth.isLoggedIn.value) _family.refresh();
  }

  Future<bool> _run(
    Future<Result<void>> Function() action, {
    String? success,
  }) async {
    setState(() => _busy = true);
    final result = await action();
    if (!mounted) return result.isSuccess;
    setState(() => _busy = false);
    final messenger = ScaffoldMessenger.of(context);
    if (result.isSuccess) {
      if (success != null) {
        messenger.showSnackBar(SnackBar(content: Text(success)));
      }
      if (Get.isRegistered<ISyncService>()) Get.find<ISyncService>().syncNow();
    } else {
      messenger.showSnackBar(
        SnackBar(content: Text(result.errorMessage ?? 'Erro.')),
      );
    }
    return result.isSuccess;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Família')),
      body: SafeArea(
        child: Obx(() {
          if (!_auth.isLoggedIn.value) return _buildLoggedOut(context);
          final ctx = _family.context;
          return RefreshIndicator(
            onRefresh: _family.refresh,
            child: ListView(
              padding: const EdgeInsets.only(bottom: 120, top: 8),
              children: [
                if (_busy || _family.loading)
                  const LinearProgressIndicator(minHeight: 2),
                if (ctx.hasFamily)
                  ..._buildFamily(context, ctx)
                else
                  ..._buildNoFamily(context, ctx),
              ],
            ),
          );
        }),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Sem conta / sem familia
  // ---------------------------------------------------------------------------

  Widget _buildLoggedOut(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(DesignTokens.spaceMd),
      children: [
        _intro(context),
        const SizedBox(height: DesignTokens.spaceLg),
        FilledButton(
          onPressed: () =>
              Get.toNamed(AppRoutes.login, arguments: {'from': 'family'}),
          child: const Text('Entrar na minha conta'),
        ),
        const SizedBox(height: DesignTokens.spaceSm),
        OutlinedButton(
          onPressed: () => Get.toNamed(AppRoutes.register),
          child: const Text('Criar conta grátis'),
        ),
        const SizedBox(height: DesignTokens.spaceSm),
        Text(
          'Foi convidado para uma Família? Entre com o e-mail que recebeu o convite.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }

  Widget _intro(BuildContext context) {
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Uma agenda para a rotina da família',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: DesignTokens.spaceXs),
        Text(
          'Pais, avós e quem mais ajuda veem a mesma agenda: provas, consultas, '
          'atividades de cada filho e compromissos da família. Quem altera, '
          'todo mundo vê na hora.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: muted),
        ),
      ],
    );
  }

  List<Widget> _buildNoFamily(BuildContext context, FamilyContext ctx) {
    return [
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        child: _intro(context),
      ),
      if (_family.myInvites.isNotEmpty) ...[
        _sectionTitle(context, 'Convites para você'),
        for (final invite in _family.myInvites) _inviteForMe(context, invite),
      ],
      if (ctx.hasPro)
        _createFamilyCard(context)
      else
        AppSurfaceCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.workspace_premium_outlined,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Família é um recurso Pro',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
              ),
              const SizedBox(height: DesignTokens.spaceXs),
              const Text(
                '• Agenda compartilhada com até 5 pessoas\n'
                '• Vários filhos, cada um com sua rotina\n'
                '• Permissões: administrador, editor e visualizador\n'
                '• Sincronização entre aparelhos e sem anúncios\n'
                'Quem você convidar não precisa assinar.',
              ),
              const SizedBox(height: DesignTokens.spaceSm),
              FilledButton(
                onPressed: () => Get.toNamed(AppRoutes.upgrade),
                child: const Text('Conhecer o Pro'),
              ),
            ],
          ),
        ),
      if (_family.myInvites.isEmpty)
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'Se alguém te convidar, o convite aparece aqui '
            '(${_auth.userEmail.value ?? 'seu e-mail'}).',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
    ];
  }

  Widget _inviteForMe(BuildContext context, FamilyInvite invite) {
    return AppSurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            invite.familyName ?? 'Família',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 4),
          Text(
            '${invite.invitedByName ?? 'Alguém'} convidou você como ${invite.role.label.toLowerCase()}.',
          ),
          Text(
            invite.role.description,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: DesignTokens.spaceSm),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: _busy
                    ? null
                    : () => _run(() => _family.declineInvite(invite.id)),
                child: const Text('Recusar'),
              ),
              const SizedBox(width: 8),
              FilledButton(
                style: FilledButton.styleFrom(minimumSize: const Size(0, 44)),
                onPressed: _busy
                    ? null
                    : () async {
                        final nickname = await _askText(
                          context,
                          title: 'Como você quer aparecer?',
                          label: 'Ex.: Vovó, Tia Ana (opcional)',
                        );
                        if (nickname == null) return;
                        final ok = await _run(
                          () => _family.acceptInvite(
                            invite.id,
                            nickname: nickname,
                          ),
                          success:
                              'Bem-vindo(a) à ${invite.familyName ?? 'Família'}!',
                        );
                        if (ok && context.mounted) {
                          await offerMoveToFamily(context);
                        }
                      },
                child: const Text('Aceitar'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _createFamilyCard(BuildContext context) {
    return AppSurfaceCard(
      child: Form(
        key: _createFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Criar minha Família',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: DesignTokens.spaceSm),
            TextFormField(
              controller: _familyNameCtrl,
              decoration: const InputDecoration(
                labelText: 'Nome da Família',
                hintText: 'Família Silva',
                border: OutlineInputBorder(),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Informe um nome' : null,
            ),
            const SizedBox(height: DesignTokens.spaceSm),
            TextFormField(
              controller: _nicknameCtrl,
              decoration: const InputDecoration(
                labelText: 'Como você aparece (opcional)',
                hintText: 'Papai, Mamãe...',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: DesignTokens.spaceSm),
            FilledButton(
              onPressed: _busy
                  ? null
                  : () async {
                      if (_createFormKey.currentState?.validate() != true) {
                        return;
                      }
                      final ok = await _run(
                        () => _family.createFamily(
                          _familyNameCtrl.text,
                          nickname: _nicknameCtrl.text,
                        ),
                        success:
                            'Família criada! Agora convide as pessoas e cadastre os filhos.',
                      );
                      if (ok && context.mounted) {
                        await offerMoveToFamily(context);
                      }
                    },
              child: const Text('Criar Família'),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Com familia
  // ---------------------------------------------------------------------------

  List<Widget> _buildFamily(BuildContext context, FamilyContext ctx) {
    final scheme = Theme.of(context).colorScheme;
    final owner = _family.members.firstWhereOrNull((m) => m.isOwner);
    return [
      AppSurfaceCard(
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: scheme.primaryContainer,
              child: Icon(
                Icons.family_restroom,
                color: scheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(width: DesignTokens.spaceSm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    ctx.familyName ?? 'Família',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    '${ctx.myRole?.label ?? ''} · ${ctx.memberCount} de ${ctx.maxMembers} pessoas',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            if (ctx.canAdmin)
              IconButton(
                tooltip: 'Renomear',
                icon: const Icon(Icons.edit_outlined),
                onPressed: () async {
                  final name = await _askText(
                    context,
                    title: 'Nome da Família',
                    initial: ctx.familyName,
                    required: true,
                  );
                  if (name != null) {
                    await _run(() => _family.renameFamily(name));
                  }
                },
              ),
          ],
        ),
      ),
      if (!ctx.isActive)
        AppSurfaceCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.lock_clock_outlined, color: scheme.error),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Agenda da Família só para consulta',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                ctx.isOwner
                    ? 'Sua assinatura Pro não está ativa. Todos continuam vendo a agenda, '
                          'mas ninguém consegue editar até a renovação. Nenhum dado foi apagado.'
                    : 'A assinatura Pro de ${owner?.label ?? 'quem criou a Família'} não está ativa. '
                          'Você continua vendo a agenda, mas as alterações estão pausadas. '
                          'Nenhum dado foi apagado.',
              ),
              if (ctx.isOwner) ...[
                const SizedBox(height: DesignTokens.spaceSm),
                FilledButton(
                  onPressed: () => Get.toNamed(AppRoutes.upgrade),
                  child: const Text('Renovar Pro'),
                ),
              ],
            ],
          ),
        ),
      _sectionTitle(context, 'Pessoas'),
      for (final m in _family.members) _memberTile(context, ctx, m),
      if (ctx.isAdmin)
        for (final invite in _family.familyInvites)
          _pendingInviteTile(context, ctx, invite),
      if (ctx.canAdmin)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: ctx.availableSlots > 0
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    FilledButton.icon(
                      onPressed: _busy
                          ? null
                          : () => _inviteByLink(context, ctx),
                      icon: const Icon(Icons.chat_outlined),
                      label: const Text('Convidar pelo WhatsApp'),
                    ),
                    const SizedBox(height: DesignTokens.spaceSm),
                    OutlinedButton.icon(
                      onPressed: _busy
                          ? null
                          : () => _showInviteDialog(context, ctx),
                      icon: const Icon(Icons.mail_outline),
                      label: const Text('Convidar por e-mail'),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${ctx.availableSlots} vaga${ctx.availableSlots == 1 ? '' : 's'} na Família',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                )
              : Text(
                  'Limite de ${ctx.maxMembers} pessoas atingido.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
        ),
      _sectionTitle(context, 'Filhos'),
      if (_family.children.isEmpty)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            ctx.canAdmin
                ? 'Cadastre os filhos para organizar a rotina de cada um.'
                : 'Nenhum filho cadastrado ainda.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
      for (final c in _family.children) _childTile(context, ctx, c),
      if (ctx.canAdmin)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: OutlinedButton.icon(
            onPressed: _busy
                ? null
                : () => _showChildDialog(context, ctx, null),
            icon: const Icon(Icons.child_care_outlined),
            label: const Text('Adicionar filho'),
          ),
        ),
      if (ctx.isAdmin && _family.allChildren.any((c) => c.isArchived))
        ExpansionTile(
          title: const Text('Filhos arquivados'),
          children: [
            for (final c in _family.allChildren.where((c) => c.isArchived))
              ListTile(
                title: Text(c.name),
                trailing: TextButton(
                  onPressed: ctx.canAdmin
                      ? () => _run(() => _family.setChildArchived(c.id, false))
                      : null,
                  child: const Text('Restaurar'),
                ),
              ),
          ],
        ),
      if (ctx.canEditAgenda)
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 0),
          child: OutlinedButton.icon(
            onPressed: _busy
                ? null
                : () => offerMoveToFamily(context, askEvenIfEmpty: true),
            icon: const Icon(Icons.drive_file_move_outline),
            label: const Text('Levar minha agenda e grades para a Família'),
          ),
        ),
      const SizedBox(height: DesignTokens.spaceLg),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: ctx.isOwner
            ? TextButton.icon(
                style: TextButton.styleFrom(foregroundColor: scheme.error),
                onPressed: _busy
                    ? null
                    : () => _confirmDeleteFamily(context, ctx),
                icon: const Icon(Icons.delete_outline),
                label: const Text('Excluir Família'),
              )
            : TextButton.icon(
                style: TextButton.styleFrom(foregroundColor: scheme.error),
                onPressed: _busy
                    ? null
                    : () async {
                        final ok = await _confirm(
                          context,
                          title: 'Sair da Família?',
                          message:
                              'Você deixará de ver a agenda da ${ctx.familyName}. '
                              'Os eventos continuam na Família.',
                          action: 'Sair',
                        );
                        if (ok) {
                          await _run(
                            _family.leave,
                            success: 'Você saiu da Família.',
                          );
                        }
                      },
                icon: const Icon(Icons.logout),
                label: const Text('Sair da Família'),
              ),
      ),
    ];
  }

  Widget _memberTile(BuildContext context, FamilyContext ctx, FamilyMember m) {
    final isMe = m.userId == _myUserId;
    final subtitle = [
      m.role.label,
      if (m.isOwner) 'Dono da assinatura',
      if (m.nickname != null && m.displayName != null) m.displayName!,
    ].join(' · ');
    final canManage = ctx.canAdmin && !m.isOwner && !isMe;
    return AppSurfaceCard(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: CircleAvatar(child: Text(_initial(m.label))),
        title: Text(isMe ? '${m.label} (você)' : m.label),
        subtitle: Text(subtitle),
        trailing: (canManage || isMe)
            ? PopupMenuButton<String>(
                onSelected: (v) async {
                  if (v == 'nickname') {
                    final nick = await _askText(
                      context,
                      title: 'Como você aparece na Família',
                      initial: m.nickname,
                    );
                    if (nick != null) {
                      await _run(() => _family.updateMyNickname(nick));
                    }
                  } else if (v == 'remove') {
                    final ok = await _confirm(
                      context,
                      title: 'Remover ${m.label}?',
                      message:
                          'A pessoa deixará de ver a agenda da Família. '
                          'Os eventos que ela criou continuam na agenda.',
                      action: 'Remover',
                    );
                    if (ok) await _run(() => _family.removeMember(m.userId));
                  } else {
                    final role = FamilyRole.values.byName(v);
                    await _run(
                      () => _family.changeRole(m.userId, role),
                      success:
                          '${m.label} agora é ${role.label.toLowerCase()}.',
                    );
                  }
                },
                itemBuilder: (_) => [
                  if (isMe)
                    const PopupMenuItem(
                      value: 'nickname',
                      child: Text('Alterar como apareço'),
                    ),
                  if (canManage)
                    for (final role in FamilyRole.values)
                      if (role != m.role)
                        PopupMenuItem(
                          value: role.name,
                          child: Text('Tornar ${role.label.toLowerCase()}'),
                        ),
                  if (canManage)
                    const PopupMenuItem(
                      value: 'remove',
                      child: Text('Remover da Família'),
                    ),
                ],
              )
            : null,
      ),
    );
  }

  Widget _pendingInviteTile(
    BuildContext context,
    FamilyContext ctx,
    FamilyInvite invite,
  ) {
    return AppSurfaceCard(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: CircleAvatar(
          child: Icon(
            invite.email == null ? Icons.link_rounded : Icons.mail_outline,
          ),
        ),
        title: Text(invite.email ?? 'Convite por link'),
        subtitle: Text('Convite pendente · ${invite.role.label}'),
        trailing: TextButton(
          onPressed: _busy
              ? null
              : () => _run(() => _family.revokeInvite(invite.id)),
          child: const Text('Cancelar'),
        ),
      ),
    );
  }

  Widget _childTile(BuildContext context, FamilyContext ctx, FamilyChild c) {
    final color =
        _parseColor(c.colorHex) ??
        Theme.of(context).colorScheme.secondaryContainer;
    final age = _age(c.birthDate);
    return AppSurfaceCard(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: CircleAvatar(
          backgroundColor: color,
          child: Text(
            _initial(c.name),
            style: const TextStyle(color: Colors.white),
          ),
        ),
        title: Text(c.name),
        subtitle: age == null ? null : Text('$age ano${age == 1 ? '' : 's'}'),
        trailing: ctx.canAdmin
            ? PopupMenuButton<String>(
                onSelected: (v) async {
                  if (v == 'edit') {
                    await _showChildDialog(context, ctx, c);
                  } else {
                    final ok = await _confirm(
                      context,
                      title: 'Arquivar ${c.name}?',
                      message:
                          'Os eventos de ${c.name} continuam na agenda. '
                          'Você pode restaurar depois.',
                      action: 'Arquivar',
                    );
                    if (ok) {
                      await _run(() => _family.setChildArchived(c.id, true));
                    }
                  }
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'edit', child: Text('Editar')),
                  PopupMenuItem(value: 'archive', child: Text('Arquivar')),
                ],
              )
            : null,
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Dialogos
  // ---------------------------------------------------------------------------

  /// Gera um link de convite (1 pessoa, 7 dias) e abre o WhatsApp com a
  /// mensagem pronta; sem WhatsApp, abre o compartilhar do Android.
  Future<void> _inviteByLink(BuildContext context, FamilyContext ctx) async {
    final role = await showModalBottomSheet<FamilyRole>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(24, 0, 24, 8),
              child: Text(
                'Como a pessoa vai participar?',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
              ),
            ),
            for (final r in const [FamilyRole.editor, FamilyRole.viewer])
              ListTile(
                leading: Icon(
                  r == FamilyRole.editor
                      ? Icons.edit_calendar_outlined
                      : Icons.visibility_outlined,
                ),
                title: Text(r.label),
                subtitle: Text(r.description),
                onTap: () => Navigator.pop(sheetContext, r),
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (role == null || !context.mounted) return;

    setState(() => _busy = true);
    final result = await _family.createInviteLink(role);
    if (!mounted || !context.mounted) return;
    setState(() => _busy = false);
    if (!result.isSuccess || result.data == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.errorMessage ?? 'Erro ao criar convite.'),
        ),
      );
      return;
    }
    final link = 'https://rbarbosa.tech/convite/${result.data}';
    final text =
        'Oi! Te convidei para a Família ${ctx.familyName ?? ''} no Smart Agenda, '
        'para a gente organizar a agenda junto. Toque no link para entrar: $link';
    final whatsApp = Uri.parse(
      'https://wa.me/?text=${Uri.encodeComponent(text)}',
    );
    final opened = await launchUrl(
      whatsApp,
      mode: LaunchMode.externalApplication,
    ).catchError((_) => false);
    if (!opened) await SharePlus.instance.share(ShareParams(text: text));
    if (!mounted || !context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Convite criado. O link vale para 1 pessoa por 7 dias.'),
      ),
    );
  }

  Future<void> _showInviteDialog(
    BuildContext context,
    FamilyContext ctx,
  ) async {
    final emailCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();
    var role = FamilyRole.editor;
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setLocal) => AlertDialog(
          title: const Text('Convidar para a Família'),
          scrollable: true,
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: emailCtrl,
                  autofocus: true,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'E-mail da pessoa',
                  ),
                  validator: (v) => emailValidator(v, required: true),
                ),
                const SizedBox(height: DesignTokens.spaceSm),
                RadioGroup<FamilyRole>(
                  groupValue: role,
                  onChanged: (v) => setLocal(() => role = v ?? role),
                  child: Column(
                    children: [
                      for (final r in FamilyRole.values)
                        RadioListTile<FamilyRole>(
                          contentPadding: EdgeInsets.zero,
                          dense: true,
                          visualDensity: VisualDensity.compact,
                          value: r,
                          title: Text(r.label),
                          subtitle: Text(
                            r.description,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                  ),
                ),
                Text(
                  'A pessoa entra com uma conta gratuita usando este e-mail. '
                  'Ela não precisa assinar o Pro.',
                  style: Theme.of(dialogContext).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(minimumSize: const Size(0, 44)),
              onPressed: () {
                if (formKey.currentState?.validate() == true) {
                  Navigator.pop(dialogContext, true);
                }
              },
              child: const Text('Convidar'),
            ),
          ],
        ),
      ),
    );
    if (ok == true) {
      await _run(
        () => _family.invite(emailCtrl.text, role),
        success: 'Convite enviado. Ele aparece para a pessoa ao entrar no app.',
      );
    }
  }

  Future<void> _showChildDialog(
    BuildContext context,
    FamilyContext ctx,
    FamilyChild? child,
  ) async {
    final nameCtrl = TextEditingController(text: child?.name);
    DateTime? birth = child?.birthDate;
    String? colorHex =
        child?.colorHex ??
        _toHex(
          DesignTokens.groupPalette[_family.allChildren.length %
              DesignTokens.groupPalette.length],
        );
    final formKey = GlobalKey<FormState>();
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setLocal) => AlertDialog(
          title: Text(
            child == null ? 'Adicionar filho' : 'Editar ${child.name}',
          ),
          scrollable: true,
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: nameCtrl,
                  autofocus: child == null,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(labelText: 'Nome'),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Informe o nome' : null,
                ),
                const SizedBox(height: DesignTokens.spaceSm),
                OutlinedButton.icon(
                  onPressed: () async {
                    final now = DateTime.now();
                    final picked = await showDatePicker(
                      context: dialogContext,
                      initialDate: birth ?? DateTime(now.year - 6),
                      firstDate: DateTime(now.year - 30),
                      lastDate: now,
                    );
                    if (picked != null) setLocal(() => birth = picked);
                  },
                  icon: const Icon(Icons.cake_outlined),
                  label: Text(
                    birth == null
                        ? 'Data de nascimento (opcional)'
                        : '${birth!.day.toString().padLeft(2, '0')}/${birth!.month.toString().padLeft(2, '0')}/${birth!.year}',
                  ),
                ),
                const SizedBox(height: DesignTokens.spaceSm),
                Wrap(
                  spacing: 8,
                  children: [
                    for (final c in DesignTokens.groupPalette)
                      GestureDetector(
                        onTap: () => setLocal(() => colorHex = _toHex(c)),
                        child: CircleAvatar(
                          radius: 14,
                          backgroundColor: c,
                          child: colorHex == _toHex(c)
                              ? const Icon(
                                  Icons.check,
                                  size: 16,
                                  color: Colors.white,
                                )
                              : null,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(minimumSize: const Size(0, 44)),
              onPressed: () {
                if (formKey.currentState?.validate() == true) {
                  Navigator.pop(dialogContext, true);
                }
              },
              child: const Text('Salvar'),
            ),
          ],
        ),
      ),
    );
    if (ok != true) return;
    final saved = FamilyChild(
      id: child?.id ?? const Uuid().v4(),
      familyId: ctx.familyId!,
      name: nameCtrl.text.trim(),
      birthDate: birth,
      colorHex: colorHex,
      avatarUrl: child?.avatarUrl,
      notes: child?.notes,
    );
    await _run(() => _family.saveChild(saved, isNew: child == null));
  }

  Future<void> _confirmDeleteFamily(
    BuildContext context,
    FamilyContext ctx,
  ) async {
    final ok = await _confirm(
      context,
      title: 'Excluir a ${ctx.familyName}?',
      message:
          'Isto apaga definitivamente a agenda da Família, os filhos cadastrados '
          'e remove todas as pessoas. Não é possível desfazer.\n\n'
          'Se a intenção é só parar de pagar, não exclua: a agenda fica disponível para consulta.',
      action: 'Excluir definitivamente',
    );
    if (ok) await _run(_family.deleteFamily, success: 'Família excluída.');
  }

  Future<bool> _confirm(
    BuildContext context, {
    required String title,
    required String message,
    required String action,
  }) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(minimumSize: const Size(0, 44)),
            onPressed: () => Navigator.pop(c, true),
            child: Text(action),
          ),
        ],
      ),
    );
    return ok == true;
  }

  /// Retorna o texto digitado ('' se vazio e opcional) ou null se cancelou.
  Future<String?> _askText(
    BuildContext context, {
    required String title,
    String? label,
    String? initial,
    bool required = false,
  }) {
    final ctrl = TextEditingController(text: initial);
    return showDialog<String>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: InputDecoration(hintText: label),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(minimumSize: const Size(0, 44)),
            onPressed: () {
              if (required && ctrl.text.trim().isEmpty) return;
              Navigator.pop(c, ctrl.text.trim());
            },
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(BuildContext context, String text) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 18, 16, 6),
    child: Text(text, style: Theme.of(context).textTheme.titleMedium),
  );

  String _initial(String s) =>
      s.trim().isEmpty ? '?' : s.trim()[0].toUpperCase();

  int? _age(DateTime? birth) {
    if (birth == null) return null;
    final now = DateTime.now();
    var age = now.year - birth.year;
    if (now.month < birth.month ||
        (now.month == birth.month && now.day < birth.day)) {
      age--;
    }
    return age;
  }

  String _toHex(Color c) =>
      '#${(c.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}';

  Color? _parseColor(String? hex) {
    if (hex == null) return null;
    final v = int.tryParse(hex.replaceFirst('#', ''), radix: 16);
    return v == null ? null : Color(0xFF000000 | v);
  }
}

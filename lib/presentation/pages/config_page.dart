import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../core/config/supabase_config.dart';
import '../../core/routes/app_routes.dart';
import '../../core/theme/design_tokens.dart';
import '../../domain/repositories/i_auth_service.dart';
import '../../domain/repositories/i_plan_service.dart';
import '../../domain/repositories/i_user_data_deletion_service.dart';
import '../controllers/agenda_controller.dart';
import '../controllers/auth_controller.dart';
import '../controllers/class_group_controller.dart';
import '../controllers/class_schedule_controller.dart';
import '../controllers/groups_controller.dart';
import '../controllers/note_controller.dart';
import '../controllers/notifications_controller.dart';
import '../widgets/section_header.dart';
import '../widgets/ui_primitives.dart';
import '../controllers/billing_controller.dart';
import '../controllers/ads_controller.dart';

class ConfigPage extends StatefulWidget {
  const ConfigPage({super.key});

  @override
  State<ConfigPage> createState() => _ConfigPageState();
}

class _ConfigPageState extends State<ConfigPage> {
  bool _deletingData = false;
  String _versionText = 'Smart Agenda';

  Worker? _authWorker;

  @override
  void initState() {
    super.initState();
    _loadVersionInfo();
    _checkPlanStatus();
    _authWorker = ever(
      Get.find<AuthController>().isLoggedIn,
      (_) => _checkPlanStatus(),
    );
  }

  @override
  void dispose() {
    _authWorker?.dispose();
    super.dispose();
  }

  Future<void> _loadVersionInfo() async {
    try {
      final info = await PackageInfo.fromPlatform();
      if (!mounted) return;
      setState(() {
        _versionText = 'Smart Agenda v${info.version} (${info.buildNumber})';
      });
    } catch (_) {}
  }

  Future<void> _checkPlanStatus() async {
    final planService = Get.find<IPlanService>();
    final authController = Get.find<AuthController>();
    final authService = Get.find<IAuthService>();
    String? email;
    if (authController.isLoggedIn.value) {
      final authResult = await authService.getCurrentUser();
      email = authResult.data?.email;
    }
    final isPremium = await planService.isPremium();
    if (authController.isLoggedIn.value) {
      authController.userEmail.value = email;
      authController.isPremium.value = isPremium;
    }
  }

  void _openPrivacyPolicy() {
    Get.toNamed(AppRoutes.privacyPolicy);
  }

  Future<void> _refreshControllersAfterDataDeletion() async {
    await Get.find<AgendaController>().refreshCurrentData();
    await Get.find<GroupsController>().loadGroups();
    await Get.find<NoteController>().loadNotes();
    await Get.find<ClassScheduleController>().load();
    final classGroup = Get.find<ClassGroupController>();
    classGroup.students.clear();
    classGroup.selectedGroup.value = null;
    await classGroup.loadGroups();
    if (Get.isRegistered<NotificationsController>()) {
      await Get.find<NotificationsController>().load();
    }
  }

  Future<void> _runDeleteAllDataFlow() async {
    final auth = Get.find<AuthController>();
    final loggedIn = auth.isLoggedIn.value;
    final hasCloud = SupabaseConfig.isConfigured && loggedIn;

    final goOn = await Get.dialog<bool>(
      barrierDismissible: false,
      AlertDialog(
        title: const Text('Apagar todos os dados'),
        content: Text(
          hasCloud
              ? 'Isso apaga permanentemente no seu aparelho e na nuvem: eventos, '
                    'grupos, anotações, notificações e turmas. Se você participa de '
                    'uma Família, você sai dela (os eventos da Família continuam com ela). '
                    'Sua conta de login continua ativa.\n\n'
                    'Esta ação não pode ser desfeita.'
              : 'Isso apaga permanentemente no seu aparelho: eventos, grupos, '
                    'anotações e demais dados salvos localmente.\n\n'
                    'Esta ação não pode ser desfeita.',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(minimumSize: const Size(0, 44)),
            onPressed: () => Get.back(result: true),
            child: const Text('Continuar'),
          ),
        ],
      ),
    );
    if (goOn != true || !mounted) return;

    final confirmController = TextEditingController();
    final okTyped = await Get.dialog<bool>(
      barrierDismissible: false,
      AlertDialog(
        title: const Text('Confirmar'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Digite APAGAR para confirmar.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: confirmController,
              autofocus: true,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(
                labelText: 'Confirmacao',
                hintText: 'APAGAR',
              ),
              onSubmitted: (_) {
                if (confirmController.text.trim() == 'APAGAR') {
                  Get.back(result: true);
                }
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              minimumSize: const Size(0, 44),
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            onPressed: () {
              if (confirmController.text.trim() == 'APAGAR') {
                Get.back(result: true);
              }
            },
            child: const Text('Apagar tudo'),
          ),
        ],
      ),
    );
    // Nao dispor no mesmo tick do fechamento do dialog: o TextField ainda notifica o foco.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      confirmController.dispose();
    });
    if (okTyped != true || !mounted) return;

    setState(() => _deletingData = true);
    try {
      final result = await Get.find<IUserDataDeletionService>()
          .deleteAllUserData();
      if (!mounted) return;
      if (!result.isSuccess) {
        Get.snackbar(
          'Não foi possível apagar',
          result.errorMessage ?? 'Tente novamente.',
          snackPosition: SnackPosition.BOTTOM,
        );
        return;
      }
      await _refreshControllersAfterDataDeletion();
      await auth.signOut();
      Get.snackbar(
        'Dados apagados',
        'Seus dados foram removidos.',
        snackPosition: SnackPosition.BOTTOM,
      );
      Get.offAllNamed(AppRoutes.home);
    } finally {
      if (mounted) setState(() => _deletingData = false);
    }
  }

  void _openAreaPremium() {
    final authController = Get.find<AuthController>();
    if (authController.isLoggedIn.value) {
      Get.toNamed(AppRoutes.upgrade);
    } else {
      Get.toNamed(AppRoutes.login, arguments: {'from': 'premium'});
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.only(
          bottom: DesignTokens.bottomNavHeight + 16,
        ),
        children: [
          const SectionHeader(title: 'Configurações'),
          _buildProfileCard(),
          // Reage na hora a compra/renovacao (antes so lia ao abrir a tela).
          Obx(
            () => Get.find<AuthController>().isPremium.value
                ? const SizedBox.shrink()
                : _buildPremiumCard(),
          ),
          _buildPrivacySection(),
          _buildFooter(),
        ],
      ),
    );
  }

  Widget _buildProfileCard() {
    return AppSurfaceCard(
      child: Obx(() {
        final authController = Get.find<AuthController>();
        final isLoggedIn = authController.isLoggedIn.value;
        final email = authController.userEmail.value;
        final isPremium = authController.isPremium.value;

        if (isLoggedIn) {
          final scheme = Theme.of(context).colorScheme;
          // Pro em verde (ativo); Gratis em cinza.
          final badgeColor = isPremium ? scheme.primary : scheme.outline;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 26,
                    backgroundColor: scheme.surfaceContainerHigh,
                    child: Icon(
                      Icons.person,
                      size: 30,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // E-mail inteiro (quebra em 2 linhas se precisar).
                        Text(
                          email ?? 'Minha conta',
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.w700),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: badgeColor.withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                isPremium
                                    ? Icons.workspace_premium_rounded
                                    : Icons.person_outline_rounded,
                                size: 14,
                                color: badgeColor,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                isPremium ? 'Pro ativo' : 'Grátis',
                                style: Theme.of(context).textTheme.labelSmall
                                    ?.copyWith(
                                      color: badgeColor,
                                      fontWeight: FontWeight.w700,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () => _confirmSignOut(authController),
                  icon: const Icon(Icons.logout_rounded, size: 18),
                  label: const Text('Sair da conta'),
                ),
              ),
            ],
          );
        }

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            children: [
              Text(
                'Entre na sua conta',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: () => Get.toNamed(AppRoutes.login),
                icon: const Icon(Icons.login_rounded, size: 20),
                label: const Text('Entrar'),
              ),
            ],
          ),
        );
      }),
    );
  }

  Future<void> _confirmSignOut(AuthController authController) async {
    final ok = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Sair da conta?'),
        content: const Text(
          'Você pode entrar de novo quando quiser com o mesmo e-mail.',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(minimumSize: const Size(0, 44)),
            onPressed: () => Get.back(result: true),
            child: const Text('Sair'),
          ),
        ],
      ),
    );
    if (ok == true) await authController.signOut();
  }

  Widget _buildPremiumCard() {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.workspace_premium_outlined,
                color: scheme.onSurfaceVariant,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                'Plano Pro',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: scheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Preco real do Google Play (nada fixo no codigo).
          Obx(() {
            final price = Get.isRegistered<BillingController>()
                ? Get.find<BillingController>().productPrice.value
                : null;
            if (price == null) return const SizedBox.shrink();
            return Text(
              price,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
                color: scheme.onSurface,
              ),
            );
          }),
          const SizedBox(height: 8),
          Text(
            'Desbloqueie todo o potencial',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: scheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Família com agenda compartilhada, vários filhos, sincronização e zero anúncios.',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _openAreaPremium,
              child: const Text('Assinar o Pro'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrivacySection() {
    final danger = Theme.of(context).colorScheme.error;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            'PRIVACIDADE',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: Theme.of(context).colorScheme.outline,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
            ),
          ),
        ),
        AppSurfaceCard(
          child: Column(
            children: [
              // Exigido pelo Google onde o consentimento de anuncios e obrigatorio.
              Obx(() {
                final ads = Get.isRegistered<AdsController>()
                    ? Get.find<AdsController>()
                    : null;
                if (ads == null || !ads.privacyOptionsRequired.value) {
                  return const SizedBox.shrink();
                }
                return Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.privacy_tip_outlined),
                      title: const Text('Privacidade dos anúncios'),
                      subtitle: const Text('Rever o consentimento de anúncios'),
                      onTap: ads.showPrivacyOptions,
                    ),
                    const Divider(height: 1),
                  ],
                );
              }),
              // Acoes destrutivas recolhidas: continuam acessiveis, sem chamar
              // atencao na tela.
              Theme(
                data: Theme.of(
                  context,
                ).copyWith(dividerColor: Colors.transparent),
                child: ExpansionTile(
                  leading: const Icon(Icons.manage_accounts_outlined),
                  title: Text(
                    'Apagar dados ou excluir conta',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  childrenPadding: EdgeInsets.zero,
                  children: [
                    Opacity(
                      opacity: _deletingData ? 0.6 : 1,
                      child: InkWell(
                        onTap: _deletingData ? null : _runDeleteAllDataFlow,
                        borderRadius: BorderRadius.circular(
                          DesignTokens.radiusMd,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 12,
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: danger.withValues(alpha: 0.12),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.delete_forever_outlined,
                                  color: danger,
                                  size: 22,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Apagar todos os meus dados',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleSmall
                                          ?.copyWith(
                                            fontWeight: FontWeight.w600,
                                            color: danger,
                                          ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Remove dados do aparelho e da nuvem (se estiver logado). '
                                      'A conta de login permanece.',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                            color: Theme.of(
                                              context,
                                            ).colorScheme.onSurfaceVariant,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                              if (_deletingData)
                                const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              else
                                Icon(
                                  Icons.chevron_right,
                                  size: 24,
                                  color: danger,
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    if (Get.find<AuthController>().isLoggedIn.value) ...[
                      const Divider(height: 1),
                      InkWell(
                        onTap: _deletingData ? null : _runDeleteAccountFlow,
                        borderRadius: BorderRadius.circular(
                          DesignTokens.radiusMd,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 12,
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: danger.withValues(alpha: 0.12),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.person_remove_outlined,
                                  color: danger,
                                  size: 22,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Excluir minha conta',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleSmall
                                          ?.copyWith(
                                            fontWeight: FontWeight.w600,
                                            color: danger,
                                          ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Exclui a conta de login e todos os seus dados.',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                            color: Theme.of(
                                              context,
                                            ).colorScheme.onSurfaceVariant,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                              Icon(
                                Icons.chevron_right,
                                size: 24,
                                color: danger,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _runDeleteAccountFlow() async {
    final confirmCtrl = TextEditingController();
    final ok = await Get.dialog<bool>(
      StatefulBuilder(
        builder: (dialogContext, setLocal) => AlertDialog(
          title: const Text('Excluir minha conta'),
          scrollable: true,
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Isso exclui definitivamente a sua conta e os seus dados: agenda e '
                'grades pessoais, anotações, turmas, fotos e a participação na Família. '
                'Eventos que você criou na Família continuam com ela.\n\n'
                'Se você tem uma assinatura, cancele no Google Play: excluir a conta '
                'não cancela a cobrança.\n\n'
                'Para confirmar, digite EXCLUIR:',
              ),
              const SizedBox(height: 8),
              TextField(
                controller: confirmCtrl,
                autofocus: true,
                textCapitalization: TextCapitalization.characters,
                onChanged: (_) => setLocal(() {}),
                decoration: const InputDecoration(hintText: 'EXCLUIR'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Get.back(result: false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(dialogContext).colorScheme.error,
                minimumSize: const Size(0, 44),
              ),
              onPressed: confirmCtrl.text.trim().toUpperCase() == 'EXCLUIR'
                  ? () => Get.back(result: true)
                  : null,
              child: const Text('Excluir conta'),
            ),
          ],
        ),
      ),
      barrierDismissible: false,
    );
    if (ok != true || !mounted) return;

    setState(() => _deletingData = true);
    final result = await Get.find<IUserDataDeletionService>().deleteAccount();
    if (!mounted) return;
    setState(() => _deletingData = false);
    if (!result.isSuccess) {
      Get.snackbar(
        'Não foi possível excluir',
        result.errorMessage ?? 'Erro.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }
    try {
      await Get.find<AuthController>().signOut();
    } catch (_) {}
    Get.offAllNamed(AppRoutes.home);
    Get.snackbar(
      'Conta excluída',
      'Sua conta e seus dados foram excluídos.',
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  Widget _buildFooter() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Column(
        children: [
          Text(
            _versionText,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextButton(
                onPressed: _openPrivacyPolicy,
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  'Termos',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
              Text(' • ', style: Theme.of(context).textTheme.bodySmall),
              TextButton(
                onPressed: _openPrivacyPolicy,
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  'Privacidade',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

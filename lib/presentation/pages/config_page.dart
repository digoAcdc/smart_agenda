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
import '../widgets/ad_banner_widget.dart';
import '../widgets/ui_primitives.dart';

class ConfigPage extends StatefulWidget {
  const ConfigPage({super.key});

  @override
  State<ConfigPage> createState() => _ConfigPageState();
}

class _ConfigPageState extends State<ConfigPage> {
  bool _isPremium = false;
  bool _deletingData = false;
  String _versionText = 'Smart Agenda';

  Worker? _authWorker;

  @override
  void initState() {
    super.initState();
    _loadVersionInfo();
    _checkPlanStatus();
    _authWorker =
        ever(Get.find<AuthController>().isLoggedIn, (_) => _checkPlanStatus());
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
    if (!mounted) return;
    setState(() {
      _isPremium = isPremium;
    });
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
    final hasCloud =
        SupabaseConfig.isConfigured && loggedIn;

    final goOn = await Get.dialog<bool>(
      barrierDismissible: false,
      AlertDialog(
        title: const Text('Apagar todos os dados'),
        content: Text(
          hasCloud
              ? 'Isso apaga permanentemente no seu aparelho e na nuvem: eventos, '
                  'grupos, anotacoes, notificacoes, turmas e compartilhamentos. '
                  'Sua conta de login continua ativa.\n\n'
                  'Esta acao nao pode ser desfeita.'
              : 'Isso apaga permanentemente no seu aparelho: eventos, grupos, '
                  'anotacoes e demais dados salvos localmente.\n\n'
                  'Esta acao nao pode ser desfeita.',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
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
      final result = await Get.find<IUserDataDeletionService>().deleteAllUserData();
      if (!mounted) return;
      if (!result.isSuccess) {
        Get.snackbar(
          'Nao foi possivel apagar',
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

  void _handleCompartilharAgenda() {
    final authController = Get.find<AuthController>();
    if (authController.isLoggedIn.value) {
      Get.toNamed(AppRoutes.sharing);
      return;
    }
    Get.toNamed(AppRoutes.login, arguments: {'from': 'sharing'});
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
        padding: const EdgeInsets.only(bottom: DesignTokens.bottomNavHeight + 16),
        children: [
          _buildProfileCard(),
          if (!_isPremium) _buildPremiumCard(),
          _buildGeralSection(),
          _buildPrivacySection(),
          _buildFooter(),
          const AdBannerWidget(),
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
          return Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor:
                    Theme.of(context).colorScheme.surfaceContainerHigh,
                child: Icon(
                  Icons.person,
                  size: 32,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      email ?? 'Usuário',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (isPremium) ...[
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .colorScheme
                              .outline
                              .withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          'Premium',
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                color: Theme.of(context).colorScheme.outline,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              IconButton(
                onPressed: () async {
                  await authController.signOut();
                },
                icon: const Icon(Icons.logout_rounded),
                tooltip: 'Sair',
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
                  'Plano Premium',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: scheme.onSurface,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'R\$ 4,99 /mes',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: scheme.onSurface,
                  ),
            ),
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
              'Sincronizacao na nuvem, backups automaticos e zero anuncios.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _openAreaPremium,
                child: const Text('Tornar-se Premium'),
              ),
            ),
          ],
        ),
    );
  }

  Widget _buildAgendaActionTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    VoidCallback? onTap,
    bool loading = false,
    bool isPremiumLocked = false,
    double opacity = 1.0,
  }) {
    return Opacity(
      opacity: opacity,
      child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (isPremiumLocked)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .colorScheme
                              .outline
                              .withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.lock_outline,
                              size: 14,
                              color: Theme.of(context).colorScheme.outline,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Premium',
                              style: Theme.of(context)
                                  .textTheme
                                  .labelSmall
                                  ?.copyWith(
                                    color: Theme.of(context).colorScheme.outline,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
            ),
            if (loading)
              const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else
              Icon(
                Icons.chevron_right,
                size: 24,
                color: iconColor,
              ),
          ],
        ),
      ),
    ),
    );
  }

  Widget _buildGeralSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            'GERAL',
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
              _buildAgendaActionTile(
                icon: Icons.people_outline,
                iconColor: Theme.of(context).colorScheme.primary,
                title: 'Compartilhar Agenda',
                  subtitle: _isPremium
                      ? 'Convidar outros usuarios'
                      : 'Plano free: 1 compartilhamento ativo',
                onTap: () => _handleCompartilharAgenda(),
              ),
              if (Get.find<AuthController>().isLoggedIn.value &&
                  SupabaseConfig.isConfigured &&
                  Get.isRegistered<NotificationsController>()) ...[
                const Divider(height: 1),
                _buildAgendaActionTile(
                  icon: Icons.notifications_outlined,
                  iconColor: Theme.of(context).colorScheme.tertiary,
                  title: 'Resumos da agenda',
                  subtitle: 'Notificacoes diarias e semanais',
                  onTap: () => Get.toNamed(AppRoutes.notifications),
                ),
              ],
            ],
          ),
        ),
      ],
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
              Opacity(
                opacity: _deletingData ? 0.6 : 1,
                child: InkWell(
                  onTap: _deletingData ? null : _runDeleteAllDataFlow,
                  borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: danger.withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.delete_forever_outlined, color: danger, size: 22),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Apagar todos os meus dados',
                                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: danger,
                                    ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Remove dados do aparelho e da nuvem (se estiver logado). '
                                'A conta de login permanece.',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                                    ),
                              ),
                            ],
                          ),
                        ),
                        if (_deletingData)
                          const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        else
                          Icon(Icons.chevron_right, size: 24, color: danger),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
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
              Text(
                ' • ',
                style: Theme.of(context).textTheme.bodySmall,
              ),
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

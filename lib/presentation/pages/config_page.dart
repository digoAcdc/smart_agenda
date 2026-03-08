import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../core/routes/app_routes.dart';
import '../../core/theme/design_tokens.dart';
import '../../domain/repositories/i_auth_service.dart';
import '../../domain/repositories/i_plan_service.dart';
import '../controllers/agenda_transfer_controller.dart';
import '../controllers/auth_controller.dart';
import '../widgets/ui_primitives.dart';

class ConfigPage extends StatefulWidget {
  const ConfigPage({super.key});

  @override
  State<ConfigPage> createState() => _ConfigPageState();
}

class _ConfigPageState extends State<ConfigPage> {
  final transferController = Get.find<AgendaTransferController>();
  bool _isPremium = false;

  bool loadingPermission = true;
  bool notificationsEnabled = false;

  Worker? _authWorker;

  @override
  void initState() {
    super.initState();
    _loadPermissionStatus();
    _checkPlanStatus();
    _authWorker =
        ever(Get.find<AuthController>().isLoggedIn, (_) => _checkPlanStatus());
  }

  @override
  void dispose() {
    _authWorker?.dispose();
    super.dispose();
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

  Future<void> _loadPermissionStatus() async {
    final status = await Permission.notification.status;
    if (!mounted) return;
    setState(() {
      loadingPermission = false;
      notificationsEnabled = status.isGranted;
    });
  }

  Future<void> _handleNotificationToggle(bool enable) async {
    if (enable) {
      final status = await Permission.notification.request();
      if (!mounted) return;
      setState(() => notificationsEnabled = status.isGranted);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            status.isGranted
                ? 'Notificacoes ativadas.'
                : 'Permissao de notificacoes negada.',
          ),
        ),
      );
      return;
    }

    final opened = await openAppSettings();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          opened
              ? 'Desative as notificacoes nas configuracoes do sistema.'
              : 'Nao foi possivel abrir as configuracoes.',
        ),
      ),
    );
    await _loadPermissionStatus();
  }

  void _openPrivacyPolicy() {
    Get.toNamed(AppRoutes.privacyPolicy);
  }

  void _openAreaPremium() {
    final authController = Get.find<AuthController>();
    if (authController.isLoggedIn.value) {
      Get.toNamed(AppRoutes.upgrade);
    } else {
      Get.toNamed(AppRoutes.login, arguments: {'from': 'premium'});
    }
  }

  Future<void> _handleShareAgenda() async {
    final ok = await transferController.shareAgenda();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok
              ? (transferController.message.value ?? 'Agenda compartilhada.')
              : (transferController.message.value ??
                  'Nao foi possivel compartilhar a agenda.'),
        ),
      ),
    );
  }

  Future<void> _handleImportAgenda() async {
    final report = await transferController.importAgenda();
    if (!mounted) return;

    if (report == null) {
      final feedback = transferController.message.value;
      if (feedback != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(feedback)),
        );
      }
      return;
    }

    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Importacao concluida'),
          content: Text(
            'Grupos: +${report.createdGroups} novos, '
            '${report.updatedGroups} atualizados, ${report.skippedGroups} ignorados.\n'
            'Eventos: +${report.createdItems} novos, '
            '${report.updatedItems} atualizados, ${report.skippedItems} ignorados.\n'
            'Grade horaria: +${report.createdClassSlots} novos, '
            '${report.updatedClassSlots} atualizados, ${report.skippedClassSlots} ignorados.\n'
            'Lembretes reagendados: ${report.reScheduledReminders}.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Fechar'),
            ),
          ],
        );
      },
    );
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
          _buildPreferenciasSection(),
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
  }) {
    return InkWell(
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
              if (!_isPremium) ...[
                _buildAgendaActionTile(
                  icon: Icons.file_upload_outlined,
                  iconColor: Theme.of(context).colorScheme.primary,
                  title: 'Exportar Agenda',
                  subtitle: 'Salvar backup local (JSON)',
                  onTap: transferController.loading.value
                      ? null
                      : () => _handleShareAgenda(),
                  loading: transferController.loading.value,
                ),
                const Divider(height: 1),
                _buildAgendaActionTile(
                  icon: Icons.file_download_outlined,
                  iconColor: Theme.of(context).colorScheme.primary,
                  title: 'Importar Agenda',
                  subtitle: 'Restaurar de arquivo (JSON)',
                  onTap: transferController.loading.value
                      ? null
                      : () => _handleImportAgenda(),
                  loading: transferController.loading.value,
                ),
                const Divider(height: 1),
              ],
              _buildAgendaActionTile(
                icon: Icons.people_outline,
                iconColor: _isPremium
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.outline,
                title: 'Compartilhar Agenda',
                subtitle: 'Convidar outros usuarios',
                onTap: _isPremium ? () => Get.toNamed(AppRoutes.sharing) : null,
                isPremiumLocked: !_isPremium,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPreferenciasSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            'PREFERENCIAS',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: Theme.of(context).colorScheme.outline,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                ),
          ),
        ),
        AppSurfaceCard(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(6, 10, 6, 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 6),
                  leading: Icon(
                    notificationsEnabled
                        ? Icons.notifications_active_outlined
                        : Icons.notifications_off_outlined,
                  ),
                  title: const Text('Notificacoes'),
                  subtitle: Text(
                    loadingPermission
                        ? 'Verificando...'
                        : notificationsEnabled
                            ? 'Ativada'
                            : 'Desativada',
                  ),
                  trailing: loadingPermission
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Switch(
                          value: notificationsEnabled,
                          onChanged: _handleNotificationToggle,
                        ),
                ),
                if (!loadingPermission && !notificationsEnabled)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 2, 16, 10),
                    child: Text(
                      'Para receber alertas de eventos, ative as notificacoes.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
              ],
            ),
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
            'Smart Agenda v1.1.0',
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

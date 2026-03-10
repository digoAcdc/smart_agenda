import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../core/config/supabase_config.dart';
import '../../core/routes/app_routes.dart';
import '../controllers/auth_controller.dart';
import '../controllers/notifications_controller.dart';
import '../widgets/ui_primitives.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  bool _loadingPermission = true;
  bool _notificationsEnabled = false;

  @override
  void initState() {
    super.initState();
    _loadPermissionStatus();
  }

  Future<void> _loadPermissionStatus() async {
    final status = await Permission.notification.status;
    if (!mounted) return;
    setState(() {
      _loadingPermission = false;
      _notificationsEnabled = status.isGranted;
    });
  }

  Future<void> _handleNotificationToggle(bool enable) async {
    if (enable) {
      final status = await Permission.notification.request();
      if (!mounted) return;
      setState(() => _notificationsEnabled = status.isGranted);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            status.isGranted
                ? 'Notificações ativadas.'
                : 'Permissão de notificações negada.',
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
              ? 'Desative as notificações nas configurações do sistema.'
              : 'Não foi possível abrir as configurações.',
        ),
      ),
    );
    await _loadPermissionStatus();
  }

  @override
  Widget build(BuildContext context) {
    if (!SupabaseConfig.isConfigured || !Get.isRegistered<NotificationsController>()) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Notificações'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => Get.offAllNamed(AppRoutes.home),
          ),
        ),
        body: const Center(
          child: Text('Notificações indisponíveis. Configure o Supabase.'),
        ),
      );
    }
    final controller = Get.find<NotificationsController>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notificações'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Get.offAllNamed(AppRoutes.home),
        ),
      ),
      body: SafeArea(
        top: false,
        bottom: false,
        child: Obx(() {
          final isPremium = Get.isRegistered<AuthController>()
              ? Get.find<AuthController>().isPremium.value
              : false;
          return ListView(
            padding: const EdgeInsets.symmetric(vertical: 8),
            children: [
              _buildSystemNotificationSection(),
              _buildPushPreferencesSection(context, controller, isPremium),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildSystemNotificationSection() {
    return AppSurfaceCard(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 6),
        leading: Icon(
          _notificationsEnabled
              ? Icons.notifications_active_outlined
              : Icons.notifications_off_outlined,
        ),
        title: const Text('Notificações'),
        subtitle: Text(
          _loadingPermission
              ? 'Verificando...'
              : _notificationsEnabled
                  ? 'Ativada'
                  : 'Desativada',
        ),
        trailing: _loadingPermission
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Switch(
                value: _notificationsEnabled,
                onChanged: _handleNotificationToggle,
              ),
      ),
    );
  }
}

Widget _buildPushPreferencesSection(
  BuildContext context,
  NotificationsController controller,
  bool isPremium,
) {
  return AppSurfaceCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(
            'Resumos por push',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ),
        Obx(() {
          final saving = controller.savingPrefs.value;
          return Column(
            children: [
              _buildPremiumSwitchTile(
                context: context,
                title: 'Agenda do dia',
                subtitle: 'Manhã',
                value: isPremium ? controller.pushDaily.value : false,
                isPremium: !isPremium,
                saving: saving,
                onTap: () => _showPremiumNotificationModal(context, 'dia'),
                onChanged: isPremium && !saving
                    ? (v) => controller.updatePushPreferences(
                          daily: v,
                          tomorrow: controller.pushTomorrow.value,
                          weekly: controller.pushWeekly.value,
                        )
                    : null,
              ),
              const Divider(height: 1),
              _buildPremiumSwitchTile(
                context: context,
                title: 'Agenda de amanhã',
                subtitle: 'Fim do dia',
                value: isPremium ? controller.pushTomorrow.value : false,
                isPremium: !isPremium,
                saving: saving,
                onTap: () => _showPremiumNotificationModal(context, 'amanhã'),
                onChanged: isPremium && !saving
                    ? (v) => controller.updatePushPreferences(
                          daily: controller.pushDaily.value,
                          tomorrow: v,
                          weekly: controller.pushWeekly.value,
                        )
                    : null,
              ),
              const Divider(height: 1),
              _buildPremiumSwitchTile(
                context: context,
                title: 'Agenda da semana',
                subtitle: 'Domingo',
                value: isPremium ? controller.pushWeekly.value : false,
                isPremium: !isPremium,
                saving: saving,
                onTap: () => _showPremiumNotificationModal(context, 'semana'),
                onChanged: isPremium && !saving
                    ? (v) => controller.updatePushPreferences(
                          daily: controller.pushDaily.value,
                          tomorrow: controller.pushTomorrow.value,
                          weekly: v,
                        )
                    : null,
              ),
            ],
          );
        }),
      ],
    ),
  );
}

Widget _buildPremiumSwitchTile({
  required BuildContext context,
  required String title,
  required String subtitle,
  required bool value,
  required bool isPremium,
  required bool saving,
  required VoidCallback onTap,
  required ValueChanged<bool>? onChanged,
}) {
  return InkWell(
    onTap: isPremium ? onTap : null,
    child: Opacity(
      opacity: isPremium ? 0.65 : 1.0,
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        title: Row(
          children: [
            if (isPremium)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.12),
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
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: Theme.of(context).colorScheme.outline,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ],
                  ),
                ),
              ),
            Expanded(child: Text(title)),
          ],
        ),
        subtitle: Text(subtitle),
        trailing: Switch(
          value: value,
          onChanged: isPremium ? null : onChanged,
        ),
      ),
    ),
  );
}

void _showPremiumNotificationModal(BuildContext context, String tipo) {
  final String content;
  final String title;
  switch (tipo) {
    case 'dia':
      title = 'Resumo do dia';
      content = 'Receba um resumo da sua agenda pela manhã, '
          'para começar o dia organizado.\n\n'
          'É um recurso exclusivo Premium. Torne-se Premium e desbloqueie essa e outras funcionalidades.';
      break;
    case 'amanhã':
      title = 'Resumo de amanhã';
      content = 'Receba um resumo da sua agenda de amanhã no fim do dia, '
          'para você se preparar com antecedência.\n\n'
          'É um recurso exclusivo Premium. Torne-se Premium e desbloqueie essa e outras funcionalidades.';
      break;
    default:
      title = 'Resumo da semana';
      content = 'Receba um resumo semanal da sua agenda no domingo, '
          'para planejar a semana que vem.\n\n'
          'É um recurso exclusivo Premium. Torne-se Premium e desbloqueie essa e outras funcionalidades.';
  }
  showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      icon: Icon(
        Icons.notifications_active_outlined,
        size: 48,
        color: Theme.of(ctx).colorScheme.primary,
      ),
      title: Text(title),
      content: Text(content),
      actionsAlignment: MainAxisAlignment.center,
      actionsOverflowAlignment: OverflowBarAlignment.center,
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(),
          child: const Text('Entendi'),
        ),
        FilledButton(
          onPressed: () {
            Navigator.of(ctx).pop();
            if (!Get.isRegistered<AuthController>()) return;
            final authController = Get.find<AuthController>();
            if (authController.isLoggedIn.value) {
              Get.toNamed(AppRoutes.upgrade);
            } else {
              Get.toNamed(AppRoutes.login, arguments: {'from': 'premium'});
            }
          },
          child: const Text('Tornar-se Premium'),
        ),
      ],
    ),
  );
}

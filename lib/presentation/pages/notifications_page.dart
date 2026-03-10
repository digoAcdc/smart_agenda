import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/routes/app_routes.dart';
import '../../domain/entities/user_notification.dart';
import '../controllers/notifications_controller.dart';
import '../widgets/empty_state_widget.dart';
import '../widgets/ui_primitives.dart';

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<NotificationsController>()) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Notificações'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => Get.offAllNamed(AppRoutes.home),
          ),
        ),
        body: const Center(
          child: Text('Notificações disponíveis apenas para usuários premium.'),
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
        child: Obx(
          () {
            if (controller.loading.value && controller.notifications.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }
            return ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                _buildPushPreferencesSection(context, controller),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Text(
                    'HISTÓRICO',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: Theme.of(context).colorScheme.outline,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8,
                        ),
                  ),
                ),
                if (controller.notifications.isEmpty)
                  EmptyStateWidget(
                    icon: Icons.notifications_none_rounded,
                    title: 'Nenhuma notificação',
                    message: 'Resumos diários e semanais da sua agenda aparecerão aqui.',
                  )
                else
                  ...controller.notifications.map(
                    (n) => _NotificationTile(
                      notification: n,
                      onTap: () => controller.onTapNotification(n),
                      formatDate: controller.formatDate,
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

Widget _buildPushPreferencesSection(
  BuildContext context,
  NotificationsController controller,
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
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Agenda do dia'),
                subtitle: const Text('Manhã'),
                value: controller.pushDaily.value,
                onChanged: saving
                    ? null
                    : (v) => controller.updatePushPreferences(
                          daily: v,
                          tomorrow: controller.pushTomorrow.value,
                          weekly: controller.pushWeekly.value,
                        ),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Agenda de amanhã'),
                subtitle: const Text('Fim do dia'),
                value: controller.pushTomorrow.value,
                onChanged: saving
                    ? null
                    : (v) => controller.updatePushPreferences(
                          daily: controller.pushDaily.value,
                          tomorrow: v,
                          weekly: controller.pushWeekly.value,
                        ),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Agenda da semana'),
                subtitle: const Text('Domingo'),
                value: controller.pushWeekly.value,
                onChanged: saving
                    ? null
                    : (v) => controller.updatePushPreferences(
                          daily: controller.pushDaily.value,
                          tomorrow: controller.pushTomorrow.value,
                          weekly: v,
                        ),
              ),
            ],
          );
        }),
      ],
    ),
  );
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({
    required this.notification,
    required this.onTap,
    required this.formatDate,
  });

  final UserNotification notification;
  final VoidCallback onTap;
  final String Function(DateTime) formatDate;

  @override
  Widget build(BuildContext context) {
    final isWeekly = notification.type == 'weekly_summary';
    final isTomorrow = notification.type == 'tomorrow_summary';
    final iconData = isWeekly
        ? Icons.calendar_view_week_rounded
        : isTomorrow
            ? Icons.schedule_rounded
            : Icons.today_rounded;
    final iconColor = isWeekly
        ? Theme.of(context).colorScheme.primary
        : Theme.of(context).colorScheme.tertiary;
    return AppSurfaceCard(
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: CircleAvatar(
          backgroundColor: iconColor.withValues(alpha: 0.2),
          child: Icon(iconData, color: iconColor),
        ),
        title: Text(
          notification.title,
          style: TextStyle(
            fontWeight: notification.isRead ? FontWeight.w500 : FontWeight.w700,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              notification.body,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              formatDate(notification.referenceDate),
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
            ),
          ],
        ),
        trailing: notification.isRead
            ? null
            : Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  shape: BoxShape.circle,
                ),
              ),
        onTap: onTap,
      ),
    );
  }
}

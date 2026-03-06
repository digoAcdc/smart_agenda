import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';

import '../controllers/agenda_transfer_controller.dart';
import '../widgets/section_header.dart';
import '../widgets/ui_primitives.dart';

class ConfigPage extends StatefulWidget {
  const ConfigPage({super.key});

  @override
  State<ConfigPage> createState() => _ConfigPageState();
}

class _ConfigPageState extends State<ConfigPage> {
  final transferController = Get.find<AgendaTransferController>();

  bool loadingPermission = true;
  bool notificationsEnabled = false;

  @override
  void initState() {
    super.initState();
    _loadPermissionStatus();
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
        children: [
          const SectionHeader(
            title: 'Configuracoes',
            subtitle: 'Permissoes e funcionamento do app',
          ),
          AppSurfaceCard(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(6, 10, 6, 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Notificacoes',
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 12),
                  ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 6),
                    leading: Icon(
                      notificationsEnabled
                          ? Icons.notifications_active_outlined
                          : Icons.notifications_off_outlined,
                    ),
                    title: const Text('Permissao de notificacao'),
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
          AppSurfaceCard(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(6, 10, 6, 6),
              child: Obx(
                () => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Compartilhamento',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 12),
                    ListTile(
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 6),
                      leading: const Icon(Icons.ios_share_rounded),
                      title: const Text('Compartilhar agenda'),
                      subtitle: const Text(
                        'Gera arquivo JSON para enviar via WhatsApp/email',
                      ),
                      trailing: transferController.loading.value
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : TextButton(
                              onPressed: _handleShareAgenda,
                              child: const Text('Compartilhar'),
                            ),
                    ),
                    ListTile(
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 6),
                      leading: const Icon(Icons.file_download_outlined),
                      title: const Text('Importar agenda'),
                      subtitle: const Text(
                        'Importa arquivo JSON do Smart Agenda',
                      ),
                      trailing: transferController.loading.value
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : TextButton(
                              onPressed: _handleImportAgenda,
                              child: const Text('Importar'),
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

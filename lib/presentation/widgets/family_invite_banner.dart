import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../domain/entities/family.dart';
import '../../domain/repositories/i_family_service.dart';
import '../../domain/repositories/i_sync_service.dart';

/// Convites para Familia recebidos pelo usuario, com Aceitar/Recusar.
/// Fica na Home para o convite nao passar despercebido.
class FamilyInviteBanner extends StatefulWidget {
  const FamilyInviteBanner({super.key});

  @override
  State<FamilyInviteBanner> createState() => _FamilyInviteBannerState();
}

class _FamilyInviteBannerState extends State<FamilyInviteBanner> {
  String? _busyInviteId;

  IFamilyService? get _family =>
      Get.isRegistered<IFamilyService>() ? Get.find<IFamilyService>() : null;

  Future<void> _respond(FamilyInvite invite, {required bool accept}) async {
    final family = _family;
    if (family == null) return;
    if (!accept) {
      final ok = await showDialog<bool>(
        context: context,
        builder: (c) => AlertDialog(
          title: Text('Recusar convite da ${invite.familyName ?? 'Família'}?'),
          content: const Text('Você pode ser convidado de novo depois.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(c, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(c, true),
              child: const Text('Recusar'),
            ),
          ],
        ),
      );
      if (ok != true) return;
    }

    setState(() => _busyInviteId = invite.id);
    final result = accept
        ? await family.acceptInvite(invite.id)
        : await family.declineInvite(invite.id);
    if (!mounted) return;
    setState(() => _busyInviteId = null);

    final messenger = ScaffoldMessenger.of(context);
    if (!result.isSuccess) {
      messenger.showSnackBar(
        SnackBar(content: Text(result.errorMessage ?? 'Erro.')),
      );
      return;
    }
    if (accept) {
      messenger.showSnackBar(
        SnackBar(
          content: Text('Bem-vindo(a) à ${invite.familyName ?? 'Família'}!'),
        ),
      );
      if (Get.isRegistered<ISyncService>()) Get.find<ISyncService>().syncNow();
    }
  }

  @override
  Widget build(BuildContext context) {
    final family = _family;
    if (family == null) return const SizedBox.shrink();
    return Obx(() {
      final invites = family.myInvites.toList();
      if (invites.isEmpty || family.context.hasFamily) {
        return const SizedBox.shrink();
      }
      final scheme = Theme.of(context).colorScheme;
      return Column(
        children: [
          for (final invite in invites)
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: scheme.primaryContainer,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.family_restroom,
                        color: scheme.onPrimaryContainer,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Convite para a ${invite.familyName ?? 'Família'}',
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: scheme.onPrimaryContainer,
                              ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${invite.invitedByName ?? 'Alguém'} convidou você como '
                    '${invite.role.label.toLowerCase()} para organizar a rotina '
                    'da família juntos.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: scheme.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: _busyInviteId != null
                            ? null
                            : () => _respond(invite, accept: false),
                        child: const Text('Recusar'),
                      ),
                      const SizedBox(width: 8),
                      FilledButton(
                        // O tema usa largura infinita (botao de formulario);
                        // lado a lado numa Row isso quebra o layout.
                        style: FilledButton.styleFrom(
                          minimumSize: const Size(0, 44),
                        ),
                        onPressed: _busyInviteId != null
                            ? null
                            : () => _respond(invite, accept: true),
                        child: _busyInviteId == invite.id
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text('Aceitar'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
        ],
      );
    });
  }
}

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/routes/app_routes.dart';
import '../../../core/theme/design_tokens.dart';
import '../../controllers/auth_controller.dart';
import '../../widgets/ui_primitives.dart';

/// Tela placeholder para criar/assinar o acesso premium.
/// O usuario precisa estar logado para acessar.
class UpgradePage extends StatelessWidget {
  const UpgradePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.palette.appBackground,
      appBar: AppBar(
        title: const Text('Area Premium'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            onPressed: () async {
              await Get.find<AuthController>().signOut();
              Get.offAllNamed(AppRoutes.home);
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(DesignTokens.spaceMd),
          child: Column(
            children: [
              const SizedBox(height: DesignTokens.spaceXl),
              Icon(
                Icons.workspace_premium_rounded,
                size: 80,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: DesignTokens.spaceLg),
              Text(
                'Criar acesso Premium',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: DesignTokens.spaceSm),
              Text(
                'Voce esta logado. Em breve, aqui voce podera assinar o plano premium e desbloquear recursos exclusivos.',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: DesignTokens.spaceXl),
              AppSurfaceCard(
                margin: EdgeInsets.zero,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Em desenvolvimento',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: DesignTokens.spaceXs),
                    Text(
                      'A tela de assinatura e checkout sera implementada em uma proxima etapa.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => Get.back(),
                  child: const Text('Voltar'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

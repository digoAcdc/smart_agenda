import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/constants/billing_constants.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/theme/design_tokens.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/billing_controller.dart';
import '../../widgets/ui_primitives.dart';

/// Tela de assinatura premium via Google Play Billing.
/// O usuario precisa estar logado para acessar.
class UpgradePage extends StatelessWidget {
  const UpgradePage({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<BillingController>();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ctrl.revalidateInBackground(triggerRestore: true, reason: 'upgrade_open');
    });
    return Obx(() {
      final isPremium = Get.find<AuthController>().isPremium.value;
      final status = ctrl.purchaseStatus.value;
      return _buildContent(context, ctrl, isPremium, status);
    });
  }

  Widget _buildContent(
    BuildContext context,
    BillingController ctrl,
    bool isPremium,
    BillingPurchaseStatus status,
  ) {
    return Scaffold(
      backgroundColor: context.palette.appBackground,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => _handleBack(ctrl),
        ),
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
                isPremium ? 'Voce e Premium' : 'Plano Premium',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: DesignTokens.spaceSm),
              Text(
                isPremium
                    ? 'Sincronizacao na nuvem, backups automaticos e zero anuncios.'
                    : 'Desbloqueie todo o potencial com sincronizacao na nuvem, backups automaticos e zero anuncios.',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: DesignTokens.spaceXl),
              if (!ctrl.isRuntimeConfigured.value && !isPremium) ...[
                AppSurfaceCard(
                  margin: EdgeInsets.zero,
                  padding: const EdgeInsets.all(DesignTokens.spaceSm),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: Theme.of(context).colorScheme.tertiary,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Ambiente de cobrança indisponível. '
                          'Atualize o app ou contate o suporte.',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: DesignTokens.spaceSm),
              ],
              if (ctrl.errorMessage.value != null && ctrl.errorMessage.value!.isNotEmpty) ...[
                AppSurfaceCard(
                  margin: EdgeInsets.zero,
                  padding: const EdgeInsets.all(DesignTokens.spaceSm),
                  child: Row(
                    children: [
                      Icon(
                        Icons.error_outline,
                        color: Theme.of(context).colorScheme.error,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          ctrl.errorMessage.value!,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Theme.of(context).colorScheme.error,
                              ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: DesignTokens.spaceSm),
              ],
              if (status == BillingPurchaseStatus.pending) ...[
                AppSurfaceCard(
                  margin: EdgeInsets.zero,
                  child: Row(
                    children: [
                      const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Pagamento pendente...',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: DesignTokens.spaceSm),
              ],
              if (status == BillingPurchaseStatus.validating) ...[
                AppSurfaceCard(
                  margin: EdgeInsets.zero,
                  child: Row(
                    children: [
                      const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Validando assinatura...',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: DesignTokens.spaceSm),
              ],
              if (status == BillingPurchaseStatus.success) ...[
                AppSurfaceCard(
                  margin: EdgeInsets.zero,
                  child: Row(
                    children: [
                      Icon(
                        Icons.check_circle,
                        color: Theme.of(context).colorScheme.primary,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Assinatura ativada com sucesso!',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: DesignTokens.spaceSm),
              ],
              if (!isPremium &&
                  ctrl.isAvailable.value &&
                  BillingConstants.hasBillingApiConfigured) ...[
                AppSurfaceCard(
                  margin: EdgeInsets.zero,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ctrl.productPrice.value ?? 'R\$ 4,99 /mes',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Assinatura mensal. Cancele quando quiser.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
              if ((!ctrl.isAvailable.value || !ctrl.isRuntimeConfigured.value) && !isPremium) ...[
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
                        ctrl.isRuntimeConfigured.value
                            ? 'A compra in-app esta disponivel apenas no Android. Em breve para outras plataformas.'
                            : 'A cobranca in-app nao esta configurada neste build.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
              const Spacer(),
              if (!isPremium &&
                  ctrl.isAvailable.value &&
                  ctrl.isRuntimeConfigured.value) ...[
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _isBusy(status)
                        ? null
                        : () async {
                            await ctrl.purchase();
                          },
                    child: _isBusy(status)
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Tornar-se Premium'),
                  ),
                ),
                const SizedBox(height: DesignTokens.spaceSm),
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: _isBusy(status) ? null : () => ctrl.restorePurchases(),
                    child: const Text('Restaurar compras'),
                  ),
                ),
                const SizedBox(height: DesignTokens.spaceSm),
              ],
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => _handleBack(ctrl),
                  child: const Text('Voltar'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  bool _isBusy(BillingPurchaseStatus status) {
    return status == BillingPurchaseStatus.loading ||
        status == BillingPurchaseStatus.purchasing ||
        status == BillingPurchaseStatus.validating ||
        status == BillingPurchaseStatus.pending;
  }

  void _handleBack(BillingController ctrl) {
    ctrl.clearStatus();
    if (Get.key.currentState?.canPop() ?? false) {
      Get.back();
      return;
    }
    Get.offAllNamed(AppRoutes.home);
  }
}

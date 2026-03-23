import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/config/supabase_config.dart';
import '../../core/routes/app_routes.dart';
import '../../core/theme/design_tokens.dart';
import '../controllers/auth_controller.dart';
import '../widgets/ui_primitives.dart';

/// Tela central de modulos - acesso a todas as funcionalidades do app.
/// Mantem o rodape limpo com as principais, e concentra o resto aqui.
class MorePage extends StatelessWidget {
  const MorePage({super.key});

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mais'),
      ),
      body: SafeArea(
        top: false,
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.all(DesignTokens.spaceMd),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(0, 0, 0, 8),
              child: Text(
                'FUNCIONALIDADES',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: Theme.of(context).colorScheme.outline,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                    ),
              ),
            ),
            AppSurfaceCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  _buildActionTile(
                    context: context,
                    icon: Icons.group_rounded,
                    iconColor: primary,
                    title: 'Turmas',
                    subtitle: 'Turmas, salas e contatos',
                    onTap: () => Get.toNamed(AppRoutes.classGroups),
                  ),
                  const Divider(height: 1),
                  _buildActionTile(
                    context: context,
                    icon: Icons.note_rounded,
                    iconColor: primary,
                    title: 'Anotacoes',
                    subtitle: 'Notas rapidas e checklist',
                    onTap: () => Get.toNamed(AppRoutes.notes),
                  ),
                  const Divider(height: 1),
                  _buildActionTile(
                    context: context,
                    icon: Icons.notifications_rounded,
                    iconColor: primary,
                    title: 'Notificacoes',
                    subtitle: 'Preferencias de push',
                    onTap: () => Get.toNamed(AppRoutes.notifications),
                  ),
                  if (SupabaseConfig.isConfigured) ...[
                    const Divider(height: 1),
                    Obx(() {
                      final auth = Get.find<AuthController>();
                      return _buildActionTile(
                        context: context,
                        icon: Icons.share_rounded,
                        iconColor: primary,
                        title: 'Compartilhar',
                        subtitle: auth.isPremium.value
                            ? 'Compartilhe sua agenda'
                            : 'Plano free: 1 compartilhamento ativo',
                        onTap: () => _handleCompartilhar(context, auth.isLoggedIn.value),
                      );
                    }),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleCompartilhar(BuildContext context, bool isLoggedIn) {
    if (isLoggedIn) {
      Get.toNamed(AppRoutes.sharing);
      return;
    }
    Get.toNamed(AppRoutes.login, arguments: {'from': 'sharing'});
  }

  Widget _buildActionTile({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
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
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant,
                          ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
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
}

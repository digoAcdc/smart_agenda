import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/config/supabase_config.dart';
import '../../core/routes/app_routes.dart';
import '../../core/theme/design_tokens.dart';

/// Tela central de modulos - acesso a todas as funcionalidades do app.
/// Mantem o rodape limpo com as principais, e concentra o resto aqui.
class MorePage extends StatelessWidget {
  const MorePage({super.key});

  @override
  Widget build(BuildContext context) {
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
            Text(
              'Funcionalidades',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: DesignTokens.spaceSm),
            _ModuleGrid(
              children: [
                _ModuleCard(
                  icon: Icons.group_rounded,
                  label: 'Turmas',
                  subtitle: 'Turmas, salas e contatos',
                  onTap: () => Get.toNamed(AppRoutes.classGroups),
                ),
                _ModuleCard(
                  icon: Icons.note_rounded,
                  label: 'Anotacoes',
                  subtitle: 'Notas rapidas e checklist',
                  onTap: () => Get.toNamed(AppRoutes.notes),
                ),
                _ModuleCard(
                  icon: Icons.notifications_rounded,
                  label: 'Notificacoes',
                  subtitle: 'Preferencias de push',
                  onTap: () => Get.toNamed(AppRoutes.notifications),
                ),
                if (SupabaseConfig.isConfigured)
                  _ModuleCard(
                    icon: Icons.share_rounded,
                    label: 'Compartilhar',
                    subtitle: 'Compartilhe sua agenda',
                    onTap: () => Get.toNamed(AppRoutes.sharing),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ModuleGrid extends StatelessWidget {
  const _ModuleGrid({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Wrap(
          spacing: DesignTokens.spaceSm,
          runSpacing: DesignTokens.spaceSm,
          children: children,
        );
      },
    );
  }
}

class _ModuleCard extends StatelessWidget {
  const _ModuleCard({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = (MediaQuery.of(context).size.width -
                DesignTokens.spaceMd * 2 -
                DesignTokens.spaceSm) /
            2;
        return SizedBox(
          width: width,
          child: Material(
            color: Theme.of(context).colorScheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
              child: Padding(
                padding: const EdgeInsets.all(DesignTokens.spaceMd),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .primaryContainer
                            .withValues(alpha: 0.5),
                        borderRadius:
                            BorderRadius.circular(DesignTokens.radiusMd),
                      ),
                      child: Icon(
                        icon,
                        color: Theme.of(context).colorScheme.primary,
                        size: 24,
                      ),
                    ),
                    const SizedBox(height: DesignTokens.spaceSm),
                    Text(
                      label,
                      style: Theme.of(context).textTheme.titleSmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

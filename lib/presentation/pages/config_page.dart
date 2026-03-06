import 'package:flutter/material.dart';

import '../widgets/section_header.dart';
import '../widgets/ui_primitives.dart';

class ConfigPage extends StatefulWidget {
  const ConfigPage({super.key});

  @override
  State<ConfigPage> createState() => _ConfigPageState();
}

class _ConfigPageState extends State<ConfigPage> {
  @override
  Widget build(BuildContext context) {
    final items = const <Map<String, dynamic>>[
      {'title': 'Premium (em breve)', 'icon': Icons.workspace_premium_outlined},
      {'title': 'Backup/Restore (stub)', 'icon': Icons.backup_outlined},
      {'title': 'Exportar (stub)', 'icon': Icons.upload_file_outlined},
      {'title': 'Restaurar compra (stub)', 'icon': Icons.restore_outlined},
      {'title': 'Sobre', 'icon': Icons.info_outline},
    ];

    return ListView(
      children: [
        const SectionHeader(
          title: 'Configuracoes',
          subtitle: 'Ajustes do app e recursos futuros',
        ),
        AppSurfaceCard(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(6, 10, 6, 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Aparencia',
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 12),
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 6),
                  leading: const Icon(Icons.light_mode_outlined),
                  title: const Text('Tema claro'),
                  subtitle: const Text('Padrao fixo do aplicativo'),
                  trailing: Icon(
                    Icons.check_circle_rounded,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
        ),
        ...items.map(
          (item) => AppSurfaceCard(
            child: ListTile(
              leading: Icon(item['icon'] as IconData),
              title: Text(item['title'] as String),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () {},
            ),
          ),
        ),
      ],
    );
  }
}

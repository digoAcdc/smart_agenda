import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../widgets/section_header.dart';

class ConfigPage extends StatefulWidget {
  const ConfigPage({super.key});

  @override
  State<ConfigPage> createState() => _ConfigPageState();
}

class _ConfigPageState extends State<ConfigPage> {
  ThemeMode selectedThemeMode = ThemeMode.system;

  void _setThemeMode(ThemeMode mode) {
    setState(() => selectedThemeMode = mode);
    Get.changeThemeMode(mode);
    String message = 'Tema do sistema aplicado';
    if (mode == ThemeMode.light) message = 'Tema claro aplicado';
    if (mode == ThemeMode.dark) message = 'Tema escuro aplicado';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }

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
        Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Aparencia',
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 12),
                SegmentedButton<ThemeMode>(
                  segments: const [
                    ButtonSegment(
                      value: ThemeMode.light,
                      icon: Icon(Icons.light_mode_outlined),
                      label: Text('Claro'),
                    ),
                    ButtonSegment(
                      value: ThemeMode.dark,
                      icon: Icon(Icons.dark_mode_outlined),
                      label: Text('Escuro'),
                    ),
                    ButtonSegment(
                      value: ThemeMode.system,
                      icon: Icon(Icons.settings_suggest_outlined),
                      label: Text('Sistema'),
                    ),
                  ],
                  selected: {selectedThemeMode},
                  onSelectionChanged: (selection) {
                    _setThemeMode(selection.first);
                  },
                ),
              ],
            ),
          ),
        ),
        ...items.map(
          (item) => Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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

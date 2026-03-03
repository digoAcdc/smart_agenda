import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/routes/app_routes.dart';
import '../../core/theme/design_tokens.dart';
import '../../domain/entities/agenda_enums.dart';
import '../../domain/value_objects/search_filters.dart';
import '../controllers/groups_controller.dart';
import '../controllers/search_controller.dart' as app;
import '../widgets/agenda_card.dart';
import '../widgets/empty_state_widget.dart';
import '../widgets/loading_placeholder_list.dart';
import '../widgets/section_header.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  late final TextEditingController _queryController;
  bool showFilters = true;

  @override
  void initState() {
    super.initState();
    _queryController = TextEditingController();
  }

  @override
  void dispose() {
    _queryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<app.SearchController>();
    final groupsController = Get.find<GroupsController>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        SectionHeader(
          title: 'Buscar eventos',
          subtitle: 'Encontre por texto, periodo, grupo e status',
          trailing: IconButton(
            tooltip: showFilters ? 'Ocultar filtros' : 'Mostrar filtros',
            onPressed: () => setState(() => showFilters = !showFilters),
            icon: Icon(
              showFilters ? Icons.tune_rounded : Icons.tune_outlined,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: SearchBar(
            controller: _queryController,
            hintText: 'Buscar por titulo ou descricao',
            leading: const Icon(Icons.search_rounded),
            onChanged: (value) => controller.query.value = value,
            onSubmitted: (_) => controller.search(),
            trailing: [
              IconButton(
                tooltip: 'Limpar busca',
                onPressed: () {
                  _queryController.clear();
                  controller.query.value = '';
                  controller.search();
                },
                icon: const Icon(Icons.close_rounded),
              ),
            ],
            padding: const WidgetStatePropertyAll(
              EdgeInsets.symmetric(horizontal: 14),
            ),
          ),
        ),
        AnimatedCrossFade(
          duration: DesignTokens.motionStandard,
          crossFadeState: showFilters
              ? CrossFadeState.showFirst
              : CrossFadeState.showSecond,
          firstChild: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Obx(
              () => Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Filtros',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        DropdownMenu<SearchDateRangeFilter>(
                          initialSelection: controller.dateRange.value,
                          label: const Text('Periodo'),
                          width: 160,
                          onSelected: (value) {
                            if (value != null) {
                              controller.dateRange.value = value;
                            }
                          },
                          dropdownMenuEntries: SearchDateRangeFilter.values
                              .map((e) => DropdownMenuEntry(
                                    value: e,
                                    label: _rangeLabel(e),
                                  ))
                              .toList(),
                        ),
                        DropdownMenu<AgendaStatus?>(
                          initialSelection: controller.status.value,
                          label: const Text('Status'),
                          width: 140,
                          onSelected: (value) =>
                              controller.status.value = value,
                          dropdownMenuEntries: [
                            const DropdownMenuEntry(
                                value: null, label: 'Todos'),
                            ...AgendaStatus.values.map(
                              (e) => DropdownMenuEntry(
                                value: e,
                                label: _statusLabel(e),
                              ),
                            ),
                          ],
                        ),
                        DropdownMenu<String?>(
                          initialSelection: controller.groupId.value,
                          label: const Text('Grupo'),
                          width: 160,
                          onSelected: (value) =>
                              controller.groupId.value = value,
                          dropdownMenuEntries: [
                            const DropdownMenuEntry(
                                value: null, label: 'Todos'),
                            ...groupsController.groups.map(
                              (g) =>
                                  DropdownMenuEntry(value: g.id, label: g.name),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              controller.dateRange.value =
                                  SearchDateRangeFilter.all;
                              controller.status.value = null;
                              controller.groupId.value = null;
                              _queryController.clear();
                              controller.query.value = '';
                              controller.search();
                            },
                            child: const Text('Limpar'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: FilledButton(
                            onPressed: controller.search,
                            child: const Text('Aplicar'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          secondChild: const SizedBox.shrink(),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Obx(
            () => Text(
              controller.results.isEmpty
                  ? 'Nenhum resultado'
                  : '${controller.results.length} resultado(s)',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Expanded(
          child: Obx(
            () {
              if (controller.loading.value) {
                return const LoadingPlaceholderList();
              }
              if (controller.results.isEmpty) {
                return _buildResponsiveEmpty(
                  EmptyStateWidget(
                    icon: Icons.search_off_rounded,
                    title: 'Nada por aqui',
                    message: 'Tente alterar filtros ou criar um novo evento.',
                    ctaLabel: 'Criar evento',
                    onTapCta: () => Get.toNamed(AppRoutes.upsertAgenda),
                  ),
                );
              }
              return ListView.builder(
                padding: const EdgeInsets.only(bottom: 120),
                itemCount: controller.results.length,
                itemBuilder: (context, index) {
                  final item = controller.results[index];
                  return AgendaCard(
                    item: item,
                    groupName: groupsController.groups
                            .firstWhereOrNull((g) => g.id == item.groupId)
                            ?.name ??
                        'Sem grupo',
                    onTap: () =>
                        Get.toNamed(AppRoutes.upsertAgenda, arguments: item),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  String _rangeLabel(SearchDateRangeFilter filter) {
    switch (filter) {
      case SearchDateRangeFilter.all:
        return 'Todos';
      case SearchDateRangeFilter.today:
        return 'Hoje';
      case SearchDateRangeFilter.next7Days:
        return 'Prox. 7 dias';
      case SearchDateRangeFilter.thisMonth:
        return 'Este mes';
    }
  }

  String _statusLabel(AgendaStatus status) {
    switch (status) {
      case AgendaStatus.pending:
        return 'Pendente';
      case AgendaStatus.done:
        return 'Concluido';
      case AgendaStatus.canceled:
        return 'Cancelado';
    }
  }

  Widget _buildResponsiveEmpty(Widget child) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(0, 8, 0, 124),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight:
                  constraints.maxHeight > 0 ? constraints.maxHeight - 8 : 0,
            ),
            child: Center(child: child),
          ),
        );
      },
    );
  }
}

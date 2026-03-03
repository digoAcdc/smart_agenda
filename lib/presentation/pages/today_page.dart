import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../core/routes/app_routes.dart';
import '../../core/theme/design_tokens.dart';
import '../../core/utils/date_utils.dart';
import '../../domain/entities/agenda_item.dart';
import '../controllers/agenda_controller.dart';
import '../controllers/groups_controller.dart';
import '../widgets/agenda_card.dart';
import '../widgets/ads_placeholder_widget.dart';
import '../widgets/empty_state_widget.dart';
import '../widgets/loading_placeholder_list.dart';
import '../widgets/section_header.dart';

enum AgendaHomeViewMode { day, week, month }

class TodayPage extends StatefulWidget {
  const TodayPage({super.key});

  @override
  State<TodayPage> createState() => _TodayPageState();
}

class _TodayPageState extends State<TodayPage> {
  AgendaHomeViewMode mode = AgendaHomeViewMode.day;
  DateTime selectedDate = DateUtilsEx.startOfDay(DateTime.now());
  DateTime focusedDay = DateUtilsEx.startOfDay(DateTime.now());
  bool isCalendarExpanded = true;
  CalendarFormat calendarFormat = CalendarFormat.week;

  @override
  void initState() {
    super.initState();
    final controller = Get.find<AgendaController>();
    controller.loadByDay(selectedDate);
    controller.loadWeek(
      DateUtilsEx.startOfWeek(selectedDate),
      DateUtilsEx.endOfWeek(selectedDate),
    );
    controller.loadMonthItems(
      DateUtilsEx.startOfMonth(focusedDay),
      DateUtilsEx.endOfMonth(focusedDay),
    );
    controller.loadMonth(
      DateUtilsEx.startOfMonth(focusedDay),
      DateUtilsEx.endOfMonth(focusedDay),
    );
  }

  @override
  Widget build(BuildContext context) {
    final agendaController = Get.find<AgendaController>();
    final groupsController = Get.find<GroupsController>();

    return Obx(
      () {
        final subtitle = DateFormat('EEEE, dd MMMM').format(selectedDate);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            const AdsPlaceholderWidget(),
            SectionHeader(
              title: mode == AgendaHomeViewMode.day
                  ? 'Agenda do dia'
                  : mode == AgendaHomeViewMode.week
                      ? 'Agenda semanal'
                      : 'Agenda mensal',
              subtitle: subtitle,
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    onPressed: () {
                      setState(() {
                        calendarFormat = calendarFormat == CalendarFormat.week
                            ? CalendarFormat.month
                            : CalendarFormat.week;
                      });
                    },
                    tooltip: calendarFormat == CalendarFormat.week
                        ? 'Expandir para mes'
                        : 'Ver somente semana',
                    icon: Icon(
                      calendarFormat == CalendarFormat.week
                          ? Icons.open_in_full_rounded
                          : Icons.close_fullscreen_rounded,
                    ),
                  ),
                  IconButton(
                    onPressed: () => setState(
                        () => isCalendarExpanded = !isCalendarExpanded),
                    tooltip: isCalendarExpanded
                        ? 'Recolher calendario'
                        : 'Expandir calendario',
                    icon: Icon(
                      isCalendarExpanded
                          ? Icons.keyboard_arrow_up_rounded
                          : Icons.keyboard_arrow_down_rounded,
                    ),
                  ),
                ],
              ),
            ),
            AnimatedCrossFade(
              duration: DesignTokens.motionStandard,
              crossFadeState: isCalendarExpanded
                  ? CrossFadeState.showFirst
                  : CrossFadeState.showSecond,
              firstChild: _buildCalendarCard(context, agendaController),
              secondChild: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.today_rounded, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          DateFormat('dd/MM/yyyy').format(selectedDate),
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                      TextButton(
                        onPressed: () =>
                            setState(() => isCalendarExpanded = true),
                        child: const Text('Abrir calendario'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
              child: SegmentedButton<AgendaHomeViewMode>(
                segments: const [
                  ButtonSegment(
                      value: AgendaHomeViewMode.day, label: Text('Dia')),
                  ButtonSegment(
                      value: AgendaHomeViewMode.week, label: Text('Semana')),
                  ButtonSegment(
                      value: AgendaHomeViewMode.month, label: Text('Mes')),
                ],
                selected: {mode},
                onSelectionChanged: (value) {
                  setState(() => mode = value.first);
                  _reloadByMode(agendaController);
                },
              ),
            ),
            Expanded(
              child: AnimatedSwitcher(
                duration: DesignTokens.motionStandard,
                switchInCurve: Curves.easeOut,
                child: _buildBodyByMode(
                  agendaController: agendaController,
                  groupsController: groupsController,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildBodyByMode({
    required AgendaController agendaController,
    required GroupsController groupsController,
  }) {
    if (agendaController.loading.value) {
      return const LoadingPlaceholderList();
    }
    if (agendaController.errorMessage.value != null) {
      return EmptyStateWidget(
        icon: Icons.error_outline,
        title: 'Algo deu errado',
        message: agendaController.errorMessage.value!,
        ctaLabel: 'Tentar novamente',
        onTapCta: () => _reloadByMode(agendaController),
      );
    }
    if (mode == AgendaHomeViewMode.day) {
      return _buildDayList(agendaController, groupsController);
    }
    if (mode == AgendaHomeViewMode.week) {
      return _buildRangeByDayAndGroup(
        agendaController: agendaController,
        groupsController: groupsController,
        items: agendaController.weekItems,
        emptyMessage: 'Sua semana esta leve. Que tal criar um novo evento?',
      );
    }
    return _buildRangeByDayAndGroup(
      agendaController: agendaController,
      groupsController: groupsController,
      items: agendaController.monthItems,
      emptyMessage: 'Nenhum evento para este mes.',
    );
  }

  Widget _buildDayList(
      AgendaController controller, GroupsController groupsController) {
    if (controller.selectedDayItems.isEmpty) {
      return _buildResponsiveEmpty(
        EmptyStateWidget(
          icon: Icons.event_note_rounded,
          title: 'Dia livre',
          message: 'Nao ha eventos para a data selecionada.',
          ctaLabel: 'Criar evento',
          onTapCta: () => Get.toNamed(AppRoutes.upsertAgenda),
        ),
      );
    }

    final groupNameById = {
      for (final group in groupsController.groups) group.id: group.name,
    };
    final groupColorById = {
      for (final group in groupsController.groups)
        group.id: _tryParseColor(group.colorHex),
    };

    return ListView.builder(
      key: const ValueKey('day_list'),
      padding: const EdgeInsets.only(bottom: 112),
      itemCount: controller.selectedDayItems.length,
      itemBuilder: (context, index) {
        final item = controller.selectedDayItems[index];
        return AgendaCard(
          item: item,
          groupName: groupNameById[item.groupId] ?? 'Sem grupo',
          groupColor: groupColorById[item.groupId],
          onTap: () => Get.toNamed(AppRoutes.upsertAgenda, arguments: item),
          onToggleStatus: (status) {
            controller.toggleStatus(item.id, status);
            _showSavedFeedback(context, 'Status atualizado');
          },
          onDelete: () => _confirmDeleteAndExecute(controller, item.id),
        );
      },
    );
  }

  Widget _buildRangeByDayAndGroup({
    required AgendaController agendaController,
    required GroupsController groupsController,
    required List<AgendaItem> items,
    required String emptyMessage,
  }) {
    if (items.isEmpty) {
      return _buildResponsiveEmpty(
        EmptyStateWidget(
          icon: Icons.calendar_month_outlined,
          title: 'Sem eventos',
          message: emptyMessage,
          ctaLabel: 'Criar evento',
          onTapCta: () => Get.toNamed(AppRoutes.upsertAgenda),
        ),
      );
    }

    final groupNameById = {
      for (final group in groupsController.groups) group.id: group.name,
    };
    final groupColorById = {
      for (final group in groupsController.groups)
        group.id: _tryParseColor(group.colorHex),
    };

    final Map<DateTime, Map<String, List<AgendaItem>>> grouped = {};
    final Map<String, Color?> groupColorByName = {};
    for (final item in items) {
      final day = DateUtilsEx.startOfDay(item.startAt);
      final groupName = groupNameById[item.groupId] ?? 'Sem grupo';
      grouped.putIfAbsent(day, () => {});
      grouped[day]!.putIfAbsent(groupName, () => []);
      grouped[day]![groupName]!.add(item);
      groupColorByName[groupName] = groupColorById[item.groupId];
    }

    final orderedDays = grouped.keys.toList()..sort();

    return ListView(
      key: ValueKey('range_${mode.name}'),
      padding: const EdgeInsets.only(bottom: 112),
      children: orderedDays.map((day) {
        final groups = grouped[day]!;
        final orderedGroupNames = groups.keys.toList()..sort();

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(18),
          ),
          clipBehavior: Clip.antiAlias,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  DateFormat('EEEE, dd/MM').format(day),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 8),
                ...orderedGroupNames.map((groupName) {
                  final groupItems = groups[groupName]!
                    ..sort((a, b) => a.startAt.compareTo(b.startAt));
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: groupColorByName[groupName] ??
                                  Theme.of(context).colorScheme.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '$groupName (${groupItems.length})',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ...groupItems.map<Widget>(
                        (item) => AgendaCard(
                          item: item,
                          groupName: groupName,
                          groupColor: groupColorById[item.groupId],
                          onTap: () => Get.toNamed(AppRoutes.upsertAgenda,
                              arguments: item),
                          onToggleStatus: (status) {
                            agendaController.toggleStatus(item.id, status);
                            _showSavedFeedback(context, 'Status atualizado');
                          },
                          onDelete: () => _confirmDeleteAndExecute(
                              agendaController, item.id),
                        ),
                      ),
                      const SizedBox(height: 6),
                    ],
                  );
                }),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  void _reloadByMode(AgendaController controller) {
    if (mode == AgendaHomeViewMode.day) {
      controller.loadByDay(selectedDate);
      return;
    }
    if (mode == AgendaHomeViewMode.week) {
      controller.loadWeek(
        DateUtilsEx.startOfWeek(selectedDate),
        DateUtilsEx.endOfWeek(selectedDate),
      );
      return;
    }
    controller.loadMonthItems(
      DateUtilsEx.startOfMonth(focusedDay),
      DateUtilsEx.endOfMonth(focusedDay),
    );
  }

  Widget _buildCalendarCard(
    BuildContext context,
    AgendaController agendaController,
  ) {
    final height = MediaQuery.of(context).size.height;
    final isCompact = height < 760;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: EdgeInsets.all(isCompact ? 8 : 10),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(DesignTokens.radiusXl),
        ),
        child: TableCalendar<void>(
          locale: 'pt_BR',
          firstDay: DateTime.utc(2020, 1, 1),
          lastDay: DateTime.utc(2050, 12, 31),
          focusedDay: focusedDay,
          rowHeight: isCompact ? 36 : 42,
          daysOfWeekHeight: isCompact ? 18 : 22,
          selectedDayPredicate: (day) => isSameDay(day, selectedDate),
          eventLoader: (day) {
            final normalized = DateUtilsEx.startOfDay(day);
            return agendaController.monthMarkers.contains(normalized)
                ? [1]
                : [];
          },
          onDaySelected: (selected, focused) {
            setState(() {
              selectedDate = DateUtilsEx.startOfDay(selected);
              focusedDay = DateUtilsEx.startOfDay(focused);
            });
            _reloadByMode(agendaController);
          },
          onPageChanged: (focused) {
            setState(() {
              focusedDay = DateUtilsEx.startOfDay(focused);
              if (selectedDate.month != focusedDay.month ||
                  selectedDate.year != focusedDay.year) {
                selectedDate = DateTime(focusedDay.year, focusedDay.month, 1);
              }
            });
            agendaController.loadMonth(
              DateUtilsEx.startOfMonth(focusedDay),
              DateUtilsEx.endOfMonth(focusedDay),
            );
            _reloadByMode(agendaController);
          },
          calendarFormat: calendarFormat,
          availableCalendarFormats: const {
            CalendarFormat.week: 'Semana',
            CalendarFormat.month: 'Mes',
          },
          headerStyle: HeaderStyle(
            formatButtonVisible: false,
            titleCentered: true,
            headerPadding: EdgeInsets.symmetric(vertical: isCompact ? 4 : 8),
            leftChevronIcon: const Icon(Icons.chevron_left_rounded),
            rightChevronIcon: const Icon(Icons.chevron_right_rounded),
            titleTextStyle: Theme.of(context).textTheme.titleMedium!,
          ),
          calendarStyle: CalendarStyle(
            outsideDaysVisible: false,
            defaultTextStyle: Theme.of(context).textTheme.bodyMedium!,
            todayDecoration: BoxDecoration(
              color:
                  Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            selectedDecoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
              shape: BoxShape.circle,
            ),
            markerDecoration: BoxDecoration(
              color: Theme.of(context).colorScheme.secondary,
              shape: BoxShape.circle,
            ),
          ),
        ),
      ),
    );
  }

  Future<bool?> _confirmDeleteAndExecute(
    AgendaController controller,
    String itemId,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir evento?'),
        content: const Text('Essa acao move o evento para exclusao logica.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar')),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Excluir')),
        ],
      ),
    );
    if (confirm == true) {
      final ok = await controller.deleteItem(itemId);
      if (ok && mounted) {
        _showSavedFeedback(context, 'Evento removido');
      }
      return ok;
    }
    return false;
  }

  void _showSavedFeedback(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        content: Text(message),
        duration: const Duration(milliseconds: 1400),
      ),
    );
  }

  Widget _buildResponsiveEmpty(Widget child) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 112),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Center(child: child),
          ),
        );
      },
    );
  }

  Color? _tryParseColor(String? colorHex) {
    if (colorHex == null || colorHex.isEmpty) return null;
    final hex = colorHex.replaceFirst('#', '');
    final normalized = hex.length == 6 ? 'FF$hex' : hex;
    final value = int.tryParse(normalized, radix: 16);
    if (value == null) return null;
    return Color(value);
  }
}

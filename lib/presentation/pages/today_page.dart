import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../core/routes/app_routes.dart';
import '../../core/theme/design_tokens.dart';
import '../../core/utils/date_utils.dart';
import '../../domain/entities/agenda_enums.dart';
import '../../domain/entities/agenda_item.dart';
import '../controllers/agenda_controller.dart';
import '../controllers/auth_controller.dart';
import '../controllers/class_schedule_controller.dart';
import '../controllers/groups_controller.dart';
import '../controllers/home_controller.dart';
import '../widgets/agenda_card.dart';
import '../widgets/ads_placeholder_widget.dart';
import '../widgets/empty_state_widget.dart';
import '../widgets/loading_placeholder_list.dart';
import '../widgets/section_header.dart';

enum AgendaHomeViewMode { day, week, month }
enum HomeLandingView { dashboard, calendar }

/// Retorna saudação conforme o horário: Bom dia (até 12h), Boa tarde (12h–18h), Boa noite (após 18h).
String _greetingByTime() {
  final h = DateTime.now().hour;
  if (h < 12) return 'BOM DIA';
  if (h < 18) return 'BOA TARDE';
  return 'BOA NOITE';
}

class TodayPage extends StatefulWidget {
  const TodayPage({
    super.key,
    this.initialLandingView = HomeLandingView.dashboard,
    this.allowLandingSwitch = true,
    this.initialCalendarFormat = CalendarFormat.week,
    this.initialDate,
    this.initialMode,
  });

  final HomeLandingView initialLandingView;
  final bool allowLandingSwitch;
  final CalendarFormat initialCalendarFormat;
  final DateTime? initialDate;
  final AgendaHomeViewMode? initialMode;

  @override
  State<TodayPage> createState() => _TodayPageState();
}

class _TodayPageState extends State<TodayPage> {
  late HomeLandingView landingView;
  String? selectedTimelineGroupId;
  AgendaHomeViewMode mode = AgendaHomeViewMode.day;
  DateTime selectedDate = DateUtilsEx.startOfDay(DateTime.now());
  DateTime focusedDay = DateUtilsEx.startOfDay(DateTime.now());
  bool isCalendarExpanded = false;
  late CalendarFormat calendarFormat;

  bool get isAgendaTabMode =>
      !widget.allowLandingSwitch &&
      widget.initialLandingView == HomeLandingView.calendar;

  @override
  void initState() {
    super.initState();
    landingView = widget.initialLandingView;
    calendarFormat = widget.initialCalendarFormat;
    mode = widget.initialMode ?? AgendaHomeViewMode.day;
    if (mode == AgendaHomeViewMode.week) {
      calendarFormat = CalendarFormat.week;
    }
    if (widget.initialDate != null) {
      selectedDate = DateUtilsEx.startOfDay(widget.initialDate!);
      focusedDay = DateUtilsEx.startOfDay(widget.initialDate!);
      if (isAgendaTabMode && Get.isRegistered<HomeController>()) {
        Get.find<HomeController>().clearInitialAgendaNavigation();
      }
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final controller = Get.find<AgendaController>();
      if (widget.initialDate != null) {
        controller.selectedDayItems.clear();
        controller.selectedDate.value = selectedDate;
      }
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
    });
  }

  @override
  Widget build(BuildContext context) {
    final agendaController = Get.find<AgendaController>();
    final groupsController = Get.find<GroupsController>();
    final classScheduleController = Get.find<ClassScheduleController>();

    return SafeArea(
      bottom: false,
      child: Obx(
        () {
          final subtitle = DateFormat('EEEE, dd MMMM').format(selectedDate);
          if (landingView == HomeLandingView.dashboard) {
            return _buildDashboardView(
              context: context,
              agendaController: agendaController,
              groupsController: groupsController,
              classScheduleController: classScheduleController,
            );
          }
          if (isAgendaTabMode) {
            return _buildAgendaTabModeView(
              context: context,
              agendaController: agendaController,
              groupsController: groupsController,
            );
          }
          return Container(
            color: null,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
            const SizedBox(height: 6),
            SectionHeader(
              title: 'Smart Agenda',
              subtitle: DateFormat('dd/MM/yyyy').format(DateTime.now()),
              trailing: widget.allowLandingSwitch
                  ? IconButton(
                      tooltip: 'Ver dashboard',
                      onPressed: () =>
                          setState(() => landingView = HomeLandingView.dashboard),
                      icon: const Icon(Icons.dashboard_customize_outlined),
                    )
                  : null,
            ),
            if (widget.allowLandingSwitch)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: SegmentedButton<HomeLandingView>(
                  segments: const [
                    ButtonSegment(
                      value: HomeLandingView.dashboard,
                      icon: Icon(Icons.home_outlined),
                      label: Text('Inicio'),
                    ),
                    ButtonSegment(
                      value: HomeLandingView.calendar,
                      icon: Icon(Icons.calendar_month_outlined),
                      label: Text('Calendario'),
                    ),
                  ],
                  selected: {landingView},
                  onSelectionChanged: (selection) {
                    setState(() => landingView = selection.first);
                  },
                ),
              ),
            const SizedBox(height: 8),
            if (!isAgendaTabMode) const AdsPlaceholderWidget(),
            SectionHeader(
              title: isAgendaTabMode
                  ? 'Calendario completo'
                  : mode == AgendaHomeViewMode.day
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
                  if (!isAgendaTabMode)
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
            if (!isAgendaTabMode)
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
            ),
          );
        },
      ),
    );
  }

  Widget _buildAgendaTabModeView({
    required BuildContext context,
    required AgendaController agendaController,
    required GroupsController groupsController,
  }) {
    return Container(
      color: context.palette.appBackground,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: SizedBox(
              height: 40,
              child: Center(
                child: Text(
                  'Agenda',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: Column(
              children: [
                SectionHeader(
                  title: 'Calendario completo',
                  subtitle: DateFormat('EEEE, dd MMMM').format(selectedDate),
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
                            ? 'Calendario maior'
                            : 'Calendario menor',
                        icon: Icon(
                          calendarFormat == CalendarFormat.week
                              ? Icons.open_in_full_rounded
                              : Icons.close_fullscreen_rounded,
                        ),
                      ),
                      IconButton(
                        onPressed: () =>
                            setState(() => isCalendarExpanded = !isCalendarExpanded),
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
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
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
                  child: mode == AgendaHomeViewMode.day
                      ? _buildSelectedDayTimeline(
                          agendaController: agendaController,
                          groupsController: groupsController,
                        )
                      : mode == AgendaHomeViewMode.week
                          ? _buildRangeByDayAndGroup(
                              agendaController: agendaController,
                              groupsController: groupsController,
                              items: agendaController.weekItems,
                              emptyMessage:
                                  'Sua semana esta leve. Que tal criar um novo evento?',
                            )
                          : _buildRangeByDayAndGroup(
                              agendaController: agendaController,
                              groupsController: groupsController,
                              items: agendaController.monthItems,
                              emptyMessage: 'Nenhum evento para este mes.',
                            ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardView({
    required BuildContext context,
    required AgendaController agendaController,
    required GroupsController groupsController,
    required ClassScheduleController classScheduleController,
  }) {
    if (agendaController.loading.value) {
      return const LoadingPlaceholderList();
    }
    final accentGreen = Theme.of(context).colorScheme.primary;
    final softBg = context.palette.appBackground;

    final todayEvents = [...agendaController.todayItems]
      ..sort((a, b) => a.startAt.compareTo(b.startAt));
    final overdue = todayEvents
        .where(
          (e) =>
              e.status == AgendaStatus.pending &&
              e.startAt.isBefore(DateTime.now()),
        )
        .toList();
    final upcoming = todayEvents
        .where((e) => e.startAt.isAfter(DateTime.now()))
        .take(6)
        .toList();
    final agendaDoDia = [...agendaController.selectedDayItems]
      ..sort((a, b) => a.startAt.compareTo(b.startAt));
    final overdueIds = overdue.map((e) => e.id).toSet();
    final agendaDoDiaExibida =
        agendaDoDia.where((e) => !overdueIds.contains(e.id)).toList();
    final groupNameById = {
      for (final g in groupsController.groups) g.id: g.name,
    };
    final scheduleWeekday = DateTime.now().weekday;
    final classes = classScheduleController.slots
        .where(
          (slot) =>
              slot.dayOfWeek == scheduleWeekday &&
              (slot.subject?.trim().isNotEmpty ?? false),
        )
        .toList()
      ..sort((a, b) => a.startMinutes.compareTo(b.startMinutes));
    final timelineItems = selectedTimelineGroupId == null
        ? upcoming
        : upcoming.where((e) => e.groupId == selectedTimelineGroupId).toList();

    return Container(
      color: softBg,
      child: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 120),
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      const CircleAvatar(
                        radius: 16,
                        child: Icon(Icons.person, size: 18),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Obx(() {
                          final authController = Get.find<AuthController>();
                          final displayName = authController.userEmail.value ??
                              'Usuário';
                          final isPremium = authController.isPremium.value;
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _greetingByTime(),
                                style: Theme.of(context)
                                    .textTheme
                                    .labelSmall
                                    ?.copyWith(letterSpacing: 1.1),
                              ),
                              Text(
                                displayName,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(
                                      fontWeight: FontWeight.w700,
                                    ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (isPremium) ...[
                                const SizedBox(height: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .primary
                                        .withValues(alpha: 0.12),
                                    borderRadius:
                                        BorderRadius.circular(999),
                                  ),
                                  child: Text(
                                    'Premium',
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelSmall
                                        ?.copyWith(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .primary,
                                          fontWeight: FontWeight.w700,
                                        ),
                                  ),
                                ),
                              ],
                            ],
                          );
                        }),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                _buildWeekStrip(agendaController, accentGreen),
                const SizedBox(height: 10),
                _sectionTitle(context, 'Agenda de hoje'),
                const SizedBox(height: 8),
                if (agendaDoDiaExibida.isEmpty)
                  _buildDashboardEmpty(context, accentGreen)
                else
                  ...agendaDoDiaExibida.take(2).map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _buildDashboardEventTile(
                        context,
                        item: item,
                        groupName: groupNameById[item.groupId] ?? 'Sem grupo',
                        accentColor: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                const SizedBox(height: 8),
                if (overdue.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: context.semanticColors.danger.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'ATENCAO NECESSARIA',
                          style:
                              Theme.of(context).textTheme.labelSmall?.copyWith(
                                    color: context.semanticColors.danger,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.8,
                                  ),
                        ),
                        const SizedBox(height: 8),
                        _buildDashboardEventTile(
                          context,
                          item: overdue.first,
                          groupName: groupNameById[overdue.first.groupId] ?? 'Sem grupo',
                          accentColor: context.semanticColors.danger,
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 14),
                _sectionTitle(context, 'Aulas de hoje', trailing: 'Ver tudo'),
                const SizedBox(height: 8),
                if (classes.isEmpty)
                  _buildDashboardEmpty(context, accentGreen)
                else
                  ...classes.map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _buildClassCard(
                        context,
                        startMinutes: item.startMinutes,
                        endMinutes: item.endMinutes,
                        subject: item.subject ?? 'Materia',
                      ),
                    ),
                  ),
                const SizedBox(height: 12),
                _sectionTitle(context, 'Timeline'),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _filterChip(
                      context,
                      'Todos',
                      selected: selectedTimelineGroupId == null,
                      onTap: () => setState(() => selectedTimelineGroupId = null),
                    ),
                    ...groupsController.groups.map(
                      (group) => _filterChip(
                        context,
                        group.name,
                        selected: selectedTimelineGroupId == group.id,
                        onTap: () =>
                            setState(() => selectedTimelineGroupId = group.id),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                if (timelineItems.isEmpty)
                  _buildDashboardEmpty(context, accentGreen)
                else
                  ...timelineItems.map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _buildTimelineTile(
                        context,
                        item: item,
                        groupName: groupNameById[item.groupId] ?? 'Sem grupo',
                        accentGreen: accentGreen,
                      ),
                    ),
                  ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: accentGreen,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Total de eventos',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: Theme.of(context).colorScheme.onPrimary,
                                  ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${todayEvents.length}',
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineSmall
                                  ?.copyWith(
                                    color: Theme.of(context).colorScheme.onPrimary,
                                    fontWeight: FontWeight.w800,
                                  ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        '+${todayEvents.where((e) => e.status == AgendaStatus.pending).length} pendentes',
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(
                              color: Theme.of(context).colorScheme.onPrimary,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeekStrip(AgendaController controller, Color accentGreen) {
    final start = DateUtilsEx.startOfWeek(DateTime.now());
    final days = List.generate(7, (index) => start.add(Duration(days: index)));
    return SizedBox(
      height: 64,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 2),
        scrollDirection: Axis.horizontal,
        itemCount: days.length,
        separatorBuilder: (_, separatorIndex) => const SizedBox(width: 6),
        itemBuilder: (context, index) {
          final day = days[index];
          final selected = isSameDay(day, selectedDate);
          return InkWell(
            onTap: () {
              setState(() => selectedDate = DateUtilsEx.startOfDay(day));
              controller.loadByDay(day);
            },
            borderRadius: BorderRadius.circular(12),
            child: AnimatedContainer(
              duration: DesignTokens.motionStandard,
              width: 50,
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
              decoration: BoxDecoration(
                color: selected ? accentGreen : Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    DateFormat('E').format(day),
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: selected
                              ? Theme.of(context).colorScheme.onPrimary
                              : Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${day.day}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: selected
                              ? Theme.of(context).colorScheme.onPrimary
                              : Theme.of(context).colorScheme.onSurface,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _sectionTitle(BuildContext context, String title, {String? trailing}) {
    return Row(
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        const Spacer(),
        if (trailing != null)
          Text(
            trailing,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
          ),
      ],
    );
  }

  Widget _filterChip(
    BuildContext context,
    String label, {
    bool selected = false,
    VoidCallback? onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(right: 6),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: selected
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: selected
                      ? Theme.of(context).colorScheme.onPrimary
                      : Theme.of(context).colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ),
      ),
    );
  }

  Widget _buildDashboardEventTile(
    BuildContext context, {
    required AgendaItem item,
    required String groupName,
    required Color accentColor,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () => Get.toNamed(AppRoutes.eventDetail, arguments: item),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.event_note, color: accentColor, size: 18),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Horario ${DateFormat('HH:mm').format(item.startAt)}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    groupName,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClassCard(
    BuildContext context, {
    required int startMinutes,
    required int endMinutes,
    required String subject,
  }) {
    final start = _formatMinutes(startMinutes);
    final end = _formatMinutes(endMinutes);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 58,
            alignment: Alignment.center,
            child: Text(
              start,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  subject,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$start - $end',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineTile(
    BuildContext context, {
    required AgendaItem item,
    required String groupName,
    required Color accentGreen,
  }) {
    final timeLabel = DateFormat('HH:mm').format(item.startAt);
    final isExpired = item.status == AgendaStatus.pending &&
        item.startAt.isBefore(DateTime.now());
    final lineColor = isExpired
        ? context.semanticColors.danger
        : accentGreen;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 58,
          child: Text(
            timeLabel,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
            ),
          ),
          const SizedBox(width: 4),
          Container(
            width: 1.5,
            height: 92,
            color: lineColor.withValues(alpha: 0.7),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: InkWell(
            borderRadius: BorderRadius.circular(16),
              onTap: () => Get.toNamed(AppRoutes.eventDetail, arguments: item),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: isExpired
                    ? Border.all(
                        color: context.semanticColors.danger.withValues(alpha: 0.2),
                      )
                    : null,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          groupName.toUpperCase(),
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.w700,
                            ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isExpired)
                        Text(
                          'Expirado',
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                color: context.semanticColors.danger,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                    ],
                  ),
                  if (item.ownerEmail != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Compartilhada por ${item.ownerEmail}',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: Theme.of(context).colorScheme.primary,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 4),
                  Text(
                    item.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.description?.trim().isNotEmpty == true
                        ? item.description!.trim()
                        : 'Sem descricao',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDashboardEmpty(BuildContext context, Color accentGreen) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline_rounded, color: accentGreen),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Nada agendado por aqui no momento.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
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

  Widget _buildSelectedDayTimeline({
    required AgendaController agendaController,
    required GroupsController groupsController,
    bool asSection = false,
  }) {
    if (agendaController.loading.value) {
      if (asSection) {
        return const Padding(
          padding: EdgeInsets.symmetric(vertical: 24),
          child: Center(child: CircularProgressIndicator()),
        );
      }
      return const LoadingPlaceholderList();
    }
    final items = [...agendaController.selectedDayItems]
      ..sort((a, b) => a.startAt.compareTo(b.startAt));
    if (items.isEmpty) {
      if (asSection) {
        return Column(
          children: [
            const SectionHeader(
              title: 'Timeline',
              subtitle: 'Eventos do dia selecionado',
              compact: true,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: EmptyStateWidget(
                icon: Icons.event_busy_outlined,
                title: 'Sem eventos neste dia',
                message: 'Selecione outra data ou crie um novo evento.',
                ctaLabel: 'Criar evento',
                onTapCta: () => Get.toNamed(AppRoutes.upsertAgenda),
              ),
            ),
          ],
        );
      }
      return _buildResponsiveEmpty(
        EmptyStateWidget(
          icon: Icons.event_busy_outlined,
          title: 'Sem eventos neste dia',
          message: 'Selecione outra data ou crie um novo evento.',
          ctaLabel: 'Criar evento',
          onTapCta: () => Get.toNamed(AppRoutes.upsertAgenda),
        ),
      );
    }
    final groupNameById = {
      for (final g in groupsController.groups) g.id: g.name,
    };
    final groupColorById = {
      for (final g in groupsController.groups) g.id: _tryParseColor(g.colorHex),
    };

    final timelineChildren = [
      const SectionHeader(
        title: 'Timeline',
        subtitle: 'Eventos do dia selecionado',
        compact: true,
      ),
      ...items.map(
        (item) => Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 64,
              child: Padding(
                padding: const EdgeInsets.only(top: 22, left: 8),
                child: Text(
                  item.allDay ? 'Dia' : DateFormat('HH:mm').format(item.startAt),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
            ),
            Expanded(
              child: _buildAgendaCompleteTimelineCard(
                context,
                item: item,
                groupName: groupNameById[item.groupId] ?? 'Sem grupo',
                groupColor: groupColorById[item.groupId],
                onTap: () => Get.toNamed(AppRoutes.eventDetail, arguments: item),
                onToggleStatus: (status) {
                  agendaController.toggleStatus(item.id, status);
                  _showSavedFeedback(context, 'Status atualizado');
                },
              ),
            ),
          ],
        ),
      ),
    ];

    if (asSection) {
      return Column(children: timelineChildren);
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(0, 4, 0, 120),
      children: timelineChildren,
    );
  }

  Widget _buildAgendaCompleteTimelineCard(
    BuildContext context, {
    required AgendaItem item,
    required String groupName,
    required Color? groupColor,
    required VoidCallback onTap,
    required ValueChanged<AgendaStatus> onToggleStatus,
  }) {
    final statusColor = item.status == AgendaStatus.done
        ? context.semanticColors.success
        : item.status == AgendaStatus.canceled
            ? context.semanticColors.warning
            : context.semanticColors.pending;
    final isExpired = item.status == AgendaStatus.pending &&
        item.startAt.isBefore(DateTime.now());
    final railColor = isExpired
        ? context.semanticColors.danger
        : (groupColor ?? statusColor);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: isExpired
            ? Border.all(
                color: context.semanticColors.danger.withValues(alpha: 0.2),
              )
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Container(
                  width: 3,
                  height: 54,
                  decoration: BoxDecoration(
                    color: railColor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            DateFormat('HH:mm').format(item.startAt),
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: railColor.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                groupName,
                                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                      color: railColor,
                                      fontWeight: FontWeight.w700,
                                    ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                          if (isExpired) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: context.semanticColors.danger
                                    .withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                'Expirado',
                                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                      color: context.semanticColors.danger,
                                      fontWeight: FontWeight.w700,
                                    ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      if (item.ownerEmail != null) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.people_outline,
                              size: 14,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                'Compartilhada por ${item.ownerEmail}',
                                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                      color: Theme.of(context).colorScheme.primary,
                                    ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 6),
                      Text(
                        item.title,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${DateFormat('dd MMM').format(item.startAt)} · ${item.status.name}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                      ),
                    ],
                  ),
                ),
                if (item.ownerEmail == null)
                  IconButton(
                    onPressed: () => onToggleStatus(
                      item.status == AgendaStatus.done
                          ? AgendaStatus.pending
                          : AgendaStatus.done,
                    ),
                    icon: Icon(
                      item.status == AgendaStatus.done
                          ? Icons.check_circle
                          : Icons.radio_button_unchecked,
                      color: statusColor,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
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
          onTap: () => Get.toNamed(AppRoutes.eventDetail, arguments: item),
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
                          onTap: () => Get.toNamed(AppRoutes.eventDetail,
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
    final accentGreen = Theme.of(context).colorScheme.primary;
    final cardBg = isAgendaTabMode
        ? Theme.of(context).colorScheme.surface
        : Theme.of(context).colorScheme.surfaceContainerLow;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: EdgeInsets.all(isCompact ? 8 : 10),
        decoration: BoxDecoration(
          color: cardBg,
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
              // Melhor UX: ao tocar em um dia no calendario, foca no modo dia.
              mode = AgendaHomeViewMode.day;
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
            leftChevronIcon: Icon(
              Icons.chevron_left_rounded,
              color: Theme.of(context).colorScheme.onSurface,
            ),
            rightChevronIcon: Icon(
              Icons.chevron_right_rounded,
              color: Theme.of(context).colorScheme.onSurface,
            ),
            titleTextStyle: Theme.of(context).textTheme.titleMedium!,
          ),
          calendarStyle: CalendarStyle(
            outsideDaysVisible: false,
            defaultTextStyle: Theme.of(context).textTheme.bodyMedium!,
            todayDecoration: BoxDecoration(
              color: (isAgendaTabMode ? accentGreen : Theme.of(context).colorScheme.primary)
                  .withValues(alpha: 0.22),
              shape: BoxShape.circle,
            ),
            selectedDecoration: BoxDecoration(
              color: isAgendaTabMode
                  ? accentGreen
                  : Theme.of(context).colorScheme.primary,
              shape: BoxShape.circle,
            ),
            markerDecoration: BoxDecoration(
              color: isAgendaTabMode
                  ? context.semanticColors.danger
                  : Theme.of(context).colorScheme.secondary,
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
        final boundedHeight = constraints.hasBoundedHeight
            ? constraints.maxHeight
            : MediaQuery.of(context).size.height * 0.45;
        return SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 112),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: boundedHeight),
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

  String _formatMinutes(int minutes) {
    final h = (minutes ~/ 60).toString().padLeft(2, '0');
    final m = (minutes % 60).toString().padLeft(2, '0');
    return '$h:$m';
  }
}

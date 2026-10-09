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
import '../widgets/empty_state_widget.dart';
import '../widgets/loading_placeholder_list.dart';
import '../widgets/section_header.dart';
import '../utils/family_item_labels.dart';
import '../../domain/repositories/i_sync_service.dart';
import '../widgets/family_invite_banner.dart';
import '../widgets/native_ad_card.dart';

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
    // Aba Agenda: o calendario acompanha o modo (Mes = mes inteiro).
    if (isAgendaTabMode) {
      calendarFormat = mode == AgendaHomeViewMode.month
          ? CalendarFormat.month
          : CalendarFormat.week;
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
      controller.loadUpcoming();
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
      child: Obx(() {
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
                        onPressed: () => setState(
                          () => landingView = HomeLandingView.dashboard,
                        ),
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
                        label: Text('Início'),
                      ),
                      ButtonSegment(
                        value: HomeLandingView.calendar,
                        icon: Icon(Icons.calendar_month_outlined),
                        label: Text('Calendário'),
                      ),
                    ],
                    selected: {landingView},
                    onSelectionChanged: (selection) {
                      setState(() => landingView = selection.first);
                    },
                  ),
                ),
              const SizedBox(height: 8),
              SectionHeader(
                title: isAgendaTabMode
                    ? 'Calendário completo'
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
                          ? 'Expandir para mês'
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
                          () => isCalendarExpanded = !isCalendarExpanded,
                        ),
                        tooltip: isCalendarExpanded
                            ? 'Recolher calendário'
                            : 'Expandir calendário',
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
                          child: const Text('Abrir calendário'),
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
                        value: AgendaHomeViewMode.day,
                        label: Text('Dia'),
                      ),
                      ButtonSegment(
                        value: AgendaHomeViewMode.week,
                        label: Text('Semana'),
                      ),
                      ButtonSegment(
                        value: AgendaHomeViewMode.month,
                        label: Text('Mês'),
                      ),
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
      }),
    );
  }

  Widget _buildAgendaTabModeView({
    required BuildContext context,
    required AgendaController agendaController,
    required GroupsController groupsController,
  }) {
    final today = DateUtilsEx.startOfDay(DateTime.now());
    final isTodaySelected = isSameDay(selectedDate, today);
    return Container(
      color: context.palette.appBackground,
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Titulo fixo; calendario e modos rolam junto com a lista para
            // sobrar espaco para os eventos (o mes inteiro ocupava a tela).
            SectionHeader(
              title: 'Agenda',
              subtitle: toBeginningOfSentenceCase(
                DateFormat('EEEE, d MMMM', 'pt_BR').format(selectedDate),
              ),
              trailing: isTodaySelected
                  ? null
                  : TextButton.icon(
                      onPressed: () {
                        setState(() {
                          selectedDate = today;
                          focusedDay = today;
                        });
                        _reloadByMode(agendaController);
                      },
                      icon: const Icon(Icons.today_rounded, size: 18),
                      label: const Text('Hoje'),
                    ),
            ),
            Expanded(
              child: NestedScrollView(
                headerSliverBuilder: (context, innerBoxIsScrolled) => [
                  SliverToBoxAdapter(
                    child: _buildCalendarCard(context, agendaController),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
                      child: SegmentedButton<AgendaHomeViewMode>(
                        segments: const [
                          ButtonSegment(
                            value: AgendaHomeViewMode.day,
                            label: Text('Dia'),
                          ),
                          ButtonSegment(
                            value: AgendaHomeViewMode.week,
                            label: Text('Semana'),
                          ),
                          ButtonSegment(
                            value: AgendaHomeViewMode.month,
                            label: Text('Mês'),
                          ),
                        ],
                        selected: {mode},
                        onSelectionChanged: (value) {
                          setState(() {
                            mode = value.first;
                            calendarFormat = mode == AgendaHomeViewMode.month
                                ? CalendarFormat.month
                                : CalendarFormat.week;
                          });
                          _reloadByMode(agendaController);
                        },
                      ),
                    ),
                  ),
                ],
                body: mode == AgendaHomeViewMode.day
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
                            'Semana livre por enquanto. Que tal criar um evento?',
                      )
                    : _buildRangeByDayAndGroup(
                        agendaController: agendaController,
                        groupsController: groupsController,
                        items: agendaController.monthItems,
                        emptyMessage: 'Nenhum evento para este mês.',
                      ),
              ),
            ),
          ],
        ),
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
    final upcoming = agendaController.upcomingItems.toList();
    final isTodaySelected = isSameDay(selectedDate, DateTime.now());
    final agendaDoDia = [...agendaController.selectedDayItems]
      ..sort((a, b) => a.startAt.compareTo(b.startAt));
    // Todos os eventos do dia ficam na lista; os atrasados (pendentes com
    // horario ja passado) aparecem em vermelho. Antes saiam da lista e so o
    // primeiro aparecia, e a tela dizia "Nada marcado para hoje".
    final overdueIds = overdue.map((e) => e.id).toSet();
    final agendaDoDiaExibida = agendaDoDia;
    final groupNameById = {
      for (final g in groupsController.groups) g.id: g.name,
    };
    final scheduleWeekday = DateTime.now().weekday;
    final classes =
        classScheduleController.allSlots
            .where(
              (slot) =>
                  slot.dayOfWeek == scheduleWeekday &&
                  (slot.subject?.trim().isNotEmpty ?? false),
            )
            .toList()
          ..sort((a, b) => a.startMinutes.compareTo(b.startMinutes));
    // Com mais de uma grade, cada aula mostra de qual grade/filho e.
    final schedules = classScheduleController.schedules.toList();
    final showClassOwner = schedules.length > 1;
    String? classOwnerLabel(String? scheduleId) {
      final g = schedules.firstWhereOrNull((s) => s.id == scheduleId);
      if (g == null) return null;
      final child = FamilyItemLabels.childName(g.childId);
      if (child == null) return g.name;
      final childSchedules = schedules.where((s) => s.childId == g.childId);
      return childSchedules.length > 1 ? '$child · ${g.name}' : child;
    }

    // Primeiro uso: nada criado ainda. Um unico convite para comecar no
    // lugar de varias secoes vazias.
    final isFirstUse =
        todayEvents.isEmpty &&
        agendaDoDia.isEmpty &&
        upcoming.isEmpty &&
        schedules.isEmpty;
    final hasSchedules = schedules.isNotEmpty;
    void openSchedules() => Get.find<HomeController>().setIndex(2);

    final timelineItems = selectedTimelineGroupId == null
        ? upcoming
        : upcoming.where((e) => e.groupId == selectedTimelineGroupId).toList();

    return Container(
      color: softBg,
      child: Column(
        children: [
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                if (Get.isRegistered<ISyncService>()) {
                  await Get.find<ISyncService>().syncNow();
                }
                await agendaController.refreshCurrentData();
                await agendaController.loadByDay(selectedDate);
              },
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
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
                            // Sem conta: so a saudacao ("Boa tarde!").
                            final email = authController.userEmail.value;
                            final greeting = _greetingByTime();
                            final displayName =
                                email ??
                                '${greeting[0]}${greeting.substring(1).toLowerCase()}!';
                            final isPremium = authController.isPremium.value;
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (email != null)
                                  Text(
                                    greeting,
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelSmall
                                        ?.copyWith(letterSpacing: 1.1),
                                  ),
                                Text(
                                  displayName,
                                  style: Theme.of(context).textTheme.titleMedium
                                      ?.copyWith(fontWeight: FontWeight.w700),
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
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                    child: Text(
                                      'Pro',
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelSmall
                                          ?.copyWith(
                                            color: Theme.of(
                                              context,
                                            ).colorScheme.primary,
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
                  const FamilyInviteBanner(),
                  const SizedBox(height: 8),
                  _buildWeekStrip(agendaController, accentGreen),
                  const SizedBox(height: 10),
                  if (isFirstUse && isTodaySelected)
                    _buildWelcomeCard(context, onOpenSchedules: openSchedules)
                  else ...[
                    _sectionTitle(
                      context,
                      _dayAgendaTitle(selectedDate),
                      trailing: isTodaySelected ? null : 'Voltar para hoje',
                      onTrailingTap: isTodaySelected
                          ? null
                          : () {
                              final today = DateUtilsEx.startOfDay(
                                DateTime.now(),
                              );
                              setState(() => selectedDate = today);
                              agendaController.loadByDay(today);
                            },
                    ),
                    const SizedBox(height: 8),
                    if (agendaDoDiaExibida.isEmpty)
                      _buildDashboardEmpty(
                        context,
                        accentGreen,
                        message: isTodaySelected
                            ? 'Nada marcado para hoje.'
                            : 'Nada marcado para este dia.',
                      )
                    else
                      ...agendaDoDiaExibida.map(
                        (item) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: _buildDashboardEventTile(
                            context,
                            item: item,
                            groupName:
                                groupNameById[item.groupId] ?? 'Sem grupo',
                            accentColor: overdueIds.contains(item.id)
                                ? context.semanticColors.danger
                                : Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ),
                    const SizedBox(height: 8),
                    const SizedBox(height: 14),
                    _sectionTitle(
                      context,
                      'Aulas de hoje',
                      trailing: hasSchedules ? 'Ver grade' : null,
                      onTrailingTap: hasSchedules ? openSchedules : null,
                    ),
                    const SizedBox(height: 8),
                    if (classes.isEmpty)
                      _buildDashboardEmpty(
                        context,
                        accentGreen,
                        message: hasSchedules
                            ? 'Sem aulas hoje.'
                            : 'Monte a grade de aulas para ver aqui as aulas do dia.',
                        actionLabel: hasSchedules ? null : 'Montar grade',
                        onAction: hasSchedules ? null : openSchedules,
                      )
                    else
                      ...classes.map(
                        (item) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: _buildClassCard(
                            context,
                            startMinutes: item.startMinutes,
                            endMinutes: item.endMinutes,
                            subject: item.subject ?? 'Matéria',
                            ownerLabel: showClassOwner
                                ? classOwnerLabel(item.scheduleId)
                                : null,
                            ownerColorHex: FamilyItemLabels.childColorHex(
                              item.childId,
                            ),
                          ),
                        ),
                      ),
                    const SizedBox(height: 12),
                    _sectionTitle(context, 'Próximos eventos'),
                    const SizedBox(height: 8),
                    // Filtro por grupo so quando ha grupos.
                    if (groupsController.groups.isNotEmpty)
                      Row(
                        children: [
                          _filterChip(
                            context,
                            'Todos',
                            selected: selectedTimelineGroupId == null,
                            onTap: () =>
                                setState(() => selectedTimelineGroupId = null),
                          ),
                          ...groupsController.groups.map(
                            (group) => _filterChip(
                              context,
                              group.name,
                              selected: selectedTimelineGroupId == group.id,
                              onTap: () => setState(
                                () => selectedTimelineGroupId = group.id,
                              ),
                            ),
                          ),
                        ],
                      ),
                    const SizedBox(height: 10),
                    if (timelineItems.isEmpty)
                      _buildDashboardEmpty(
                        context,
                        accentGreen,
                        message: 'Nenhum evento nos próximos dias.',
                      )
                    else
                      for (final (index, item) in timelineItems.indexed) ...[
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _buildTimelineTile(
                            context,
                            item: item,
                            groupName:
                                groupNameById[item.groupId] ?? 'Sem grupo',
                            accentGreen: accentGreen,
                          ),
                        ),
                        // Plano Free: um anuncio nativo depois do 2o evento
                        // (ou do ultimo, se houver menos).
                        if (index ==
                            (timelineItems.length < 2
                                ? timelineItems.length - 1
                                : 1))
                          const NativeAdCard(),
                      ],
                    const SizedBox(height: 8),
                    if (todayEvents.isNotEmpty)
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
                                    'Eventos de hoje',
                                    style: Theme.of(context).textTheme.bodySmall
                                        ?.copyWith(
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.onPrimary,
                                        ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${todayEvents.length}',
                                    style: Theme.of(context)
                                        .textTheme
                                        .headlineSmall
                                        ?.copyWith(
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.onPrimary,
                                          fontWeight: FontWeight.w800,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              '${todayEvents.where((e) => e.status == AgendaStatus.pending).length} pendentes',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onPrimary,
                                  ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Primeiro uso: atalhos para o que a pessoa provavelmente quer fazer.
  Widget _buildWelcomeCard(
    BuildContext context, {
    required VoidCallback onOpenSchedules,
  }) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Comece por aqui',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Anote compromissos, tarefas e lembretes, e monte a grade de '
            'aulas. Tudo do dia aparece nesta tela.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 14),
          FilledButton.icon(
            onPressed: () => Get.toNamed(AppRoutes.upsertAgenda),
            icon: const Icon(Icons.add_rounded),
            label: const Text('Criar primeiro evento'),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: onOpenSchedules,
            icon: const Icon(Icons.menu_book_rounded),
            label: const Text('Montar grade de aulas'),
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
                color: selected
                    ? accentGreen
                    : Theme.of(context).colorScheme.surface,
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

  Widget _sectionTitle(
    BuildContext context,
    String title, {
    String? trailing,
    VoidCallback? onTrailingTap,
  }) {
    final trailingText = trailing == null
        ? null
        : Text(
            trailing,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
          );
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (trailingText != null)
          onTrailingTap == null
              ? trailingText
              : InkWell(
                  onTap: onTrailingTap,
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 6,
                    ),
                    child: trailingText,
                  ),
                ),
      ],
    );
  }

  /// "Agenda de hoje", "Agenda de amanhã" ou "Agenda de sex, 17/10".
  String _dayAgendaTitle(DateTime day) {
    final today = DateUtilsEx.startOfDay(DateTime.now());
    final target = DateUtilsEx.startOfDay(day);
    final diff = target.difference(today).inDays;
    if (diff == 0) return 'Agenda de hoje';
    if (diff == 1) return 'Agenda de amanhã';
    if (diff == -1) return 'Agenda de ontem';
    return 'Agenda de ${DateFormat('EEE, dd/MM', 'pt_BR').format(target)}';
  }

  /// Data curta para a lista de proximos eventos.
  String _upcomingDateLabel(DateTime start) {
    final today = DateUtilsEx.startOfDay(DateTime.now());
    final diff = DateUtilsEx.startOfDay(start).difference(today).inDays;
    if (diff == 0) return 'Hoje';
    if (diff == 1) return 'Amanhã';
    if (diff < 7) return DateFormat('EEE', 'pt_BR').format(start);
    if (start.year == today.year) return DateFormat('dd/MM').format(start);
    return DateFormat('dd/MM/yy').format(start);
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
                    'Horário ${DateFormat('HH:mm').format(item.startAt)}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 2),
                  if (FamilyItemLabels.subject(item) == null)
                    Text(
                      groupName,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
            ),
            if (FamilyItemLabels.subject(item) != null)
              _ownerBadge(
                context,
                FamilyItemLabels.subject(item)!,
                FamilyItemLabels.subjectColorHex(item),
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
    String? ownerLabel,
    String? ownerColorHex,
  }) {
    final start = _formatMinutes(startMinutes);
    final end = _formatMinutes(endMinutes);
    final now = DateTime.now();
    final nowMinutes = now.hour * 60 + now.minute;
    final isNow = nowMinutes >= startMinutes && nowMinutes < endMinutes;
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: isNow ? Border.all(color: scheme.primary, width: 1.5) : null,
      ),
      child: Row(
        children: [
          Container(
            width: 58,
            alignment: Alignment.center,
            child: Text(
              start,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w700),
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
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 2),
                Text(
                  isNow ? 'Agora · até $end' : 'até $end',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: isNow ? scheme.primary : scheme.onSurfaceVariant,
                    fontWeight: isNow ? FontWeight.w700 : null,
                  ),
                ),
              ],
            ),
          ),
          if (ownerLabel != null)
            _ownerBadge(context, ownerLabel, ownerColorHex),
        ],
      ),
    );
  }

  /// Etiqueta "de quem e" (filho/Familia/membro) com a cor do filho.
  Widget _ownerBadge(BuildContext context, String label, String? colorHex) {
    final color = _hexColor(colorHex) ?? Theme.of(context).colorScheme.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(radius: 4, backgroundColor: color),
          const SizedBox(width: 5),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 110),
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: color,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color? _hexColor(String? hex) {
    if (hex == null || hex.isEmpty) return null;
    final h = hex.replaceFirst('#', '');
    final v = int.tryParse(h.length == 6 ? 'FF$h' : h, radix: 16);
    return v == null ? null : Color(v);
  }

  Widget _buildTimelineTile(
    BuildContext context, {
    required AgendaItem item,
    required String groupName,
    required Color accentGreen,
  }) {
    final timeLabel =
        '${_upcomingDateLabel(item.startAt)}\n${item.allDay ? 'Dia todo' : DateFormat('HH:mm').format(item.startAt)}';
    final isExpired =
        item.status == AgendaStatus.pending &&
        item.startAt.isBefore(DateTime.now());
    final lineColor = isExpired ? context.semanticColors.danger : accentGreen;
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
                        color: context.semanticColors.danger.withValues(
                          alpha: 0.2,
                        ),
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
                          (FamilyItemLabels.subject(item) ?? groupName)
                              .toUpperCase(),
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(
                                color:
                                    _hexColor(
                                      FamilyItemLabels.subjectColorHex(item),
                                    ) ??
                                    Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.w700,
                              ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isExpired)
                        Text(
                          'Atrasado',
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(
                                color: context.semanticColors.danger,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                    ],
                  ),
                  if (FamilyItemLabels.summary(item) != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      FamilyItemLabels.summary(item)!,
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
                        : 'Sem descrição',
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

  Widget _buildDashboardEmpty(
    BuildContext context,
    Color accentGreen, {
    String message = 'Nada marcado por aqui.',
    String? actionLabel,
    VoidCallback? onAction,
  }) {
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
            child: Text(message, style: Theme.of(context).textTheme.bodyMedium),
          ),
          if (actionLabel != null && onAction != null)
            TextButton(onPressed: onAction, child: Text(actionLabel)),
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
        emptyMessage: 'Semana livre por enquanto. Que tal criar um evento?',
      );
    }
    return _buildRangeByDayAndGroup(
      agendaController: agendaController,
      groupsController: groupsController,
      items: agendaController.monthItems,
      emptyMessage: 'Nenhum evento para este mês.',
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
            const SectionHeader(title: 'Eventos do dia', compact: true),
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
      ...items.map(
        (item) => Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 64,
              child: Padding(
                padding: const EdgeInsets.only(top: 22, left: 8),
                child: Text(
                  item.allDay
                      ? 'Dia'
                      : DateFormat('HH:mm').format(item.startAt),
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
                onTap: () =>
                    Get.toNamed(AppRoutes.eventDetail, arguments: item),
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
    final isExpired =
        item.status == AgendaStatus.pending &&
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
                  height: 44,
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
                      // Hora fica na coluna da esquerda; aqui so etiquetas.
                      if (item.groupId != null || isExpired)
                        Row(
                          children: [
                            if (item.groupId != null)
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
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelSmall
                                        ?.copyWith(
                                          color: railColor,
                                          fontWeight: FontWeight.w700,
                                        ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                            if (isExpired) ...[
                              if (item.groupId != null)
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
                                  'Atrasado',
                                  style: Theme.of(context).textTheme.labelSmall
                                      ?.copyWith(
                                        color: context.semanticColors.danger,
                                        fontWeight: FontWeight.w700,
                                      ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      if (FamilyItemLabels.summary(item) != null) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.family_restroom_outlined,
                              size: 14,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                FamilyItemLabels.summary(item)!,
                                style: Theme.of(context).textTheme.labelSmall
                                    ?.copyWith(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.primary,
                                    ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 4),
                      Text(
                        item.title,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        [
                          if (item.allDay)
                            'Dia todo'
                          else if (item.endAt != null)
                            'até ${DateFormat('HH:mm').format(item.endAt!)}',
                          item.status.label,
                        ].join(' · '),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                if (FamilyItemLabels.canEdit(item))
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
    AgendaController controller,
    GroupsController groupsController,
  ) {
    if (controller.selectedDayItems.isEmpty) {
      return _buildResponsiveEmpty(
        EmptyStateWidget(
          icon: Icons.event_note_rounded,
          title: 'Dia livre',
          message: 'Não há eventos para a data selecionada.',
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
                              color:
                                  groupColorByName[groupName] ??
                                  Theme.of(context).colorScheme.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '$groupName (${groupItems.length})',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
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
                          onTap: () => Get.toNamed(
                            AppRoutes.eventDetail,
                            arguments: item,
                          ),
                          onToggleStatus: (status) {
                            agendaController.toggleStatus(item.id, status);
                            _showSavedFeedback(context, 'Status atualizado');
                          },
                          onDelete: () => _confirmDeleteAndExecute(
                            agendaController,
                            item.id,
                          ),
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
          rowHeight: calendarFormat == CalendarFormat.month
              ? (isCompact ? 34 : 38)
              : (isCompact ? 36 : 42),
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
              // Ao tocar em um dia: modo Dia; na aba Agenda o calendario
              // recolhe para a semana para os eventos do dia aparecerem.
              mode = AgendaHomeViewMode.day;
              if (isAgendaTabMode) calendarFormat = CalendarFormat.week;
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
            CalendarFormat.month: 'Mês',
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
              color:
                  (isAgendaTabMode
                          ? accentGreen
                          : Theme.of(context).colorScheme.primary)
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
        content: const Text('O evento sai da agenda.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(minimumSize: const Size(0, 44)),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Excluir'),
          ),
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

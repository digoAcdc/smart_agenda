import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../core/routes/app_routes.dart';
import '../../core/theme/design_tokens.dart';
import '../controllers/home_controller.dart';
import 'class_schedule_page.dart';
import 'config_page.dart';
import 'more_page.dart';
import 'today_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final homeController = Get.find<HomeController>();
    final args = Get.arguments;
    if (!homeController.navigationArgsApplied &&
        args is Map &&
        args['tab'] != null &&
        args['date'] != null) {
      homeController.markNavigationArgsApplied();
      try {
        homeController.setInitialDate(DateTime.parse(args['date'] as String));
      } catch (_) {}
      if (args['mode'] != null) {
        homeController.setInitialMode(args['mode'] as String);
      }
      // setIndex dispara Obx - precisa ser apos o build para evitar markNeedsBuild durante build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        homeController.setIndex(args['tab'] as int);
      });
    }
    final textScale = MediaQuery.of(context).textScaler.scale(1.0);
    final isCompactNav = MediaQuery.of(context).size.width < 360 || textScale > 1.05;
    final navHeight = isCompactNav ? 78.0 : 86.0;
    final barStackHeight = navHeight + 42;
    final initialDate = homeController.initialDateValueForAgenda;
    final initialModeRaw = homeController.initialModeValueForAgenda;
    final initialMode = initialModeRaw == 'week'
        ? AgendaHomeViewMode.week
        : AgendaHomeViewMode.day;
    final pages = [
      TodayPage(
        initialLandingView: HomeLandingView.dashboard,
        allowLandingSwitch: false,
      ),
      TodayPage(
        initialLandingView: HomeLandingView.calendar,
        allowLandingSwitch: false,
        initialCalendarFormat: initialMode == AgendaHomeViewMode.week
            ? CalendarFormat.week
            : CalendarFormat.month,
        initialDate: initialDate,
        initialMode: initialMode,
      ),
      ClassSchedulePage(),
      MorePage(),
      ConfigPage(),
    ];
    const iconList = [
      Icons.home_rounded,
      Icons.calendar_month_rounded,
      Icons.menu_book_rounded,
      Icons.apps_rounded,
      Icons.settings_rounded,
    ];

    return Obx(
      () => Scaffold(
        body: AnimatedSwitcher(
          duration: DesignTokens.motionStandard,
          switchInCurve: Curves.easeOut,
          switchOutCurve: Curves.easeIn,
          transitionBuilder: (child, animation) => FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.02, 0),
                end: Offset.zero,
              ).animate(animation),
              child: child,
            ),
          ),
          child: KeyedSubtree(
            key: ValueKey(homeController.currentIndex.value),
            child: pages[homeController.currentIndex.value],
          ),
        ),
        bottomNavigationBar: SafeArea(
          top: false,
          child: SizedBox(
            height: barStackHeight,
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.bottomCenter,
              children: [
                Positioned(
                  left: 12,
                  right: 12,
                  bottom: 0,
                  child: Container(
                    height: navHeight,
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(40),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.06),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Row(
                      children: List.generate(iconList.length, (index) {
                        final isActive = homeController.currentIndex.value == index;
                        final labels = ['Home', 'Agenda', 'Materias', 'Mais', 'Config'];
                        final inactive = Theme.of(context).colorScheme.onSurfaceVariant;
                        return Expanded(
                          child: InkWell(
                            borderRadius: BorderRadius.circular(28),
                            onTap: () => homeController.setIndex(index),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 2),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  AnimatedContainer(
                                    duration: DesignTokens.motionStandard,
                                    width: isActive ? 52 : 38,
                                    height: isActive ? 52 : 30,
                                    decoration: BoxDecoration(
                                      color: isActive
                                          ? Theme.of(context).colorScheme.primary
                                          : Colors.transparent,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      iconList[index],
                                      color: isActive
                                          ? Theme.of(context).colorScheme.onPrimary
                                          : inactive,
                                      size: isActive ? 28 : 23,
                                    ),
                                  ),
                                  if (!isCompactNav) ...[
                                    const SizedBox(height: 3),
                                    Text(
                                      labels[index],
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                            color: inactive,
                                            fontWeight: FontWeight.w600,
                                          ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                ),
                Positioned(
                  top: 0,
                  right: 22,
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(30),
                      onTap: () => Get.toNamed(AppRoutes.upsertAgenda),
                      child: Container(
                        width: 58,
                        height: 58,
                        decoration: BoxDecoration(
                          color: const Color(0xFF0B1633),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF0B1633).withValues(alpha: 0.30),
                              blurRadius: 18,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.add_rounded,
                          color: Colors.white,
                          size: 30,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

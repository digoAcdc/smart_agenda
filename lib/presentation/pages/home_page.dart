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
import '../widgets/anchored_ad_banner.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final homeController = Get.find<HomeController>();
    return Obx(() {
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
        WidgetsBinding.instance.addPostFrameCallback((_) {
          homeController.setIndex(args['tab'] as int);
        });
      }

      const navHeight = 74.0;
      const barStackHeight = navHeight + 42;
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
      const navLabels = ['Início', 'Agenda', 'Matérias', 'Mais', 'Config'];

      return Scaffold(
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
        bottomNavigationBar: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const AnchoredAdBanner(),
            SafeArea(
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
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 6,
                        ),
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
                            final isActive =
                                homeController.currentIndex.value == index;
                            return Expanded(
                              child: HomeNavItem(
                                icon: iconList[index],
                                label: navLabels[index],
                                isActive: isActive,
                                onTap: () => homeController.setIndex(index),
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
                                  color: const Color(
                                    0xFF0B1633,
                                  ).withValues(alpha: 0.30),
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
          ],
        ),
      );
    });
  }
}

/// Item da barra inferior: icone com o nome sempre visivel embaixo.
class HomeNavItem extends StatelessWidget {
  const HomeNavItem({
    super.key,
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = isActive ? scheme.primary : scheme.onSurfaceVariant;
    return Semantics(
      selected: isActive,
      button: true,
      label: label,
      excludeSemantics: true,
      child: InkWell(
        borderRadius: BorderRadius.circular(28),
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: DesignTokens.motionStandard,
              width: isActive ? 52 : 40,
              height: 30,
              decoration: BoxDecoration(
                color: isActive ? scheme.primary : Colors.transparent,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                icon,
                color: isActive ? scheme.onPrimary : color,
                size: 22,
              ),
            ),
            const SizedBox(height: 4),
            // A escala de fonte e limitada e o texto encolhe se precisar,
            // para o nome caber mesmo em telas estreitas.
            MediaQuery.withClampedTextScaling(
              maxScaleFactor: 1.15,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  maxLines: 1,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: color,
                        fontSize: 11.5,
                        fontWeight:
                            isActive ? FontWeight.w700 : FontWeight.w500,
                      ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

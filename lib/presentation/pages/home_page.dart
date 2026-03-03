import 'package:animated_bottom_navigation_bar/animated_bottom_navigation_bar.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/routes/app_routes.dart';
import '../../core/theme/design_tokens.dart';
import '../controllers/home_controller.dart';
import 'class_schedule_page.dart';
import 'config_page.dart';
import 'groups_page.dart';
import 'search_page.dart';
import 'today_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final homeController = Get.find<HomeController>();
    final textScale = MediaQuery.of(context).textScaler.scale(1.0);
    final isCompactNav =
        MediaQuery.of(context).size.width < 360 || textScale > 1.05;
    final navHeight = isCompactNav ? 62.0 : 70.0;
    final barStackHeight = navHeight + 16;
    const pages = [
      TodayPage(),
      ClassSchedulePage(),
      SearchPage(),
      GroupsPage(),
      ConfigPage(),
    ];
    const iconList = [
      Icons.calendar_today_rounded,
      Icons.table_chart_rounded,
      Icons.search_rounded,
      Icons.group_work_rounded,
      Icons.settings_rounded,
    ];

    return Obx(
      () => Scaffold(
        appBar: AppBar(title: const Text('Smart Agenda')),
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
              alignment: Alignment.topCenter,
              children: [
                Positioned.fill(
                  child: AnimatedBottomNavigationBar.builder(
                    itemCount: iconList.length,
                    activeIndex: homeController.currentIndex.value,
                    gapLocation: GapLocation.none,
                    leftCornerRadius: 22,
                    rightCornerRadius: 22,
                    height: navHeight,
                    backgroundColor:
                        Theme.of(context).colorScheme.surfaceContainer,
                    splashColor: Theme.of(context)
                        .colorScheme
                        .primary
                        .withValues(alpha: 0.16),
                    onTap: homeController.setIndex,
                    tabBuilder: (index, isActive) {
                      final color = isActive
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.onSurfaceVariant;
                      final labels = [
                        'Agenda',
                        'Grade',
                        'Buscar',
                        'Grupos',
                        'Config'
                      ];
                      return Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            iconList[index],
                            color: color,
                            size: isActive ? 24 : 22,
                          ),
                          if (!isCompactNav) ...[
                            const SizedBox(height: 3),
                            Text(
                              labels[index],
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: color,
                                    fontWeight: isActive
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                  ),
                            ),
                          ],
                        ],
                      );
                    },
                  ),
                ),
                Positioned(
                  top: -22,
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(30),
                      onTap: () => Get.toNamed(AppRoutes.upsertAgenda),
                      child: Container(
                        width: 58,
                        height: 58,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Theme.of(context)
                                  .colorScheme
                                  .primary
                                  .withValues(alpha: 0.32),
                              blurRadius: 18,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.add_rounded,
                          color: Theme.of(context).colorScheme.onPrimary,
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

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../core/routes/app_routes.dart';
import '../../core/utils/date_utils.dart';
import '../controllers/agenda_controller.dart';
import '../widgets/agenda_item_tile.dart';

class MonthPage extends StatefulWidget {
  const MonthPage({super.key});

  @override
  State<MonthPage> createState() => _MonthPageState();
}

class _MonthPageState extends State<MonthPage> {
  DateTime focusedDay = DateTime.now();

  @override
  void initState() {
    super.initState();
    final c = Get.find<AgendaController>();
    c.loadMonth(DateUtilsEx.startOfMonth(focusedDay),
        DateUtilsEx.endOfMonth(focusedDay));
    c.loadByDay(focusedDay);
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<AgendaController>();
    return Scaffold(
      body: Obx(
        () => Column(
          children: [
            TableCalendar<void>(
              firstDay: DateTime.utc(2020, 1, 1),
              lastDay: DateTime.utc(2050, 12, 31),
              focusedDay: focusedDay,
              selectedDayPredicate: (day) =>
                  isSameDay(day, controller.selectedDate.value),
              onDaySelected: (selectedDay, focused) {
                setState(() => focusedDay = focused);
                controller.loadByDay(selectedDay);
              },
              eventLoader: (day) {
                final normalized = DateUtilsEx.startOfDay(day);
                return controller.monthMarkers.contains(normalized) ? [1] : [];
              },
              onPageChanged: (focused) {
                focusedDay = focused;
                controller.loadMonth(
                  DateUtilsEx.startOfMonth(focused),
                  DateUtilsEx.endOfMonth(focused),
                );
              },
            ),
            Expanded(
              child: ListView.builder(
                itemCount: controller.selectedDayItems.length,
                itemBuilder: (context, index) {
                  final item = controller.selectedDayItems[index];
                  return AgendaItemTile(
                    item: item,
                    onTap: () =>
                        Get.toNamed(AppRoutes.upsertAgenda, arguments: item),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Get.toNamed(AppRoutes.upsertAgenda),
        child: const Icon(Icons.add),
      ),
    );
  }
}

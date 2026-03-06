import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../core/routes/app_routes.dart';
import '../../core/utils/date_utils.dart';
import '../controllers/agenda_controller.dart';
import '../widgets/agenda_item_tile.dart';

class WeekPage extends StatefulWidget {
  const WeekPage({super.key});

  @override
  State<WeekPage> createState() => _WeekPageState();
}

class _WeekPageState extends State<WeekPage> {
  @override
  void initState() {
    super.initState();
    final c = Get.find<AgendaController>();
    final now = DateTime.now();
    c.loadWeek(DateUtilsEx.startOfWeek(now), DateUtilsEx.endOfWeek(now));
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<AgendaController>();
    return Scaffold(
      body: SafeArea(
        top: false,
        bottom: false,
        child: Obx(() {
          final grouped = <String, List<dynamic>>{};
          for (final item in controller.weekItems) {
            final key = DateFormat('EEE dd/MM').format(item.startAt);
            grouped.putIfAbsent(key, () => []).add(item);
          }
          return ListView(
            children: grouped.entries.map((entry) {
              return ExpansionTile(
                title: Text('${entry.key} (${entry.value.length})'),
                initiallyExpanded: true,
                children: entry.value
                    .map<Widget>(
                      (item) => AgendaItemTile(
                        item: item,
                        onTap: () =>
                            Get.toNamed(AppRoutes.eventDetail, arguments: item),
                      ),
                    )
                    .toList(),
              );
            }).toList(),
          );
        }),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Get.toNamed(AppRoutes.upsertAgenda),
        child: const Icon(Icons.add),
      ),
    );
  }
}

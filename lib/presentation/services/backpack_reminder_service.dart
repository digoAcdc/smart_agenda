import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/class_schedule_slot.dart';
import '../../domain/repositories/i_family_service.dart';
import '../../domain/repositories/i_notification_service.dart';
import '../../domain/services/backpack_planner.dart';
import '../controllers/class_schedule_controller.dart';

/// "Mochila de amanha": aviso local as 20h com o que levar no dia seguinte,
/// a partir do "o que levar" de cada materia das grades. Agenda as proximas
/// 7 noites; e refeito ao abrir o app e quando a grade muda. Gratis e funciona
/// sem internet (e gerado no aparelho).
class BackpackReminderService extends GetxService {
  static const _enabledKey = 'backpack_reminder_enabled';
  static const _baseId = 770000;
  static const _days = 7;

  final RxBool enabled = true.obs;
  bool _loaded = false;

  Future<void> _load() async {
    if (_loaded) return;
    _loaded = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      enabled.value = prefs.getBool(_enabledKey) ?? true;
    } catch (_) {}
  }

  Future<void> setEnabled(bool value) async {
    enabled.value = value;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_enabledKey, value);
    } catch (_) {}
    await reschedule();
  }

  String _ownerLabel(ClassSchedule schedule) {
    final family = Get.isRegistered<IFamilyService>()
        ? Get.find<IFamilyService>()
        : null;
    return family?.childById(schedule.childId)?.name ?? schedule.name;
  }

  Future<void> reschedule() async {
    if (!Get.isRegistered<INotificationService>() ||
        !Get.isRegistered<ClassScheduleController>()) {
      return;
    }
    await _load();
    final notifications = Get.find<INotificationService>();
    for (var i = 0; i < _days; i++) {
      await notifications.cancelById(_baseId + i);
    }
    if (!enabled.value) return;

    final schedules = Get.find<ClassScheduleController>();
    final plans = buildBackpackPlans(
      schedules: schedules.schedules.toList(),
      slots: schedules.allSlots.toList(),
      now: DateTime.now(),
      ownerLabel: _ownerLabel,
      days: _days,
    );
    for (var i = 0; i < plans.length; i++) {
      await notifications.scheduleAt(
        _baseId + i,
        'Mochila de amanhã 🎒',
        plans[i].body,
        plans[i].notifyAt,
      );
    }
    debugPrint('[Mochila] ${plans.length} avisos agendados');
  }
}

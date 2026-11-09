import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/backpack_item.dart';
import '../../domain/entities/class_schedule_slot.dart';
import '../../domain/repositories/i_family_service.dart';
import '../../domain/repositories/i_notification_service.dart';
import '../../domain/services/backpack_planner.dart';
import '../controllers/class_schedule_controller.dart';

/// "Mochila de amanha": aviso local as 20h com o que levar no dia seguinte,
/// a partir dos itens de cada materia das grades. Agenda as proximas 7
/// noites; e refeito ao abrir o app e quando a grade muda. Gratis e funciona
/// sem internet (e gerado no aparelho).
///
/// Tambem guarda a checklist "ja coloquei" de amanha (so neste aparelho).
/// Ela vale para um dia: no dia seguinte comeca vazia.
class BackpackReminderService extends GetxService {
  static const _enabledKey = 'backpack_reminder_enabled';
  static const _checkedKey = 'backpack_checked';
  static const _baseId = 770000;
  static const _days = 7;

  /// Payload do aviso das 20h: o toque abre a checklist de amanha.
  static const notificationPayload = 'backpack:tomorrow';

  final RxBool enabled = true.obs;
  bool _loaded = false;

  /// Itens marcados como "ja coloquei" para [_checkedDay].
  final RxSet<String> checked = <String>{}.obs;
  String? _checkedDay;

  @override
  void onInit() {
    super.onInit();
    _loadChecked();
  }

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

  static DateTime _tomorrow() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day + 1);
  }

  static String _dayKey(DateTime d) => d.toIso8601String().split('T').first;

  /// O que levar amanha, por materia (Inicio e checklist). Vazio se nada
  /// cadastrado para as aulas de amanha.
  List<BackpackSubjectGroup> tomorrowGroups() {
    if (!Get.isRegistered<ClassScheduleController>()) return const [];
    final schedules = Get.find<ClassScheduleController>();
    return backpackForDay(
      schedules: schedules.schedules.toList(),
      slots: schedules.allSlots.toList(),
      day: _tomorrow(),
      ownerLabel: _ownerLabel,
    );
  }

  /// Chave do item na checklist (o mesmo id pode existir em duas grades).
  static String checkKey(BackpackSubjectGroup group, BackpackItem item) =>
      '${group.scheduleId}|${item.id}';

  /// Sem efeito colateral (e chamado no build): marcacao de outro dia nao
  /// conta, e e limpa no proximo toque.
  bool isChecked(BackpackSubjectGroup group, BackpackItem item) =>
      checked.contains(checkKey(group, item)) &&
      _checkedDay == _dayKey(_tomorrow());

  Future<void> toggleChecked(
    BackpackSubjectGroup group,
    BackpackItem item,
  ) async {
    _resetIfNewDay();
    final key = checkKey(group, item);
    if (!checked.remove(key)) checked.add(key);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _checkedKey,
        jsonEncode({'day': _checkedDay, 'ids': checked.toList()}),
      );
    } catch (_) {}
  }

  /// A checklist e de "amanha": virou o dia, comeca vazia.
  void _resetIfNewDay() {
    final day = _dayKey(_tomorrow());
    if (_checkedDay == day) return;
    _checkedDay = day;
    if (checked.isNotEmpty) checked.clear();
  }

  Future<void> _loadChecked() async {
    _resetIfNewDay();
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_checkedKey);
      if (raw == null) return;
      final data = jsonDecode(raw);
      if (data is! Map || data['day'] != _checkedDay) {
        await prefs.remove(_checkedKey);
        return;
      }
      final ids = data['ids'];
      if (ids is List) checked.addAll(ids.whereType<String>());
    } catch (_) {}
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
        payload: notificationPayload,
      );
    }
    debugPrint('[Mochila] ${plans.length} avisos agendados');
  }
}

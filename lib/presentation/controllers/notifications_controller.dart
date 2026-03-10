import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../core/config/supabase_config.dart';
import '../../core/routes/app_routes.dart';
import '../../core/utils/date_utils.dart';
import '../../data/datasources/notifications_supabase_datasource.dart';
import '../../data/datasources/push_preferences_supabase_datasource.dart';
import '../../domain/entities/user_notification.dart';

class NotificationsController extends GetxController {
  NotificationsController(this._datasource, this._prefsDatasource);

  final NotificationsSupabaseDataSource _datasource;
  final PushPreferencesSupabaseDataSource _prefsDatasource;

  final RxList<UserNotification> notifications = <UserNotification>[].obs;
  final RxBool loading = false.obs;

  final RxBool pushDaily = true.obs;
  final RxBool pushTomorrow = false.obs;
  final RxBool pushWeekly = true.obs;

  final RxBool savingPrefs = false.obs;

  int get unreadCount =>
      notifications.where((n) => !n.isRead).length;

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    if (!SupabaseConfig.isConfigured) return;
    loading.value = true;
    try {
      notifications.value = await _datasource.getNotifications();
      final prefs = await _prefsDatasource.getPreferences();
      pushDaily.value = prefs.pushDailySummary;
      pushTomorrow.value = prefs.pushTomorrowSummary;
      pushWeekly.value = prefs.pushWeeklySummary;
    } catch (_) {
      notifications.clear();
    } finally {
      loading.value = false;
    }
  }

  Future<void> updatePushPreferences({
    required bool daily,
    required bool tomorrow,
    required bool weekly,
  }) async {
    if (!SupabaseConfig.isConfigured) return;
    savingPrefs.value = true;
    try {
      await _prefsDatasource.updatePreferences(
        pushDailySummary: daily,
        pushTomorrowSummary: tomorrow,
        pushWeeklySummary: weekly,
      );
      pushDaily.value = daily;
      pushTomorrow.value = tomorrow;
      pushWeekly.value = weekly;
    } finally {
      savingPrefs.value = false;
    }
  }

  Future<void> onTapNotification(UserNotification n) async {
    if (!n.isRead) {
      try {
        await _datasource.markAsRead(n.id);
        await load();
      } catch (_) {}
    }
    Get.offAllNamed(
      AppRoutes.home,
      arguments: {
        'tab': 1,
        'date': n.referenceDate.toIso8601String().split('T').first,
        if (n.type == 'weekly_summary') 'mode': 'week',
      },
    );
  }

  String formatDate(DateTime d) {
    final now = DateTime.now();
    final today = DateUtilsEx.startOfDay(now);
    final target = DateUtilsEx.startOfDay(d);
    if (target == today) return 'Hoje';
    final yesterday = today.subtract(const Duration(days: 1));
    if (target == yesterday) return 'Ontem';
    return DateFormat('dd/MM/yyyy').format(d);
  }
}

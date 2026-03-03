import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../../core/constants/app_constants.dart';
import '../../core/result/result.dart';
import '../../domain/entities/agenda_item.dart';
import '../../domain/repositories/i_notification_service.dart';

class NotificationServiceImpl implements INotificationService {
  NotificationServiceImpl(this._notificationsPlugin);

  final FlutterLocalNotificationsPlugin _notificationsPlugin;

  @override
  Future<Result<void>> init() async {
    try {
      tz_data.initializeTimeZones();
      const androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      const settings = InitializationSettings(android: androidSettings);
      await _notificationsPlugin.initialize(settings);

      final androidImplementation =
          _notificationsPlugin.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      await androidImplementation?.createNotificationChannel(
        const AndroidNotificationChannel(
          AppConstants.notificationChannelId,
          AppConstants.notificationChannelName,
          importance: Importance.high,
        ),
      );

      return Result.success(null);
    } catch (e) {
      return Result.failure('Falha ao inicializar notificacoes: $e');
    }
  }

  @override
  Future<Result<void>> scheduleForItem(AgendaItem item) async {
    try {
      final reminder = item.reminder;
      if (reminder == null ||
          !reminder.enabled ||
          reminder.minutesBefore == null) {
        return Result.success(null);
      }

      final scheduledAt =
          item.startAt.subtract(Duration(minutes: reminder.minutesBefore!));
      if (scheduledAt.isBefore(DateTime.now())) {
        return Result.success(null);
      }

      await _notificationsPlugin.zonedSchedule(
        reminder.notificationId,
        item.title,
        item.description ?? 'Evento em breve',
        tz.TZDateTime.from(scheduledAt, tz.local),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            AppConstants.notificationChannelId,
            AppConstants.notificationChannelName,
            importance: Importance.high,
            priority: Priority.high,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );
      return Result.success(null);
    } catch (e) {
      return Result.failure('Erro ao agendar notificacao: $e');
    }
  }

  @override
  Future<Result<void>> cancelForItem(AgendaItem item) async {
    try {
      final reminder = item.reminder;
      if (reminder == null) return Result.success(null);
      await _notificationsPlugin.cancel(reminder.notificationId);
      return Result.success(null);
    } catch (e) {
      return Result.failure('Erro ao cancelar notificacao: $e');
    }
  }

  @override
  Future<Result<void>> scheduleDailySummary() async {
    return Result.success(null);
  }
}

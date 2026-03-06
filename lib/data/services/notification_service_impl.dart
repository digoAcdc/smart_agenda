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
  Future<Result<bool>> ensurePermissions() async {
    try {
      bool granted = true;
      var handledRuntimePermission = false;

      final androidImplementation =
          _notificationsPlugin.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      if (androidImplementation != null) {
        handledRuntimePermission = true;
        final enabled =
            await androidImplementation.areNotificationsEnabled() ?? true;
        if (enabled) {
          granted = true;
        } else {
          granted =
              await androidImplementation.requestNotificationsPermission() ??
                  false;
        }
      }

      final iosImplementation =
          _notificationsPlugin.resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>();
      if (iosImplementation != null) {
        handledRuntimePermission = true;
        final iosGranted = await iosImplementation.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
        granted = granted && (iosGranted ?? false);
      }

      final macImplementation =
          _notificationsPlugin.resolvePlatformSpecificImplementation<
              MacOSFlutterLocalNotificationsPlugin>();
      if (macImplementation != null) {
        handledRuntimePermission = true;
        final macGranted = await macImplementation.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
        granted = granted && (macGranted ?? false);
      }

      if (!handledRuntimePermission) {
        return Result.success(true);
      }

      return Result.success(granted);
    } catch (e) {
      return Result.failure('Falha ao solicitar permissao de notificacoes: $e');
    }
  }

  @override
  Future<Result<void>> scheduleForItem(AgendaItem item) async {
    try {
      final permission = await ensurePermissions();
      if (!permission.isSuccess) {
        return Result.failure(permission.errorMessage ?? 'Permissao negada');
      }
      if (!(permission.data ?? false)) {
        return Result.failure('Permissao de notificacao nao concedida');
      }

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

      final scheduleDate = tz.TZDateTime.from(scheduledAt, tz.local);
      final details = const NotificationDetails(
        android: AndroidNotificationDetails(
          AppConstants.notificationChannelId,
          AppConstants.notificationChannelName,
          importance: Importance.high,
          priority: Priority.high,
        ),
      );

      // On some Android devices/versions exact alarms are restricted.
      // Try exact first and fallback to inexact to keep reminders working.
      try {
        await _notificationsPlugin.zonedSchedule(
          reminder.notificationId,
          item.title,
          item.description ?? 'Evento em breve',
          scheduleDate,
          details,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        );
      } catch (_) {
        await _notificationsPlugin.zonedSchedule(
          reminder.notificationId,
          item.title,
          item.description ?? 'Evento em breve',
          scheduleDate,
          details,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        );
      }

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

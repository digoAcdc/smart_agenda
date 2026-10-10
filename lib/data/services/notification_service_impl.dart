import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../../core/constants/app_constants.dart';
import '../../core/result/result.dart';
import '../../domain/entities/agenda_item.dart';
import '../../domain/services/recurrence_expander.dart';
import '../../domain/repositories/i_notification_service.dart';

class NotificationServiceImpl implements INotificationService {
  NotificationServiceImpl(this._notificationsPlugin);

  final FlutterLocalNotificationsPlugin _notificationsPlugin;

  @override
  Future<Result<void>> init({
    Future<void> Function(String? payload)? onNotificationTap,
  }) async {
    try {
      tz_data.initializeTimeZones();
      try {
        final timeZoneInfo = await FlutterTimezone.getLocalTimezone();
        tz.setLocalLocation(tz.getLocation(timeZoneInfo.identifier));
      } catch (_) {
        tz.setLocalLocation(tz.getLocation('America/Sao_Paulo'));
      }
      const androidSettings = AndroidInitializationSettings(
        '@mipmap/ic_launcher',
      );
      final settings = InitializationSettings(
        android: androidSettings,
        iOS: DarwinInitializationSettings(),
      );
      await _notificationsPlugin.initialize(
        settings,
        onDidReceiveNotificationResponse: (response) {
          final payload = response.payload;
          if (payload != null && payload.isNotEmpty) {
            onNotificationTap?.call(payload);
          }
        },
      );

      final androidImplementation = _notificationsPlugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      await androidImplementation?.createNotificationChannel(
        const AndroidNotificationChannel(
          AppConstants.notificationChannelId,
          AppConstants.notificationChannelName,
          importance: Importance.high,
        ),
      );

      if (onNotificationTap != null) {
        final launchDetails = await _notificationsPlugin
            .getNotificationAppLaunchDetails();
        if (launchDetails != null &&
            launchDetails.didNotificationLaunchApp &&
            launchDetails.notificationResponse?.payload != null) {
          final payload = launchDetails.notificationResponse!.payload!;
          if (payload.isNotEmpty) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              onNotificationTap(payload);
            });
          }
        }
      }

      return Result.success(null);
    } catch (e) {
      return Result.failure('Falha ao inicializar notificações: $e');
    }
  }

  @override
  Future<Result<bool>> ensurePermissions() async {
    try {
      bool granted = true;
      var handledRuntimePermission = false;

      final androidImplementation = _notificationsPlugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
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

      final iosImplementation = _notificationsPlugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >();
      if (iosImplementation != null) {
        handledRuntimePermission = true;
        final iosGranted = await iosImplementation.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
        granted = granted && (iosGranted ?? false);
      }

      final macImplementation = _notificationsPlugin
          .resolvePlatformSpecificImplementation<
            MacOSFlutterLocalNotificationsPlugin
          >();
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
      return Result.failure('Falha ao solicitar permissão de notificações: $e');
    }
  }

  /// Id do lembrete: um por evento; em serie que se repete, um por dia.
  int _notificationIdFor(AgendaItem item) {
    final base = item.reminder?.notificationId ?? 0;
    final day = item.occurrenceDate;
    if (day != null) {
      return '${item.id}|${day.year}-${day.month}-${day.day}'.hashCode &
          0x7FFFFFFF;
    }
    return base != 0 ? base : (item.id.hashCode & 0x7FFFFFFF);
  }

  @override
  Future<Result<void>> scheduleForItem(AgendaItem item) async {
    // Serie: agenda as proximas ocorrencias (o app reagenda ao abrir).
    if (item.isRecurring && !item.isOccurrence) {
      if (!(item.reminder?.enabled ?? false)) return Result.success(null);
      for (final occ in RecurrenceExpander.nextOccurrences(
        item,
        DateTime.now(),
      )) {
        final r = await scheduleForItem(occ);
        if (!r.isSuccess) return r;
      }
      return Result.success(null);
    }
    try {
      final permission = await ensurePermissions();
      if (!permission.isSuccess) {
        return Result.failure(permission.errorMessage ?? 'Permissão negada');
      }
      if (!(permission.data ?? false)) {
        return Result.failure('Permissão de notificação não concedida');
      }

      final reminder = item.reminder;
      if (reminder == null ||
          !reminder.enabled ||
          reminder.minutesBefore == null) {
        return Result.success(null);
      }

      final scheduledAt = item.startAt.subtract(
        Duration(minutes: reminder.minutesBefore!),
      );
      if (scheduledAt.isBefore(DateTime.now())) {
        return Result.success(null);
      }

      final scheduleDate = tz.TZDateTime.from(scheduledAt, tz.local);
      final notificationId = _notificationIdFor(item);
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
          notificationId,
          item.title,
          item.description ?? 'Evento em breve',
          scheduleDate,
          details,
          payload: item.id,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        );
      } catch (_) {
        await _notificationsPlugin.zonedSchedule(
          notificationId,
          item.title,
          item.description ?? 'Evento em breve',
          scheduleDate,
          details,
          payload: item.id,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        );
      }

      return Result.success(null);
    } catch (e) {
      return Result.failure('Erro ao agendar notificação: $e');
    }
  }

  @override
  Future<Result<void>> cancelForItem(AgendaItem item) async {
    try {
      final reminder = item.reminder;
      if (reminder == null) return Result.success(null);
      await _notificationsPlugin.cancel(_notificationIdFor(item));
      if (item.isRecurring) {
        // Serie editada/excluida: cancela tambem as proximas ocorrencias.
        final from = DateTime.now().subtract(const Duration(days: 1));
        for (final occ in RecurrenceExpander.nextOccurrences(
          item.copyWith(),
          from,
          limit: 16,
        )) {
          await _notificationsPlugin.cancel(_notificationIdFor(occ));
        }
        final masterId = reminder.notificationId != 0
            ? reminder.notificationId
            : (item.id.hashCode & 0x7FFFFFFF);
        await _notificationsPlugin.cancel(masterId);
      }
      return Result.success(null);
    } catch (e) {
      return Result.failure('Erro ao cancelar notificação: $e');
    }
  }

  @override
  Future<Result<void>> scheduleAt(
    int id,
    String title,
    String body,
    DateTime at,
  ) async {
    try {
      if (!at.isAfter(DateTime.now())) return Result.success(null);
      final details = const NotificationDetails(
        android: AndroidNotificationDetails(
          AppConstants.notificationChannelId,
          AppConstants.notificationChannelName,
          importance: Importance.high,
          priority: Priority.high,
        ),
      );
      // Horario aproximado basta (aviso das 20h): nao exige alarme exato.
      await _notificationsPlugin.zonedSchedule(
        id,
        title,
        body,
        tz.TZDateTime.from(at, tz.local),
        details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
      return Result.success(null);
    } catch (e) {
      return Result.failure('Erro ao agendar aviso: $e');
    }
  }

  @override
  Future<Result<void>> cancelById(int id) async {
    try {
      await _notificationsPlugin.cancel(id);
      return Result.success(null);
    } catch (e) {
      return Result.failure('Erro ao cancelar aviso: $e');
    }
  }

  @override
  Future<Result<void>> scheduleDailySummary() async {
    return Result.success(null);
  }

  @override
  Future<Result<void>> showPush(
    String title,
    String body, {
    String? payload,
  }) async {
    try {
      const details = NotificationDetails(
        android: AndroidNotificationDetails(
          AppConstants.notificationChannelId,
          AppConstants.notificationChannelName,
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      );
      await _notificationsPlugin.show(
        DateTime.now().millisecondsSinceEpoch % 100000,
        title,
        body,
        details,
        payload: payload,
      );
      return Result.success(null);
    } catch (e) {
      return Result.failure('Erro ao exibir notificação: $e');
    }
  }
}

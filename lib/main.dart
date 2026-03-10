import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:get/get.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/config/supabase_config.dart';
import 'core/constants/app_constants.dart';
import 'core/di/app_binding.dart';
import 'data/datasources/fcm_token_supabase_datasource.dart';
import 'core/routes/app_pages.dart';
import 'core/routes/app_routes.dart';
import 'core/services/firebase_service.dart';
import 'core/theme/app_theme.dart';
import 'domain/repositories/i_agenda_repository.dart';
import 'domain/repositories/i_notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await MobileAds.instance.initialize();
  await initializeDateFormatting('pt_BR');
  Intl.defaultLocale = 'pt_BR';
  if (SupabaseConfig.isConfigured) {
    await Supabase.initialize(
      url: SupabaseConfig.url,
      anonKey: SupabaseConfig.anonKey,
    );
  }
  final firebaseOk = await FirebaseService.initialize();
  if (firebaseOk) {
    await FirebaseService.setupPushNotifications(
      onMessage: (m) => _onPushMessage(m),
      onMessageOpenedApp: (m) => _onPushMessageOpened(m),
    );
    final userId = SupabaseConfig.isConfigured
        ? Supabase.instance.client.auth.currentUser?.id
        : null;
    if (userId != null) {
      await FirebaseService.setUserId(userId);
    }
  }
  AppBinding().dependencies();
  if (firebaseOk && SupabaseConfig.isConfigured) {
    FirebaseService.setTokenRefreshCallback((token) async {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null && Get.isRegistered<FcmTokenSupabaseDataSource>()) {
        try {
          await Get.find<FcmTokenSupabaseDataSource>().upsertToken(user.id, token);
        } catch (_) {}
      }
    });
  }
  // App aberto ao tocar em notificação (estado terminated)
  final initialMessage = firebaseOk ? await FirebaseService.getInitialMessage() : null;
  if (initialMessage != null) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _onPushMessageOpened(initialMessage);
    });
  }
  await Get.find<INotificationService>().init(
    onNotificationTap: _handleNotificationTap,
  );
  runApp(const SmartAgendaApp());
}

void _onPushMessage(RemoteMessage message) {
  final title = message.notification?.title ?? message.data['title'] ?? 'Smart Agenda';
  final body = message.notification?.body ?? message.data['body'] ?? '';
  if (body.isEmpty) return;
  final type = message.data['type']?.toString();
  final date = message.data['date']?.toString();
  String? payload;
  if ((type == 'daily_summary' ||
          type == 'tomorrow_summary' ||
          type == 'weekly_summary') &&
      date != null) {
    payload = type == 'weekly_summary' ? 'date:$date;mode:week' : 'date:$date';
  }
  try {
    Get.find<INotificationService>().showPush(title, body, payload: payload);
  } catch (_) {}
}

void _onPushMessageOpened(RemoteMessage message) {
  final type = message.data['type']?.toString();
  final date = message.data['date']?.toString();
  if ((type == 'daily_summary' ||
          type == 'tomorrow_summary' ||
          type == 'weekly_summary') &&
      date != null) {
    _navigateToAgendaFromNotification(
      tab: 1,
      date: date,
      mode: type == 'weekly_summary' ? 'week' : null,
    );
    return;
  }
  final payload = message.data['payload'] ?? message.data['id'];
  if (payload != null && payload.toString().isNotEmpty) {
    _handleNotificationTap(payload.toString());
  }
}

void _navigateToAgendaFromNotification({
  required int tab,
  required String date,
  String? mode,
}) {
  final args = <String, dynamic>{'tab': tab, 'date': date};
  if (mode != null) args['mode'] = mode;
  Get.offAllNamed(AppRoutes.home, arguments: args);
}

Future<void> _handleNotificationTap(String? payload) async {
  if (payload == null || payload.isEmpty) return;
  if (payload.startsWith('date:')) {
    String date = payload.substring(5);
    String? mode;
    if (payload.contains(';mode:')) {
      final parts = payload.split(';mode:');
      date = parts.first.substring(5);
      mode = parts.length > 1 ? parts[1] : null;
    }
    _navigateToAgendaFromNotification(tab: 1, date: date, mode: mode);
    return;
  }
  try {
    final repo = Get.find<IAgendaRepository>();
    final result = await repo.getItemById(payload);
    if (result.isSuccess && result.data != null) {
      Get.toNamed(AppRoutes.eventDetail, arguments: result.data);
    }
  } catch (_) {}
}

class SmartAgendaApp extends StatelessWidget {
  const SmartAgendaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      initialRoute: AppRoutes.home,
      getPages: AppPages.routes,
      locale: const Locale('pt', 'BR'),
      supportedLocales: const [
        Locale('pt', 'BR'),
        Locale('en', 'US'),
      ],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.light,
      builder: (context, child) {
        if (child == null) return const SizedBox.shrink();
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: MediaQuery.of(context).textScaler,
          ),
          child: child,
        );
      },
    );
  }
}

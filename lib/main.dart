import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:get/get.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/config/supabase_config.dart';
import 'core/constants/app_constants.dart';
import 'core/di/app_binding.dart';
import 'data/datasources/agenda_supabase_datasource.dart';
import 'data/datasources/fcm_token_supabase_datasource.dart';
import 'core/routes/app_pages.dart';
import 'core/routes/app_routes.dart';
import 'core/services/firebase_service.dart';
import 'core/theme/app_theme.dart';
import 'domain/entities/agenda_item.dart';
import 'domain/repositories/i_agenda_repository.dart';
import 'domain/repositories/i_notification_service.dart';
import 'presentation/controllers/home_controller.dart';

/// Limite pra cada etapa da abertura. Se uma delas travar (aparelho sem
/// rede, Play Services desatualizado), o app abre sem aquele recurso em
/// vez de ficar parado na splash.
const _startupTimeout = Duration(seconds: 8);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Antes do runApp só o que a primeira tela precisa — tudo local. A
  // splash nativa fica na tela até o primeiro frame: qualquer await que
  // não termine aqui deixa o app "travado" no ícone.
  await _startupStep('datas', () => initializeDateFormatting('pt_BR'));
  Intl.defaultLocale = 'pt_BR';
  if (SupabaseConfig.isConfigured) {
    await _startupStep(
      'supabase',
      () => Supabase.initialize(
        url: SupabaseConfig.url,
        anonKey: SupabaseConfig.anonKey,
      ),
    );
  }
  final firebaseOk = await FirebaseService.initialize();
  AppBinding().dependencies();
  if (firebaseOk && SupabaseConfig.isConfigured) {
    FirebaseService.setTokenRefreshCallback((token) async {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null && Get.isRegistered<FcmTokenSupabaseDataSource>()) {
        try {
          await Get.find<FcmTokenSupabaseDataSource>().upsertToken(
            user.id,
            token,
          );
        } catch (_) {}
      }
    });
  }
  await _startupStep(
    'notificacoes locais',
    () => Get.find<INotificationService>().init(
      onNotificationTap: _handleNotificationTap,
    ),
  );
  runApp(const SmartAgendaApp());

  // Push depende do Play Services e da rede (e no Android 13+ pede
  // permissão): roda com o app já aberto, sem segurar a splash.
  if (firebaseOk) unawaited(_setupPush());
}

Future<void> _startupStep(String name, Future<Object?> Function() step) async {
  try {
    await step().timeout(_startupTimeout);
  } catch (e) {
    debugPrint('[startup] $name falhou: $e');
  }
}

Future<void> _setupPush() async {
  try {
    // App aberto ao tocar em notificação (estado terminated). Antes da
    // permissão: o pedido de permissão espera o usuário responder.
    final initialMessage = await FirebaseService.getInitialMessage();
    if (initialMessage != null) {
      await WidgetsBinding.instance.endOfFrame;
      _onPushMessageOpened(initialMessage);
    }
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
  } catch (e) {
    debugPrint('[startup] push falhou: $e');
  }
}

const _summaryPushTypes = {
  'daily_summary',
  'tomorrow_summary',
  'weekly_summary',
};

/// Payload da notificacao local a partir dos dados do push: resumo vira
/// 'date:...' (abre a Agenda no dia/semana); aviso da Familia vira o id do
/// evento (abre o detalhe).
String? _payloadFromPush(Map<String, dynamic> data) {
  final type = data['type']?.toString();
  final date = data['date']?.toString();
  if (_summaryPushTypes.contains(type) && date != null) {
    return type == 'weekly_summary' ? 'date:$date;mode:week' : 'date:$date';
  }
  final id = data['item_id'] ?? data['payload'] ?? data['id'];
  final value = id?.toString();
  return value == null || value.isEmpty ? null : value;
}

void _onPushMessage(RemoteMessage message) {
  final title =
      message.notification?.title ?? message.data['title'] ?? 'Smart Agenda';
  final body = message.notification?.body ?? message.data['body'] ?? '';
  if (body.isEmpty) return;
  try {
    Get.find<INotificationService>().showPush(
      title,
      body,
      payload: _payloadFromPush(message.data),
    );
  } catch (_) {}
}

void _onPushMessageOpened(RemoteMessage message) {
  _handleNotificationTap(_payloadFromPush(message.data));
}

Future<void> _handleNotificationTap(String? payload) async {
  if (payload == null || payload.isEmpty) return;
  if (payload.startsWith('date:')) {
    final parts = payload.substring(5).split(';mode:');
    final date = DateTime.tryParse(parts.first);
    if (date == null) return;
    Get.find<HomeController>().openAgendaAt(
      date,
      mode: parts.length > 1 ? parts[1] : null,
    );
    return;
  }
  try {
    final item = await _findItemForNotification(payload);
    if (item != null) Get.toNamed(AppRoutes.eventDetail, arguments: item);
  } catch (_) {}
}

/// Evento do aviso: primeiro no aparelho; se ainda nao sincronizou (aviso
/// da Familia chega antes do sync), busca na nuvem.
Future<AgendaItem?> _findItemForNotification(String id) async {
  final local = await Get.find<IAgendaRepository>().getItemById(id);
  if (local.isSuccess && local.data != null) return local.data;
  if (!SupabaseConfig.isConfigured ||
      !Get.isRegistered<AgendaSupabaseDataSource>()) {
    return null;
  }
  return Get.find<AgendaSupabaseDataSource>().fetchItem(id);
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
      supportedLocales: const [Locale('pt', 'BR'), Locale('en', 'US')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.light,
      builder: (context, child) {
        if (child == null) return const SizedBox.shrink();
        return MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: MediaQuery.of(context).textScaler),
          child: child,
        );
      },
    );
  }
}

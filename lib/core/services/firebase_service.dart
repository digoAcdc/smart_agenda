import 'dart:io';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import '../../firebase_options.dart';

/// Handler para mensagens em background (deve ser top-level).
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  if (kDebugMode) {
    debugPrint('Background message: ${message.messageId}');
  }
}

/// Serviço central para Firebase (Analytics + Push).
class FirebaseService {
  FirebaseService._();
  static FirebaseService? _instance;
  static FirebaseService get instance => _instance ??= FirebaseService._();

  FirebaseAnalytics? _analytics;
  FirebaseMessaging? _messaging;
  bool _initialized = false;

  FirebaseAnalytics? get analytics => _analytics;
  FirebaseMessaging? get messaging => _messaging;
  bool get isInitialized => _initialized;

  /// Inicializa Firebase. Retorna true se configurado com sucesso.
  static Future<bool> initialize() async {
    if (instance._initialized) return true;
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      instance._analytics = FirebaseAnalytics.instance;
      instance._messaging = FirebaseMessaging.instance;
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
      instance._initialized = true;
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Configura push notifications: permissão + token.
  static Future<String?> setupPushNotifications({
    void Function(RemoteMessage)? onMessage,
    void Function(RemoteMessage)? onMessageOpenedApp,
  }) async {
    if (!instance._initialized || instance._messaging == null) return null;
    final messaging = instance._messaging!;

    if (onMessage != null) {
      FirebaseMessaging.onMessage.listen(onMessage);
    }
    if (onMessageOpenedApp != null) {
      FirebaseMessaging.onMessageOpenedApp.listen(onMessageOpenedApp);
    }

    final settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    if (settings.authorizationStatus == AuthorizationStatus.denied) {
      return null;
    }

    if (Platform.isAndroid) {
      await messaging.getToken();
    }
    messaging.onTokenRefresh.listen((token) {
      _tokenRefreshCallback?.call(token);
    });
    final token = await messaging.getToken();
    if (kDebugMode && token != null) {
      debugPrint('FCM Token (use para testar push): $token');
    }
    return token;
  }

  static void Function(String)? _tokenRefreshCallback;

  /// Registra callback para quando o token FCM for atualizado (salvar no Supabase).
  static void setTokenRefreshCallback(void Function(String) cb) {
    _tokenRefreshCallback = cb;
  }

  /// Retorna o token FCM atual (para salvar no Supabase).
  static Future<String?> getToken() async {
    if (!instance._initialized || instance._messaging == null) return null;
    return instance._messaging!.getToken();
  }

  /// Mensagem que abriu o app (app estava fechado e usuário tocou na notificação).
  static Future<RemoteMessage?> getInitialMessage() async {
    if (!instance._initialized || instance._messaging == null) return null;
    return instance._messaging!.getInitialMessage();
  }

  /// Registra evento de analytics.
  static Future<void> logEvent({
    required String name,
    Map<String, Object>? parameters,
  }) async {
    if (!instance._initialized || instance._analytics == null) return;
    await instance._analytics!.logEvent(name: name, parameters: parameters);
  }

  /// Define o user ID para analytics (ex: Supabase user id).
  static Future<void> setUserId(String? userId) async {
    if (!instance._initialized || instance._analytics == null) return;
    await instance._analytics!.setUserId(id: userId);
  }
}

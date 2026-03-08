import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:get/get.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/config/supabase_config.dart';
import 'core/constants/app_constants.dart';
import 'core/di/app_binding.dart';
import 'core/routes/app_pages.dart';
import 'core/routes/app_routes.dart';
import 'core/theme/app_theme.dart';
import 'domain/repositories/i_agenda_repository.dart';
import 'domain/repositories/i_notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('pt_BR');
  Intl.defaultLocale = 'pt_BR';
  if (SupabaseConfig.isConfigured) {
    await Supabase.initialize(
      url: SupabaseConfig.url,
      anonKey: SupabaseConfig.anonKey,
    );
  }
  AppBinding().dependencies();
  await Get.find<INotificationService>().init(
    onNotificationTap: _handleNotificationTap,
  );
  runApp(const SmartAgendaApp());
}

Future<void> _handleNotificationTap(String? payload) async {
  if (payload == null || payload.isEmpty) return;
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

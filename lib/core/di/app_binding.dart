import 'dart:io';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../core/config/supabase_config.dart';
import '../../data/datasources/agenda_local_datasource.dart';
import '../../data/datasources/agenda_supabase_datasource.dart';
import '../../data/datasources/class_schedule_datasource_orchestrator.dart';
import '../../data/datasources/class_schedule_local_datasource.dart';
import '../../data/datasources/class_schedule_supabase_datasource.dart';
import '../../data/datasources/groups_local_datasource.dart';
import '../../data/datasources/agenda_sharing_supabase_datasource.dart';
import '../../data/datasources/fcm_token_supabase_datasource.dart';
import '../../data/datasources/notifications_supabase_datasource.dart';
import '../../data/datasources/push_preferences_supabase_datasource.dart';
import '../../data/datasources/subscription_supabase_datasource.dart';
import '../../data/datasources/groups_supabase_datasource.dart';
import '../../data/local/app_database.dart';
import '../../data/repositories/agenda_repository_impl.dart';
import '../../data/repositories/groups_repository_impl.dart';
import '../../data/services/ads_service_stub.dart';
import '../../data/services/agenda_transfer_service_impl.dart';
import '../../data/services/auth_service_stub.dart';
import '../../data/services/file_storage_service_orchestrator.dart';
import '../../data/services/local_to_cloud_migration_service_impl.dart';
import '../../data/services/billing_service_impl.dart';
import '../../data/services/billing_service_stub.dart';
import '../../data/services/plan_service_impl.dart';
import '../../data/services/supabase_auth_service_impl.dart';
import '../../data/services/notification_service_impl.dart';
import '../../data/services/connectivity_service_impl.dart';
import '../../data/services/sharing_service_impl.dart';
import '../../data/services/sharing_service_stub.dart';
import '../../data/services/sync_engine_impl.dart';
import '../../data/services/sync_service_stub.dart';
import '../../domain/repositories/i_ads_service.dart';
import '../../domain/repositories/i_agenda_repository.dart';
import '../../domain/repositories/i_agenda_transfer_service.dart';
import '../../domain/repositories/i_auth_service.dart';
import '../../domain/repositories/i_file_storage_service.dart';
import '../../domain/repositories/i_groups_repository.dart';
import '../../domain/repositories/i_notification_service.dart';
import '../../domain/repositories/i_class_schedule_datasource.dart';
import '../../domain/repositories/i_local_to_cloud_migration_service.dart';
import '../../domain/repositories/i_connectivity_service.dart';
import '../../domain/repositories/i_billing_service.dart';
import '../../domain/repositories/i_plan_service.dart';
import '../../domain/repositories/i_sharing_service.dart';
import '../../domain/repositories/i_sync_service.dart';
import '../../domain/usecases/agenda_usecases.dart';
import '../../domain/usecases/agenda_transfer_usecases.dart';
import '../../domain/usecases/group_usecases.dart';
import '../../presentation/controllers/ads_controller.dart';
import '../../presentation/controllers/billing_controller.dart';
import '../../presentation/controllers/agenda_controller.dart';
import '../../presentation/controllers/auth_controller.dart';
import '../../presentation/controllers/agenda_transfer_controller.dart';
import '../../presentation/controllers/class_schedule_controller.dart';
import '../../presentation/controllers/notifications_controller.dart';
import '../../presentation/controllers/sync_controller.dart';
import '../../presentation/controllers/groups_controller.dart';
import '../../presentation/controllers/home_controller.dart';

class AppBinding extends Bindings {
  @override
  void dependencies() {
    Get.put(AppDatabase(), permanent: true);

    Get.lazyPut(() => AgendaLocalDataSource(Get.find()), fenix: true);
    Get.lazyPut(() => GroupsLocalDataSource(Get.find()), fenix: true);
    Get.lazyPut<IAuthService>(
      () => SupabaseConfig.isConfigured
          ? SupabaseAuthServiceImpl(Supabase.instance.client)
          : AuthServiceStub(),
      fenix: true,
    );
    Get.put<IPlanService>(
      PlanServiceImpl(
        Get.find<IAuthService>(),
        SupabaseConfig.isConfigured ? Supabase.instance.client : null,
      ),
      permanent: true,
    );
    if (SupabaseConfig.isConfigured) {
      Get.lazyPut<AgendaSupabaseDataSource>(
        () => AgendaSupabaseDataSource(Supabase.instance.client),
        fenix: true,
      );
      Get.lazyPut<GroupsSupabaseDataSource>(
        () => GroupsSupabaseDataSource(Supabase.instance.client),
        fenix: true,
      );
      Get.lazyPut<AgendaSharingSupabaseDataSource>(
        () => AgendaSharingSupabaseDataSource(Supabase.instance.client),
        fenix: true,
      );
      Get.lazyPut<SubscriptionSupabaseDataSource>(
        () => SubscriptionSupabaseDataSource(Supabase.instance.client),
        fenix: true,
      );
      Get.lazyPut<FcmTokenSupabaseDataSource>(
        () => FcmTokenSupabaseDataSource(Supabase.instance.client),
        fenix: true,
      );
      Get.lazyPut<NotificationsSupabaseDataSource>(
        () => NotificationsSupabaseDataSource(Supabase.instance.client),
        fenix: true,
      );
      Get.lazyPut<PushPreferencesSupabaseDataSource>(
        () => PushPreferencesSupabaseDataSource(Supabase.instance.client),
        fenix: true,
      );
      Get.lazyPut<NotificationsController>(
        () => NotificationsController(
          Get.find<NotificationsSupabaseDataSource>(),
          Get.find<PushPreferencesSupabaseDataSource>(),
        ),
        fenix: true,
      );
    }
    Get.lazyPut<IBillingService>(
      () => SupabaseConfig.isConfigured && Platform.isAndroid
          ? BillingServiceImpl(
              iap: InAppPurchase.instance,
              subscriptionDataSource: Get.find<SubscriptionSupabaseDataSource>(),
            )
          : BillingServiceStub(),
      fenix: true,
    );
    Get.lazyPut<ISharingService>(
      () => SupabaseConfig.isConfigured
          ? SharingServiceImpl(
              Get.find<IPlanService>(),
              Get.find<IAuthService>(),
              Get.find<AgendaSharingSupabaseDataSource>(),
            )
          : SharingServiceStub(),
      fenix: true,
    );
    if (SupabaseConfig.isConfigured) {
      Get.lazyPut<ILocalToCloudMigrationService>(
        () => LocalToCloudMigrationServiceImpl(
          Get.find<IPlanService>(),
          Get.find<AgendaLocalDataSource>(),
          Get.find<GroupsLocalDataSource>(),
          Get.find<ClassScheduleLocalDataSource>(),
          Get.find<AgendaSupabaseDataSource>(),
          Get.find<GroupsSupabaseDataSource>(),
          Get.find<IFileStorageService>(),
          Supabase.instance.client,
        ),
        fenix: true,
      );
    }
    Get.lazyPut<IAgendaRepository>(
      () => AgendaRepositoryImpl(
        Get.find<AgendaLocalDataSource>(),
        Get.find<ISyncService>(),
        SupabaseConfig.isConfigured ? Get.find<AgendaSupabaseDataSource>() : null,
        Get.find<ISharingService>(),
      ),
      fenix: true,
    );
    Get.lazyPut<IGroupsRepository>(
      () => GroupsRepositoryImpl(
        Get.find<GroupsLocalDataSource>(),
        Get.find<ISyncService>(),
      ),
      fenix: true,
    );
    Get.lazyPut<IFileStorageService>(
      () => FileStorageServiceOrchestrator(
        Get.find<IPlanService>(),
        const Uuid(),
        SupabaseConfig.isConfigured ? Supabase.instance.client : null,
      ),
      fenix: true,
    );
    Get.lazyPut<IAdsService>(() => AdsServiceStub(), fenix: true);
    Get.lazyPut<IConnectivityService>(() => ConnectivityServiceImpl(), fenix: true);
    Get.lazyPut<ISyncService>(
      () => SupabaseConfig.isConfigured
          ? SyncEngineImpl(
              Get.find<IPlanService>(),
              Get.find<IConnectivityService>(),
              Get.find<AgendaLocalDataSource>(),
              Get.find<GroupsLocalDataSource>(),
              Get.find<ClassScheduleLocalDataSource>(),
              Get.find<AgendaSupabaseDataSource>(),
              Get.find<GroupsSupabaseDataSource>(),
              Get.find<IFileStorageService>(),
              Supabase.instance.client,
            )
          : SyncServiceStub(),
      fenix: true,
    );
    Get.lazyPut<INotificationService>(
      () => NotificationServiceImpl(FlutterLocalNotificationsPlugin()),
      fenix: true,
    );
    Get.lazyPut<IAgendaTransferService>(
      () => AgendaTransferServiceImpl(
        database: Get.find(),
        agendaRepository: Get.find(),
        groupsRepository: Get.find(),
        notificationService: Get.find(),
      ),
      fenix: true,
    );

    Get.lazyPut(() => ClassScheduleLocalDataSource(Get.find()), fenix: true);
    if (SupabaseConfig.isConfigured) {
      Get.lazyPut<ClassScheduleSupabaseDataSource>(
        () => ClassScheduleSupabaseDataSource(Supabase.instance.client),
        fenix: true,
      );
    }
    Get.lazyPut<IClassScheduleDataSource>(
      () => ClassScheduleDataSourceOrchestrator(
        Get.find<ClassScheduleLocalDataSource>(),
        Get.find<ISyncService>(),
      ),
      fenix: true,
    );

    Get.lazyPut(() => CreateAgendaItem(Get.find()), fenix: true);
    Get.lazyPut(() => UpdateAgendaItem(Get.find()), fenix: true);
    Get.lazyPut(() => DeleteAgendaItem(Get.find()), fenix: true);
    Get.lazyPut(
      () => DuplicateAgendaItem(Get.find(), () => const Uuid().v4()),
      fenix: true,
    );
    Get.lazyPut(() => SetAgendaStatus(Get.find()), fenix: true);
    Get.lazyPut(() => GetAgendaItemsByDay(Get.find()), fenix: true);
    Get.lazyPut(() => GetAgendaItemsByRange(Get.find()), fenix: true);
    Get.lazyPut(() => GetAgendaMarkersByRange(Get.find()), fenix: true);
    Get.lazyPut(() => SearchAgendaItems(Get.find()), fenix: true);
    Get.lazyPut(() => ExportAgendaToFile(Get.find()), fenix: true);
    Get.lazyPut(() => ImportAgendaFromFile(Get.find()), fenix: true);

    Get.lazyPut(() => CreateGroup(Get.find()), fenix: true);
    Get.lazyPut(() => UpdateGroup(Get.find()), fenix: true);
    Get.lazyPut(() => DeleteGroup(Get.find()), fenix: true);
    Get.lazyPut(() => GetGroups(Get.find()), fenix: true);

    Get.put(HomeController(), permanent: true);
    Get.put(AuthController(Get.find<IAuthService>(), Get.find<IPlanService>()),
        permanent: true);
    Get.put(
      AgendaController(
        createAgendaItem: Get.find(),
        updateAgendaItem: Get.find(),
        deleteAgendaItem: Get.find(),
        duplicateAgendaItem: Get.find(),
        setAgendaStatus: Get.find(),
        getAgendaItemsByDay: Get.find(),
        getAgendaItemsByRange: Get.find(),
        getAgendaMarkersByRange: Get.find(),
        searchAgendaItems: Get.find(),
        notificationService: Get.find(),
      ),
      permanent: true,
    );
    Get.put(
      GroupsController(
        createGroupUseCase: Get.find(),
        updateGroupUseCase: Get.find(),
        deleteGroupUseCase: Get.find(),
        getGroupsUseCase: Get.find(),
      ),
      permanent: true,
    );
    Get.put(ClassScheduleController(Get.find<IClassScheduleDataSource>()),
        permanent: true);
    if (SupabaseConfig.isConfigured) {
      Get.put(
        SyncController(
          Get.find<IConnectivityService>(),
          Get.find<ISyncService>(),
        ),
        permanent: true,
      );
    }
    Get.put(AdsController(Get.find()), permanent: true);
    Get.put(
      BillingController(Get.find<IBillingService>(), Get.find<IPlanService>()),
      permanent: true,
    );
    Get.put(
      AgendaTransferController(
        exportAgendaToFile: Get.find(),
        importAgendaFromFile: Get.find(),
        agendaController: Get.find(),
      ),
      permanent: true,
    );
  }
}

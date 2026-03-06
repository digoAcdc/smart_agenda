import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'package:uuid/uuid.dart';

import '../../data/datasources/agenda_local_datasource.dart';
import '../../data/datasources/agenda_remote_datasource.dart';
import '../../data/datasources/groups_local_datasource.dart';
import '../../data/local/app_database.dart';
import '../../data/repositories/agenda_repository_impl.dart';
import '../../data/repositories/groups_repository_impl.dart';
import '../../data/services/ads_service_stub.dart';
import '../../data/services/agenda_transfer_service_impl.dart';
import '../../data/services/auth_service_stub.dart';
import '../../data/services/file_storage_service_impl.dart';
import '../../data/services/notification_service_impl.dart';
import '../../data/services/sync_service_stub.dart';
import '../../domain/repositories/i_ads_service.dart';
import '../../domain/repositories/i_agenda_repository.dart';
import '../../domain/repositories/i_agenda_transfer_service.dart';
import '../../domain/repositories/i_auth_service.dart';
import '../../domain/repositories/i_file_storage_service.dart';
import '../../domain/repositories/i_groups_repository.dart';
import '../../domain/repositories/i_notification_service.dart';
import '../../domain/repositories/i_sync_service.dart';
import '../../domain/usecases/agenda_usecases.dart';
import '../../domain/usecases/agenda_transfer_usecases.dart';
import '../../domain/usecases/group_usecases.dart';
import '../../presentation/controllers/ads_controller.dart';
import '../../presentation/controllers/agenda_controller.dart';
import '../../presentation/controllers/agenda_transfer_controller.dart';
import '../../presentation/controllers/class_schedule_controller.dart';
import '../../presentation/controllers/groups_controller.dart';
import '../../presentation/controllers/home_controller.dart';

class AppBinding extends Bindings {
  @override
  void dependencies() {
    Get.put(AppDatabase(), permanent: true);

    Get.lazyPut(() => AgendaLocalDataSource(Get.find()), fenix: true);
    Get.lazyPut(() => GroupsLocalDataSource(Get.find()), fenix: true);
    Get.lazyPut<IAgendaRemoteDataSource>(() => AgendaRemoteDataSourceStub(),
        fenix: true);

    Get.lazyPut<IAgendaRepository>(
      () => AgendaRepositoryImpl(Get.find(), Get.find()),
      fenix: true,
    );
    Get.lazyPut<IGroupsRepository>(() => GroupsRepositoryImpl(Get.find()),
        fenix: true);

    Get.lazyPut<IFileStorageService>(() => FileStorageServiceImpl(),
        fenix: true);
    Get.lazyPut<IAdsService>(() => AdsServiceStub(), fenix: true);
    Get.lazyPut<IAuthService>(() => AuthServiceStub(), fenix: true);
    Get.lazyPut<ISyncService>(() => SyncServiceStub(), fenix: true);
    Get.lazyPut<INotificationService>(
      () => NotificationServiceImpl(FlutterLocalNotificationsPlugin()),
      fenix: true,
    );
    Get.lazyPut<IAgendaTransferService>(
      () => AgendaTransferServiceImpl(
        agendaRepository: Get.find(),
        groupsRepository: Get.find(),
        notificationService: Get.find(),
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
    Get.put(ClassScheduleController(Get.find()), permanent: true);
    Get.put(AdsController(Get.find()), permanent: true);
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

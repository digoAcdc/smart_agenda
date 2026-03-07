import 'package:get/get.dart';

import '../../presentation/pages/groups_page.dart';
import '../../presentation/pages/home_page.dart';
import '../../presentation/pages/event_detail_page.dart';
import '../../presentation/pages/privacy_policy_page.dart';
import '../../presentation/pages/upsert_agenda_page.dart';
import 'app_routes.dart';

class AppPages {
  static final routes = <GetPage>[
    GetPage(name: AppRoutes.home, page: HomePage.new),
    GetPage(name: AppRoutes.upsertAgenda, page: UpsertAgendaPage.new),
    GetPage(name: AppRoutes.eventDetail, page: EventDetailPage.new),
    GetPage(name: AppRoutes.groups, page: GroupsPage.new),
    GetPage(name: AppRoutes.privacyPolicy, page: PrivacyPolicyPage.new),
  ];
}

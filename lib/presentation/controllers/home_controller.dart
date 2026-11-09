import 'package:get/get.dart';

import '../../core/routes/app_routes.dart';
import '../services/invite_link_handler.dart';

class HomeController extends GetxController {
  final RxInt currentIndex = 0.obs;
  final Rxn<DateTime> initialDateForAgenda = Rxn<DateTime>();
  final RxnString initialModeForAgenda = RxnString();

  /// Muda a cada [openAgendaAt]: recria a aba Agenda para ela abrir no dia
  /// pedido mesmo que ja estivesse aberta.
  final RxInt agendaNavigationId = 0.obs;

  @override
  void onReady() {
    super.onReady();
    // Convite da Familia por link (abriu o app pelo link ou instalou pela pagina).
    if (Get.isRegistered<InviteLinkHandler>()) {
      Get.find<InviteLinkHandler>().start();
    }
  }

  void setIndex(int value) {
    if (value < 0 || value > 4) return;
    currentIndex.value = value;
  }

  /// Abre a aba Agenda em [date] ('week' mostra a semana). Usado ao tocar
  /// numa notificacao — funciona quantas vezes precisar (o controller e
  /// permanente, entao nao da pra depender dos argumentos da rota).
  void openAgendaAt(DateTime date, {String? mode}) {
    // Volta para a Home que ja existe; so cria outra se ela nao estiver na
    // pilha (ex.: tela de login). Duas Homes vivas disputariam a data.
    Get.until((route) => route.isFirst);
    if (Get.currentRoute != AppRoutes.home) Get.offAllNamed(AppRoutes.home);
    initialDateForAgenda.value = date;
    initialModeForAgenda.value = mode;
    agendaNavigationId.value++;
    currentIndex.value = 1;
  }

  DateTime? get initialDateValueForAgenda => initialDateForAgenda.value;
  String? get initialModeValueForAgenda => initialModeForAgenda.value;

  void clearInitialAgendaNavigation() {
    initialDateForAgenda.value = null;
    initialModeForAgenda.value = null;
  }
}

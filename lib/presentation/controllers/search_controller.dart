import 'package:get/get.dart';

import '../../domain/entities/agenda_enums.dart';
import '../../domain/entities/agenda_item.dart';
import '../../domain/usecases/agenda_usecases.dart';
import '../../domain/value_objects/search_filters.dart';

class SearchController extends GetxController {
  SearchController(this._searchAgendaItems);

  final SearchAgendaItems _searchAgendaItems;

  final RxString query = ''.obs;
  final Rx<SearchDateRangeFilter> dateRange = SearchDateRangeFilter.all.obs;
  final RxnString groupId = RxnString();
  final Rxn<AgendaStatus> status = Rxn<AgendaStatus>();
  final RxList<AgendaItem> results = <AgendaItem>[].obs;
  final RxBool loading = false.obs;

  Future<void> search() async {
    loading.value = true;
    final res = await _searchAgendaItems(
      query.value,
      SearchFilters(
        dateRange: dateRange.value,
        groupId: groupId.value,
        status: status.value,
      ),
    );
    if (res.isSuccess) {
      results.assignAll(res.data ?? []);
    }
    loading.value = false;
  }
}

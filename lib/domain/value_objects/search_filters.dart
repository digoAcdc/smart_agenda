import '../entities/agenda_enums.dart';

enum SearchDateRangeFilter { all, today, next7Days, thisMonth }

class SearchFilters {
  const SearchFilters({
    this.dateRange = SearchDateRangeFilter.all,
    this.groupId,
    this.status,
  });

  final SearchDateRangeFilter dateRange;
  final String? groupId;
  final AgendaStatus? status;

  SearchFilters copyWith({
    SearchDateRangeFilter? dateRange,
    String? groupId,
    AgendaStatus? status,
  }) {
    return SearchFilters(
      dateRange: dateRange ?? this.dateRange,
      groupId: groupId ?? this.groupId,
      status: status ?? this.status,
    );
  }
}

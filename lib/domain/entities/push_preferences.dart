import 'package:equatable/equatable.dart';

class PushPreferences extends Equatable {
  const PushPreferences({
    required this.pushDailySummary,
    required this.pushTomorrowSummary,
    required this.pushWeeklySummary,
  });

  final bool pushDailySummary;
  final bool pushTomorrowSummary;
  final bool pushWeeklySummary;

  @override
  List<Object?> get props => [pushDailySummary, pushTomorrowSummary, pushWeeklySummary];
}

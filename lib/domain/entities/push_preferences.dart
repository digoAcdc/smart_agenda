import 'package:equatable/equatable.dart';

class PushPreferences extends Equatable {
  const PushPreferences({
    required this.pushDailySummary,
    required this.pushTomorrowSummary,
    required this.pushWeeklySummary,
    this.pushFamilyChanges = true,
  });

  final bool pushDailySummary;
  final bool pushTomorrowSummary;
  final bool pushWeeklySummary;

  /// Aviso na hora quando alguem cria/altera/cancela evento da Familia.
  final bool pushFamilyChanges;

  @override
  List<Object?> get props => [
    pushDailySummary,
    pushTomorrowSummary,
    pushWeeklySummary,
    pushFamilyChanges,
  ];
}

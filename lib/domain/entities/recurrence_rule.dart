import 'package:equatable/equatable.dart';

import 'agenda_enums.dart';

class RecurrenceRule extends Equatable {
  const RecurrenceRule({
    this.type = RecurrenceType.none,
    this.interval = 1,
    this.byWeekDays,
    this.count,
    this.until,
    this.exceptions = const [],
  });

  final RecurrenceType type;
  final int interval;
  final List<int>? byWeekDays;
  final int? count;
  final DateTime? until;
  final List<DateTime> exceptions;

  String get label {
    switch (type) {
      case RecurrenceType.none:
        return 'Nao repete';
      case RecurrenceType.daily:
        return interval == 1
            ? 'Repete diariamente'
            : 'Repete a cada $interval dias';
      case RecurrenceType.weekly:
        return interval == 1
            ? 'Repete semanalmente'
            : 'Repete a cada $interval semanas';
      case RecurrenceType.monthly:
        return interval == 1
            ? 'Repete mensalmente'
            : 'Repete a cada $interval meses';
      case RecurrenceType.custom:
        return 'Recorrencia personalizada';
    }
  }

  Map<String, dynamic> toJson() => {
        'type': type.name,
        'interval': interval,
        'byWeekDays': byWeekDays,
        'count': count,
        'until': until?.toIso8601String(),
        'exceptions': exceptions.map((e) => e.toIso8601String()).toList(),
      };

  factory RecurrenceRule.fromJson(Map<String, dynamic> json) {
    final days = json['byWeekDays'] as List<dynamic>?;
    final ex = json['exceptions'] as List<dynamic>?;
    return RecurrenceRule(
      type: RecurrenceType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => RecurrenceType.none,
      ),
      interval: json['interval'] as int? ?? 1,
      byWeekDays: days?.map((e) => e as int).toList(),
      count: json['count'] as int?,
      until: json['until'] == null
          ? null
          : DateTime.parse(json['until'] as String),
      exceptions: ex == null
          ? const []
          : ex.map((e) => DateTime.parse(e as String)).toList(),
    );
  }

  @override
  List<Object?> get props =>
      [type, interval, byWeekDays, count, until, exceptions];
}

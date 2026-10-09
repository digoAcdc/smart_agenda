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
    this.completedDates = const [],
  });

  final RecurrenceType type;
  final int interval;
  final List<int>? byWeekDays;
  final int? count;
  final DateTime? until;

  /// Dias removidos da serie ("excluir so este").
  final List<DateTime> exceptions;

  /// Dias concluidos (cada ocorrencia tem seu proprio "concluido").
  final List<DateTime> completedDates;

  bool get repeats => type != RecurrenceType.none;

  static const _weekdayShort = {
    1: 'seg',
    2: 'ter',
    3: 'qua',
    4: 'qui',
    5: 'sex',
    6: 'sáb',
    7: 'dom',
  };

  /// Texto curto para a tela: "Toda semana (ter, qui)", "Todo dia"...
  String get shortLabel {
    final base = switch (type) {
      RecurrenceType.none => 'Não repete',
      RecurrenceType.daily =>
        interval == 1 ? 'Todo dia' : 'A cada $interval dias',
      RecurrenceType.weekly =>
        interval == 1 ? 'Toda semana' : 'A cada $interval semanas',
      RecurrenceType.monthly =>
        interval == 1 ? 'Todo mês' : 'A cada $interval meses',
      RecurrenceType.custom => 'Personalizado',
    };
    final days = byWeekDays;
    final withDays =
        type == RecurrenceType.weekly && days != null && days.isNotEmpty
        ? '$base (${([...days]..sort()).map((d) => _weekdayShort[d]).join(', ')})'
        : base;
    if (until != null) {
      final u = until!;
      return '$withDays até ${u.day.toString().padLeft(2, '0')}/${u.month.toString().padLeft(2, '0')}';
    }
    if (count != null) return '$withDays, $count vezes';
    return withDays;
  }

  RecurrenceRule copyWith({
    RecurrenceType? type,
    int? interval,
    List<int>? byWeekDays,
    int? count,
    DateTime? until,
    List<DateTime>? exceptions,
    List<DateTime>? completedDates,
    bool clearEnd = false,
  }) {
    return RecurrenceRule(
      type: type ?? this.type,
      interval: interval ?? this.interval,
      byWeekDays: byWeekDays ?? this.byWeekDays,
      count: clearEnd ? null : (count ?? this.count),
      until: clearEnd ? null : (until ?? this.until),
      exceptions: exceptions ?? this.exceptions,
      completedDates: completedDates ?? this.completedDates,
    );
  }

  String get label {
    switch (type) {
      case RecurrenceType.none:
        return 'Não repete';
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
        return 'Recorrência personalizada';
    }
  }

  Map<String, dynamic> toJson() => {
    'type': type.name,
    'interval': interval,
    'byWeekDays': byWeekDays,
    'count': count,
    'until': until?.toIso8601String(),
    'exceptions': exceptions.map((e) => e.toIso8601String()).toList(),
    'completedDates': completedDates.map((e) => e.toIso8601String()).toList(),
  };

  factory RecurrenceRule.fromJson(Map<String, dynamic> json) {
    final days = json['byWeekDays'] as List<dynamic>?;
    final ex = json['exceptions'] as List<dynamic>?;
    final done = json['completedDates'] as List<dynamic>?;
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
      completedDates: done == null
          ? const []
          : done.map((e) => DateTime.parse(e as String)).toList(),
    );
  }

  @override
  List<Object?> get props => [
    type,
    interval,
    byWeekDays,
    count,
    until,
    exceptions,
    completedDates,
  ];
}

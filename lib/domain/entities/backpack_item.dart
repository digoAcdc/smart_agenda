import 'package:equatable/equatable.dart';

/// Com que frequencia o item vai na mochila.
enum BackpackFrequency {
  /// Toda aula da materia.
  weekly,

  /// So num dia de aula escolhido ([BackpackItem.dueDate]); depois dele
  /// some. O nome ficou do formato gravado ("so na proxima aula").
  nextClass,
}

/// Um item da Mochila de uma materia (ex.: "tênis" em Ed. Física).
class BackpackItem extends Equatable {
  const BackpackItem({
    required this.id,
    required this.subject,
    required this.label,
    this.frequency = BackpackFrequency.weekly,
    this.dueDate,
    this.remind = true,
  });

  final String id;
  final String subject;
  final String label;
  final BackpackFrequency frequency;

  /// Dia da aula em que o item vai (so em [BackpackFrequency.nextClass]).
  final DateTime? dueDate;

  /// Entra no aviso das 20h da vespera. Desligado, o item so aparece na
  /// checklist "Amanhã leve". Dado sem o campo (antigo) conta como ligado.
  final bool remind;

  bool get isWeekly => frequency == BackpackFrequency.weekly;

  Map<String, dynamic> toJson() => {
    'id': id,
    'subject': subject,
    'label': label,
    'frequency': frequency.name,
    if (dueDate != null)
      'due': DateTime(
        dueDate!.year,
        dueDate!.month,
        dueDate!.day,
      ).toIso8601String().split('T').first,
    if (!remind) 'remind': false,
  };

  /// Nulo se faltar algo essencial (dado de versao futura ou corrompido).
  static BackpackItem? fromJson(Object? raw) {
    if (raw is! Map) return null;
    final id = raw['id'];
    final subject = raw['subject'];
    final label = raw['label'];
    if (id is! String || subject is! String || label is! String) return null;
    if (subject.trim().isEmpty || label.trim().isEmpty) return null;
    final frequency = raw['frequency'] == BackpackFrequency.nextClass.name
        ? BackpackFrequency.nextClass
        : BackpackFrequency.weekly;
    final due = raw['due'] is String
        ? DateTime.tryParse(raw['due'] as String)
        : null;
    if (frequency == BackpackFrequency.nextClass && due == null) return null;
    return BackpackItem(
      id: id,
      subject: subject.trim(),
      label: label.trim(),
      frequency: frequency,
      dueDate: due,
      remind: raw['remind'] != false,
    );
  }

  BackpackItem copyWith({bool? remind}) => BackpackItem(
    id: id,
    subject: subject,
    label: label,
    frequency: frequency,
    dueDate: dueDate,
    remind: remind ?? this.remind,
  );

  @override
  List<Object?> get props => [id, subject, label, frequency, dueDate, remind];
}

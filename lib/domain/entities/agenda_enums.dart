enum AgendaStatus { pending, done, canceled }

extension AgendaStatusLabel on AgendaStatus {
  /// Nome para a tela (o .name e o valor salvo, em ingles).
  String get label => switch (this) {
    AgendaStatus.pending => 'Pendente',
    AgendaStatus.done => 'Concluído',
    AgendaStatus.canceled => 'Cancelado',
  };
}

enum AttachmentType { image, file, link, audio }

enum SyncState { pending, synced, conflict }

enum ItemSource { local, cloud }

enum RecurrenceType { none, daily, weekly, monthly, custom }

/// Tipo do item: compromisso/evento, tarefa (concluivel) ou lembrete.
enum AgendaItemKind { event, task, reminder }

/// De quem e o item na familia: ninguem especifico, familia toda, um filho ou um membro.
enum AgendaSubjectType { none, family, child, member }

/// Responsavel pelo item: ninguem, todos ou um membro.
enum AgendaAssigneeType { none, all, member }

T enumByName<T extends Enum>(List<T> values, String? name, T fallback) {
  for (final v in values) {
    if (v.name == name) return v;
  }
  return fallback;
}

import 'package:get/get.dart';

import '../../domain/entities/agenda_enums.dart';
import '../../domain/entities/agenda_item.dart';
import '../../domain/repositories/i_family_service.dart';

/// Textos e permissoes de itens da Familia para a UI.
class FamilyItemLabels {
  FamilyItemLabels._();

  static IFamilyService? get _fs =>
      Get.isRegistered<IFamilyService>() ? Get.find<IFamilyService>() : null;

  /// Itens pessoais sempre editaveis; da Familia so para admin/editor de Familia ativa.
  static bool canEdit(AgendaItem item) {
    if (!item.isFamilyItem) return true;
    final ctx = _fs?.context;
    return ctx != null && ctx.familyId == item.familyId && ctx.canEditAgenda;
  }

  /// "De quem e": nome do filho, membro ou "Família". Nulo para itens pessoais.
  static String? subject(AgendaItem item) {
    if (!item.isFamilyItem) return null;
    final fs = _fs;
    switch (item.subjectType) {
      case AgendaSubjectType.child:
        return fs?.childById(item.subjectChildId)?.name ?? 'Filho';
      case AgendaSubjectType.member:
        return fs?.memberById(item.subjectUserId)?.label ?? 'Membro';
      case AgendaSubjectType.family:
      case AgendaSubjectType.none:
        return 'Família';
    }
  }

  /// Cor do filho (quando o item e de um filho).
  static String? subjectColorHex(AgendaItem item) {
    if (item.subjectType != AgendaSubjectType.child) return null;
    return _fs?.childById(item.subjectChildId)?.colorHex;
  }

  static String? assignee(AgendaItem item) {
    if (!item.isFamilyItem) return null;
    switch (item.assigneeType) {
      case AgendaAssigneeType.none:
        return null;
      case AgendaAssigneeType.all:
        return 'Todos';
      case AgendaAssigneeType.member:
        return _fs?.memberById(item.assigneeUserId)?.label ?? 'Membro';
    }
  }

  static String? createdBy(AgendaItem item) {
    if (!item.isFamilyItem || item.createdBy == null) return null;
    return _fs?.memberById(item.createdBy)?.label ?? 'Ex-membro';
  }

  static String? completedBy(AgendaItem item) {
    if (!item.isFamilyItem || item.completedBy == null) return null;
    return _fs?.memberById(item.completedBy)?.label;
  }

  /// Linha curta para cards: "João · Resp.: Mamãe".
  static String? summary(AgendaItem item) {
    final s = subject(item);
    if (s == null) return null;
    final a = assignee(item);
    return a == null ? s : '$s · Resp.: $a';
  }
}

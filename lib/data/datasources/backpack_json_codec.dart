import 'dart:convert';

import '../../domain/entities/backpack_item.dart';
import '../../domain/services/backpack_planner.dart';

/// Chave reservada do bring_json com a lista de itens (formato v2).
///
/// O bring_json continua sendo "materia -> o que levar" (texto), que e o que
/// as versoes antigas do app leem e gravam. A lista nova vai inteira nesta
/// chave: o app antigo a trata como uma materia que nunca aparece na grade e
/// a preserva ao salvar. Assim nao precisa de coluna nova nem migration no
/// Supabase, e a Familia com versoes misturadas nao perde nada.
const backpackV2Key = '_mochila_v2';

/// Le o bring_json (antigo ou v2) como lista de itens.
///
/// - Sem v2 (dado antigo): cada texto vira um item "toda semana", com o texto
///   exato (nao quebra "tênis e uniforme" para nao estragar nada).
/// - Com v2: se o texto de uma materia nao bate com o que o app novo gravou,
///   foi um app antigo que mudou ou apagou; o texto dele vale para aquela
///   materia (os itens "so na proxima aula" ficam).
List<BackpackItem> decodeBackpackItems(String? json) {
  if (json == null || json.isEmpty) return const [];
  final Object? raw;
  try {
    raw = jsonDecode(json);
  } catch (_) {
    return const [];
  }
  if (raw is! Map) return const [];

  final legacy = <String, String>{
    for (final e in raw.entries)
      if (e.key != backpackV2Key &&
          e.value is String &&
          e.key.toString().trim().isNotEmpty &&
          (e.value as String).trim().isNotEmpty)
        e.key.toString().trim(): (e.value as String).trim(),
  };

  final v2 = _decodeV2(raw[backpackV2Key]);
  if (v2 == null) {
    return [for (final e in legacy.entries) _legacyItem(e.key, e.value)];
  }

  final items = [...v2];
  final subjects = {
    ...legacy.keys,
    for (final i in v2)
      if (i.isWeekly) i.subject,
  };
  for (final subject in subjects) {
    final expected = legacyBringText(v2, subject);
    final actual = legacy[subject];
    if (expected == actual) continue;
    items.removeWhere((i) => i.isWeekly && i.subject == subject);
    if (actual != null) items.add(_legacyItem(subject, actual));
  }
  return items;
}

/// Grava a lista como bring_json: texto por materia (para o app antigo) +
/// a lista completa em [backpackV2Key]. Nulo quando nao ha itens.
String? encodeBackpackItems(List<BackpackItem> items) {
  if (items.isEmpty) return null;
  final map = <String, String>{};
  for (final item in items) {
    if (!item.isWeekly || map.containsKey(item.subject)) continue;
    map[item.subject] = legacyBringText(items, item.subject)!;
  }
  map[backpackV2Key] = jsonEncode([for (final i in items) i.toJson()]);
  return jsonEncode(map);
}

/// Texto "o que levar" da materia no formato antigo: os itens de toda
/// semana juntos ("tênis e uniforme"). Nulo se a materia nao tem nenhum.
String? legacyBringText(List<BackpackItem> items, String subject) {
  final labels = [
    for (final i in items)
      if (i.isWeekly && i.subject == subject) i.label,
  ];
  return labels.isEmpty ? null : joinPt(labels);
}

List<BackpackItem>? _decodeV2(Object? value) {
  if (value is! String) return null;
  try {
    final list = jsonDecode(value);
    if (list is! List) return null;
    return [for (final e in list) ?BackpackItem.fromJson(e)];
  } catch (_) {
    return null;
  }
}

/// Id fixo: o mesmo dado antigo gera sempre o mesmo item (o "ja coloquei"
/// nao se perde entre leituras antes de ser regravado).
BackpackItem _legacyItem(String subject, String text) =>
    BackpackItem(id: 'legado:$subject:$text', subject: subject, label: text);

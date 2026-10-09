import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:smart_agenda/data/datasources/family_supabase_datasource.dart';
import 'package:smart_agenda/domain/entities/family.dart';

void main() {
  test('interpreta a resposta real de list_my_family_invites', () {
    // Copiado do servidor (convite real para o hotmail).
    final rows = jsonDecode(
      '[{"invite_id":"6e42a876-66a9-4817-9bb6-34bad0cb8a3a","family_id":"fe32b7a2-7ef0-43e3-abe4-8ba3852c6f02",'
      '"family_name":"silveira","role":"editor","invited_by_name":"barbosa.silveira",'
      '"created_at":"2026-10-09T12:03:34.708353+00:00","expires_at":"2026-10-16T12:03:34.708353+00:00"}]',
    ) as List;
    final invites = FamilySupabaseDataSource.parseMyInvites(rows);
    expect(invites, hasLength(1));
    expect(invites.single.familyName, 'silveira');
    expect(invites.single.role, FamilyRole.editor);
  });

  test('interpreta o contexto real de quem nao tem Familia', () {
    final ctx = FamilyContext.fromJson(jsonDecode(
      '{"has_pro":false,"family_id":null,"family_name":null,"my_role":null,"is_owner":null,'
      '"family_is_active":false,"member_count":0,"max_members":null,"pending_invites":0}',
    ) as Map<String, dynamic>);
    expect(ctx.hasFamily, isFalse);
  });
}

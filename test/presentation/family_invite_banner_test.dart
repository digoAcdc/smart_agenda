import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:smart_agenda/core/result/result.dart';
import 'package:smart_agenda/data/services/family_service_stub.dart';
import 'package:smart_agenda/domain/entities/family.dart';
import 'package:smart_agenda/domain/repositories/i_family_service.dart';
import 'package:smart_agenda/presentation/widgets/family_invite_banner.dart';

/// Usuario sem Familia com um convite pendente.
class _InvitedFamily extends FamilyServiceStub {
  final invites = <FamilyInvite>[
    FamilyInvite(
      id: 'inv1',
      familyId: 'fam',
      familyName: 'Família silveira',
      invitedByName: 'Rodrigo',
      role: FamilyRole.editor,
      createdAt: DateTime(2026, 10, 9),
      expiresAt: DateTime(2026, 10, 16),
    ),
  ].obs;
  final accepted = <String>[];

  @override
  List<FamilyInvite> get myInvites => invites;

  @override
  Future<Result<void>> acceptInvite(String inviteId, {String? nickname}) async {
    accepted.add(inviteId);
    invites.clear();
    return Result.success(null);
  }
}

void main() {
  late _InvitedFamily family;

  setUp(() {
    Get.testMode = true;
    family = _InvitedFamily();
    Get.put<IFamilyService>(family);
  });
  tearDown(Get.reset);

  testWidgets('mostra o convite na Home e aceita com um toque', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: Scaffold(body: FamilyInviteBanner())));

    expect(find.text('Convite para a Família silveira'), findsOneWidget);
    expect(find.textContaining('Rodrigo convidou você como editor'), findsOneWidget);

    await tester.tap(find.text('Aceitar'));
    await tester.pumpAndSettle();

    expect(family.accepted, ['inv1']);
    expect(find.text('Convite para a Família silveira'), findsNothing);
  });

  testWidgets('sem convites nao mostra nada', (tester) async {
    family.invites.clear();
    await tester.pumpWidget(const MaterialApp(home: Scaffold(body: FamilyInviteBanner())));
    expect(find.byType(FilledButton), findsNothing);
  });
}

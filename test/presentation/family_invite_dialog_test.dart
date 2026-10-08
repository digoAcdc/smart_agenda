import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:smart_agenda/data/services/family_service_stub.dart';
import 'package:smart_agenda/domain/entities/family.dart';
import 'package:smart_agenda/domain/repositories/i_auth_service.dart';
import 'package:smart_agenda/domain/repositories/i_family_service.dart';
import 'package:smart_agenda/domain/repositories/i_plan_service.dart';
import 'package:smart_agenda/presentation/controllers/auth_controller.dart';
import 'package:smart_agenda/presentation/pages/family_page.dart';

class _Unused implements IAuthService, IPlanService {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// AuthController sem efeitos colaterais (nao consulta Supabase/Firebase).
class _LoggedInAuth extends AuthController {
  _LoggedInAuth() : super(_Unused(), _Unused());

  @override
  // ignore: must_call_super
  void onInit() {
    isLoggedIn.value = true;
    userEmail.value = 'dono@teste.dev';
  }
}

class _AdminFamily extends FamilyServiceStub {
  @override
  FamilyContext get context => const FamilyContext(
        hasPro: true,
        familyId: 'f1',
        familyName: 'Família Barbosa',
        myRole: FamilyRole.admin,
        isOwner: true,
        isActive: true,
        memberCount: 1,
      );

  @override
  List<FamilyMember> get members => [
        FamilyMember(
          userId: 'u1',
          role: FamilyRole.admin,
          nickname: 'Papai',
          isOwner: true,
          joinedAt: DateTime(2026),
        ),
      ];
}

void main() {
  setUp(() {
    Get.testMode = true;
    Get.put<IFamilyService>(_AdminFamily());
    Get.put<AuthController>(_LoggedInAuth());
  });

  tearDown(Get.reset);

  testWidgets('convite nao estoura em tela pequena com teclado aberto', (tester) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const GetMaterialApp(home: FamilyPage()));
    await tester.pump();

    final inviteButton = find.textContaining('Convidar pessoa');
    await tester.scrollUntilVisible(inviteButton, 200);
    await tester.tap(inviteButton);
    await tester.pumpAndSettle();

    // Teclado abre ao focar o e-mail.
    tester.view.viewInsets = const FakeViewPadding(bottom: 300);

    expect(find.text('Convidar para a Família'), findsOneWidget);
    await tester.enterText(find.byType(TextFormField).last, 'vovo@teste.dev');
    await tester.pumpAndSettle();

    // Qualquer RenderFlex overflow vira excecao no teste.
    expect(tester.takeException(), isNull);
    expect(find.text('Visualizador'), findsOneWidget);
  });
}

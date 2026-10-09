import 'package:flutter_test/flutter_test.dart';
import 'package:smart_agenda/core/theme/app_theme.dart';
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

class _LoggedInAuth extends AuthController {
  _LoggedInAuth() : super(_Unused(), _Unused());
  @override
  // ignore: must_call_super
  void onInit() {
    isLoggedIn.value = true;
    userEmail.value = 'barbosa_silveira@hotmail.com';
  }
}

/// Como o hotmail: sem Pro, sem Familia, 1 convite pendente.
class _Invited extends FamilyServiceStub {
  @override
  FamilyContext get context => const FamilyContext(hasPro: false, isActive: false);
  @override
  List<FamilyInvite> get myInvites => [
        FamilyInvite(
          id: 'inv1',
          familyId: 'fam',
          familyName: 'silveira',
          invitedByName: 'barbosa.silveira',
          role: FamilyRole.editor,
          createdAt: DateTime(2026, 10, 9),
          expiresAt: DateTime(2026, 10, 16),
        ),
      ];
}

void main() {
  setUp(() {
    Get.testMode = true;
    Get.put<IFamilyService>(_Invited());
    Get.put<AuthController>(_LoggedInAuth());
  });
  tearDown(Get.reset);

  testWidgets('tela Familia abre para convidado sem Familia', (tester) async {
    await tester.pumpWidget(GetMaterialApp(theme: AppTheme.light(), home: const FamilyPage()));
    await tester.pump(const Duration(milliseconds: 100));
    expect(tester.takeException(), isNull);
    expect(find.text('silveira'), findsOneWidget);
    expect(find.text('Aceitar'), findsOneWidget);
  });
}

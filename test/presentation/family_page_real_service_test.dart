import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:smart_agenda/data/datasources/family_supabase_datasource.dart';
import 'package:smart_agenda/data/services/family_service_impl.dart';
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

/// Respostas reais do servidor para o hotmail (sem Familia, 1 convite).
class _ServerAsHotmail extends FamilySupabaseDataSource {
  _ServerAsHotmail() : super(SupabaseClient('http://localhost', 'anon'));
  int contextCalls = 0;

  @override
  String? get currentUserId => '9807a8b2-23af-4d1d-82d7-cf48dc01e5eb';

  @override
  Future<FamilyContext> getContext() async {
    contextCalls++;
    return FamilyContext.fromJson(jsonDecode(
      '{"has_pro":false,"family_id":null,"family_name":null,"my_role":null,"is_owner":null,'
      '"family_is_active":false,"member_count":0,"max_members":null,"pending_invites":0}',
    ) as Map<String, dynamic>);
  }

  @override
  Future<List<FamilyInvite>> getMyInvites() async => FamilySupabaseDataSource.parseMyInvites(
        jsonDecode(
          '[{"invite_id":"6e42a876-66a9-4817-9bb6-34bad0cb8a3a","family_id":"fe32b7a2-7ef0-43e3-abe4-8ba3852c6f02",'
          '"family_name":"silveira","role":"editor","invited_by_name":"barbosa.silveira",'
          '"created_at":"2026-10-09T12:03:34.708353+00:00","expires_at":"2026-10-16T12:03:34.708353+00:00"}]',
        ) as List,
      );
}

void main() {
  late _ServerAsHotmail ds;
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    Get.testMode = true;
    ds = _ServerAsHotmail();
    Get.put<IFamilyService>(FamilyServiceImpl(ds));
    Get.put<AuthController>(_LoggedInAuth());
  });
  tearDown(Get.reset);

  testWidgets('tela Familia com servico real nao trava e mostra o convite', (tester) async {
    await tester.pumpWidget(const GetMaterialApp(home: FamilyPage()));
    for (var i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(tester.takeException(), isNull);
    expect(find.text('silveira'), findsOneWidget);
    // Abrir a tela nao pode disparar refresh em loop.
    expect(ds.contextCalls, lessThan(3));
  });
}

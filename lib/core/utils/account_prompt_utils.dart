import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../presentation/controllers/auth_controller.dart';
import '../routes/app_routes.dart';

enum AccountPromptDecision { createAccount, continueWithoutAccount }

class AccountPromptUtils {
  /// Quem ja escolheu usar sem conta nao e perguntado de novo a cada salvar.
  static const _dismissedKey = 'local_save_prompt_dismissed';

  /// Sempre libera o salvamento; so pergunta (uma vez) se quer criar conta.
  static Future<bool> confirmSaveWithoutAccount() async {
    if (!Get.isRegistered<AuthController>()) return true;
    final authController = Get.find<AuthController>();
    if (authController.isLoggedIn.value) return true;

    SharedPreferences? prefs;
    try {
      prefs = await SharedPreferences.getInstance();
      if (prefs.getBool(_dismissedKey) ?? false) return true;
    } catch (_) {}

    final decision = await Get.dialog<AccountPromptDecision>(
      AlertDialog(
        title: const Text('Salvar no aparelho'),
        content: const Text(
          'Sem conta, sua agenda fica salva neste celular.\n\n'
          'Com uma conta você pode participar de uma Família e, no Pro, '
          'sincronizar entre aparelhos.',
        ),
        actions: [
          TextButton(
            onPressed: () =>
                Get.back(result: AccountPromptDecision.continueWithoutAccount),
            child: const Text('Continuar sem criar conta'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(minimumSize: const Size(0, 44)),
            onPressed: () =>
                Get.back(result: AccountPromptDecision.createAccount),
            child: const Text('Criar conta'),
          ),
        ],
      ),
      barrierDismissible: false,
    );

    if (decision == AccountPromptDecision.createAccount) {
      // Salva o que a pessoa digitou e depois abre o cadastro (antes o
      // evento se perdia). A tela do formulario fecha ao salvar.
      Future.delayed(
        const Duration(milliseconds: 500),
        () =>
            Get.toNamed(AppRoutes.register, arguments: {'from': 'local-save'}),
      );
      return true;
    }

    try {
      await prefs?.setBool(_dismissedKey, true);
    } catch (_) {}
    return true;
  }
}

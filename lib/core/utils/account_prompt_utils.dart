import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../presentation/controllers/auth_controller.dart';
import '../routes/app_routes.dart';

enum AccountPromptDecision { createAccount, continueWithoutAccount }

class AccountPromptUtils {
  static Future<bool> confirmSaveWithoutAccount() async {
    if (!Get.isRegistered<AuthController>()) return true;
    final authController = Get.find<AuthController>();
    if (authController.isLoggedIn.value) return true;

    final decision = await Get.dialog<AccountPromptDecision>(
      AlertDialog(
        title: const Text('Sincronização online'),
        content: const Text(
          'Para sincronizar online, é preciso ter uma conta cadastrada.\n\n'
          'Você pode continuar sem conta e salvar localmente no celular.',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: AccountPromptDecision.continueWithoutAccount),
            child: const Text('Continuar sem criar conta'),
          ),
          FilledButton(
            onPressed: () => Get.back(result: AccountPromptDecision.createAccount),
            child: const Text('Criar conta'),
          ),
        ],
      ),
      barrierDismissible: false,
    );

    if (decision == AccountPromptDecision.createAccount) {
      Get.toNamed(AppRoutes.register, arguments: {'from': 'local-save'});
      return false;
    }

    return decision == AccountPromptDecision.continueWithoutAccount;
  }
}

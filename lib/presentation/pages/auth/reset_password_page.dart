import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/design_tokens.dart';
import '../../controllers/auth_controller.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/ui_primitives.dart';

class ResetPasswordPage extends StatefulWidget {
  const ResetPasswordPage({super.key});

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handleReset() async {
    if (!_formKey.currentState!.validate()) return;
    final authController = Get.find<AuthController>();

    final ok = await authController.resetPassword(_emailController.text.trim());
    if (!mounted) return;
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Verifique seu e-mail. Enviamos um link para redefinir sua senha.',
          ),
        ),
      );
      Get.back();
    }
  }

  @override
  Widget build(BuildContext context) {
    final authController = Get.find<AuthController>();
    return Scaffold(
      backgroundColor: context.palette.appBackground,
      appBar: AppBar(
        title: const Text('Recuperar senha'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: DesignTokens.spaceMd),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                const SizedBox(height: DesignTokens.spaceXl),
                Icon(
                  Icons.lock_reset_rounded,
                  size: 56,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: DesignTokens.spaceLg),
                Text(
                  'Esqueceu sua senha?',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: DesignTokens.spaceXs),
                Text(
                  'Informe seu e-mail e enviaremos um link para redefinir sua senha.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: DesignTokens.spaceXl),
                AppSurfaceCard(
                  margin: EdgeInsets.zero,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        autocorrect: false,
                        decoration: const InputDecoration(
                          labelText: 'E-mail',
                          hintText: 'seu@email.com',
                          prefixIcon: Icon(Icons.email_outlined),
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'Informe seu e-mail';
                          }
                          if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                              .hasMatch(v.trim())) {
                            return 'E-mail invalido';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: DesignTokens.spaceLg),
                      Obx(
                        () => PrimaryButton(
                          label: 'Enviar link de recuperacao',
                          icon: Icons.send_rounded,
                          loading: authController.loading.value,
                          onPressed: _handleReset,
                        ),
                      ),
                      if (authController.errorMessage.value != null) ...[
                        const SizedBox(height: DesignTokens.spaceSm),
                        Text(
                          authController.errorMessage.value!,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: context.semanticColors.danger,
                              ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: DesignTokens.spaceLg),
                TextButton(
                  onPressed: () => Get.back(),
                  child: const Text('Voltar ao login'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

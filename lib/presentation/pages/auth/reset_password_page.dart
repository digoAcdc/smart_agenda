import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  final _codeController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  int _step = 1;
  String _emailSent = '';
  int _cooldownSeconds = 0;
  Timer? _cooldownTimer;

  static const int _cooldownDuration = 60;

  void _startCooldown() {
    _cooldownTimer?.cancel();
    setState(() => _cooldownSeconds = _cooldownDuration);
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        _cooldownSeconds--;
        if (_cooldownSeconds <= 0) {
          _cooldownTimer?.cancel();
          _cooldownTimer = null;
        }
      });
    });
  }

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    _emailController.dispose();
    _codeController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleSendCode() async {
    if (!_formKey.currentState!.validate()) return;
    final authController = Get.find<AuthController>();
    final email = _emailController.text.trim();

    final ok = await authController.resetPassword(email);
    if (!mounted) return;
    if (ok) {
      _startCooldown();
      setState(() {
        _emailSent = email;
        _step = 2;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Codigo enviado! Use o codigo do e-mail (ignore o link).',
          ),
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        ),
      );
    } else {
      final msg = authController.errorMessage.value ?? 'Erro ao enviar e-mail.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  Future<void> _handleResetPassword() async {
    if (!_formKey.currentState!.validate()) return;
    final authController = Get.find<AuthController>();

    final ok = await authController.verifyRecoveryAndUpdatePassword(
      _emailSent,
      _codeController.text.trim(),
      _newPasswordController.text,
    );
    if (!mounted) return;
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Senha alterada com sucesso! Faca login.'),
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        ),
      );
      Get.back();
    } else {
      final msg =
          authController.errorMessage.value ?? 'Erro ao redefinir senha.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  Future<void> _handleResendCode() async {
    final authController = Get.find<AuthController>();
    final ok = await authController.resetPassword(_emailSent);
    if (!mounted) return;
    if (ok) {
      _startCooldown();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Novo codigo enviado! Verifique seu e-mail.'),
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        ),
      );
    } else {
      final msg = authController.errorMessage.value ?? 'Erro ao reenviar.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authController = Get.find<AuthController>();
    return Scaffold(
      backgroundColor: context.palette.appBackground,
      appBar: AppBar(
        title: const Text('Recuperar senha'),
        leading: _step == 2
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  authController.errorMessage.value = null;
                  setState(() => _step = 1);
                },
              )
            : null,
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
                if (_step == 1) ...[
                  Text(
                    'Esqueceu sua senha?',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: DesignTokens.spaceXs),
                  Text(
                    'Informe seu e-mail e enviaremos um codigo para redefinir sua senha.',
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
                          enabled: _step == 1,
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
                            label: _cooldownSeconds > 0
                                ? 'Aguarde $_cooldownSeconds s'
                                : 'Enviar codigo',
                            icon: Icons.send_rounded,
                            loading: authController.loading.value,
                            onPressed: _cooldownSeconds > 0
                                ? null
                                : _handleSendCode,
                          ),
                        ),
                        if (authController.errorMessage.value != null) ...[
                          const SizedBox(height: DesignTokens.spaceSm),
                          Text(
                            authController.errorMessage.value!,
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(
                                  color: context.semanticColors.danger,
                                ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ] else ...[
                  Text(
                    'Digite o codigo',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: DesignTokens.spaceXs),
                  Text(
                    'Enviamos um codigo de 6 digitos para $_emailSent',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: DesignTokens.spaceXs),
                  Text(
                    'Ignore o link no e-mail e use apenas o codigo abaixo.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontStyle: FontStyle.italic,
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
                          controller: _codeController,
                          keyboardType: TextInputType.number,
                          autocorrect: false,
                          maxLength: 6,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          decoration: const InputDecoration(
                            labelText: 'Codigo',
                            hintText: '000000',
                            prefixIcon: Icon(Icons.pin_rounded),
                            counterText: '',
                          ),
                          validator: (v) {
                            if (v == null || v.trim().length != 6) {
                              return 'Digite o codigo de 6 digitos';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: DesignTokens.spaceLg),
                        TextFormField(
                          controller: _newPasswordController,
                          obscureText: true,
                          autocorrect: false,
                          decoration: const InputDecoration(
                            labelText: 'Nova senha',
                            hintText: 'Minimo 6 caracteres',
                            prefixIcon: Icon(Icons.lock_outline),
                          ),
                          validator: (v) {
                            if (v == null || v.length < 6) {
                              return 'A senha deve ter pelo menos 6 caracteres';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: DesignTokens.spaceLg),
                        TextFormField(
                          controller: _confirmPasswordController,
                          obscureText: true,
                          autocorrect: false,
                          decoration: const InputDecoration(
                            labelText: 'Confirmar senha',
                            hintText: 'Repita a nova senha',
                            prefixIcon: Icon(Icons.lock_outline),
                          ),
                          validator: (v) {
                            if (v != _newPasswordController.text) {
                              return 'As senhas nao coincidem';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: DesignTokens.spaceLg),
                        Obx(
                          () => PrimaryButton(
                            label: 'Redefinir senha',
                            icon: Icons.check_rounded,
                            loading: authController.loading.value,
                            onPressed: _handleResetPassword,
                          ),
                        ),
                        if (authController.errorMessage.value != null) ...[
                          const SizedBox(height: DesignTokens.spaceSm),
                          Text(
                            authController.errorMessage.value!,
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(
                                  color: context.semanticColors.danger,
                                ),
                          ),
                        ],
                        const SizedBox(height: DesignTokens.spaceSm),
                        TextButton.icon(
                          onPressed: _cooldownSeconds > 0
                              ? null
                              : _handleResendCode,
                          icon: const Icon(Icons.refresh_rounded, size: 18),
                          label: Text(
                            _cooldownSeconds > 0
                                ? 'Reenviar em $_cooldownSeconds s'
                                : 'Reenviar codigo',
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
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

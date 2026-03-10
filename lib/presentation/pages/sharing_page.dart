import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/theme/design_tokens.dart';
import '../../core/utils/form_validators.dart';
import '../../domain/repositories/i_plan_service.dart';
import '../../domain/repositories/i_sharing_service.dart';
import '../controllers/auth_controller.dart';
import '../widgets/ui_primitives.dart';

/// Tela para compartilhar agenda com outros usuarios (premium).
class SharingPage extends StatefulWidget {
  const SharingPage({super.key});

  @override
  State<SharingPage> createState() => _SharingPageState();
}

class _SharingPageState extends State<SharingPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _sharingService = Get.find<ISharingService>();
  final _planService = Get.find<IPlanService>();
  final _authController = Get.find<AuthController>();

  List<AgendaShare> _sharesByMe = [];
  bool _loading = true;
  bool _sharing = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadShares();
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _loadShares() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final result = await _sharingService.getSharesByMe();
    if (!mounted) return;
    setState(() {
      _loading = false;
      _sharesByMe = result.isSuccess ? result.data! : [];
      _error = result.isSuccess ? null : result.errorMessage;
    });
  }

  Future<void> _handleShare() async {
    if (_formKey.currentState?.validate() != true) return;
    final email = _emailController.text.trim();

    setState(() {
      _sharing = true;
      _error = null;
    });
    final result = await _sharingService.shareWith(email);
    if (!mounted) return;
    setState(() {
      _sharing = false;
      _error = result.isSuccess ? null : result.errorMessage;
    });
    if (result.isSuccess) {
      _emailController.clear();
      await _loadShares();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Agenda compartilhada com sucesso.')),
        );
      }
    }
  }

  Future<void> _handleRevoke(String sharedWithId) async {
    final result = await _sharingService.revokeShare(sharedWithId);
    if (!mounted) return;
    if (result.isSuccess) {
      await _loadShares();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Compartilhamento removido.')),
        );
      }
    } else {
      setState(() => _error = result.errorMessage);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_authController.isLoggedIn.value) {
      return Scaffold(
        appBar: AppBar(title: const Text('Compartilhar agenda')),
        body: const Center(
          child: Text('Entre na sua conta para compartilhar.'),
        ),
      );
    }

    return Scaffold(
      backgroundColor: context.palette.appBackground,
      appBar: AppBar(
        title: const Text('Compartilhar minha agenda'),
      ),
      body: FutureBuilder<bool>(
        future: _planService.isPremium(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.data != true) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(DesignTokens.spaceLg),
                child: Text(
                  'Compartilhamento disponivel apenas para usuarios premium.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ),
            );
          }

          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(DesignTokens.spaceMd),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Compartilhe sua agenda com outro usuario. Ele podera visualizar mas nao alterar.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                  const SizedBox(height: DesignTokens.spaceLg),
                  Form(
                    key: _formKey,
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    child: TextFormField(
                      controller: _emailController,
                      decoration: const InputDecoration(
                        labelText: 'Email do usuario',
                        hintText: 'exemplo@email.com',
                        prefixIcon: Icon(Icons.email_outlined),
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.done,
                      validator: (v) => emailValidator(v, required: true),
                      onFieldSubmitted: (_) => _handleShare(),
                    ),
                  ),
                  const SizedBox(height: DesignTokens.spaceSm),
                  if (_error != null) ...[
                    Text(
                      _error!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.error,
                          ),
                    ),
                    const SizedBox(height: DesignTokens.spaceSm),
                  ],
                  FilledButton(
                    onPressed: _sharing ? null : _handleShare,
                    child: _sharing
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Compartilhar'),
                  ),
                  const SizedBox(height: DesignTokens.spaceXl),
                  Text(
                    'Compartilhado com',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: DesignTokens.spaceSm),
                  if (_loading)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: CircularProgressIndicator(),
                      ),
                    )
                  else if (_sharesByMe.isEmpty)
                    AppSurfaceCard(
                      margin: EdgeInsets.zero,
                      child: Text(
                        'Nenhum compartilhamento ativo.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                      ),
                    )
                  else
                    ..._sharesByMe.map((share) => AppSurfaceCard(
                        margin: const EdgeInsets.only(bottom: DesignTokens.spaceSm),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    share.sharedWithEmail,
                                    style: Theme.of(context).textTheme.titleSmall,
                                  ),
                                  Text(
                                    'Compartilhado em ${_formatDate(share.createdAt)}',
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                            TextButton(
                              onPressed: () => _handleRevoke(share.sharedWithId),
                              child: const Text('Remover'),
                            ),
                          ],
                        ),
                      )),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  String _formatDate(DateTime d) {
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  }
}

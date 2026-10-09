import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../domain/repositories/i_family_service.dart';
import '../../domain/repositories/i_personal_to_family_service.dart';

/// Pergunta se a pessoa quer levar a agenda e as grades que tinha so para si
/// para a Familia (sugerido ao criar ou entrar numa Familia).
/// Retorna true se levou.
Future<bool> offerMoveToFamily(
  BuildContext context, {
  bool askEvenIfEmpty = false,
}) async {
  if (!Get.isRegistered<IPersonalToFamilyService>() ||
      !Get.isRegistered<IFamilyService>()) {
    return false;
  }
  final ctx = Get.find<IFamilyService>().context;
  if (!ctx.canEditAgenda || ctx.familyId == null) return false;

  final service = Get.find<IPersonalToFamilyService>();
  final summary = await service.summary();
  if (summary.isEmpty) {
    if (askEvenIfEmpty && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Você não tem nada só seu para levar.')),
      );
    }
    return false;
  }
  if (!context.mounted) return false;

  final parts = [
    if (summary.items > 0)
      '${summary.items} ${summary.items == 1 ? 'evento ou tarefa' : 'eventos e tarefas'}',
    if (summary.schedules > 0)
      '${summary.schedules} ${summary.schedules == 1 ? 'grade' : 'grades'}',
  ];
  final ok = await showDialog<bool>(
    context: context,
    builder: (c) => AlertDialog(
      title: Text('Levar sua agenda para a ${ctx.familyName ?? 'Família'}?'),
      content: Text(
        'Você tem ${parts.join(' e ')} só seus. Levando, toda a Família passa '
        'a ver e editar conforme o papel de cada um.\n\n'
        'Depois, para algo privado, use "Só minha" ao criar o evento.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(c, false),
          child: const Text('Agora não'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(minimumSize: const Size(0, 44)),
          onPressed: () => Navigator.pop(c, true),
          child: const Text('Levar para a Família'),
        ),
      ],
    ),
  );
  if (ok != true || !context.mounted) return false;

  final result = await service.moveAllToFamily(ctx.familyId!);
  if (!context.mounted) return result.isSuccess;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        result.isSuccess
            ? 'Pronto! Sua agenda agora é da ${ctx.familyName ?? 'Família'}.'
            : result.errorMessage ?? 'Erro.',
      ),
    ),
  );
  return result.isSuccess;
}

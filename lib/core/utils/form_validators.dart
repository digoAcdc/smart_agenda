import 'package:brasil_fields/brasil_fields.dart';
import 'package:flutter/services.dart';

/// Validador para campo obrigatorio.
String? requiredValidator(String? value, [String message = 'Campo obrigatorio']) {
  if (value == null || value.trim().isEmpty) return message;
  return null;
}

/// Validador para email.
/// Se [required] for true, exige preenchimento. Senao, valida formato apenas se preenchido.
String? emailValidator(String? value, {bool required = false}) {
  final trimmed = value?.trim() ?? '';
  if (trimmed.isEmpty) {
    return required ? 'Informe o e-mail' : null;
  }
  if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(trimmed)) {
    return 'E-mail invalido';
  }
  return null;
}

/// Validador para telefone brasileiro (10 ou 11 digitos).
/// Se [required] for true, exige preenchimento. Senao, valida formato apenas se preenchido.
String? phoneValidator(String? value, {bool required = false}) {
  final digits = unmaskPhone(value);
  if (digits.isEmpty) {
    return required ? 'Informe o telefone' : null;
  }
  if (digits.length != 10 && digits.length != 11) {
    return 'Telefone invalido (10 ou 11 digitos)';
  }
  return null;
}

/// Remove caracteres nao numericos do telefone para persistencia.
String unmaskPhone(String? value) {
  if (value == null || value.isEmpty) return '';
  return value.replaceAll(RegExp(r'\D'), '');
}

/// Formata telefone para exibicao inicial (ex: ao editar contato).
/// Retorna vazio se invalido; obterTelefone exige 10 ou 11 digitos.
String formatPhoneForDisplay(String? value) {
  final digits = unmaskPhone(value);
  if (digits.isEmpty || (digits.length != 10 && digits.length != 11)) {
    return value?.trim() ?? '';
  }
  return UtilBrasilFields.obterTelefone(digits);
}

/// Formatters para campo de telefone (mascara brasileira).
List<TextInputFormatter> get phoneInputFormatters => [
      FilteringTextInputFormatter.digitsOnly,
      TelefoneInputFormatter(),
    ];

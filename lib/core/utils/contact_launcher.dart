import 'package:url_launcher/url_launcher.dart';

/// Atalhos de contato do professor (email, ligacao, WhatsApp).
Future<void> launchMailto(String email) async {
  final uri = Uri.parse('mailto:$email');
  if (await canLaunchUrl(uri)) {
    await launchUrl(uri);
  }
}

Future<void> launchTel(String phone) async {
  final digits = phone.replaceAll(RegExp(r'\D'), '');
  final uri = Uri.parse('tel:$digits');
  if (await canLaunchUrl(uri)) {
    await launchUrl(uri);
  }
}

Future<void> launchWhatsApp(String phone) async {
  final digits = phone.replaceAll(RegExp(r'\D'), '');
  final number = digits.length >= 12 ? digits : '55$digits';
  final uri = Uri.parse('https://wa.me/$number');
  if (await canLaunchUrl(uri)) {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}

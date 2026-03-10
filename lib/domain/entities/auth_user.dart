import 'package:equatable/equatable.dart';

/// Representacao do usuario autenticado (domain layer, sem dependencia do Supabase).
class AuthUser extends Equatable {
  const AuthUser({
    required this.id,
    required this.email,
  });

  final String id;
  final String email;

  @override
  List<Object?> get props => [id, email];
}

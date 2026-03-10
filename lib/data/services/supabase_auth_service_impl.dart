import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/result/result.dart';
import '../../domain/entities/auth_user.dart' as domain;
import '../../domain/repositories/i_auth_service.dart';

class SupabaseAuthServiceImpl implements IAuthService {
  SupabaseAuthServiceImpl(this._client);

  final SupabaseClient _client;

  @override
  Future<Result<bool>> isLoggedIn() async {
    try {
      final session = _client.auth.currentSession;
      return Result.success(session != null);
    } catch (e) {
      return Result.failure(_mapError(e));
    }
  }

  @override
  Future<Result<domain.AuthUser?>> getCurrentUser() async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) return Result.success(null);
      return Result.success(domain.AuthUser(id: user.id, email: user.email ?? ''));
    } catch (e) {
      return Result.failure(_mapError(e));
    }
  }

  @override
  Future<Result<void>> signInWithEmail(String email, String password) async {
    try {
      await _client.auth.signInWithPassword(email: email, password: password);
      return Result.success(null);
    } catch (e) {
      return Result.failure(_mapError(e));
    }
  }

  @override
  Future<Result<void>> signUp(String email, String password) async {
    try {
      await _client.auth.signUp(email: email, password: password);
      return Result.success(null);
    } catch (e) {
      return Result.failure(_mapError(e));
    }
  }

  @override
  Future<Result<void>> resetPasswordForEmail(String email) async {
    try {
      await _client.auth.resetPasswordForEmail(email);
      return Result.success(null);
    } catch (e) {
      return Result.failure(_mapError(e));
    }
  }

  @override
  Future<Result<void>> verifyRecoveryAndUpdatePassword(
    String email,
    String token,
    String newPassword,
  ) async {
    try {
      await _client.auth.verifyOTP(
        type: OtpType.recovery,
        token: token,
        email: email,
      );
      await _client.auth.updateUser(UserAttributes(password: newPassword));
      return Result.success(null);
    } catch (e) {
      return Result.failure(_mapError(e));
    }
  }

  @override
  Future<Result<void>> signInAnonymously() async {
    try {
      await _client.auth.signInAnonymously();
      return Result.success(null);
    } catch (e) {
      return Result.failure(_mapError(e));
    }
  }

  @override
  Future<Result<void>> signOut() async {
    try {
      await _client.auth.signOut();
      return Result.success(null);
    } catch (e) {
      return Result.failure(_mapError(e));
    }
  }

  String _mapError(Object e) {
    debugPrint('SupabaseAuth error: $e');
    if (e is AuthException) {
      final msg = e.message.toLowerCase();
      if (msg.contains('invalid login credentials') ||
          msg.contains('invalid_credentials')) {
        return 'E-mail ou senha incorretos. Tente novamente.';
      }
      if (msg.contains('email not confirmed')) {
        return 'Confirme seu e-mail antes de entrar. Verifique sua caixa de entrada.';
      }
      if (msg.contains('user already registered') ||
          msg.contains('already registered')) {
        return 'Este e-mail ja esta cadastrado. Faca login ou recupere sua senha.';
      }
      if (msg.contains('password')) {
        return 'A senha deve ter pelo menos 6 caracteres.';
      }
      if (msg.contains('error sending confirmation email') ||
          msg.contains('confirmation email') ||
          (msg.contains('unexpected_failure') &&
              msg.contains('sending'))) {
        return 'SMTP nao configurado. Tente fazer login - sua conta pode ter sido criada. No Supabase: Authentication > Providers > desative "Confirm email".';
      }
      if (msg.contains('error sending') ||
          msg.contains('recovery') ||
          msg.contains('reset') ||
          msg.contains('password reset')) {
        return 'SMTP nao configurado. O link de recuperacao nao pode ser enviado. Configure SMTP no Supabase (Project Settings > Auth > SMTP).';
      }
      if (msg.contains('route') &&
          (msg.contains('api/errors') || msg.contains('not-started'))) {
        return 'Servico de recuperacao nao disponivel. Verifique a configuracao do Supabase (SMTP e Auth).';
      }
      if (msg.contains('otp_expired') ||
          msg.contains('token has expired') ||
          msg.contains('expired')) {
        return 'Codigo expirado. Solicite um novo codigo.';
      }
      if (msg.contains('invalid_otp') ||
          msg.contains('invalid token') ||
          msg.contains('otp verification failed')) {
        return 'Codigo invalido. Verifique e tente novamente.';
      }
      return e.message;
    }
    final str = e.toString().toLowerCase();
    if (str.contains('api/errors') || str.contains('not-started')) {
      return 'Servico de recuperacao nao disponivel. Verifique a configuracao do Supabase (SMTP e Auth).';
    }
    if (str.contains('connection') ||
        str.contains('socket') ||
        str.contains('network') ||
        str.contains('timeout') ||
        str.contains('failed to connect')) {
      return 'Sem conexao. Verifique sua internet e tente novamente.';
    }
    return 'Ocorreu um erro. Tente novamente.';
  }
}

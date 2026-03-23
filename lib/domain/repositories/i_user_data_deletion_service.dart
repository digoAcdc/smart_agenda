import '../../core/result/result.dart';

/// Apaga todos os dados do app no dispositivo e, se houver sessão Supabase,
/// os dados remotos do usuário (sem remover a conta de autenticação).
abstract class IUserDataDeletionService {
  Future<Result<void>> deleteAllUserData();
}

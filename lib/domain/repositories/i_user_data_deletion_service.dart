import '../../core/result/result.dart';

abstract class IUserDataDeletionService {
  /// Apaga os dados do app no aparelho e, com sessao, os dados na nuvem.
  /// A conta de login continua.
  Future<Result<void>> deleteAllUserData();

  /// Exclui a conta de login e tudo ligado a ela (LGPD / Google Play).
  /// Falha se a pessoa for dona de uma Familia (excluir a Familia antes).
  Future<Result<void>> deleteAccount();
}

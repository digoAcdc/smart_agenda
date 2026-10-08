import '../../core/result/result.dart';

abstract class ISyncService {
  /// Envia alteracoes locais e baixa as do servidor (pessoal Pro e Familia).
  Future<Result<void>> syncNow();

  /// Emite quando dados chegaram do servidor e as telas devem recarregar.
  Stream<void> get onDataChanged;

  /// Remove do aparelho dados de nuvem do usuario (logout).
  Future<void> clearCloudCache();
}

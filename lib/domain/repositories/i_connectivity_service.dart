/// Servico que verifica conectividade de rede.
abstract class IConnectivityService {
  /// Retorna true se ha conexao com internet.
  Future<bool> get isOnline;

  /// Stream que emite quando o status de conectividade muda.
  Stream<bool> get onConnectivityChanged;
}

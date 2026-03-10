/// Servico que expoe o status premium de forma sincrona (cacheado).
/// Usado para decisões na UI como exibir ou nao anuncios.
abstract class IPremiumService {
  /// Retorna true se o usuario esta no plano premium (valor cacheado).
  bool get isPremium;

  /// Atualiza o cache consultando IPlanService.
  Future<void> refresh();
}


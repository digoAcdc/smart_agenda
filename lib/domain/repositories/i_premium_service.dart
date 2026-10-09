/// Servico que expoe o status premium de forma sincrona (cacheado).
/// Usado para decisões na UI como exibir ou nao anuncios.
abstract class IPremiumService {
  /// Retorna true se o usuario esta no plano premium (valor cacheado).
  bool get isPremium;

  /// Ja sabe se e Premium (evita pedir anuncio antes de saber).
  bool get isResolved;

  /// Emite sempre que o status e (re)avaliado.
  Stream<void> get changes;

  /// Atualiza o cache consultando IPlanService.
  Future<void> refresh();
}

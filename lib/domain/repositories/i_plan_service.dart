/// Servico que determina se o usuario esta no plano premium.
/// Premium = autenticado + email na allow list ativa.
/// Preparado para futura substituicao por in-app purchase.
abstract class IPlanService {
  /// Retorna true se o usuario esta no plano premium.
  Future<bool> isPremium();

  /// Atualiza o cache do status premium (chamar apos login/logout).
  Future<void> refresh();

  /// Indica se a verificacao do status premium esta em andamento.
  bool get isLoading;

  /// Mensagem de erro da ultima verificacao (se houver).
  String? get error;
}

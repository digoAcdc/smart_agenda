/// Servico que migra dados locais para a nuvem quando o usuario assina premium.
abstract class ILocalToCloudMigrationService {
  /// Executa a migracao se o usuario for premium e ainda nao migrou.
  /// Retorna true se migrou, false se nao era necessario.
  Future<bool> migrateIfNeeded();
}

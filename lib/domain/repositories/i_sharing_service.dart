import '../../core/result/result.dart';

/// Registro de compartilhamento (quem compartilhou com quem).
class AgendaShare {
  const AgendaShare({
    required this.id,
    required this.ownerId,
    required this.sharedWithId,
    required this.ownerEmail,
    required this.sharedWithEmail,
    required this.createdAt,
  });

  final String id;
  final String ownerId;
  final String sharedWithId;
  final String ownerEmail;
  final String sharedWithEmail;
  final DateTime createdAt;
}

/// Servico de compartilhamento de agenda com regras por plano.
abstract class ISharingService {
  /// Compartilha a agenda com o usuario do email informado.
  Future<Result<void>> shareWith(String email);

  /// Revoga o compartilhamento com o usuario.
  Future<Result<void>> revokeShare(String sharedWithId);

  /// Lista compartilhamentos feitos por mim (quem eu compartilhei).
  Future<Result<List<AgendaShare>>> getSharesByMe();

  /// Lista compartilhamentos comigo (quem compartilhou comigo).
  Future<Result<List<AgendaShare>>> getSharesWithMe();
}

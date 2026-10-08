import '../../core/result/result.dart';

abstract class IFileStorageService {
  /// Copia a imagem para a pasta do app e devolve o caminho local.
  Future<Result<String>> copyImageToAppStorage(String sourcePath);

  /// Envia um arquivo local para a nuvem (pasta pessoal ou da Familia)
  /// e devolve a URL de acesso.
  Future<Result<String>> uploadToCloud(String localPath, {String? familyId});
}

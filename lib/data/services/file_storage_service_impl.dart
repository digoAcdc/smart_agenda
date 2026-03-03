import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import '../../core/result/result.dart';
import '../../domain/repositories/i_file_storage_service.dart';

class FileStorageServiceImpl implements IFileStorageService {
  FileStorageServiceImpl({Uuid? uuid}) : _uuid = uuid ?? const Uuid();

  final Uuid _uuid;

  @override
  Future<Result<String>> copyImageToAppStorage(String sourcePath) async {
    try {
      final source = File(sourcePath);
      if (!source.existsSync()) {
        return Result.failure('Arquivo de origem nao encontrado');
      }

      final dir = await getApplicationDocumentsDirectory();
      final attachmentsDir = Directory('${dir.path}/attachments');
      if (!attachmentsDir.existsSync()) {
        attachmentsDir.createSync(recursive: true);
      }

      final extension =
          source.path.contains('.') ? source.path.split('.').last : 'jpg';
      final destPath = '${attachmentsDir.path}/${_uuid.v4()}.$extension';
      await source.copy(destPath);
      return Result.success(destPath);
    } catch (e) {
      return Result.failure('Falha ao salvar imagem: $e');
    }
  }
}

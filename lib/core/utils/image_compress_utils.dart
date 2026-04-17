import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import '../constants/image_upload_constants.dart';

/// Resultado de [prepareImageForStorage]: caminho a usar e se deve apagar após cópia/upload.
class ImagePrepareResult {
  const ImagePrepareResult({
    required this.path,
    required this.isTemporary,
  });

  final String path;
  final bool isTemporary;
}

/// Compressão centralizada antes de salvar/copiar/upload (sync, migração, UI).
class ImageCompressUtils {
  ImageCompressUtils._();

  static final _uuid = Uuid();

  /// Comprime/redimensiona para JPEG em arquivo temporário quando possível.
  /// Em falha, devolve o [sourcePath] original (`isTemporary: false`).
  static Future<ImagePrepareResult> prepareImageForStorage(
    String sourcePath,
  ) async {
    final source = File(sourcePath);
    if (!await source.exists()) {
      debugPrint('[ImageCompress] Arquivo inexistente: $sourcePath');
      return ImagePrepareResult(path: sourcePath, isTemporary: false);
    }

    try {
      final tempDir = await getTemporaryDirectory();
      final targetPath =
          '${tempDir.path}/smart_agenda_img_${_uuid.v4()}.jpg';

      final xfile = await FlutterImageCompress.compressAndGetFile(
        sourcePath,
        targetPath,
        minWidth: ImageUploadConstants.compressMinWidth,
        minHeight: ImageUploadConstants.compressMinHeight,
        quality: ImageUploadConstants.compressQuality,
        format: CompressFormat.jpeg,
      );

      if (xfile == null) {
        debugPrint('[ImageCompress] compressAndGetFile retornou null');
        return ImagePrepareResult(path: sourcePath, isTemporary: false);
      }

      final out = File(xfile.path);
      if (!await out.exists()) {
        return ImagePrepareResult(path: sourcePath, isTemporary: false);
      }

      return ImagePrepareResult(path: xfile.path, isTemporary: true);
    } catch (e, st) {
      debugPrint('[ImageCompress] Erro: $e\n$st');
      return ImagePrepareResult(path: sourcePath, isTemporary: false);
    }
  }

  static Future<void> deleteIfTemporary(ImagePrepareResult result) async {
    if (!result.isTemporary) return;
    try {
      final f = File(result.path);
      if (await f.exists()) await f.delete();
    } catch (_) {}
  }
}

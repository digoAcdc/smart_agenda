import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../core/result/result.dart';
import '../../core/utils/image_compress_utils.dart';
import '../../domain/repositories/i_file_storage_service.dart';

/// Imagens ficam sempre no aparelho primeiro; o envio para a nuvem
/// acontece na sincronizacao ([uploadToCloud]), na pasta do escopo:
/// `user/<uid>/` (pessoal) ou `family/<family_id>/` (Familia).
class FileStorageServiceOrchestrator implements IFileStorageService {
  FileStorageServiceOrchestrator(
    this._uuid,
    this._client,
  );

  final Uuid _uuid;
  final SupabaseClient? _client;

  @override
  Future<Result<String>> copyImageToAppStorage(String sourcePath) async {
    ImagePrepareResult? prepared;
    try {
      prepared = await ImageCompressUtils.prepareImageForStorage(sourcePath);
      final source = File(prepared.path);
      if (!source.existsSync()) {
        return Result.failure('Arquivo de origem nao encontrado');
      }
      return _copyLocal(source);
    } catch (e) {
      return Result.failure('Falha ao salvar imagem: $e');
    } finally {
      if (prepared != null) {
        await ImageCompressUtils.deleteIfTemporary(prepared);
      }
    }
  }

  Future<Result<String>> _copyLocal(File source) async {
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
  }

  @override
  Future<Result<String>> uploadToCloud(String localPath, {String? familyId}) async {
    final source = File(localPath);
    if (!source.existsSync()) {
      return Result.failure('Arquivo local nao encontrado');
    }
    try {
      final client = _client;
      if (client == null) return Result.failure('Supabase nao configurado');
      final uid = client.auth.currentUser?.id;
      if (uid == null) {
        return Result.failure('Usuario nao autenticado');
      }

      final extension =
          source.path.contains('.') ? source.path.split('.').last : 'jpg';
      final attachmentId = _uuid.v4();
      final folder = familyId != null ? 'family/$familyId' : 'user/$uid';
      final storagePath = '$folder/$attachmentId.$extension';

      await client.storage.from('attachments').upload(
            storagePath,
            source,
            fileOptions: const FileOptions(upsert: true),
          );

      const expirySeconds = 365 * 24 * 3600;
      final url = await client.storage
          .from('attachments')
          .createSignedUrl(storagePath, expirySeconds);
      debugPrint('[FileStorageOrchestrator] uploaded to $storagePath');
      return Result.success(url);
    } catch (e) {
      return Result.failure('Upload falhou: $e');
    }
  }
}

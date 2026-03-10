import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../core/result/result.dart';
import '../../domain/repositories/i_file_storage_service.dart';
import '../../domain/repositories/i_plan_service.dart';

/// Orquestrador: free = copia local; premium = upload para Supabase Storage.
/// Retorna path local ou URL publica conforme o plano.
class FileStorageServiceOrchestrator implements IFileStorageService {
  FileStorageServiceOrchestrator(
    this._planService,
    this._uuid,
    this._client,
  );

  final IPlanService _planService;
  final Uuid _uuid;
  final SupabaseClient? _client;

  @override
  Future<Result<String>> copyImageToAppStorage(String sourcePath) async {
    try {
      final source = File(sourcePath);
      if (!source.existsSync()) {
        return Result.failure('Arquivo de origem nao encontrado');
      }

      if (await _planService.isPremium() && _client != null) {
        final uploaded = await _uploadToStorage(source);
        if (uploaded.isSuccess) return uploaded;
        return _copyLocal(source);
      }
      return _copyLocal(source);
    } catch (e) {
      return Result.failure('Falha ao salvar imagem: $e');
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

  Future<Result<String>> _uploadToStorage(File source) async {
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
      final storagePath = '$uid/$attachmentId.$extension';

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

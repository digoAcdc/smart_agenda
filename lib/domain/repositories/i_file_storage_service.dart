import '../../core/result/result.dart';

abstract class IFileStorageService {
  Future<Result<String>> copyImageToAppStorage(String sourcePath);
}

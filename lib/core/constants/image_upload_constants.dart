/// Limites para escolha e compressão de imagens (anexos de agenda/notas).
abstract final class ImageUploadConstants {
  /// Primeira redução no [ImagePicker] (lado nativo).
  static const double pickImageMaxWidth = 1600;
  static const double pickImageMaxHeight = 1600;
  static const int pickImageQuality = 85;

  /// Segunda passagem em [ImageCompressUtils] via `flutter_image_compress`.
  /// `minWidth`/`minHeight` do plugin: se a imagem for maior, é redimensionada
  /// mantendo proporção (ver documentação do pacote).
  static const int compressMinWidth = 1600;
  static const int compressMinHeight = 1600;
  static const int compressQuality = 80;

  /// Acima disso, comprime de novo, menor e com menos qualidade.
  static const int targetMaxBytes = 2 * 1024 * 1024;
  static const int fallbackMinSide = 1280;
  static const int fallbackQuality = 60;

  /// Limite do bucket `attachments` no servidor (5 MB).
  static const int hardMaxBytes = 5 * 1024 * 1024;

  /// Fotos por evento (o servidor tambem barra, migration 027).
  static const int maxAttachmentsPerItem = 5;
}

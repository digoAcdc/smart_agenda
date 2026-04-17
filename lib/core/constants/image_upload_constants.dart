/// Limites para escolha e compressão de imagens (anexos de agenda/notas).
abstract final class ImageUploadConstants {
  /// Primeira redução no [ImagePicker] (lado nativo).
  static const double pickImageMaxWidth = 2048;
  static const double pickImageMaxHeight = 2048;
  static const int pickImageQuality = 85;

  /// Segunda passagem em [ImageCompressUtils] via `flutter_image_compress`.
  /// `minWidth`/`minHeight` do plugin: se a imagem for maior, é redimensionada
  /// mantendo proporção (ver documentação do pacote).
  static const int compressMinWidth = 1920;
  static const int compressMinHeight = 1920;
  static const int compressQuality = 85;
}

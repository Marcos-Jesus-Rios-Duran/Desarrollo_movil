import 'dart:typed_data';
import 'package:firabase_multimedia/features/media/domain/models/media_item.dart';

/// Contrato abstracto para el repositorio de medios.
///
/// Define las operaciones de persistencia sin acoplar
/// la capa de dominio a Firebase ni a ninguna implementación concreta.
abstract class IMediaRepository {
  /// Sube bytes de imagen comprimidos a Cloud Storage.
  ///
  /// La imagen se almacena en `users/{userId}/photos/{uuid.jpg}`
  /// respetando las reglas de seguridad de Storage.
  ///
  /// Retorna la Download URL del archivo subido.
  ///
  /// [onProgress] recibe la fracción real de bytes transferidos
  /// (`bytesTransferred / totalBytes`), de 0.0 a 1.0.
  Future<String> uploadImageBytes(
    Uint8List bytes,
    String userId, {
    void Function(double progress)? onProgress,
  });

  /// Persiste el documento [MediaItem] en Firestore.
  ///
  /// Guarda la Download URL (String) en Firestore,
  /// nunca los bytes en base64.
  Future<void> saveMediaDocument(MediaItem item);

  /// Elimina el binario asociado a [downloadUrl].
  ///
  /// Se usa si la escritura en Firestore falla, para no dejar
  /// archivos huérfanos en el bucket.
  Future<void> deleteUploadedImage(String downloadUrl);

  /// Recupera la lista de imágenes ordenadas por fecha descendente.
  Future<List<MediaItem>> getMediaItems(String ownerId);
}

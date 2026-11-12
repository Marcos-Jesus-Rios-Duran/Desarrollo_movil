import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';
import 'package:firabase_multimedia/features/media/domain/models/media_item.dart';
import 'package:firabase_multimedia/features/media/domain/repositories/i_media_repository.dart';
import 'package:firabase_multimedia/features/media/data/dtos/media_item_dto.dart';

/// Implementación concreta de [IMediaRepository] usando Firebase.
///
/// - **Cloud Storage** (`putData`): almacena los binarios de imagen.
/// - **Cloud Firestore** (colección `productos`): persiste la metadata
///   incluyendo la Download URL como String.
///
/// **Regla de Oro:** Los binarios NUNCA se guardan en Firestore;
/// solo la URL de descarga.
///
/// **Ruta segura:** `users/{userId}/photos/{uuid.jpg}`
class FirebaseMediaRepository implements IMediaRepository {
  final FirebaseStorage _storage;
  final FirebaseFirestore _firestore;
  final Uuid _uuid;

  FirebaseMediaRepository(this._storage, this._firestore, this._uuid);

  @override
  Future<String> uploadImageBytes(
    Uint8List bytes,
    String userId, {
    void Function(double progress)? onProgress,
  }) async {
    final fileName = '${_uuid.v4()}.jpg';
    final ref = _storage.ref().child('users/$userId/photos/$fileName');

    final uploadTask = ref.putData(
      bytes,
      SettableMetadata(contentType: 'image/jpeg'),
    );

    final subscription = uploadTask.snapshotEvents.listen((snapshot) {
      final total = snapshot.totalBytes;
      if (total <= 0) return;
      onProgress?.call(snapshot.bytesTransferred / total);
    });

    try {
      await uploadTask;
      return ref.getDownloadURL();
    } finally {
      await subscription.cancel();
    }
  }

  @override
  Future<void> deleteUploadedImage(String downloadUrl) {
    return _storage.refFromURL(downloadUrl).delete();
  }

  @override
  Future<void> saveMediaDocument(MediaItem item) async {
    // Convierte el modelo de dominio a DTO para serialización
    final dto = MediaItemDto.fromDomain(item);

    // Persiste en la colección 'productos' usando el ID como document ID
    await _firestore.collection('productos').doc(item.id).set(dto.toJson());
  }

  @override
  Future<List<MediaItem>> getMediaItems(String ownerId) async {
    try {
      // Ordenamos por 'updatedAt' ya que es el campo inyectado en MediaItemDto.toJson()
      final snapshot = await _firestore
          .collection('productos')
          .where('ownerId', isEqualTo: ownerId)
          .get();

      // Deserializamos usando el DTO y convertimos al modelo de dominio puro
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return MediaItemDto.fromJson(data).toDomain();
      }).toList();
    } catch (e) {
      throw Exception('Error al obtener la galería: $e');
    }
  }
}

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
  Future<String> uploadImageBytes(Uint8List bytes, String userId) async {
    // Genera un nombre único para prevenir sobreescrituras
    final fileName = '${_uuid.v4()}.jpg';

    // Ruta segura: users/{userId}/photos/{uuid.jpg}
    final ref = _storage.ref().child('users/$userId/photos/$fileName');

    // Sube los bytes comprimidos con metadata de tipo JPEG
    final uploadTask = await ref.putData(
      bytes,
      SettableMetadata(contentType: 'image/jpeg'),
    );

    // Obtiene y retorna la Download URL
    final downloadUrl = await uploadTask.ref.getDownloadURL();
    return downloadUrl;
  }

  @override
  Future<void> saveMediaDocument(MediaItem item) async {
    // Convierte el modelo de dominio a DTO para serialización
    final dto = MediaItemDto.fromDomain(item);

    // Persiste en la colección 'productos' usando el ID como document ID
    await _firestore.collection('productos').doc(item.id).set(dto.toJson());
  }

  Future<List<MediaItem>> getMediaItems() async {
    try {
      // Ordenamos por 'updatedAt' ya que es el campo inyectado en MediaItemDto.toJson()
      final snapshot = await _firestore
          .collection('productos')
          .orderBy('updatedAt', descending: true)
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


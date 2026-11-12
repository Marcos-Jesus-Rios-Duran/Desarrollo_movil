import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firabase_multimedia/features/media/domain/models/media_item.dart';

/// Data Transfer Object para serializar/deserializar [MediaItem]
/// desde y hacia Firestore.
///
/// Separa la lógica de serialización del modelo de dominio puro,
/// inyectando campos específicos de infraestructura como
/// `FieldValue.serverTimestamp()`.
class MediaItemDto {
  final String id;
  final String name;
  final String imageUrl;
  final String ownerId;

  const MediaItemDto({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.ownerId,
  });

  /// Construye un DTO desde un modelo de dominio.
  factory MediaItemDto.fromDomain(MediaItem item) {
    return MediaItemDto(
      id: item.id,
      name: item.name,
      imageUrl: item.imageUrl,
      ownerId: item.ownerId,
    );
  }

  /// Convierte el DTO a un Map serializable para Firestore.
  ///
  /// Inyecta `updatedAt` con `FieldValue.serverTimestamp()`
  /// para tener timestamps consistentes generados por el servidor.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'imageUrl': imageUrl,
      'ownerId': ownerId,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  /// Construye un DTO desde un documento de Firestore.
  factory MediaItemDto.fromJson(Map<String, dynamic> json) {
    return MediaItemDto(
      id: json['id'] as String,
      name: json['name'] as String,
      imageUrl: json['imageUrl'] as String,
      ownerId: json['ownerId'] as String,
    );
  }

  /// Convierte el DTO de vuelta a un modelo de dominio.
  MediaItem toDomain() {
    return MediaItem(
      id: id,
      name: name,
      imageUrl: imageUrl,
      ownerId: ownerId,
    );
  }
}

import 'package:equatable/equatable.dart';

/// Modelo puro de dominio que representa un elemento multimedia.
///
/// Es inmutable y utiliza [Equatable] para comparaciones por valor
/// en lugar de por referencia, facilitando tests y manejo de estado.
///
/// **Regla de Oro:** [imageUrl] almacena la Download URL de Cloud Storage,
/// NUNCA datos en base64.
class MediaItem extends Equatable {
  /// Identificador único (UUID).
  final String id;

  /// Nombre descriptivo del elemento multimedia.
  final String name;

  /// URL de descarga de Cloud Storage.
  ///
  /// Se obtiene tras subir el binario a Firebase Storage
  /// y se persiste como String en Firestore.
  final String imageUrl;

  /// UID de Firebase Auth propietario del recurso.
  final String ownerId;

  const MediaItem({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.ownerId,
  });

  @override
  List<Object?> get props => [id, name, imageUrl, ownerId];

  /// Copia superficial con campos opcionales sobreescritos.
  MediaItem copyWith({
    String? id,
    String? name,
    String? imageUrl,
    String? ownerId,
  }) {
    return MediaItem(
      id: id ?? this.id,
      name: name ?? this.name,
      imageUrl: imageUrl ?? this.imageUrl,
      ownerId: ownerId ?? this.ownerId,
    );
  }

  @override
  String toString() => 'MediaItem(id: $id, name: $name)';
}

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/equipment_model.dart';

/// Servicio que encapsula toda comunicación con Firestore.
/// La capa de vista nunca importa Firebase directamente; depende de esta abstracción.
class EquipmentService {
  /// Instancia privada de Firestore (puede ser inyectada en tests).
  final FirebaseFirestore _firestore;

  EquipmentService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Devuelve un [Stream] reactivo sobre la colección 'Equipment'.
  ///
  /// * Ordena por 'name' ascendente.
  /// * Limita a 20 documentos.
  /// * Firestore maneja automáticamente inserciones, borrados y actualizaciones
  ///   sin necesidad de "pull-to-refresh" manual.
  Stream<List<EquipmentModel>> getCatalogStream() {
    return _firestore
        .collection('Equipment')
        .orderBy('name')
        .limit(20)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(EquipmentModel.fromDocument)
              .toList(growable: false),
        );
  }
}

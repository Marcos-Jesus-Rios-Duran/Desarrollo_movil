import 'package:cloud_firestore/cloud_firestore.dart';

/// Modelo puro de dominio que representa un equipo del catálogo.
/// La vista no conoce nada de Firebase; solo trabaja con esta clase.
class EquipmentModel {
  final String id;
  final String name;
  final String category;
  final bool status;
  final double price;

  const EquipmentModel({
    required this.id,
    required this.name,
    required this.category,
    required this.status,
    required this.price,
  });

  /// Construye un [EquipmentModel] a partir de un [DocumentSnapshot] de Firestore.
  /// Aplica valores por defecto seguros si algún campo es nulo o tiene tipo incorrecto.
  factory EquipmentModel.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    return EquipmentModel(
      id: doc.id,
      name: (data['name'] as String?) ?? 'Sin nombre',
      category: (data['category'] as String?) ?? 'Sin categoría',
      status: (data['status'] as bool?) ?? false,
      // 'Precio' puede llegar como int o double desde Firestore
      price: (data['Precio'] as num?)?.toDouble() ?? 0.0,
    );
  }

  // ---------------------------------------------------------------------------
  // Igualdad estructural: Flutter usa == internamente para decidir si un widget
  // necesita repintarse. Al implementar esto correctamente evitamos rebuilds
  // innecesarios cuando el stream emite el mismo conjunto de datos.
  // ---------------------------------------------------------------------------

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is EquipmentModel &&
        other.id == id &&
        other.name == name &&
        other.category == category &&
        other.status == status &&
        other.price == price;
  }

  @override
  int get hashCode =>
      Object.hash(id, name, category, status, price);

  @override
  String toString() =>
      'EquipmentModel(id: $id, name: $name, category: $category, '
      'status: $status, price: $price)';
}

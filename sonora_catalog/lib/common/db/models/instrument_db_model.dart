/// Modelo de base de datos para la tabla/colección de instrumentos musicales.
///
/// Refleja las columnas de SQLite y los campos remotos de Cloud Firestore,
/// incluyendo metadatos de sincronización y borrado lógico.
class InstrumentDbModel {
  final String id;
  final String categoryId;
  final String name;
  final String brand;
  final double price;
  final int stock;
  final int version;
  final String updatedAt;
  final int isSynced;
  final int isDeleted;

  const InstrumentDbModel({
    required this.id,
    required this.categoryId,
    required this.name,
    required this.brand,
    required this.price,
    required this.stock,
    this.version = 1,
    required this.updatedAt,
    this.isSynced = 0,
    this.isDeleted = 0,
  });

  // ---------------------------------------------------------------------------
  // Serialización para SQLite (Local)
  // ---------------------------------------------------------------------------

  /// Crea una instancia de [InstrumentDbModel] desde una fila de SQLite.
  factory InstrumentDbModel.fromMap(Map<String, dynamic> map) {
    return InstrumentDbModel(
      id: map['id'] as String,
      categoryId: map['category_id'] as String,
      name: map['name'] as String,
      brand: map['brand'] as String,
      price: (map['price'] as num).toDouble(),
      stock: (map['stock'] as int?) ?? 0,
      version: (map['version'] as int?) ?? 1,
      updatedAt: map['updated_at'] as String,
      isSynced: (map['is_synced'] as int?) ?? 0,
      isDeleted: (map['is_deleted'] as int?) ?? 0,
    );
  }

  /// Convierte el modelo de BD a un mapa compatible con SQLite.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'category_id': categoryId,
      'name': name,
      'brand': brand,
      'price': price,
      'stock': stock,
      'version': version,
      'updated_at': updatedAt,
      'is_synced': isSynced,
      'is_deleted': isDeleted,
    };
  }

  // vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv
  // Serialización para Cloud Firestore (Remoto)
  // vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv

  /// Crea una instancia de [InstrumentDbModel] desde un documento de Firestore.
  factory InstrumentDbModel.fromFirestore(
    Map<String, dynamic> data,
    String docId,
  ) {
    return InstrumentDbModel(
      id: docId,
      categoryId: (data['category_id'] as String?) ?? '',
      name: (data['name'] as String?) ?? '',
      brand: (data['brand'] as String?) ?? '',
      price: ((data['price'] as num?) ?? 0.0).toDouble(),
      stock: (data['stock'] as int?) ?? 0,
      version: (data['version'] as int?) ?? 1,
      updatedAt:
          (data['updated_at'] as String?) ??
          DateTime.now().toUtc().toIso8601String(),
      isSynced: 1,
      isDeleted: (data['is_deleted'] as int?) ?? 0,
    );
  }

  /// Convierte el modelo de BD a un mapa para Firestore.
  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'category_id': categoryId,
      'name': name,
      'brand': brand,
      'price': price,
      'stock': stock,
      'version': version,
      'updated_at': updatedAt,
      'is_deleted': isDeleted,
    };
  }

  // ---------------------------------------------------------------------------
  // Inmutabilidad
  // ---------------------------------------------------------------------------

  /// Retorna una copia del modelo con los campos modificados.
  InstrumentDbModel copyWith({
    String? id,
    String? categoryId,
    String? name,
    String? brand,
    double? price,
    int? stock,
    int? version,
    String? updatedAt,
    int? isSynced,
    int? isDeleted,
  }) {
    return InstrumentDbModel(
      id: id ?? this.id,
      categoryId: categoryId ?? this.categoryId,
      name: name ?? this.name,
      brand: brand ?? this.brand,
      price: price ?? this.price,
      stock: stock ?? this.stock,
      version: version ?? this.version,
      updatedAt: updatedAt ?? this.updatedAt,
      isSynced: isSynced ?? this.isSynced,
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }
}

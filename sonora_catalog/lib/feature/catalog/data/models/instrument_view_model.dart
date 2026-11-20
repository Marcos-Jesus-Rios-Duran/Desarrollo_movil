import 'package:sonora_catalog/feature/catalog/data/models/instrument_dto.dart';

/// Modelo de presentación para un instrumento musical.
///
/// Convierte los datos crudos del [InstrumentDto] en tipos Dart nativos
/// listos para consumir en la capa de UI, aplicando formato y reglas de
/// negocio de presentación.
///
/// Implementa [==] y [hashCode] basados en los campos de **negocio** para
/// que `setState` / `ValueListenableBuilder` detecten cambios de forma
/// eficiente sin reconstruir widgets innecesariamente.
class InstrumentViewModel {
  // ---------------------------------------------------------------------------
  // Campos de presentación
  // ---------------------------------------------------------------------------

  /// Identificador único (UUID) del instrumento.
  final String id;

  /// Identificador de la categoría a la que pertenece.
  final String categoryId;

  /// Nombre del instrumento (ej. "Guitarra Clásica 4/4").
  final String name;

  /// Marca fabricante (ej. "Yamaha").
  final String brand;

  /// Precio formateado como `double` listo para mostrar.
  final double price;

  /// Unidades disponibles en inventario.
  final int stock;

  /// Versión incremental para control de colisiones LWW.
  final int version;

  /// Marca temporal UTC de la última modificación.
  final DateTime updatedAt;

  /// `true` cuando el registro ya fue confirmado por el servidor remoto.
  final bool isSynced;

  /// `true` cuando el instrumento está marcado para borrado lógico.
  final bool isDeleted;

  // vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv
  // Constructor
  // vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv

  const InstrumentViewModel({
    required this.id,
    required this.categoryId,
    required this.name,
    required this.brand,
    required this.price,
    required this.stock,
    required this.version,
    required this.updatedAt,
    required this.isSynced,
    required this.isDeleted,
  });

  // ---------------------------------------------------------------------------
  // Fábrica desde DTO
  // ---------------------------------------------------------------------------

  /// Construye un [InstrumentViewModel] a partir del [InstrumentDto] de la capa
  /// de datos, parseando `updatedAt` a [DateTime] y convirtiendo flags enteros.
  factory InstrumentViewModel.fromDto(InstrumentDto dto) {
    return InstrumentViewModel(
      id: dto.id,
      categoryId: dto.categoryId,
      name: dto.name.trim(),
      brand: dto.brand.trim(),
      price: dto.price,
      stock: dto.stock,
      version: dto.version,
      updatedAt: DateTime.tryParse(dto.updatedAt)?.toLocal() ?? DateTime.now(),
      isSynced: dto.isSynced == 1,
      isDeleted: dto.isDeleted == 1,
    );
  }

  // vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv
  // Conversión inversa a DTO (para operaciones de escritura desde UI)
  // vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv

  /// Convierte este [InstrumentViewModel] de vuelta a un [InstrumentDto]
  /// con `isSynced = 0` listo para escritura local inmediata.
  InstrumentDto toDto() {
    return InstrumentDto(
      id: id,
      categoryId: categoryId,
      name: name,
      brand: brand,
      price: price,
      stock: stock,
      version: version,
      updatedAt: updatedAt.toUtc().toIso8601String(),
      isSynced: isSynced ? 1 : 0,
      isDeleted: isDeleted ? 1 : 0,
    );
  }

  // ---------------------------------------------------------------------------
  // Inmutabilidad
  // ---------------------------------------------------------------------------

  /// Retorna una copia del [InstrumentViewModel] con los campos indicados
  /// sobreescritos; útil en edición de formularios sin mutar el estado.
  InstrumentViewModel copyWith({
    String? id,
    String? categoryId,
    String? name,
    String? brand,
    double? price,
    int? stock,
    int? version,
    DateTime? updatedAt,
    bool? isSynced,
    bool? isDeleted,
  }) {
    return InstrumentViewModel(
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

  // vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv
  // Igualdad y hash — detección eficiente de cambios en la UI
  // vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv

  /// Dos instrumentos son **iguales** cuando comparten `id` y todos los
  /// campos de negocio coinciden (incluyendo `version` y `updatedAt` para
  /// detectar actualizaciones remotas).
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! InstrumentViewModel) return false;
    return id == other.id &&
        categoryId == other.categoryId &&
        name == other.name &&
        brand == other.brand &&
        price == other.price &&
        stock == other.stock &&
        version == other.version &&
        updatedAt == other.updatedAt &&
        isSynced == other.isSynced &&
        isDeleted == other.isDeleted;
  }

  /// Hash basado en los mismos campos que [==] para garantizar consistencia
  /// en colecciones (`Set`, `Map`, `ListView` con claves).
  @override
  int get hashCode => Object.hash(
    id,
    categoryId,
    name,
    brand,
    price,
    stock,
    version,
    updatedAt,
    isSynced,
    isDeleted,
  );

  // ---------------------------------------------------------------------------
  // Helpers de presentación
  // ---------------------------------------------------------------------------

  /// Precio formateado con símbolo de moneda (ej. `"\$1,299.99"`).
  String get formattedPrice => '\$${price.toStringAsFixed(2)}';

  /// Etiqueta de stock: "Agotado" si `stock == 0`, si no la cantidad.
  String get stockLabel => stock == 0 ? 'Agotado' : '$stock uds.';

  /// Icono de sincronización textual para debug / UI secundaria.
  String get syncStatus => isSynced ? '✓ Sincronizado' : '⏳ Pendiente';

  @override
  String toString() =>
      'InstrumentViewModel(id: $id, name: $name, brand: $brand, '
      'price: $price, stock: $stock, version: $version, '
      'isSynced: $isSynced, isDeleted: $isDeleted)';
}

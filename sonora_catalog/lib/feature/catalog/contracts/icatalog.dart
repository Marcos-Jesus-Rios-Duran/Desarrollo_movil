import 'package:sonora_catalog/feature/catalog/data/models/instrument_dto.dart';

/// Contrato común para fuentes de datos del catálogo de instrumentos.
///
/// Garantiza que la implementación local (SQLite) y la remota (Cloud Firestore)
/// expongan las mismas operaciones bajo Inversión de Dependencias (DIP).
abstract class DataLogInterface {
  // ---------------------------------------------------------------------------
  // Operaciones CRUD y borrado lógico
  // ---------------------------------------------------------------------------

  /// Obtiene todos los instrumentos activos (`isDeleted == 0`).
  Future<List<InstrumentDto>> getAll();

  /// Busca un instrumento por su identificador único.
  Future<InstrumentDto?> getById(String id);

  /// Inserta o actualiza un instrumento en la fuente correspondiente.
  Future<void> upsert(InstrumentDto instrument);

  /// Marca un instrumento como eliminado de forma lógica (`isDeleted = 1`)[cite: 11].
  Future<void> softDelete(String id, String updatedAt);
}

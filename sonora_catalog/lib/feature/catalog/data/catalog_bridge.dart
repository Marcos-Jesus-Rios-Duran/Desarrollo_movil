import 'package:sonora_catalog/common/db/cloud/cloud_catalog_dao.dart';
import 'package:sonora_catalog/common/db/local/sqlite_catalog_dao.dart';
import 'package:sonora_catalog/feature/catalog/contracts/icatalog.dart';
import 'package:sonora_catalog/feature/catalog/data/models/instrument_dto.dart';
import 'package:sonora_catalog/feature/catalog/data/models/instrument_view_model.dart';

/// Puente (Bridge) que orquesta las dos fuentes de datos bajo DIP.
///
/// Implementa el patrón **Offline-First**: toda escritura va **primero** a
/// SQLite (latencia ≈ 0 ms), y la sincronización con Cloud Firestore se
/// delega al [SyncService] en segundo plano.
///
/// [CatalogBridge] expone [InstrumentViewModel] a la capa de presentación,
/// aislando completamente el DTO y el modelo de BD de la UI.
class CatalogBridge {
  // ---------------------------------------------------------------------------
  // Fuentes de datos inyectadas (DIP)
  // ---------------------------------------------------------------------------

  final DataLogInterface _local;
  final CloudCatalogDao _remote;

  CatalogBridge({DataLogInterface? local, CloudCatalogDao? remote})
    : _local = local ?? SqliteCatalogDao(),
      _remote = remote ?? CloudCatalogDao();

  // vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv
  // Lectura — Single Source of Truth: SQLite local
  // vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv

  /// Devuelve todos los instrumentos activos como [InstrumentViewModel].
  ///
  /// La fuente siempre es **SQLite local** para garantizar 0 ms de latencia
  /// percibida, independientemente de la conectividad.
  Future<List<InstrumentViewModel>> getAll() async {
    final List<InstrumentDto> dtos = await _local.getAll();
    return dtos.map(InstrumentViewModel.fromDto).toList();
  }

  /// Busca un instrumento por [id] en la caché local.
  Future<InstrumentViewModel?> getById(String id) async {
    final InstrumentDto? dto = await _local.getById(id);
    return dto != null ? InstrumentViewModel.fromDto(dto) : null;
  }

  // ---------------------------------------------------------------------------
  // Escritura — Offline-First: local inmediato, remoto diferido
  // ---------------------------------------------------------------------------

  /// Inserta o actualiza un instrumento.
  ///
  /// 1. Escribe en SQLite con `is_synced = 0` e incrementa `version`.
  /// 2. No toca Firestore; el [SyncService] lo hará en background.
  Future<void> save(InstrumentViewModel vm) async {
    await _local.upsert(vm.toDto());
  }

  /// Elimina lógicamente un instrumento (`is_deleted = 1`).
  ///
  /// La operación local es inmediata; Firestore se sincronizará después.
  Future<void> delete(String id) async {
    final String utcNow = DateTime.now().toUtc().toIso8601String();
    await _local.softDelete(id, utcNow);
  }

  // vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv
  // Acceso a las fuentes raw para el SyncService
  // vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv

  /// Expone el DAO local para operaciones de sincronización de bajo nivel.
  DataLogInterface get localDao => _local;

  /// Expone el DAO remoto para operaciones de sincronización de bajo nivel.
  CloudCatalogDao get remoteDao => _remote;
}

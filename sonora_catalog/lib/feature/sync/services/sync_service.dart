import 'package:sonora_catalog/common/db/cloud/cloud_catalog_dao.dart';
import 'package:sonora_catalog/common/db/local/db_create.dart';
import 'package:sonora_catalog/common/db/local/db_helper.dart';
import 'package:sonora_catalog/common/db/local/sqlite_catalog_dao.dart';
import 'package:sonora_catalog/common/db/models/instrument_db_model.dart';
import 'package:sonora_catalog/feature/catalog/data/models/instrument_dto.dart';
import 'package:sonora_catalog/feature/sync/models/sync_log_model.dart';
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

/// Servicio de sincronización bidireccional **Push & Pull**.
///
/// ## Ciclo completo
/// 1. **Push** – Envía a Firestore todos los registros con `is_synced = 0`.
/// 2. **ACK**  – Marca esos registros como `is_synced = 1` en SQLite.
/// 3. **Pull** – Descarga de Firestore los cambios posteriores a [_lastPullAt].
/// 4. **Merge** – Aplica LWW (Last-Write-Wins por `updated_at` + `version`)
///                para resolver colisiones entre el delta remoto y el local.
///
/// Se invoca desde [WorkManager] en background o directamente cuando la app
/// detecta conectividad mediante `connectivity_plus`.
///
/// No contiene lógica de UI ni accede a `BuildContext`.
class SyncService {
  // ---------------------------------------------------------------------------
  // Dependencias
  // ---------------------------------------------------------------------------

  final SqliteCatalogDao _local;
  final CloudCatalogDao _remote;
  final DbHelper _dbHelper;
  final Uuid _uuid;

  SyncService({
    SqliteCatalogDao? local,
    CloudCatalogDao? remote,
    DbHelper? dbHelper,
    Uuid? uuid,
  }) : _local = local ?? SqliteCatalogDao(),
       _remote = remote ?? CloudCatalogDao(),
       _dbHelper = dbHelper ?? DbHelper.instance,
       _uuid = uuid ?? const Uuid();

  // vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv
  // Punto de entrada principal
  // vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv

  /// Ejecuta el ciclo completo Push → ACK → Pull → Merge.
  ///
  /// Devuelve `true` si la sincronización concluyó sin errores críticos.
  Future<bool> runSync() async {
    try {
      await _pushPending();
      await _pullAndMerge();
      return true;
    } catch (e, st) {
      debugPrint('runSync error: $e\n$st');
      await _writeSyncLog(
        entityId: 'global',
        entityType: 'sync',
        action: 'run_sync',
        status: 'error',
      );
      return false;
    }
  }

  // ---------------------------------------------------------------------------
  // Fase 1: Push — Envío de pendientes locales a Firestore
  // ---------------------------------------------------------------------------

  /// Obtiene los registros `is_synced = 0` y los escribe en Firestore por lotes.
  ///
  /// Tras confirmación exitosa del batch, marca cada registro como sincronizado
  /// en SQLite (ACK).
  Future<void> _pushPending() async {
    final List<InstrumentDbModel> pending = await _local.getPendingSync();
    if (pending.isEmpty) return;

    // Convertir a DTOs para el DAO remoto
    final List<InstrumentDto> dtos = pending
        .map(
          (m) => InstrumentDto(
            id: m.id,
            categoryId: m.categoryId,
            name: m.name,
            brand: m.brand,
            price: m.price,
            stock: m.stock,
            version: m.version,
            updatedAt: m.updatedAt,
            isSynced: m.isSynced,
            isDeleted: m.isDeleted,
          ),
        )
        .toList();

    // Push masivo vía batch
    await _remote.batchUpsert(dtos);

    // ACK: marcar como sincronizados en SQLite
    for (final InstrumentDbModel item in pending) {
      final bool acked = await _local.markAsSyncedIfUnchanged(
        item.id,
        version: item.version,
        updatedAt: item.updatedAt,
      );
      await _writeSyncLog(
        entityId: item.id,
        entityType: 'instrument',
        action: 'push',
        status: acked ? 'ok' : 'stale_ack_skipped',
      );
    }
  }

  // vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv
  // Fase 2: Pull — Descarga de cambios remotos + Merge (LWW)
  // vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv

  /// Descarga los cambios remotos posteriores al último Pull y los fusiona
  /// con SQLite usando la estrategia **Last-Write-Wins**.
  ///
  /// **Regla de merge:**
  /// - Si el registro local NO existe → insertar el remoto.
  /// - Si `remoto.version > local.version` → el remoto gana; actualizar local.
  /// - Si `remoto.updatedAt > local.updatedAt` y versiones iguales → remoto gana.
  /// - En caso contrario → mantener local (ya fue enviado con version superior).
  Future<void> _pullAndMerge() async {
    final String since = await _getLastPullAt();
    final List<InstrumentDto> remoteChanges = await _remote.getChangedSince(
      since,
    );

    String? maxUpdatedAt;

    for (final InstrumentDto remote in remoteChanges) {
      if (maxUpdatedAt == null ||
          remote.updatedAt.compareTo(maxUpdatedAt) > 0) {
        maxUpdatedAt = remote.updatedAt;
      }

      final InstrumentDbModel? local = await _local.getDbModelById(remote.id);

      if (local == null) {
        await _local.upsertFromRemote(_dtoToDbModel(remote, isSynced: 1));
        await _writeSyncLog(
          entityId: remote.id,
          entityType: 'instrument',
          action: 'pull_insert',
          status: 'ok',
        );
        continue;
      }

      // Eco de nuestro propio push: idéntico, no hay nada que hacer ni loguear.
      if (remote.version == local.version &&
          remote.updatedAt == local.updatedAt) {
        continue;
      }

      final bool remoteWins =
          remote.version > local.version ||
          (remote.version == local.version &&
              remote.updatedAt.compareTo(local.updatedAt) > 0);

      if (remoteWins) {
        await _local.upsertFromRemote(_dtoToDbModel(remote, isSynced: 1));
        await _writeSyncLog(
          entityId: remote.id,
          entityType: 'instrument',
          action: 'pull_merge',
          status: 'ok',
        );
      } else {
        // Local gana: se enviará en el próximo push si está pendiente.
        await _writeSyncLog(
          entityId: remote.id,
          entityType: 'instrument',
          action: 'pull_conflict_local_wins',
          status: 'conflict',
        );
      }
    }

    // Avanzar el cursor solo si llegaron cambios, con el reloj del servidor de datos.
    if (maxUpdatedAt != null) {
      await _setLastPullAt(maxUpdatedAt);
    }
  }

  // ---------------------------------------------------------------------------
  // Helpers privados
  // ---------------------------------------------------------------------------

  /// Convierte un [InstrumentDto] en un [InstrumentDbModel] para escritura local.
  InstrumentDbModel _dtoToDbModel(InstrumentDto dto, {required int isSynced}) {
    return InstrumentDbModel(
      id: dto.id,
      categoryId: dto.categoryId,
      name: dto.name,
      brand: dto.brand,
      price: dto.price,
      stock: dto.stock,
      version: dto.version,
      updatedAt: dto.updatedAt,
      isSynced: isSynced,
      isDeleted: dto.isDeleted,
    );
  }

  /// Escribe una entrada en la tabla `sync_logs` de SQLite.
  Future<void> _writeSyncLog({
    required String entityId,
    required String entityType,
    required String action,
    required String status,
  }) async {
    final Database db = await _dbHelper.database;
    final SyncLogModel log = SyncLogModel(
      id: _uuid.v4(),
      entityId: entityId,
      entityType: entityType,
      action: action,
      status: status,
      timestamp: DateTime.now().toUtc().toIso8601String(),
    );
    await db.insert(
      DbCreate.tableSyncLogs,
      log.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv
  // Cursor de Pull (persistido en SQLite como clave/valor auxiliar)
  // vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv

  static const String _pullCursorEntity = '__pull_cursor__';

  /// Recupera la marca temporal del último Pull exitoso.
  ///
  /// Si nunca se ha hecho Pull, devuelve la época Unix (inicio absoluto).
  Future<String> _getLastPullAt() async {
    final Database db = await _dbHelper.database;
    final List<Map<String, dynamic>> rows = await db.query(
      DbCreate.tableSyncLogs,
      columns: <String>['timestamp'],
      where: "entity_id = ? AND action = 'set_pull_cursor' AND status = 'ok'",
      whereArgs: <Object>[_pullCursorEntity],
      orderBy: 'timestamp DESC',
      limit: 1,
    );
    if (rows.isEmpty) return '1970-01-01T00:00:00.000Z';
    return rows.first['timestamp'] as String;
  }

  /// Persiste el cursor del último Pull en la tabla `sync_logs`.
  Future<void> _setLastPullAt(String utcTimestamp) async {
    final Database db = await _dbHelper.database;
    final SyncLogModel cursor = SyncLogModel(
      id: _uuid.v4(),
      entityId: _pullCursorEntity,
      entityType: 'system',
      action: 'set_pull_cursor',
      status: 'ok',
      timestamp: utcTimestamp,
    );
    await db.insert(
      DbCreate.tableSyncLogs,
      cursor.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
}

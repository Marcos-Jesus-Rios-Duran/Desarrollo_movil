/// Modelo que representa una entrada en el log de sincronización (`sync_logs`).
///
/// Permite auditar cada operación de Push/Pull para diagnóstico y
/// control de reintentos.
class SyncLogModel {
  // ---------------------------------------------------------------------------
  // Campos
  // ---------------------------------------------------------------------------

  /// UUID único del registro de log.
  final String id;

  /// ID de la entidad afectada (ej. instrumento UUID).
  final String entityId;

  /// Tipo de entidad afectada (ej. `'instrument'`).
  final String entityType;

  /// Acción ejecutada: `'push'`, `'pull'`, `'delete'`.
  final String action;

  /// Estado resultante: `'ok'`, `'error'`, `'conflict'`.
  final String status;

  /// Marca temporal UTC del intento de sincronización.
  final String timestamp;

  const SyncLogModel({
    required this.id,
    required this.entityId,
    required this.entityType,
    required this.action,
    required this.status,
    required this.timestamp,
  });

  // vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv
  // Serialización SQLite
  // vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv

  /// Construye un [SyncLogModel] desde una fila de SQLite.
  factory SyncLogModel.fromMap(Map<String, dynamic> map) {
    return SyncLogModel(
      id: map['id'] as String,
      entityId: map['entity_id'] as String,
      entityType: map['entity_type'] as String,
      action: map['action'] as String,
      status: map['status'] as String,
      timestamp: map['timestamp'] as String,
    );
  }

  /// Convierte a un mapa compatible con SQLite.
  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'entity_id': entityId,
      'entity_type': entityType,
      'action': action,
      'status': status,
      'timestamp': timestamp,
    };
  }
}

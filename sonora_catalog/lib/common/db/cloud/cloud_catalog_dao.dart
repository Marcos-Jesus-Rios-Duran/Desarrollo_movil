import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sonora_catalog/common/config/app_config.dart';
import 'package:sonora_catalog/feature/catalog/contracts/icatalog.dart';
import 'package:sonora_catalog/feature/catalog/data/models/instrument_dto.dart';

/// DAO remoto que implementa [DataLogInterface] usando Cloud Firestore.
///
/// Todas las operaciones son **no bloqueantes** (async/await) y respetan el
/// contrato definido en [DataLogInterface].  El borrado siempre es **lógico**
/// (`is_deleted = 1`) para mantener consistencia con el esquema SQLite local.
///
/// Modo prueba: se asume que las reglas de Firestore permiten lectura/escritura
/// anónima.  La seguridad en producción se refuerza con SHA-1 del certificado
/// y reglas de Firestore basadas en rutas.
class CloudCatalogDao implements DataLogInterface {
  // ---------------------------------------------------------------------------
  // Dependencias inyectadas
  // ---------------------------------------------------------------------------

  final FirebaseFirestore _firestore;

  /// Referencia a la colección remota de instrumentos.
  late final CollectionReference<Map<String, dynamic>> _col;

  CloudCatalogDao({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance {
    _col = _firestore.collection(AppConfig.instrumentsCollection);
  }

  // vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv
  // Implementación de DataLogInterface
  // vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv

  /// Obtiene todos los instrumentos activos (`is_deleted == 0`) de Firestore.
  @override
  Future<List<InstrumentDto>> getAll() async {
    final QuerySnapshot<Map<String, dynamic>> snapshot = await _col
        .where('is_deleted', isEqualTo: 0)
        .orderBy('updated_at', descending: true)
        .get();

    return snapshot.docs
        .map((doc) => InstrumentDto.fromFirestore(doc.data(), doc.id))
        .toList();
  }

  /// Busca un instrumento remoto por su [id] (ID del documento).
  @override
  Future<InstrumentDto?> getById(String id) async {
    final DocumentSnapshot<Map<String, dynamic>> doc = await _col.doc(id).get();
    if (!doc.exists || doc.data() == null) return null;
    return InstrumentDto.fromFirestore(doc.data()!, doc.id);
  }

  /// Inserta o actualiza el documento en Firestore usando `set` con merge.
  ///
  /// No sobreescribe campos no incluidos gracias a `SetOptions(merge: true)`.
  @override
  Future<void> upsert(InstrumentDto instrument) async {
    final Map<String, dynamic> data = instrument.toFirestore();
    await _col.doc(instrument.id).set(data, SetOptions(merge: true));
  }

  /// Marca el documento como eliminado de forma lógica (`is_deleted = 1`).
  ///
  /// También incrementa `version` y actualiza `updated_at` para que la
  /// siguiente sincronización Pull detecte el cambio por LWW.
  @override
  Future<void> softDelete(String id, String updatedAt) async {
    final DocumentSnapshot<Map<String, dynamic>> doc = await _col.doc(id).get();
    if (!doc.exists) return;

    final int currentVersion = (doc.data()?['version'] as int?) ?? 1;

    await _col.doc(id).update(<String, dynamic>{
      'is_deleted': 1,
      'updated_at': updatedAt,
      'version': currentVersion + 1,
    });
  }

  // ---------------------------------------------------------------------------
  // Operaciones auxiliares de sincronización
  // ---------------------------------------------------------------------------

  /// Descarga todos los documentos modificados **después** de [since] (UTC ISO-8601).
  ///
  /// Usado en la fase **Pull** del ciclo de sincronización bidireccional para
  /// obtener únicamente los deltas remotos.
  Future<List<InstrumentDto>> getChangedSince(String since) async {
    final QuerySnapshot<Map<String, dynamic>> snapshot = await _col
        .where('updated_at', isGreaterThan: since)
        .orderBy('updated_at')
        .get();

    return snapshot.docs
        .map((doc) => InstrumentDto.fromFirestore(doc.data(), doc.id))
        .toList();
  }

  /// Realiza un **batch write** de múltiples instrumentos en una sola operación
  /// para reducir RTTs durante la fase **Push** masiva.
  ///
  /// Firestore permite máx. 500 escrituras por batch; este método fragmenta
  /// automáticamente si la lista supera ese límite.
  Future<void> batchUpsert(List<InstrumentDto> instruments) async {
    const int batchLimit = 500;

    for (int i = 0; i < instruments.length; i += batchLimit) {
      final List<InstrumentDto> chunk = instruments.sublist(
        i,
        (i + batchLimit).clamp(0, instruments.length),
      );

      final WriteBatch batch = _firestore.batch();
      for (final InstrumentDto dto in chunk) {
        batch.set(_col.doc(dto.id), dto.toFirestore(), SetOptions(merge: true));
      }
      await batch.commit();
    }
  }
}

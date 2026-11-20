import 'package:sonora_catalog/common/db/local/db_create.dart';
import 'package:sonora_catalog/common/db/local/db_helper.dart';
import 'package:sonora_catalog/common/db/models/instrument_db_model.dart';
import 'package:sonora_catalog/feature/catalog/contracts/icatalog.dart';
import 'package:sonora_catalog/feature/catalog/data/models/instrument_dto.dart';
import 'package:sqflite/sqflite.dart';

/// DAO local que implementa [DataLogInterface] usando SQLite.
///
/// Aplica escritura **offline-first**:
/// - Todo upsert marca `is_synced = 0` e incrementa `version`.
/// - El borrado es siempre **lógico** (`is_deleted = 1`).
/// - Los métodos auxiliares `getPendingSync` y `markAsSynced` son usados
///   exclusivamente por [SyncService].
class SqliteCatalogDao implements DataLogInterface {
  final DbHelper _dbHelper;

  SqliteCatalogDao({DbHelper? dbHelper})
      : _dbHelper = dbHelper ?? DbHelper.instance;

  // ---------------------------------------------------------------------------
  // Implementación de DataLogInterface
  // ---------------------------------------------------------------------------

  /// Obtiene todos los instrumentos activos (`is_deleted = 0`) como [InstrumentDto].
  @override
  Future<List<InstrumentDto>> getAll() async {
    final Database db = await _dbHelper.database;
    final List<Map<String, dynamic>> rows = await db.query(
      DbCreate.tableInstruments,
      where: 'is_deleted = ?',
      whereArgs: <Object>[0],
      orderBy: 'updated_at DESC',
    );

    return rows.map(_rowToDto).toList();
  }

  /// Busca un instrumento por su [id]; retorna `null` si no existe.
  @override
  Future<InstrumentDto?> getById(String id) async {
    final Database db = await _dbHelper.database;
    final List<Map<String, dynamic>> rows = await db.query(
      DbCreate.tableInstruments,
      where: 'id = ?',
      whereArgs: <Object>[id],
      limit: 1,
    );

    if (rows.isEmpty) return null;
    return _rowToDto(rows.first);
  }

  /// Inserta o actualiza un instrumento marcando `is_synced = 0`.
  ///
  /// Acepta tanto [InstrumentDto] como [InstrumentDbModel] mediante
  /// conversión interna, incrementando `version` automáticamente.
  @override
  Future<void> upsert(covariant InstrumentDto instrument) async {
    final Database db = await _dbHelper.database;
    final String utcNow = DateTime.now().toUtc().toIso8601String();

    final Map<String, dynamic> row = <String, dynamic>{
      'id': instrument.id,
      'category_id': instrument.categoryId,
      'name': instrument.name,
      'brand': instrument.brand,
      'price': instrument.price,
      'stock': instrument.stock,
      'version': instrument.version + 1,
      'updated_at': utcNow,
      'is_synced': 0,
      'is_deleted': instrument.isDeleted,
    };

    await db.insert(
      DbCreate.tableInstruments,
      row,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Marca un instrumento como eliminado lógicamente (`is_deleted = 1`).
  @override
  Future<void> softDelete(String id, String updatedAt) async {
    final Database db = await _dbHelper.database;
    final InstrumentDto? existing = await getById(id);
    if (existing == null) return;

    final Map<String, dynamic> row = existing.toMap()
      ..addAll(<String, dynamic>{
        'is_deleted': 1,
        'is_synced': 0,
        'version': existing.version + 1,
        'updated_at': updatedAt,
      });

    await db.insert(
      DbCreate.tableInstruments,
      row,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv
  // Auxiliares de sincronización (usados por SyncService)
  // vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv

  /// Devuelve todos los registros con `is_synced = 0` como [InstrumentDbModel].
  ///
  /// Se devuelve [InstrumentDbModel] (no DTO) porque [SyncService] necesita
  /// el tipado de BD directamente para el batch push.
  Future<List<InstrumentDbModel>> getPendingSync() async {
    final Database db = await _dbHelper.database;
    final List<Map<String, dynamic>> rows = await db.query(
      DbCreate.tableInstruments,
      where: 'is_synced = ?',
      whereArgs: <Object>[0],
    );

    return rows.map(InstrumentDbModel.fromMap).toList();
  }

  /// Confirma la sincronización de un registro (`is_synced = 1`).
  ///
  /// Si se proporciona [remoteVersion], también actualiza el campo `version`.
  Future<void> markAsSynced(String id, {int? remoteVersion}) async {
    final Database db = await _dbHelper.database;
    final Map<String, dynamic> values = <String, dynamic>{'is_synced': 1};
    if (remoteVersion != null) values['version'] = remoteVersion;

    await db.update(
      DbCreate.tableInstruments,
      values,
      where: 'id = ?',
      whereArgs: <Object>[id],
    );
  }

  // ---------------------------------------------------------------------------
  // Helper interno
  // ---------------------------------------------------------------------------

  /// Convierte una fila SQLite en [InstrumentDto].
  InstrumentDto _rowToDto(Map<String, dynamic> row) {
    return InstrumentDto.fromMap(row);
  }
}

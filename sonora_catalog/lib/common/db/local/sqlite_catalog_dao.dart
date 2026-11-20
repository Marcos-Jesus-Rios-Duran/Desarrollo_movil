import 'package:sonora_catalog/common/db/local/db_create.dart';
import 'package:sonora_catalog/common/db/local/db_helper.dart';
import 'package:sonora_catalog/common/db/models/instrument_db_model.dart';
import 'package:sonora_catalog/feature/catalog/contracts/icatalog.dart';
import 'package:sqflite/sqflite.dart';

/// DAO local que implementa [DataLogInterface] usando SQLite.
class SqliteCatalogDao implements DataLogInterface {
  final DbHelper _dbHelper;

  SqliteCatalogDao({DbHelper? dbHelper})
      : _dbHelper = dbHelper ?? DbHelper.instance;

  // ---------------------------------------------------------------------------
  // Implementación de DataLogInterface
  // ---------------------------------------------------------------------------

  @override
  Future<List<InstrumentDbModel>> getAll() async {
    final Database db = await _dbHelper.database;
    final List<Map<String, dynamic>> rows = await db.query(
      DbCreate.tableInstruments,
      where: 'is_deleted = ?',
      whereArgs: <Object>[0],
      orderBy: 'updated_at DESC',
    );

    return rows.map(InstrumentDbModel.fromMap).toList();
  }

  @override
  Future<InstrumentDbModel?> getById(String id) async {
    final Database db = await _dbHelper.database;
    final List<Map<String, dynamic>> rows = await db.query(
      DbCreate.tableInstruments,
      where: 'id = ?',
      whereArgs: <Object>[id],
      limit: 1,
    );

    if (rows.isEmpty) return null;
    return InstrumentDbModel.fromMap(rows.first);
  }

  @override
  Future<void> upsert(InstrumentDbModel instrument) async {
    final Database db = await _dbHelper.database;
    final String utcNow = DateTime.now().toUtc().toIso8601String();

    final InstrumentDbModel pendingInstrument = instrument.copyWith(
      isSynced: 0,
      isDeleted: 0,
      version: instrument.version + 1,
      updatedAt: utcNow,
    );

    await db.insert(
      DbCreate.tableInstruments,
      pendingInstrument.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<void> softDelete(String id, String updatedAt) async {
    final Database db = await _dbHelper.database;
    final InstrumentDbModel? existing = await getById(id);

    if (existing == null) return;

    final InstrumentDbModel deletedItem = existing.copyWith(
      isDeleted: 1,
      isSynced: 0,
      version: existing.version + 1,
      updatedAt: updatedAt,
    );

    await db.insert(
      DbCreate.tableInstruments,
      deletedItem.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv
  // Auxiliares de sincronización local
  // vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv

  /// Obtiene todos los registros locales pendientes de sincronización.
  Future<List<InstrumentDbModel>> getPendingSync() async {
    final Database db = await _dbHelper.database;
    final List<Map<String, dynamic>> rows = await db.query(
      DbCreate.tableInstruments,
      where: 'is_synced = ?',
      whereArgs: <Object>[0],
    );

    return rows.map(InstrumentDbModel.fromMap).toList();
  }

  /// Confirma la sincronización del registro con su valor remoto.
  Future<void> markAsSynced(String id, {int? remoteVersion}) async {
    final Database db = await _dbHelper.database;
    final Map<String, dynamic> values = <String, dynamic>{
      'is_synced': 1,
    };

    if (remoteVersion != null) {
      values['version'] = remoteVersion;
    }

    await db.update(
      DbCreate.tableInstruments,
      values,
      where: 'id = ?',
      whereArgs: <Object>[id],
    );
  }
}
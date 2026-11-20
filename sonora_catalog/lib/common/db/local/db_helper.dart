import 'package:path/path.dart';
import 'package:sonora_catalog/common/db/local/db_create.dart';
import 'package:sqflite/sqflite.dart';

/// Administrador Singleton de la base de datos local SQLite.
///
/// Garantiza una única instancia abierta de `sonora_catalog.db`, habilita
/// claves foráneas y centraliza la versión del esquema y migraciones.
class DbHelper {
  // ---------------------------------------------------------------------------
  // Singleton y constantes de configuración
  // ---------------------------------------------------------------------------

  static const String _dbName = 'sonora_catalog.db';
  static const int _dbVersion = 1;

  DbHelper._internal();
  static final DbHelper instance = DbHelper._internal();

  static Database? _database;

  // vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv
  // Acceso a la base de datos y ciclo de vida
  // vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv

  /// Retorna la instancia activa de [Database], abriéndola si aún no existe.
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  /// Abre o crea la base de datos SQLite en el directorio por defecto de la app.
  Future<Database> _initDatabase() async {
    final String dbPath = await getDatabasesPath();
    final String path = join(dbPath, _dbName);

    return openDatabase(
      path,
      version: _dbVersion,
      onConfigure: _onConfigure,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  /// Habilita el soporte de llaves foráneas en SQLite.
  Future<void> _onConfigure(Database db) async {
    await db.execute('PRAGMA foreign_keys = ON');
  }

  /// Ejecuta las sentencias iniciales cuando la base de datos se crea por primera vez.
  Future<void> _onCreate(Database db, int version) async {
    final List<String> statements = DbCreate.createTablesScript
        .split(';')
        .map((String stmt) => stmt.trim())
        .where((String stmt) => stmt.isNotEmpty)
        .toList();

    for (final String statement in statements) {
      await db.execute(statement);
    }
  }

  /// Maneja migraciones incrementales al subir [_dbVersion].
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Ejemplo futuro: if (oldVersion < 2) { await db.execute(...); }
  }
}

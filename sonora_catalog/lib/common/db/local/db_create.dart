/// Definición del esquema SQLite para la aplicación Sonora Catalog.
///
/// Contiene las sentencias DDL para crear las tablas locales con metadatos
/// de sincronización (`is_synced`, `updated_at`, `version`, `is_deleted`).
class DbCreate {
  // ---------------------------------------------------------------------------
  // Constantes de nombres de tablas
  // ---------------------------------------------------------------------------

  static const String tableCategories = 'categories';
  static const String tableInstruments = 'instruments';
  static const String tableSyncLogs = 'sync_logs';

  // vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv
  // Script de creación de tablas (DDL)
  // vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv

  /// Sentencias SQL separadas por punto y coma para ejecutar en `onCreate`.
  static const String createTablesScript = '''
    CREATE TABLE $tableCategories (
      id TEXT PRIMARY KEY,
      name TEXT NOT NULL,
      description TEXT NOT NULL DEFAULT '',
      version INTEGER NOT NULL DEFAULT 1,
      updated_at TEXT NOT NULL,
      is_synced INTEGER NOT NULL DEFAULT 0,
      is_deleted INTEGER NOT NULL DEFAULT 0
    );

    CREATE TABLE $tableInstruments (
      id TEXT PRIMARY KEY,
      category_id TEXT NOT NULL,
      name TEXT NOT NULL,
      brand TEXT NOT NULL,
      price REAL NOT NULL DEFAULT 0.0,
      stock INTEGER NOT NULL DEFAULT 0,
      version INTEGER NOT NULL DEFAULT 1,
      updated_at TEXT NOT NULL,
      is_synced INTEGER NOT NULL DEFAULT 0,
      is_deleted INTEGER NOT NULL DEFAULT 0,
      FOREIGN KEY (category_id) REFERENCES $tableCategories (id)
    );

    CREATE TABLE $tableSyncLogs (
      id TEXT PRIMARY KEY,
      entity_id TEXT NOT NULL,
      entity_type TEXT NOT NULL,
      action TEXT NOT NULL,
      status TEXT NOT NULL,
      timestamp TEXT NOT NULL
    );
  ''';
}
import 'dart:convert';
import 'dart:math';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path/path.dart';
import 'package:sonora_catalog/common/db/local/db_create.dart';
import 'package:sqflite_sqlcipher/sqflite.dart';

/// Administrador Singleton de la base de datos local SQLite **cifrada**
/// (SQLCipher). La clave es aleatoria, se genera en el primer arranque y
/// vive solo en flutter_secure_storage (Android Keystore).
class DbHelper {
  static const String _dbName = 'sonora_catalog.db';
  static const int _dbVersion = 1;
  static const String _keyName = 'db_encryption_key';

  DbHelper._internal();
  static final DbHelper instance = DbHelper._internal();

  static const FlutterSecureStorage _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  /// Apertura compartida: evita que dos llamadas simultáneas generen
  /// dos claves o abran la BD dos veces.
  static Future<Database>? _opening;

  /// Retorna la instancia activa de [Database], abriéndola si aún no existe.
  Future<Database> get database async {
    try {
      return await (_opening ??= _initDatabase());
    } catch (_) {
      _opening = null;
      rethrow;
    }
  }

  Future<String> _dbPath() async => join(await getDatabasesPath(), _dbName);

  Future<Database> _initDatabase() async {
    final String path = await _dbPath();

    String? key = await _storage.read(key: _keyName);
    if (key == null || key.isEmpty) {
      // Sin clave no se puede abrir un archivo previo (BD sin cifrar de una
      // versión anterior, o restaurada sin su clave): se descarta y se crea
      // una nueva ya cifrada.
      await deleteDatabase(path);
      final Random rng = Random.secure();
      key = base64UrlEncode(
        List<int>.generate(32, (_) => rng.nextInt(256)),
      );
      await _storage.write(key: _keyName, value: key);
    }

    return openDatabase(
      path,
      password: key,
      version: _dbVersion,
      onConfigure: _onConfigure,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onConfigure(Database db) async {
    await db.execute('PRAGMA foreign_keys = ON');
  }

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

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Ejemplo futuro: if (oldVersion < 2) { await db.execute(...); }
  }

  /// Logout: cierra la BD, borra el archivo y elimina la clave del
  /// almacenamiento seguro. El siguiente inicio de sesión genera una nueva.
  /// (Sustituye al purgeAll anterior; session_service lo sigue llamando igual.)
  Future<void> purgeAll() async {
    final Future<Database>? opening = _opening;
    _opening = null;
    if (opening != null) {
      try {
        await (await opening).close();
      } catch (_) {}
    }
    await deleteDatabase(await _dbPath());
    await _storage.delete(key: _keyName);
  }
}
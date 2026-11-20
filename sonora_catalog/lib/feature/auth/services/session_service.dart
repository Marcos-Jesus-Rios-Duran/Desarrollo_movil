import 'package:sonora_catalog/common/config/app_config.dart';
import 'package:sonora_catalog/common/db/local/db_helper.dart';
import 'package:sonora_catalog/common/db/local/sqlite_catalog_dao.dart';
import 'package:sonora_catalog/feature/auth/services/auth_service.dart';
import 'package:sonora_catalog/feature/sync/services/sync_service.dart';
import 'package:workmanager/workmanager.dart';

/// Cierre de sesión seguro: intenta subir pendientes, cancela el background,
/// cierra sesión y purga SQLite.
class SessionService {
  final AuthService _auth;
  final SqliteCatalogDao _local;
  final SyncService _sync;
  final DbHelper _db;

  SessionService({
    AuthService? auth,
    SqliteCatalogDao? local,
    SyncService? sync,
    DbHelper? db,
  }) : _auth = auth ?? AuthService(),
       _local = local ?? SqliteCatalogDao(),
       _sync = sync ?? SyncService(),
       _db = db ?? DbHelper.instance;

  /// Devuelve 0 si cerró sesión. Si quedan registros sin subir y [force] es
  /// false, NO cierra sesión y devuelve cuántos se perderían.
  Future<int> logout({bool force = false}) async {
    if (!force) {
      int pending = (await _local.getPendingSync()).length;
      if (pending > 0) {
        await _sync.runSync().timeout(
          const Duration(seconds: 15),
          onTimeout: () => false,
        );
        pending = (await _local.getPendingSync()).length;
      }
      if (pending > 0) return pending;
    }

    await Workmanager().cancelByUniqueName(AppConfig.syncTaskUniqueName);
    await _auth.signOut();
    await _db.purgeAll();
    return 0;
  }
}

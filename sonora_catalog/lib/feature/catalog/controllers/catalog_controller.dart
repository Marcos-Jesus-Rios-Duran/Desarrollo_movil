import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:sonora_catalog/common/config/app_config.dart';
import 'package:sonora_catalog/feature/catalog/data/catalog_bridge.dart';
import 'package:sonora_catalog/feature/catalog/data/models/instrument_view_model.dart';
import 'package:sonora_catalog/feature/sync/services/sync_service.dart';
import 'package:workmanager/workmanager.dart';

/// Controlador del catálogo de instrumentos.
///
/// Actúa como la capa de **lógica de presentación** (similar a un ViewModel
/// en MVVM) expuesta a la UI mediante [ValueNotifier].
///
/// Responsabilidades:
/// - Orquestar lecturas a través de [CatalogBridge] (Single Source of Truth).
/// - Disparar sincronizaciones manuales e instantáneas.
/// - Registrar tareas diferidas con [WorkManager] para sync en background.
/// - Monitorear conectividad y ejecutar sync automático al recuperarla.
///
/// La UI **sólo observa** [instruments], [isLoading] y [errorMessage].
class CatalogController {
  // ---------------------------------------------------------------------------
  // Estado observable para la UI
  // ---------------------------------------------------------------------------

  /// Lista reactiva de instrumentos presentados en pantalla.
  final ValueNotifier<List<InstrumentViewModel>> instruments = ValueNotifier(
    <InstrumentViewModel>[],
  );

  /// Indicador de carga / sincronización en progreso.
  final ValueNotifier<bool> isLoading = ValueNotifier(false);

  /// Mensaje de error de la última operación fallida (vacío = sin error).
  final ValueNotifier<String> errorMessage = ValueNotifier('');

  /// Estado de conectividad observable por la UI.
  final ValueNotifier<bool> isOnline = ValueNotifier(false);

  // vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv
  // Dependencias
  // vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv

  final CatalogBridge _bridge;
  final SyncService _syncService;
  final Connectivity _connectivity;

  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;

  CatalogController({
    CatalogBridge? bridge,
    SyncService? syncService,
    Connectivity? connectivity,
  }) : _bridge = bridge ?? CatalogBridge(),
       _syncService = syncService ?? SyncService(),
       _connectivity = connectivity ?? Connectivity();

  // ---------------------------------------------------------------------------
  // Inicialización
  // ---------------------------------------------------------------------------

  /// Inicializa el controlador:
  /// 1. Registra la tarea periódica en [WorkManager].
  /// 2. Arranca el monitor de conectividad.
  /// 3. Carga el catálogo desde SQLite.
  Future<void> init() async {
    await _registerBackgroundTask();
    _startConnectivityMonitor();
    await loadCatalog();
  }

  // vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv
  // Lectura del catálogo
  // vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv

  /// Carga (o recarga) el catálogo desde la caché SQLite local.
  ///
  /// Actualiza [instruments] sin parpadeo visible gracias al diff por `==`.
  Future<void> loadCatalog() async {
    isLoading.value = true;
    errorMessage.value = '';
    try {
      final List<InstrumentViewModel> loaded = await _bridge.getAll();
      // Sólo actualiza si la lista cambió (evita rebuilds innecesarios)
      if (!_listEquals(instruments.value, loaded)) {
        instruments.value = loaded;
      }
    } catch (e) {
      errorMessage.value = 'Error al cargar el catálogo: $e';
    } finally {
      isLoading.value = false;
    }
  }

  // ---------------------------------------------------------------------------
  // Escritura CRUD
  // ---------------------------------------------------------------------------

  /// Guarda un instrumento (insert o update) de forma offline-first.
  ///
  /// Escribe en SQLite inmediatamente y recarga la lista local.
  Future<void> saveInstrument(InstrumentViewModel vm) async {
    isLoading.value = true;
    errorMessage.value = '';
    try {
      await _bridge.save(vm);
      await loadCatalog();
      // Si hay conexión, sincroniza de inmediato
      if (isOnline.value) await syncNow();
    } catch (e) {
      errorMessage.value = 'Error al guardar: $e';
    } finally {
      isLoading.value = false;
    }
  }

  /// Elimina lógicamente un instrumento (`is_deleted = 1`).
  Future<void> deleteInstrument(String id) async {
    isLoading.value = true;
    errorMessage.value = '';
    try {
      await _bridge.delete(id);
      await loadCatalog();
      if (isOnline.value) await syncNow();
    } catch (e) {
      errorMessage.value = 'Error al eliminar: $e';
    } finally {
      isLoading.value = false;
    }
  }

  // vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv
  // Sincronización
  // vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv

  /// Ejecuta el ciclo Push → ACK → Pull → Merge de forma inmediata.
  ///
  /// Después recarga el catálogo para reflejar cambios remotos.
  Future<void> syncNow() async {
    isLoading.value = true;
    errorMessage.value = '';
    try {
      final bool ok = await _syncService.runSync();
      if (!ok) {
        errorMessage.value = 'Sincronización parcial — reintentando más tarde.';
      }
      await loadCatalog();
    } catch (e) {
      errorMessage.value = 'Error de sincronización: $e';
    } finally {
      isLoading.value = false;
    }
  }

  // ---------------------------------------------------------------------------
  // Monitor de conectividad (connectivity_plus)
  // ---------------------------------------------------------------------------

  /// Escucha cambios de conectividad y dispara sync automático al recuperarla.
  void _startConnectivityMonitor() {
    _connectivitySub = _connectivity.onConnectivityChanged.listen(
      _onConnectivityChanged,
    );
    // Verificación inicial
    _connectivity.checkConnectivity().then(_onConnectivityChanged);
  }

  Future<void> _onConnectivityChanged(List<ConnectivityResult> results) async {
    final bool online = results.any((r) => r != ConnectivityResult.none);
    final bool wasOffline = !isOnline.value;
    isOnline.value = online;

    // Al recuperar conexión tras estar offline, sincronizar inmediatamente
    if (online && wasOffline) {
      await syncNow();
    }
  }

  // vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv
  // Tarea periódica en background (WorkManager)
  // vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv

  /// Registra la tarea periódica de sincronización en WorkManager.
  ///
  /// Frecuencia: cada 15 minutos (mínimo permitido por WorkManager).
  /// Con `existingWorkPolicy: ExistingWorkPolicy.keep` para no duplicar tareas.
  Future<void> _registerBackgroundTask() async {
    await Workmanager().registerPeriodicTask(
      AppConfig.syncTaskUniqueName,
      AppConfig.syncTaskName,
      frequency: const Duration(minutes: 15),
      constraints: Constraints(networkType: NetworkType.connected),
      existingWorkPolicy: ExistingWorkPolicy.keep,
    );
  }

  // ---------------------------------------------------------------------------
  // Ciclo de vida
  // ---------------------------------------------------------------------------

  /// Libera recursos: cancela suscripciones y dispone [ValueNotifier]s.
  void dispose() {
    _connectivitySub?.cancel();
    instruments.dispose();
    isLoading.dispose();
    errorMessage.dispose();
    isOnline.dispose();
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  /// Comparación elemento-a-elemento usando el `==` de [InstrumentViewModel].
  bool _listEquals(List<InstrumentViewModel> a, List<InstrumentViewModel> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

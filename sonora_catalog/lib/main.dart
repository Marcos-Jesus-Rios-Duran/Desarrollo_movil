import 'package:flutter/material.dart';
import 'package:sonora_catalog/common/config/app_config.dart';
import 'package:sonora_catalog/feature/catalog/controllers/catalog_controller.dart';
import 'package:sonora_catalog/feature/catalog/views/catalog_page.dart';
import 'package:sonora_catalog/feature/sync/services/sync_service.dart';
import 'package:workmanager/workmanager.dart';

// ---------------------------------------------------------------------------
// Callback de WorkManager — se ejecuta en un isolate separado.
// DEBE ser una función top-level (no método de clase) y anotada con
// @pragma('vm:entry-point') para que el compilador de release la preserve.
// ---------------------------------------------------------------------------

/// Punto de entrada del isolate de background para WorkManager.
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((
    String taskName,
    Map<String, dynamic>? inputData,
  ) async {
    // Inicializar Firebase dentro del isolate de background
    await AppConfig.initializeFirebase();

    if (taskName == AppConfig.syncTaskName) {
      final SyncService syncService = SyncService();
      return syncService.runSync();
    }
    return Future.value(true);
  });
}

// vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv
// Punto de entrada principal
// vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Inicializar Firebase (modo prueba — sin autenticación)
  await AppConfig.initializeFirebase();

  // 2. Inicializar WorkManager con el dispatcher de background
  await Workmanager().initialize(
    callbackDispatcher,
    isInDebugMode: true, // false en producción
  );

  runApp(const SonoraApp());
}

/// Aplicación raíz de Sonora Catalog.
class SonoraApp extends StatelessWidget {
  const SonoraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sonora Catalog',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      // Inyección del controlador en la raíz de la feature
      home: CatalogPage(controller: CatalogController()),
    );
  }
}

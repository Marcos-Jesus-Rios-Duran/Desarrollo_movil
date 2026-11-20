import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:sonora_catalog/common/config/app_config.dart';
import 'package:sonora_catalog/feature/auth/services/auth_service.dart';
import 'package:sonora_catalog/feature/auth/views/login_page.dart';
import 'package:sonora_catalog/feature/catalog/controllers/catalog_controller.dart';
import 'package:sonora_catalog/feature/catalog/views/catalog_page.dart';
import 'package:sonora_catalog/feature/sync/services/sync_service.dart';
import 'package:workmanager/workmanager.dart';

/// Punto de entrada del isolate de background para WorkManager.
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((
    String taskName,
    Map<String, dynamic>? inputData,
  ) async {
    await AppConfig.initializeFirebase();

    // Sin sesión no se sincroniza (las reglas lo rechazarían igual).
    final User? user = await FirebaseAuth.instance.authStateChanges().first;
    if (user == null) return true;

    if (taskName == AppConfig.syncTaskName) {
      final SyncService syncService = SyncService();
      return syncService.runSync();
    }
    return Future.value(true);
  });
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await AppConfig.initializeFirebase();

  await Workmanager().initialize(callbackDispatcher, isInDebugMode: kDebugMode);

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
      home: AuthGate(auth: AuthService()),
    );
  }
}

/// Muestra login o catálogo según la sesión. Firebase persiste la sesión,
/// así que la app abre directo al catálogo aunque no haya internet.
class AuthGate extends StatelessWidget {
  final AuthService auth;
  const AuthGate({super.key, required this.auth});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: auth.authState,
      builder: (BuildContext context, AsyncSnapshot<User?> snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final User? user = snap.data;
        if (user == null) return LoginPage(auth: auth);
        return _CatalogHost(key: ValueKey<String>(user.uid));
      },
    );
  }
}

/// Crea el controlador una sola vez por sesión (CatalogPage lo libera).
class _CatalogHost extends StatefulWidget {
  const _CatalogHost({super.key});

  @override
  State<_CatalogHost> createState() => _CatalogHostState();
}

class _CatalogHostState extends State<_CatalogHost> {
  final CatalogController _controller = CatalogController();

  @override
  Widget build(BuildContext context) => CatalogPage(controller: _controller);
}

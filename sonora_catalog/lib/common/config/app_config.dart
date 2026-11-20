import 'package:firebase_core/firebase_core.dart';
import 'package:sonora_catalog/firebase_options.dart';

/// Configuración global y arranque de servicios Cloud para Sonora Catalog.
class AppConfig {
  // ---------------------------------------------------------------------------
  // Constantes de colecciones y sincronización
  // ---------------------------------------------------------------------------

  static const String instrumentsCollection = 'instruments';
  static const String categoriesCollection = 'categories';
  static const String syncTaskUniqueName = 'sonora_bidirectional_sync';
  static const String syncTaskName = 'bidirectionalSync';
  static const String usersCollection = 'users';

  // vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv
  // Inicialización de Firebase
  // vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv

  /// Inicializa Firebase utilizando las opciones generadas por FlutterFire CLI.
  static Future<void> initializeFirebase() async {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }
}

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:firabase_multimedia/firebase_options.dart';
import 'package:firabase_multimedia/core/di/injection_container.dart';
import 'package:firabase_multimedia/features/auth/presentation/stores/auth_store.dart';
import 'package:firabase_multimedia/features/auth/presentation/screens/login_screen.dart';
import 'package:firabase_multimedia/features/media/presentation/stores/media_store.dart';
import 'package:firabase_multimedia/features/media/presentation/screens/media_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializa Firebase con las opciones generadas por FlutterFire CLI
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Configura el Service Locator (inyección de dependencias)
  configureDependencies();

  runApp(const FirebaseMultimediaApp());
}

/// Widget raíz de la aplicación.
///
/// Provee los stores globales ([AuthStore], [MediaStore]) a todo
/// el árbol de widgets mediante [MultiProvider].
class FirebaseMultimediaApp extends StatelessWidget {
  const FirebaseMultimediaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthStore>(
          create: (_) => sl<AuthStore>(),
        ),
        ChangeNotifierProvider<MediaStore>(
          create: (_) => sl<MediaStore>(),
        ),
      ],
      child: MaterialApp(
        title: 'Firebase Multimedia',
        debugShowCheckedModeBanner: false,
        theme: _buildTheme(),
        initialRoute: '/',
        routes: {
          '/': (context) => const LoginScreen(),
          '/media': (context) => const MediaScreen(),
        },
      ),
    );
  }

  /// Tema visual elegante basado en Material 3 con Deep Purple.
  ThemeData _buildTheme() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF6750A4),
        brightness: Brightness.light,
      ),
      fontFamily: 'Roboto',
      cardTheme: CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 0,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

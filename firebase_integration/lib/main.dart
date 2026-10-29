import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'views/maindView.dart';

/// Punto de entrada de la aplicación.
/// Inicializa Firebase antes de montar el árbol de widgets.
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Monitor de Equipos',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF4F46E5),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      home: const MainView(),
    );
  }
}

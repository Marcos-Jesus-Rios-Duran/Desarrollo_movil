import 'package:flutter/material.dart';
import 'features/geolocation/data/repositories/location_repository_impl.dart';
import 'features/geolocation/presentation/controllers/map_view_controller.dart';
import 'features/geolocation/presentation/pages/map_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Inyección de Dependencias respetando Clean Architecture / SOLID
    final locationRepository = LocationRepositoryImpl();
    final mapController = MapViewController(locationRepository);

    return MaterialApp(
      title: 'Práctica Geolocalización UTXJ',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: MapPage(controller: mapController),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../controllers/map_view_controller.dart';

/// Pantalla principal del mapa y panel de información geoespacial.
class MapPage extends StatefulWidget {
  final MapViewController controller;

  const MapPage({super.key, required this.controller});

  @override
  State<MapPage> createState() => _MapPageState();
}

/// Administra la suscripción al estado del controlador durante la vida de la pantalla.
class _MapPageState extends State<MapPage> {
  @override
  void initState() {
    super.initState();
    widget.controller.initializeMap().catchError((error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al inicializar GPS: $error')),
      );
    });
    widget.controller.addListener(_onControllerChanged);
  }

  void _onControllerChanged() {
    setState(() {});
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerChanged);
    widget.controller.mapController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Localizador de Puntos de Interés'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: widget.controller.isLoading
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                GoogleMap(
                  initialCameraPosition: const CameraPosition(
                    target: LatLng(20.2756, -97.9611), // Posición inicial de respaldo.
                    zoom: 15.5,
                  ),
                  myLocationEnabled: true,
                  myLocationButtonEnabled: true,
                  markers: widget.controller.markers,
                  onMapCreated: widget.controller.onMapCreated,
                  onTap: widget.controller.onMapTapped,
                ),
                Positioned(
                  bottom: 24,
                  left: 16,
                  right: 16,
                  child: Card(
                    elevation: 8,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Panel de Información Geoespacial',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Colors.indigo,
                            ),
                          ),
                          const Divider(),
                          const SizedBox(height: 4),
                          Text(
                            'Distancia al destino: ${widget.controller.distanceInMeters.toStringAsFixed(2)} m '
                            '(${(widget.controller.distanceInMeters / 1000).toStringAsFixed(2)} km)',
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Dirección: ${widget.controller.destinationAddress.isEmpty ? "Toca cualquier punto del mapa para calcular" : widget.controller.destinationAddress}',
                            style: const TextStyle(fontSize: 13, color: Colors.black87),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
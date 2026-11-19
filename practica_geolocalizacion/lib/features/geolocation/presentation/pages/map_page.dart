import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:practica_geolocalizacion/features/geolocation/presentation/controllers/map_view_controller.dart';

/// Pantalla principal del mapa y panel de información geoespacial.
class MapPage extends StatefulWidget {
  /// Controlador que proporciona el estado y las acciones del mapa.
  final MapViewController controller;

  /// Construye la pantalla usando el controlador de geolocalización recibido.
  const MapPage({super.key, required this.controller});

  @override
  State<MapPage> createState() => _MapPageState();
}

/// Administra la suscripción al estado del controlador durante la vida de la pantalla.
class _MapPageState extends State<MapPage> {
  @override
  /// Inicia la ubicación y registra la escucha de cambios del controlador.
  void initState() {
    super.initState();
    widget.controller.initializeMap().catchError((Object error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al inicializar GPS: $error')),
      );
    });
    widget.controller.addListener(_onControllerChanged);
  }

  /// Solicita la reconstrucción de la vista cuando cambia el estado del mapa.
  void _onControllerChanged() {
    setState(() {});
  }

  @override
  /// Libera la suscripción y el controlador nativo de Google Maps.
  void dispose() {
    widget.controller.removeListener(_onControllerChanged);
    widget.controller.dispose();
    super.dispose();
  }

  @override
  /// Construye el mapa, sus controles y el panel de información del destino.
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 20,
        title: const Row(
          children: [
            Icon(Icons.explore_outlined),
            SizedBox(width: 10),
            Text('Explora tu ubicación'),
          ],
        ),
        backgroundColor: const Color(0xFF182B49),
        foregroundColor: Colors.white,
        elevation: 0,
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
                    elevation: 10,
                    color: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.pin_drop_outlined, color: Color(0xFF1565C0)),
                              SizedBox(width: 8),
                              Text(
                                'Punto seleccionado',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16,
                                  color: Color(0xFF182B49),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEAF2FF),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.straighten, color: Color(0xFF1565C0)),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    'Distancia al destino\n${widget.controller.distanceInMeters.toStringAsFixed(2)} m '
                                    '(${(widget.controller.distanceInMeters / 1000).toStringAsFixed(2)} km)',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      height: 1.35,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF182B49),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.location_on_outlined, color: Color(0xFFE05252)),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  widget.controller.destinationAddress.isEmpty
                                      ? 'Toca cualquier punto del mapa para consultar la dirección.'
                                      : widget.controller.destinationAddress,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    height: 1.35,
                                    color: Colors.black87,
                                  ),
                                ),
                              ),
                            ],
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
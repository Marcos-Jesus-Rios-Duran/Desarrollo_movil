import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:practica_geolocalizacion/features/geolocation/domain/repositories/i_location_repository.dart';

/// Coordina el estado de la pantalla de mapa y sus interacciones.
class MapViewController extends ChangeNotifier {
  final ILocationRepository _locationRepository;

  MapViewController(this._locationRepository);

  /// Controlador nativo del mapa, asignado cuando Google Maps termina de crearse.
  GoogleMapController? mapController;
  /// Última posición conocida del usuario.
  Position? currentPosition;
  /// Punto seleccionado por el usuario al tocar el mapa.
  LatLng? selectedDestination;
  /// Dirección postal del punto seleccionado.
  String destinationAddress = '';
  /// Distancia entre la posición actual y el destino, expresada en metros.
  double distanceInMeters = 0.0;
  /// Marcadores visibles para la posición actual y el destino.
  Set<Marker> markers = {};
  /// Indica si la carga inicial de ubicación continúa en progreso.
  bool isLoading = true;

  StreamSubscription<Position>? _locationSubscription;

  /// Obtiene la posición inicial y prepara la actualización dinámica.
  Future<void> initializeMap() async {
    try {
      isLoading = true;
      notifyListeners();

      currentPosition = await _locationRepository.getCurrentLocation();
      _updateMarkers();

      await _locationSubscription?.cancel();
      _locationSubscription = _locationRepository.getLocationUpdates().listen(
        _updateCurrentPosition,
        onError: (Object error) {
          debugPrint('Error al actualizar ubicación: $error');
        },
      );

      isLoading = false;
      notifyListeners();
    } catch (e) {
      isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  /// Registra el mapa y centra la cámara en la posición del usuario.
  void onMapCreated(GoogleMapController controller) {
    mapController = controller;
    if (currentPosition != null) {
      mapController?.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: LatLng(currentPosition!.latitude, currentPosition!.longitude),
            zoom: 16.0,
          ),
        ),
      );
    }
  }

  /// Actualiza la posición actual y recalcula la distancia al destino.
  void _updateCurrentPosition(Position position) {
    currentPosition = position;

    if (selectedDestination != null) {
      distanceInMeters = _locationRepository.calculateDistance(
        position.latitude,
        position.longitude,
        selectedDestination!.latitude,
        selectedDestination!.longitude,
      );
    }

    _updateMarkers();
    notifyListeners();
  }

  /// Selecciona un destino, calcula su distancia y obtiene su dirección.
  Future<void> onMapTapped(LatLng point) async {
    selectedDestination = point;

    if (currentPosition != null) {
      distanceInMeters = _locationRepository.calculateDistance(
        currentPosition!.latitude,
        currentPosition!.longitude,
        point.latitude,
        point.longitude,
      );
    }

    destinationAddress = await _locationRepository.getAddressFromCoordinates(
      point.latitude,
      point.longitude,
    );

    _updateMarkers();
    notifyListeners();
  }

  /// Reconstruye los marcadores que representan usuario y destino.
  void _updateMarkers() {
    markers.clear();

    if (selectedDestination != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('destination'),
          position: selectedDestination!,
          infoWindow: InfoWindow(
            title: 'Destino seleccionado',
            snippet: destinationAddress,
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        ),
      );
    }
  }

  @override
  void dispose() {
    _locationSubscription?.cancel();
    super.dispose();
  }
}
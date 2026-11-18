import 'package:flutter/foundation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../../domain/repositories/i_location_repository.dart';

class MapViewController extends ChangeNotifier {
  final ILocationRepository _locationRepository;

  MapViewController(this._locationRepository);

  GoogleMapController? mapController;
  Position? currentPosition;
  LatLng? selectedDestination;
  String destinationAddress = '';
  double distanceInMeters = 0.0;
  Set<Marker> markers = {};
  bool isLoading = true;

  Future<void> initializeMap() async {
    try {
      isLoading = true;
      notifyListeners();

      currentPosition = await _locationRepository.getCurrentLocation();
      _updateMarkers();

      isLoading = false;
      notifyListeners();
    } catch (e) {
      isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

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

  Future<void> onMapTapped(LatLng point) async {
    selectedDestination = point;

    if (currentPosition != null) {
      // Requerimiento: Cálculo de distancia en vivo[cite: 14, 16]
      distanceInMeters = _locationRepository.calculateDistance(
        currentPosition!.latitude,
        currentPosition!.longitude,
        point.latitude,
        point.longitude,
      );
    }

    // Requerimiento: Geocodificación inversa[cite: 14, 16]
    destinationAddress = await _locationRepository.getAddressFromCoordinates(
      point.latitude,
      point.longitude,
    );

    _updateMarkers();
    notifyListeners();
  }

  void _updateMarkers() {
    markers.clear();

    if (currentPosition != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('current_location'),
          position: LatLng(currentPosition!.latitude, currentPosition!.longitude),
          infoWindow: const InfoWindow(title: 'Mi Ubicación Actual'),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
        ),
      );
    }

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
}
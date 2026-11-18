import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:practica_geolocalizacion/features/geolocation/domain/repositories/i_location_repository.dart';

/// Implementación de acceso a ubicación, permisos y geocodificación.
class LocationRepositoryImpl implements ILocationRepository {
  @override
  /// Verifica el servicio de ubicación y solicita permiso cuando es necesario.
  Future<Position> getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('El servicio de GPS está desactivado');
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Los permisos de ubicación fueron denegados');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception('Los permisos están denegados permanentemente');
    }

    // Se solicita alta precisión para obtener una posición adecuada para el mapa.
    return await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
    );
  }

  @override
  /// Devuelve la calle y colonia/localidad asociadas a las coordenadas.
  Future<String> getAddressFromCoordinates(double lat, double lng) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(lat, lng);
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks.first;
        String street = place.street ?? '';
        String locality = place.subLocality ?? place.locality ?? '';
        return '$street, $locality';
      }
      return 'Dirección no encontrada';
    } catch (e) {
      return 'Error al obtener la geocodificación inversa';
    }
  }

  @override
  /// Calcula la distancia en línea recta sobre la superficie terrestre.
  double calculateDistance(double startLat, double startLng, double endLat, double endLng) {
    return Geolocator.distanceBetween(startLat, startLng, endLat, endLng);
  }
}
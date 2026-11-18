import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../../domain/repositories/i_location_repository.dart';

class LocationRepositoryImpl implements ILocationRepository {
  @override
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

    // Usando alta precisión como requiere la especificación técnica
    return await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
    );
  }

  @override
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
  double calculateDistance(double startLat, double startLng, double endLat, double endLng) {
    // Retorna la distancia geodésica en metros exactos[cite: 14]
    return Geolocator.distanceBetween(startLat, startLng, endLat, endLng);
  }
}
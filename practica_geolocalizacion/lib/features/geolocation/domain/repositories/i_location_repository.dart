import 'package:geolocator/geolocator.dart';

abstract class ILocationRepository {
  /// Obtiene la posición actual después de validar GPS y permisos.
  Future<Position> getCurrentLocation();

  /// Convierte coordenadas geográficas en una dirección postal legible.
  Future<String> getAddressFromCoordinates(double lat, double lng);

  /// Calcula la distancia geodésica entre dos coordenadas, en metros.
  double calculateDistance(double startLat, double startLng, double endLat, double endLng);
}
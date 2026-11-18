import 'package:geolocator/geolocator.dart';

abstract class ILocationRepository {
  Future<Position> getCurrentLocation();
  Future<String> getAddressFromCoordinates(double lat, double lng);
  double calculateDistance(double startLat, double startLng, double endLat, double endLng);
}
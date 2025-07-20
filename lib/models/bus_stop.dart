import 'package:google_maps_flutter/google_maps_flutter.dart';

class BusStop {
  final LatLng coordinates;
  final List<String> busNumbers;
  final String? address; // Optional address field
  final String type;
  final Map<String, Map<String, String>>? busRoutes;
  final int? busStopIndex;
  final String? direction;

  BusStop({
    required this.coordinates,
    required this.busNumbers,
    this.address,
    this.type = 'Bus stop',
    this.busRoutes,
    this.busStopIndex,
    this.direction,
  });
}

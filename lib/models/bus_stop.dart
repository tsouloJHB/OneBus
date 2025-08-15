import 'package:google_maps_flutter/google_maps_flutter.dart';

class BusStop {
  final LatLng coordinates;
  final String? address; // Optional address field
  final String type;
  final int? busStopIndex;
  final String? direction;
  final Map<String, int>? busStopIndices;

  BusStop({
    required this.coordinates,
    this.address,
    this.type = 'Bus stop',
    this.busStopIndex,
    this.direction,
    this.busStopIndices,
  });
}

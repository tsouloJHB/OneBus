import 'dart:math' as math;

import 'package:google_maps_flutter/google_maps_flutter.dart';

double calculateDistance(LatLng start, LatLng end) {
  const int earthRadius = 6371000; // Earth's radius in meters

  double lat1 = start.latitude;
  double lon1 = start.longitude;
  double lat2 = end.latitude;
  double lon2 = end.longitude;

  double dLat = _toRadians(lat2 - lat1);
  double dLon = _toRadians(lon2 - lon1);

  double a = math.sin(dLat / 2) * math.sin(dLat / 2) +
      math.cos(_toRadians(lat1)) *
          math.cos(_toRadians(lat2)) *
          math.sin(dLon / 2) *
          math.sin(dLon / 2);
  double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));

  double distance = earthRadius * c;
  return distance;
}

double _toRadians(double degree) {
  return degree * (math.pi / 180);
}

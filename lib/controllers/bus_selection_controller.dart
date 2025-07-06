import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:haversine_distance/haversine_distance.dart' as haversinePackage;
import 'package:location/location.dart';
import '../models/bus_stop.dart';
import '../state/track_bus_state.dart';
import '../state/screen_state.dart';


class BusSelectionController {
  Location? userLocation;

  void setUserLocation(Location location) {
    userLocation = location;
  }

  Location getUserLocation() {
    return userLocation!;
  }

  static void checkProximityToBusStops({
    required LatLng? currentLocation,
    required List<BusStop> busStops,
    required WidgetRef ref,
  }) {
    if (currentLocation == null || busStops.isEmpty) return;

    final haversine = haversinePackage.HaversineDistance();
    List<BusStop> nearbyBusStops = busStops.where((busStop) {
      final distance = haversine.haversine(
        haversinePackage.Location(
            currentLocation.latitude, currentLocation.longitude),
        haversinePackage.Location(
            busStop.coordinates.latitude, busStop.coordinates.longitude),
        haversinePackage.Unit.METER,
      );
      return distance <= 200; // Check if within 200 meters
    }).toList();

    if (nearbyBusStops.isNotEmpty) {
      // Sort by distance and select the closest
      nearbyBusStops.sort((a, b) {
        final distanceA = haversine.haversine(
          haversinePackage.Location(
              currentLocation.latitude, currentLocation.longitude),
          haversinePackage.Location(
              a.coordinates.latitude, a.coordinates.longitude),
          haversinePackage.Unit.METER,
        );
        final distanceB = haversine.haversine(
          haversinePackage.Location(
              currentLocation.latitude, currentLocation.longitude),
          haversinePackage.Location(
              b.coordinates.latitude, b.coordinates.longitude),
          haversinePackage.Unit.METER,
        );
        return distanceA.compareTo(distanceB);
      });
      final closestBusStop = nearbyBusStops.first;
      ref.read(selectedBusStopProvider.notifier).state = closestBusStop;
      ref.read(currentScreenStateProvider.notifier).state =
          ScreenState.tracking;
      print(
          'Automatically selected closest bus stop within 200m: ${closestBusStop.coordinates}, Distance: ${haversine.haversine(haversinePackage.Location(currentLocation.latitude, currentLocation.longitude), haversinePackage.Location(closestBusStop.coordinates.latitude, closestBusStop.coordinates.longitude), haversinePackage.Unit.METER)}m');
    }
  }
}

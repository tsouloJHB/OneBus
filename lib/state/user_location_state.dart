import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';

// State class for holding location data
class LocationState {
  final LatLng? currentLocation;
  LocationState({this.currentLocation});
}

// StateNotifier to manage the location state
class LocationNotifier extends StateNotifier<LocationState> {
  LocationNotifier() : super(LocationState());

  final Location _location = Location();

  // Method to get the user's current location
  Future<void> getUserLocation() async {
    try {
      // Request permission if necessary
      final permissionGranted = await _location.requestPermission();
      if (permissionGranted == PermissionStatus.granted) {
        // Fetch the user's current location
        final locationData = await _location.getLocation();
        if (locationData.latitude != null && locationData.longitude != null) {
          // Update state with the new location
          state = LocationState(
            currentLocation:
                LatLng(locationData.latitude!, locationData.longitude!),
          );
          print(
              'Location: ${locationData.latitude}, ${locationData.longitude}');
        }
      }
    } catch (e) {
      print("Error getting location: $e");
    }
  }
}

// Riverpod provider for LocationNotifier
final locationProvider = StateNotifierProvider<LocationNotifier, LocationState>(
  (ref) => LocationNotifier(),
);

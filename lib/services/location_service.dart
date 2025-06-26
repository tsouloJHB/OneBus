import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:onebus/state/track_bus_state.dart';
import 'package:onebus/state/screen_state.dart';

class LocationService {
  final Location _location = Location();
  final WidgetRef ref;
  StreamSubscription<LocationData>? _locationSubscription;
  Function(LatLng)? onLocationChanged;

  LocationService(this.ref);

  Future<void> initialize() async {
    await _location.changeSettings(
      accuracy: LocationAccuracy.high,
      interval: 1000,
    );

    final status = await _location.requestPermission();
    if (status != PermissionStatus.granted) {
      throw Exception('Location permission not granted');
    }
  }

  Future<LatLng?> getCurrentLocation() async {
    try {
      final locationData = await _location.getLocation();
      return LatLng(locationData.latitude!, locationData.longitude!);
    } catch (e) {
      debugPrint('Error getting location: $e');
      return null;
    }
  }

  void startLocationUpdates({
    required Function(LatLng) onLocationUpdate,
    required String mode,
  }) {
    onLocationChanged = onLocationUpdate;

    _locationSubscription?.cancel();
    _locationSubscription = _location.onLocationChanged.listen((locationData) {
      final newLocation = LatLng(
        locationData.latitude!,
        locationData.longitude!,
      );

      onLocationChanged?.call(newLocation);

      // Update current location in provider
      ref.read(currentLocationProvider.notifier).state = newLocation;
    });
  }

  void stopLocationUpdates() {
    _locationSubscription?.cancel();
    _locationSubscription = null;
    onLocationChanged = null;
  }

  void dispose() {
    stopLocationUpdates();
  }
}

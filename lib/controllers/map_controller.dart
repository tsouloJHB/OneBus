import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:onebus/models/bus_stop.dart';
import 'package:onebus/services/bus_communication_services.dart';
import 'package:onebus/state/track_bus_state.dart';
import 'package:onebus/state/screen_state.dart';
import 'package:location/location.dart';
import 'package:geocoding/geocoding.dart' hide Location;

// Bus location provider
final currentBusLocationProvider = StateProvider<LatLng?>((ref) => null);

class MapController {
  late GoogleMapController mapController;
  final WidgetRef ref;
  final Location location = Location();
  Set<Marker> markers = {};
  BitmapDescriptor? customMarkerIcon;
  bool isTrackingUserLocation = true;

  MapController(this.ref);

  void onMapCreated(GoogleMapController controller) {
    mapController = controller;
    final currentScreenState = ref.read(currentScreenStateProvider);
    if (currentScreenState == ScreenState.tracking) {
      _moveToBusLocation();
    }
  }

  double getZoomLevel(ScreenState screenState) {
    switch (screenState) {
      case ScreenState.tracking:
        return 18.0; // Close zoom for detailed bus tracking
      case ScreenState.locationSelection:
        return 15.0; // Wider view for selecting bus stops
      case ScreenState.searchBus:
        return 15.0; // Wider view for initial bus search
      default:
        return 15.0;
    }
  }

  void _moveToBusLocation() {
    final busLocation = ref.read(currentBusLocationProvider);
    final currentScreenState = ref.read(currentScreenStateProvider);

    if (busLocation != null) {
      mapController.animateCamera(
        CameraUpdate.newLatLngZoom(
          busLocation,
          getZoomLevel(currentScreenState),
        ),
      );
    }
  }

  Future<void> moveToLocation(LatLng location, {double? zoom}) async {
    final currentScreenState = ref.read(currentScreenStateProvider);
    await mapController.animateCamera(
      CameraUpdate.newLatLngZoom(
        location,
        zoom ?? getZoomLevel(currentScreenState),
      ),
    );
  }

  Future<String> getAddressFromLatLng(LatLng latLng) async {
    try {
      final placemarks = await placemarkFromCoordinates(
        latLng.latitude,
        latLng.longitude,
      );
      if (placemarks.isNotEmpty) {
        final placemark = placemarks.first;
        return '${placemark.street ?? 'Unknown'}, ${placemark.locality ?? ''}, ${placemark.country ?? ''}';
      }
    } catch (e) {
      debugPrint('Error fetching address: $e');
    }
    return 'Unknown street address';
  }

  void updateMarkers(Set<Marker> newMarkers) {
    markers = newMarkers;
  }

  void addMarker(Marker marker) {
    markers.add(marker);
  }

  void removeMarker(MarkerId markerId) {
    markers.removeWhere((marker) => marker.markerId == markerId);
  }

  void clearMarkers() {
    markers.clear();
  }
}

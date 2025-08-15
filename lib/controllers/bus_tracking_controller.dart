import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:onebus/models/BusInfo.dart';
import '../models/bus_stop.dart';
import '../state/track_bus_state.dart';
import '../state/screen_state.dart';
import '../services/bus_communication_services.dart';
import 'package:haversine_distance/haversine_distance.dart' as haversine;
import '../controllers/map_controller.dart'; // Import for currentBusLocationProvider

class BusTrackingController {
  final WidgetRef ref;

  BusTrackingController(this.ref);

  // Bus Selection Methods
  void selectBus(String busNumber) {
    ref.read(selectedBusState.notifier).state = busNumber;
  }

  void clearBusSelection() {
    ref.read(selectedBusState.notifier).state = '';
  }

  void selectBusStop(BusStop busStop) async {
    print("DEBUG: Selecting bus stop - calculations disabled for testing");
    print("DEBUG: Bus stop: ${busStop.address}");

    // Only update the bus stop state
    ref.read(selectedBusStopProvider.notifier).state = busStop;

    // Comment out all initial calculations for testing
    /*
    // Get the currently selected bus
    final selectedBus = ref.read(selectedBusState);

    // Get current bus location
    final busLocation = ref.read(currentBusLocationProvider);
    if (busLocation != null) {
      // Calculate initial distance and ETA
      final distance = _calculateDistance(busLocation, busStop.coordinates);
      final estimatedTimeMinutes = _calculateETA(distance);

      // Update tracking state with real values
      ref.read(busTrackingProvider.notifier).updateBusTracking(
            selectedBus: selectedBus,
            selectedBusStop: busStop,
            distance: distance,
            estimatedArrivalTime: estimatedTimeMinutes,
            isOnTime: true,
          );
    }
    */
  }

  void clearBusStop() {
    ref.read(selectedBusStopProvider.notifier).state = null;
  }

  // Screen State Management
  void changeScreenState(ScreenState newState) {
    ref.read(currentScreenStateProvider.notifier).state = newState;
  }

  void setLocationScreenStep(int step) {
    ref.read(locationScreenStepProvider.notifier).state = step;
  }

  int getLocationScreenStep() {
    return ref.read(locationScreenStepProvider);
  }

  void nextLocationStep() {
    final currentStep = getLocationScreenStep();
    setLocationScreenStep(currentStep + 1);
  }

  void previousLocationStep() {
    final currentStep = getLocationScreenStep();
    if (currentStep > 1) {
      setLocationScreenStep(currentStep - 1);
    }
  }

  // Bus Tracking Methods
  void startTracking(String busNumber, BusStop busStop) async {
    print("DEBUG: Starting tracking - calculations disabled for testing");
    print("DEBUG: Bus number: $busNumber");
    print("DEBUG: Bus stop: ${busStop.address}");

    // Only update state providers
    ref.read(selectedBusState.notifier).state = busNumber;
    ref.read(selectedBusStopProvider.notifier).state = busStop;
    ref.read(currentTrackedBusProvider.notifier).state = busNumber;
    ref.read(currentScreenStateProvider.notifier).state = ScreenState.tracking;

    // Comment out all initial calculations for testing
    /*
    // Only initialize tracking if we have a valid bus location
    final busLocation = ref.read(currentBusLocationProvider);
    if (busLocation != null) {
      // Calculate initial distance and ETA
      final distance = _calculateDistance(busLocation, busStop.coordinates);
      if (distance > 0.01) {
        // Only update if distance is significant
        final estimatedTimeMinutes = _calculateETA(distance);

        // Initialize tracking with calculated values
        ref.read(busTrackingProvider.notifier).updateBusTracking(
              selectedBus: busNumber,
              selectedBusStop: busStop,
              distance: distance,
              estimatedArrivalTime: estimatedTimeMinutes,
              isOnTime: true,
            );
      }
    }
    */
  }

  void stopTracking() {
    ref.read(selectedBusState.notifier).state = '';
    ref.read(selectedBusStopProvider.notifier).state = null;
    ref.read(currentTrackedBusProvider.notifier).state = null;
    ref.read(currentScreenStateProvider.notifier).state = ScreenState.searchBus;
    ref.read(busTrackingProvider.notifier).clearTracking();
  }

  // Comprehensive method to clear all tracking state
  void clearAllTrackingState() {
    print("DEBUG: BusTrackingController - Clearing all tracking state");

    // Clear all state providers
    ref.read(selectedBusState.notifier).state = '';
    ref.read(selectedBusStopProvider.notifier).state = null;
    ref.read(currentTrackedBusProvider.notifier).state = null;
    ref.read(currentScreenStateProvider.notifier).state = ScreenState.searchBus;
    ref.read(locationScreenStateProvider.notifier).state = false;
    ref.read(locationScreenStepProvider.notifier).state = 1;
    ref.read(containerHeightProvider.notifier).state = 0.0;

    // Clear location and map state
    ref.read(currentLocationProvider.notifier).state = null;
    ref.read(markersProvider.notifier).state = {};

    // Clear bus tracking state
    ref.read(busTrackingProvider.notifier).clearTracking();

    print(
        "DEBUG: BusTrackingController - All tracking state cleared successfully");
  }

  String? getCurrentlyTrackedBus() {
    return ref.read(currentTrackedBusProvider);
  }

  // Map Management Methods
  Future<void> updateMarkers(Set<Marker> newMarkers) async {
    ref.read(markersProvider.notifier).state = newMarkers;
  }

  Future<void> loadBusStops() async {
    final busStops = await BusCommunicationServices.getBusStopsFromJson();
    // Process bus stops and update markers
    // This would be implemented based on your specific needs
  }

  // Helper methods for distance and ETA calculations
  double _calculateDistance(LatLng from, LatLng to) {
    final calculator = haversine.HaversineDistance();
    return calculator.haversine(
      haversine.Location(from.latitude, from.longitude),
      haversine.Location(to.latitude, to.longitude),
      haversine.Unit.KM,
    );
  }

  double _calculateETA(double distance) {
    // Assuming average speed of 30 km/h
    const averageSpeedKmH = 30.0;
    final estimatedTimeHours = distance / averageSpeedKmH;
    return (estimatedTimeHours * 60); // Convert to minutes
  }
}

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../models/bus_stop.dart';
import 'screen_state.dart';

// Screen State Management
final currentScreenStateProvider =
    StateProvider<ScreenState>((ref) => ScreenState.searchBus);
final locationScreenStateProvider = StateProvider<bool>((ref) => false);
final containerHeightProvider = StateProvider<double>((ref) => 0.0);
final locationScreenStepProvider = StateProvider<int>((ref) => 1);

// Bus Selection State
final selectedBusState = StateProvider<String>((ref) => '');
final selectedBusCompanyState = StateProvider<String>((ref) => '');
final selectedBusStopProvider = StateProvider<BusStop?>((ref) => null);
final currentTrackedBusProvider = StateProvider<String?>((ref) => null);

// Location and Map State
final currentLocationProvider = StateProvider<LatLng?>((ref) => null);
final markersProvider = StateProvider<Set<Marker>>((ref) => {});

// Persistent tracking values
final persistentDistanceProvider = StateProvider<double>((ref) => 0.0);
final persistentETAProvider = StateProvider<double>((ref) => 0.0);

// Bus Tracking State
class BusTrackingState {
  final String selectedBus;
  final BusStop? selectedBusStop;
  final double distance;
  final double estimatedArrivalTime;
  final bool isOnTime;
  final String arrivalStatus;
  final Map<String, dynamic>? directionData;

  BusTrackingState({
    required this.selectedBus,
    required this.selectedBusStop,
    required this.distance,
    required this.estimatedArrivalTime,
    required this.isOnTime,
    required this.arrivalStatus,
    this.directionData,
  });

  BusTrackingState copyWith({
    String? selectedBus,
    BusStop? selectedBusStop,
    double? distance,
    double? estimatedArrivalTime,
    bool? isOnTime,
    String? arrivalStatus,
    Map<String, dynamic>? directionData,
  }) {
    return BusTrackingState(
      selectedBus: selectedBus ?? this.selectedBus,
      selectedBusStop: selectedBusStop ?? this.selectedBusStop,
      distance: distance ?? this.distance,
      estimatedArrivalTime: estimatedArrivalTime ?? this.estimatedArrivalTime,
      isOnTime: isOnTime ?? this.isOnTime,
      arrivalStatus: arrivalStatus ?? this.arrivalStatus,
      directionData: directionData ?? this.directionData,
    );
  }
}

class BusTrackingNotifier extends StateNotifier<BusTrackingState?> {
  final Ref ref;

  BusTrackingNotifier(this.ref) : super(null);

  void updateBusTracking({
    required String selectedBus,
    required BusStop? selectedBusStop,
    required double distance,
    required double estimatedArrivalTime,
    required bool isOnTime,
    required String arrivalStatus,
    Map<String, dynamic>? directionData,
  }) {
    // Update persistent values
    ref.read(persistentDistanceProvider.notifier).state = distance;
    ref.read(persistentETAProvider.notifier).state = estimatedArrivalTime;

    state = BusTrackingState(
      selectedBus: selectedBus,
      selectedBusStop: selectedBusStop,
      distance: distance,
      estimatedArrivalTime: estimatedArrivalTime,
      isOnTime: isOnTime,
      arrivalStatus: arrivalStatus,
      directionData: directionData,
    );
  }

  void restoreTracking() {
    if (state != null) {
      // Restore from persistent values
      final distance = ref.read(persistentDistanceProvider);
      final eta = ref.read(persistentETAProvider);

      state = state!.copyWith(
        distance: distance,
        estimatedArrivalTime: eta,
      );
    }
  }

  void clearTracking() {
    // Clear persistent values
    ref.read(persistentDistanceProvider.notifier).state = 0.0;
    ref.read(persistentETAProvider.notifier).state = 0.0;
    state = null;
  }

  // Comprehensive method to clear all tracking state
  void clearAllTrackingState() {
    print("DEBUG: Clearing all tracking state");

    // Clear bus tracking state
    clearTracking();

    // Clear all related providers
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

    print("DEBUG: All tracking state cleared successfully");
  }
}

final busTrackingProvider =
    StateNotifierProvider<BusTrackingNotifier, BusTrackingState?>((ref) {
  return BusTrackingNotifier(ref);
});

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geocoding/geocoding.dart';
import 'package:onebus/models/bus_stop.dart';
import 'package:onebus/services/bus_communication_services.dart';
import 'package:onebus/state/track_bus_state.dart';
import 'package:onebus/state/screen_state.dart';

class BusStopService {
  final WidgetRef ref;
  List<BusStop> busStops = [];

  BusStopService(this.ref);

  Future<void> loadBusStops() async {
    try {
      final busStopsData = await BusCommunicationServices.getBusStopsFromJson();
      busStops = await Future.wait(
        busStopsData.map((busStop) async {
          final coordinates = busStop["coordinates"];
          final latitude = coordinates["latitude"];
          final longitude = coordinates["longitude"];
          final busNumbers = List<String>.from(busStop["bus_numbers"]);
          final latLng = LatLng(latitude, longitude);
          final type = busStop["type"] ?? "Bus stop";
          final busRoutes = busStop["bus_routes"] != null
              ? Map<String, Map<String, String>>.from(
                  busStop["bus_routes"].map((key, value) => MapEntry(
                        key,
                        Map<String, String>.from(value),
                      )))
              : null;
          final busStopIndex =
              busStop["bus_stop_index"] ?? busStop["busStopIndex"];
          final direction = busStop["direction"];

          return BusStop(
            coordinates: latLng,
            busNumbers: busNumbers,
            address: await _getAddressFromLatLng(latLng),
            type: type,
            busRoutes: busRoutes,
            busStopIndex: busStopIndex,
            direction: direction,
          );
        }),
      );
    } catch (e) {
      debugPrint('Error loading bus stops: $e');
      busStops = [];
    }
  }

  Future<String> _getAddressFromLatLng(LatLng latLng) async {
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

  Future<void> handleBusStopSelection(BusStop busStop) async {
    final selectedBus = ref.read(selectedBusState);
    final currentScreenState = ref.read(currentScreenStateProvider);

    if (currentScreenState == ScreenState.locationSelection &&
        selectedBus.isNotEmpty) {
      if (!busStop.busNumbers.contains(selectedBus)) {
        // Show bus not available dialog
        return;
      }

      if (busStop.type.toLowerCase() == 'bus station' &&
          busStop.busRoutes != null) {
        // Get bus direction data
        // final directionData =
        //     await BusCommunicationServices.getBusDirectionData(
        //   selectedBus,
        //   busStop.coordinates.toString(),
        // );

        // Update bus tracking state with direction data
        ref.read(busTrackingProvider.notifier).updateBusTracking(
              selectedBus: selectedBus,
              selectedBusStop: busStop,
              distance: 0.0, // Will be calculated when tracking starts
              estimatedArrivalTime:
                  0.0, // Will be calculated when tracking starts
              isOnTime: true,
              arrivalStatus: 'On Time',
              // directionData: directionData,
            );
      } else {
        // Regular bus stop selection
        ref.read(selectedBusStopProvider.notifier).state = busStop;
      }
    }
  }

  Set<Marker> createBusStopMarkers({
    required BitmapDescriptor? customMarkerIcon,
    required Function(BusStop) onTap,
  }) {
    return busStops.map((busStop) {
      return Marker(
        markerId: MarkerId(busStop.coordinates.toString()),
        position: busStop.coordinates,
        infoWindow: InfoWindow(
          title: busStop.type,
          snippet:
              'Buses: ${busStop.busNumbers.join(", ")}\n${busStop.address}',
        ),
        icon: customMarkerIcon ?? BitmapDescriptor.defaultMarker,
        onTap: () => onTap(busStop),
      );
    }).toSet();
  }
}

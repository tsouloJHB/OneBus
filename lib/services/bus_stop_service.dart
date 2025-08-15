import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geocoding/geocoding.dart';
import 'package:onebus/models/bus_stop.dart';
import 'package:onebus/services/bus_communication_services.dart';
import 'package:onebus/services/bus_route_service.dart';
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
          final busStopIndex = busStop["bus_stop_index"];
          final direction = busStop["direction"];
          final busStopIndices = busStop["bus_stop_indices"] != null
              ? Map<String, int>.from(busStop["bus_stop_indices"])
              : null;

          return BusStop(
            coordinates: latLng,
            address: busStop["address"],
            type: type,
            busStopIndex: busStopIndex,
            direction: direction,
            busStopIndices: busStopIndices,
          );
        }),
      );
    } catch (e) {
      debugPrint('Error loading bus stops: $e');
      busStops = [];
    }
  }

  /// Load bus stops from API for a specific bus and company
  Future<void> loadBusStopsFromApi(String busNumber, String companyName) async {
    try {
      debugPrint(
          '[DEBUG] Loading bus stops from API for bus: $busNumber, company: $companyName');

      final busRouteResponse =
          await BusRouteService.getBusRoutesAndStops(busNumber, companyName);

      if (busRouteResponse != null && busRouteResponse.routes.isNotEmpty) {
        // Get all stops from all routes
        List<BusStop> allStops = [];

        for (var route in busRouteResponse.routes) {
          if (route.active && route.stops.isNotEmpty) {
            final routeStops =
                BusRouteService.convertApiStopsToBusStops(route.stops);
            allStops.addAll(routeStops);
          }
        }

        if (allStops.isNotEmpty) {
          busStops = allStops;
          debugPrint(
              '[DEBUG] Successfully loaded ${busStops.length} bus stops from API');
          return;
        }
      }

      // Fallback to JSON if API fails or returns no data
      debugPrint('[WARN] API returned no data, falling back to JSON file');
      await loadBusStopsFromJson();
    } catch (e) {
      debugPrint('[ERROR] Error loading bus stops from API: $e');
      // Fallback to JSON if API fails
      await loadBusStopsFromJson();
    }
  }

  /// Load bus stops from JSON file (fallback method)
  Future<void> loadBusStopsFromJson() async {
    try {
      final busStopsData = await BusCommunicationServices.getBusStopsFromJson();
      busStops = await Future.wait(
        busStopsData.map((busStop) async {
          final coordinates = busStop["coordinates"];
          final latitude = coordinates["latitude"];
          final longitude = coordinates["longitude"];
          final latLng = LatLng(latitude, longitude);
          final type = busStop["type"] ?? "Bus stop";
          final busStopIndex = busStop["bus_stop_index"];
          final direction = busStop["direction"];
          final busStopIndices = busStop["bus_stop_indices"] != null
              ? Map<String, int>.from(busStop["bus_stop_indices"])
              : null;

          return BusStop(
            coordinates: latLng,
            address: busStop["address"],
            type: type,
            busStopIndex: busStopIndex,
            direction: direction,
            busStopIndices: busStopIndices,
          );
        }),
      );
      debugPrint('[DEBUG] Loaded ${busStops.length} bus stops from JSON file');
    } catch (e) {
      debugPrint('[ERROR] Error loading bus stops from JSON: $e');
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
    final currentScreenState = ref.read(currentScreenStateProvider);

    if (currentScreenState == ScreenState.locationSelection) {
      // No busNumbers check, just select the stop
      ref.read(selectedBusStopProvider.notifier).state = busStop;
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
          snippet: busStop.address ?? '',
        ),
        icon: customMarkerIcon ?? BitmapDescriptor.defaultMarker,
        onTap: () => onTap(busStop),
      );
    }).toSet();
  }
}

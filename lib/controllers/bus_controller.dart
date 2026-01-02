import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/bus_location_data.dart';
import '../services/bus_communication_services.dart';
import '../services/bus_route_service.dart';

// Add providers for bus tracking
final selectedBusCompanyState = StateProvider<String>((ref) => '');
final busLocationProvider = StateProvider<BusLocationData?>((ref) => null);

// Provider for available buses that updates when company changes
final availableBusesProvider =
    FutureProvider.autoDispose<List<String>>((ref) async {
  final busCompany = ref.watch(selectedBusCompanyState);

  if (busCompany.isEmpty) {
    return [];
  }

  try {
    final serverBuses =
        await BusRouteService.getBusNumbersByCompany(busCompany);

    if (serverBuses.isNotEmpty) {
      print(
          '[DEBUG] Successfully fetched ${serverBuses.length} buses from server for $busCompany');
      return serverBuses;
    } else {
      print(
          '[WARN] No buses returned from server, falling back to hardcoded list');
      return _getHardcodedBusesFallback(busCompany);
    }
  } catch (e) {
    print('[ERROR] Exception in availableBusesProvider: $e');
    print('[WARN] Falling back to hardcoded list due to error');
    return _getHardcodedBusesFallback(busCompany);
  }
});

// Fallback hardcoded bus list based on company
List<String> _getHardcodedBusesFallback(String companyName) {
  switch (companyName.toLowerCase()) {
    case 'rea vaya':
      return ["C5", "C4", "C6", "T1", "T3", "T2"];
    case 'metrobus':
      return ["M1", "M2", "M3", "M4"];
    case 'putco':
      return ["P1", "P2", "P3", "P4"];
    default:
      return ["C5", "C4", "C6", "T1", "T3", "T2"]; // Default fallback
  }
}

// Provider to store the current BusCommunicationServices instance for cleanup
// REMOVED: This was causing Riverpod initialization issues

final busTrackingStreamProvider = StreamProvider.autoDispose
    .family<BusLocationData, Map<String, dynamic>>((ref, params) {
  final busCompany = ref.watch(selectedBusCompanyState);
  final busService = BusCommunicationServices();
  
  // CRITICAL: Ensure cleanup on provider dispose
  ref.onDispose(() {
    print('[DEBUG] ===== PROVIDER DISPOSING - FORCING WEBSOCKET CLEANUP =====');
    busService.closeConnection(reason: 'provider_dispose');
    print('[DEBUG] ===== PROVIDER DISPOSE COMPLETE =====');
  });
  
  // Expect params: {busNumber, direction, busStopIndex, latitude, longitude}
  final stream = busService.streamBusLocationLive(
    busNumber: params['busNumber'] ?? 'C5',
    busCompany: busCompany,
    direction: params['direction'] ?? 'Northbound',
    busStopIndex: params['busStopIndex'],
    latitude: params['latitude'],
    longitude: params['longitude'],
  );
  
  // Convert to broadcast stream to allow multiple listeners without creating duplicate connections
  return stream.asBroadcastStream();
});

class BusController {
  final WidgetRef ref;
  BusController(this.ref);

  BusCommunicationServices busCommunicationServices =
      BusCommunicationServices();
  Future<Uint8List> loadBusIcon() async {
    // Load the image from assets
    ByteData byteData = await rootBundle.load('assets/busIcon.png');
    Uint8List imageBytes = byteData.buffer.asUint8List();

    // Resize and compress the image
    final Uint8List? resizedImage = await FlutterImageCompress.compressWithList(
      imageBytes,
      minWidth: 84, // Desired width
      minHeight: 84, // Desired height
      quality: 90, // Quality of the image (0-100)
      format: CompressFormat.png, // Output format
    );

    if (resizedImage == null) {
      throw Exception('Failed to resize image');
    }

    return resizedImage;
  }

  Future<void> setUpBusTracking(int busNumber) async {
    // Set up the bus tracking service
    // This could involve setting up a location tracking service
    // or connecting to a third-party API

    //connect to api and get bus info
    // Map<String, dynamic> busInfo = busCommunicationServices.getBusInfo(busNumber);
    // BusInfo busInfo = BusInfo(
    //   busNumber: 'KAS 123',
    //   name: 'Bus 1',
    //   busId: 'bus1',
    // );
  }

  Future<List<String>> getAvailableBuses() async {
    try {
      final busCompany = ref.read(selectedBusCompanyState);

      if (busCompany.isEmpty) {
        print('[WARN] No bus company selected, returning empty list');
        return [];
      }

      print('[DEBUG] Fetching available buses for company: $busCompany');

      // Try to fetch from server first
      final serverBuses =
          await BusRouteService.getBusNumbersByCompany(busCompany);

      if (serverBuses.isNotEmpty) {
        print(
            '[DEBUG] Successfully fetched ${serverBuses.length} buses from server');
        return serverBuses;
      } else {
        print(
            '[WARN] No buses returned from server, falling back to hardcoded list');
        // Fallback to hardcoded list if server returns empty or fails
        return _getHardcodedBuses(busCompany);
      }
    } catch (e) {
      print('[ERROR] Exception in getAvailableBuses: $e');
      print('[WARN] Falling back to hardcoded list due to error');
      final busCompany = ref.read(selectedBusCompanyState);
      return _getHardcodedBuses(busCompany);
    }
  }

  /// Fallback hardcoded bus list based on company
  List<String> _getHardcodedBuses(String companyName) {
    switch (companyName.toLowerCase()) {
      case 'rea vaya':
        return ["C5", "C4", "C6", "T1", "T3", "T2"];
      case 'metrobus':
        return ["M1", "M2", "M3", "M4"];
      case 'putco':
        return ["P1", "P2", "P3", "P4"];
      default:
        return ["C5", "C4", "C6", "T1", "T3", "T2"]; // Default fallback
    }
  }

  setBusComapny(String busCompany) {
    ref.read(selectedBusCompanyState.notifier).state = busCompany;
  }

  getBusCompany() {
    String busCompany = ref.watch(selectedBusCompanyState);
    return busCompany;
  }

  Future<void> startBusTracking({
    required String busNumber,
    required String direction,
  }) async {
    final busCompany = ref.read(selectedBusCompanyState);

    try {
      // The stream will automatically start through the provider
      // and the first value will be our initial location
      print('Starting bus tracking for bus $busNumber in direction $direction');
    } catch (e) {
      print('Error starting bus tracking: $e');
      throw Exception('Failed to start bus tracking');
    }
  }
}

import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/bus_location_data.dart';
import '../services/bus_communication_services.dart';

// Add providers for bus tracking
final selectedBusCompanyState = StateProvider<String>((ref) => '');
final busLocationProvider = StateProvider<BusLocationData?>((ref) => null);
final busTrackingStreamProvider = StreamProvider.autoDispose
    .family<BusLocationData, Map<String, dynamic>>((ref, params) {
  final busCompany = ref.watch(selectedBusCompanyState);
  final busService = BusCommunicationServices();
  // Expect params: {busNumber, direction, busStopIndex, latitude, longitude}
  return busService.streamBusLocationLive(
    busNumber: params['busNumber'] ?? 'C5',
    busCompany: busCompany,
    direction: params['direction'] ?? 'Northbound',
    busStopIndex: params['busStopIndex'],
    latitude: params['latitude'],
    longitude: params['longitude'],
  );
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

  getAvailableBuses() async {
    //List<BusInfo> buses = await busCommunicationServices.getAvailableBuses();
    final List<String> buses = [
      "C5",
      "C4",
      "C6",
      "T1",
      "T3",
      "T2",
    ];
    return buses;
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

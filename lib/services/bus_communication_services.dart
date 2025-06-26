import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../models/BusInfo.dart';
import '../models/bus_position.model.dart';
import '../models/bus_location_data.dart';

class BusCommunicationServices {
  // Keep track of simulated bus positions
  static final Map<String, LatLng> _simulatedBusPositions = {};
  static const double _baseLatitude = -26.18161422751231;
  static const double _baseLongitude = 27.979878347512333;

  static LatLng _getSimulatedPosition(String busNumber) {
    if (!_simulatedBusPositions.containsKey(busNumber)) {
      // Initialize with base position if not exists
      _simulatedBusPositions[busNumber] = LatLng(_baseLatitude, _baseLongitude);
    }
    return _simulatedBusPositions[busNumber]!;
  }

  static void _updateSimulatedPosition(String busNumber) {
    final currentPos = _getSimulatedPosition(busNumber);
    // Simulate movement
    final newPos = LatLng(
      currentPos.latitude + (DateTime.now().millisecond / 10000),
      currentPos.longitude + (DateTime.now().millisecond / 10000),
    );
    _simulatedBusPositions[busNumber] = newPos;
  }

  static Future<void> sendBusInfo(BusInfo busInfo) async {
    //   try {
    //     final url = 'your_api_url_here';
    //     final response = await http.post(
    //       Uri.parse(url),
    //       body: json.encode(busInfo),
    //       headers: {'Content-Type': 'application/json'},
    //     );

    //     if (response.statusCode == 200) {
    //       // Request was successful, handle response if needed
    //       print('Bus info sent successfully!');
    //     } else {
    //       // Request failed, handle error if needed
    //       print('Failed to send bus info. Error: ${response.statusCode}');
    //     }
    //   } catch (error) {
    //     // Handle any exceptions or errors
    //     print('An error occurred while sending bus info: $error');
    //   }
    // }
    print(busInfo);
  }

  static Future<void> sendBusCoordinates(
      BusPosition busPosition, BusInfo busState) async {
    final docUser = FirebaseFirestore.instance
        .collection('BusLocation')
        .doc(busPosition.busId);

    // Get the current document snapshot
    final snapshot = await docUser.get();

    // Retrieve the current counter value or set it to 0 if it doesn't exist
    final currentCounter =
        snapshot.exists ? (snapshot.data()!['counter'] ?? 0) : 0;

    // Increment the counter
    final newCounter = currentCounter + 1;

    // Update the document with the new counter value and other fields
    final jsonData = {
      'busNumber': busPosition.busNumber,
      'busId': busPosition.busId,
      'latitude': busPosition.coordinates.latitude,
      'longitude': busPosition.coordinates.longitude,
      'timestamp': FieldValue.serverTimestamp(),
      'counter': newCounter,
    };
    await docUser.set(jsonData);
  }
  // static Future<void> sendBusCoordinates(
  //     BusPosition busPosition, BusInfo busState) async {
  //   final docUser = FirebaseFirestore.instance
  //       .collection('BusLocation')
  //       .doc(busPosition.busId);
  //   final jsonData = {
  //     'busNumber': busPosition.busNumber,
  //     'busId': busPosition.busId,
  //     'latitude': busPosition.latitude,
  //     'longitude': busPosition.longitude,
  //     'timestamp': FieldValue.serverTimestamp(),
  //     'driverName': busState.name
  //   };
  //   await docUser.set(jsonData);
  // }
  //   static Future<void> sendBusCoordinates(
  //     BusPosition busPosition, BusInfo busState) async {

  //   final docUser = FirebaseFirestore.instance.collection('BusLocation');
  //   final jsonData = {
  //     'BusNumber': busPosition.busNumber,
  //     'BusID': busPosition.busId,
  //     'latitude': busPosition.latitude,
  //     'longitude': busPosition.longitude
  //   };
  //   await docUser.add(jsonData);
  // }

  static Future<List<dynamic>> getBusStopsFromJson() async {
    return await loadJsonData();
  }

  static Future<List<dynamic>> loadJsonData() async {
    String jsonString =
        await rootBundle.loadString('lib/models/data/busStops.json');
    var jsonData = json.decode(jsonString);
    return jsonData['bus_stops'];
  }

  Future<Map<String, dynamic>> getBusInfo(String busNumber) async {
    //final docUser = FirebaseFirestore.instance.collection('BusLocation');
    //final jsonData = await docUser.doc(busNumber).get();

    return {};
  }

  // Cache for loaded paths to avoid reloading
  static final Map<String, List<LatLng>> _busPathsCache = {};

  // Helper to load path from JSON
  static Future<List<LatLng>> loadBusPath(String bus, String direction) async {
    final cacheKey = '$bus-$direction';
    print('[DEBUG] Loading path for bus: $bus, direction: $direction');
    if (_busPathsCache.containsKey(cacheKey)) {
      print('[DEBUG] Path cache hit for $cacheKey');
      return _busPathsCache[cacheKey]!;
    }
    try {
      final data = await rootBundle.loadString('lib/models/data/reyaVayaPaths.json');
      final jsonResult = json.decode(data);
      final coords = jsonResult[bus.toLowerCase()]?[direction]?['coordinates'] as List<dynamic>?;
      if (coords == null) {
        print('[DEBUG] No coordinates found for $bus $direction');
        return [];
      }
      final path = coords.map((c) => LatLng(c['latitude'], c['longitude'])).toList();
      print('[DEBUG] Loaded path with ${path.length} points for $bus $direction');
      _busPathsCache[cacheKey] = path;
      return path;
    } catch (e) {
      print('[ERROR] Failed to load bus path: $e');
      return [];
    }
  }

  // Method to start real-time bus tracking using real path
  Stream<BusLocationData> streamBusLocation({
    required String busNumber,
    required String busCompany,
    required String direction,
  }) async* {
    final path = await loadBusPath(busNumber, direction);
    if (path.isEmpty) {
      print('[DEBUG] Path is empty for $busNumber $direction, falling back to random simulation');
      yield* _simulateRandomPosition(busNumber, busCompany, direction);
      return;
    }
    int idx = 0;
    print('[DEBUG] Starting stream for $busNumber $direction, path length: ${path.length}');
    while (true) {
      final position = path[idx % path.length];
      print('[DEBUG] Emitting position $idx: (${position.latitude}, ${position.longitude})');
      yield BusLocationData(
        busNumber: busNumber,
        busCompany: busCompany,
        direction: direction,
        coordinates: position,
        speed: 40.0, // You may enhance with dynamic speed if needed
        isActive: true,
        lastUpdated: DateTime.now(),
      );
      idx++;
      await Future.delayed(const Duration(seconds: 5));
    }
  }

  // Old simulation fallback
  Stream<BusLocationData> _simulateRandomPosition(
    String busNumber,
    String busCompany,
    String direction,
  ) async* {
    print('[DEBUG] Using fallback random simulation for $busNumber $direction');
    while (true) {
      await Future.delayed(const Duration(seconds: 5));
      _updateSimulatedPosition(busNumber);
      final position = _getSimulatedPosition(busNumber);
      print('[DEBUG] Emitting random simulated position: (${position.latitude}, ${position.longitude})');
      yield BusLocationData(
        busNumber: busNumber,
        busCompany: busCompany,
        direction: direction,
        coordinates: position,
        speed: 40.0 + (DateTime.now().second % 10),
        isActive: true,
        lastUpdated: DateTime.now(),
      );
    }
  }
}

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:io' show WebSocketException;
import 'package:web_socket_channel/web_socket_channel.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:stomp_dart_client/stomp_dart_client.dart';

import '../constants/app_constants.dart';
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
    // Simulate realistic movement along a route (small increments)
    final random = DateTime.now().millisecondsSinceEpoch;
    final latIncrement = (random % 20 - 10) / 100000.0; // -0.0001 to +0.0001 degrees
    final lngIncrement = (random % 20 - 10) / 100000.0; // Small realistic movements
    
    final newPos = LatLng(
      (currentPos.latitude + latIncrement).clamp(-26.3, -26.1), // Keep in Johannesburg area
      (currentPos.longitude + lngIncrement).clamp(27.8, 28.2),  // Keep in Johannesburg area
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
        await rootBundle.loadString('lib/models/data/reayVaya5cRoute.json');
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
      final data =
          await rootBundle.loadString('lib/models/data/reyaVayaPaths.json');
      final jsonResult = json.decode(data);
      final coords = jsonResult[bus.toLowerCase()]?[direction]?['coordinates']
          as List<dynamic>?;
      if (coords == null) {
        print('[DEBUG] No coordinates found for $bus $direction');
        return [];
      }
      final path =
          coords.map((c) => LatLng(c['latitude'], c['longitude'])).toList();
      print(
          '[DEBUG] Loaded path with ${path.length} points for $bus $direction');
      _busPathsCache[cacheKey] = path;
      return path;
    } catch (e) {
      print('[ERROR] Failed to load bus path: $e');
      return [];
    }
  }

  Stream<BusLocationData> streamBusLocationLive({
    required String busNumber,
    required String busCompany,
    required String direction,
    int? busStopIndex,
    double? latitude,
    double? longitude,
  }) {
    final controller = StreamController<BusLocationData>();
    final topic = "/topic/bus/${busNumber}_${direction}";
    StompClient? stompClient;

    // Add a timeout to fallback to simulation if WebSocket fails
    Timer? connectionTimeout;

    print(
        '[DEBUG] streamBusLocationLive: Initializing for bus $busNumber, direction $direction');
    print(
        '[DEBUG] streamBusLocationLive: WebSocket URL: ${AppConstants.webSocketUrl}');
    print('[DEBUG] streamBusLocationLive: Subscribing to topic: $topic');

    stompClient = StompClient(
      config: StompConfig(
        url: AppConstants.webSocketUrl,
        // Add SockJS compatibility settings
        webSocketConnectHeaders: {
          'Accept': 'application/json, text/plain, */*',
          'Accept-Language': 'en-US,en;q=0.9',
          'Cache-Control': 'no-cache',
          'Pragma': 'no-cache',
          'Sec-WebSocket-Protocol': 'websocket',
          'Upgrade': 'websocket',
          'Connection': 'Upgrade',
        },
        onConnect: (StompFrame frame) {
          print('[SUCCESS] streamBusLocationLive: Connected to WebSocket');
          connectionTimeout
              ?.cancel(); // Cancel timeout since connection succeeded

          // Subscribe to the bus topic
          stompClient?.subscribe(
            destination: topic,
            callback: (frame) {
              if (frame.body != null) {
                try {
                  final data = json.decode(frame.body!);
                  print(
                      '[DEBUG] Received data for $busNumber $direction: $data');

                  // Map the backend data to our BusLocationData model
                  controller.add(
                    BusLocationData(
                      busNumber: data['busNumber'] ?? busNumber,
                      busCompany: busCompany,
                      direction: data['tripDirection'] ?? direction,
                      coordinates: LatLng(
                        data['lat']?.toDouble() ??
                            data['latitude']?.toDouble() ??
                            0.0,
                        data['lon']?.toDouble() ??
                            data['longitude']?.toDouble() ??
                            0.0,
                      ),
                      speed: data['speedKmh']?.toDouble() ??
                          data['speed']?.toDouble() ??
                          0.0,
                      isActive: true,
                      lastUpdated: DateTime.now(),
                    ),
                  );
                } catch (e) {
                  print('[ERROR] Failed to parse bus data: $e');
                  print('[ERROR] Raw data: ${frame.body}');
                }
              } else {
                print(
                    '[WARN] streamBusLocationLive: Received empty frame body for topic $topic');
              }
            },
          );

          // Send subscription request to backend
          print(
              '[DEBUG] streamBusLocationLive: Sending subscription message to /app/subscribe');
          final Map<String, dynamic> payload = {
            'busNumber': busNumber,
            'direction': direction,
          };
          if (busStopIndex != null) payload['busStopIndex'] = busStopIndex;
          if (latitude != null) payload['latitude'] = latitude;
          if (longitude != null) payload['longitude'] = longitude;
          stompClient?.send(
            destination: '/app/subscribe',
            body: json.encode(payload),
          );
        },
        onWebSocketError: (dynamic error) {
          print('[ERROR] streamBusLocationLive: WebSocket error: $error');
          print(
              '[ERROR] streamBusLocationLive: Error type: ${error.runtimeType}');
          if (error is WebSocketException) {
            print(
                '[ERROR] streamBusLocationLive: WebSocket exception details: ${error.message}');
          }
          print(
              '[INFO] streamBusLocationLive: Falling back to simulated data due to WebSocket error');
          // Fallback to simulated data instead of throwing error
          _startSimulatedStream(controller, busNumber, busCompany, direction);
        },
        onStompError: (dynamic error) {
          print('[ERROR] streamBusLocationLive: STOMP error: $error');
          print(
              '[ERROR] streamBusLocationLive: STOMP error type: ${error.runtimeType}');
          controller.addError(error);
        },
      ),
    );

    controller.onListen = () {
      print('[DEBUG] streamBusLocationLive: Activating STOMP client...');

      // Set a timeout to fallback to simulation if WebSocket doesn't connect
      connectionTimeout = Timer(const Duration(seconds: 10), () {
        print(
            '[WARN] streamBusLocationLive: WebSocket connection timeout, falling back to simulation');
        if (!controller.isClosed) {
          _startSimulatedStream(controller, busNumber, busCompany, direction);
        }
      });

      stompClient?.activate();
    };

    controller.onCancel = () {
      print('[DEBUG] streamBusLocationLive: Deactivating STOMP client...');
      connectionTimeout?.cancel();

      // Send unsubscribe request to backend
      if (stompClient != null) {
        stompClient?.send(
          destination: '/app/unsubscribe',
          body: json.encode({'busNumber': busNumber, 'direction': direction}),
        );
      }

      stompClient?.deactivate();
    };

    return controller.stream;
  }

  // // Method to start real-time bus tracking using real path
  // Stream<BusLocationData> streamBusLocationLive({
  //   required String busNumber,
  //   required String busCompany,
  //   required String direction,
  // }) async* {}

  // Method to start real-time bus tracking using real path
  Stream<BusLocationData> streamBusLocation({
    required String busNumber,
    required String busCompany,
    required String direction,
  }) async* {
    final path = await loadBusPath(busNumber, direction);
    if (path.isEmpty) {
      print(
          '[DEBUG] Path is empty for $busNumber $direction, falling back to random simulation');
      yield* _simulateRandomPosition(busNumber, busCompany, direction);
      return;
    }
    int idx = 0;
    print(
        '[DEBUG] Starting stream for $busNumber $direction, path length: ${path.length}');
    while (true) {
      final position = path[idx % path.length];
      print(
          '[DEBUG] Emitting position $idx: (${position.latitude}, ${position.longitude})');
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
      print(
          '[DEBUG] Emitting random simulated position: (${position.latitude}, ${position.longitude})');
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

  // Helper method to start simulated stream in a StreamController
  void _startSimulatedStream(
    StreamController<BusLocationData> controller,
    String busNumber,
    String busCompany,
    String direction,
  ) async {
    print('[INFO] Starting simulated stream for $busNumber $direction');
    try {
      await for (final data
          in _simulateRandomPosition(busNumber, busCompany, direction)) {
        if (!controller.isClosed) {
          controller.add(data);
        } else {
          break;
        }
      }
    } catch (e) {
      print('[ERROR] Error in simulated stream: $e');
      if (!controller.isClosed) {
        controller.addError(e);
      }
    }
  }

  // Test method to check WebSocket connectivity
  static Future<bool> testWebSocketConnection() async {
    try {
      print(
          '[TEST] Testing WebSocket connection to: ${AppConstants.webSocketUrl}');

      final completer = Completer<bool>();
      StompClient? client;

      client = StompClient(
        config: StompConfig(
          url: AppConstants.webSocketUrl,
          // Add SockJS compatibility settings
          webSocketConnectHeaders: {
            'Accept': 'application/json, text/plain, */*',
            'Accept-Language': 'en-US,en;q=0.9',
            'Cache-Control': 'no-cache',
            'Pragma': 'no-cache',
          },
          onConnect: (StompFrame frame) {
            print('[TEST] WebSocket connection successful!');
            completer.complete(true);
            client?.deactivate();
          },
          onWebSocketError: (dynamic error) {
            print('[TEST] WebSocket connection failed: $error');
            completer.complete(false);
          },
          onStompError: (dynamic error) {
            print('[TEST] STOMP error: $error');
            completer.complete(false);
          },
        ),
      );

      client.activate();

      // Wait for connection with timeout
      final result = await completer.future.timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          print('[TEST] WebSocket connection timeout');
          client?.deactivate();
          return false;
        },
      );

      return result;
    } catch (e) {
      print('[TEST] Error testing WebSocket connection: $e');
      return false;
    }
  }

  // Test multiple WebSocket endpoints
  static Future<Map<String, bool>> testAllWebSocketEndpoints() async {
    final endpoints = [
      'ws://192.168.8.146:8080/ws/bus-updates',
      'ws://192.168.8.146:8080/ws/bus-updates/websocket',
      'ws://192.168.8.146:8080/ws',
      'ws://192.168.8.146:8080/websocket',
      'ws://192.168.8.146:8080/ws/bus-updates/websocket/websocket',
      'ws://192.168.8.146:8080/ws/bus-updates/websocket/websocket/websocket',
    ];

    final results = <String, bool>{};

    for (final endpoint in endpoints) {
      print('[TEST] Testing endpoint: $endpoint');
      try {
        final completer = Completer<bool>();
        StompClient? client;

        client = StompClient(
          config: StompConfig(
            url: endpoint,
            webSocketConnectHeaders: {
              'Accept': 'application/json, text/plain, */*',
              'Accept-Language': 'en-US,en;q=0.9',
              'Cache-Control': 'no-cache',
              'Pragma': 'no-cache',
            },
            onConnect: (StompFrame frame) {
              print('[TEST] ✅ Connected to: $endpoint');
              completer.complete(true);
              client?.deactivate();
            },
            onWebSocketError: (dynamic error) {
              print('[TEST] ❌ Failed to connect to: $endpoint - $error');
              completer.complete(false);
            },
            onStompError: (dynamic error) {
              print('[TEST] ❌ STOMP error for: $endpoint - $error');
              completer.complete(false);
            },
          ),
        );

        client.activate();

        final result = await completer.future.timeout(
          const Duration(seconds: 3),
          onTimeout: () {
            print('[TEST] ⏰ Timeout for: $endpoint');
            client?.deactivate();
            return false;
          },
        );

        results[endpoint] = result;
      } catch (e) {
        print('[TEST] ❌ Exception for: $endpoint - $e');
        results[endpoint] = false;
      }
    }

    return results;
  }

  // Test method to check if server is reachable via HTTP
  static Future<bool> testServerReachability() async {
    try {
      // Test the base server endpoint
      final httpUrl = 'http://192.168.8.146:8080';
      print('[TEST] Testing HTTP connection to: $httpUrl');

      final httpClient = HttpClient();
      final request = await httpClient.getUrl(Uri.parse(httpUrl));
      final response = await request.close();

      print('[TEST] HTTP response status: ${response.statusCode}');
      httpClient.close();

      return response.statusCode <
          400; // Any status less than 400 means server is reachable
    } catch (e) {
      print('[TEST] HTTP connection failed: $e');
      return false;
    }
  }

  // Test direct WebSocket connection (without STOMP)
  static Future<bool> testDirectWebSocketConnection() async {
    try {
      print(
          '[TEST] Testing direct WebSocket connection to: ${AppConstants.webSocketUrl}');

      final channel = WebSocketChannel.connect(
        Uri.parse(AppConstants.webSocketUrl),
      );

      // Wait a bit to see if connection is established
      await Future.delayed(const Duration(seconds: 2));

      // Try to send a test message
      try {
        channel.sink.add('test');
        print('[TEST] ✅ Direct WebSocket connection successful!');
        channel.sink.close();
        return true;
      } catch (e) {
        print('[TEST] ❌ Direct WebSocket connection failed: $e');
        return false;
      }
    } catch (e) {
      print('[TEST] ❌ Direct WebSocket connection error: $e');
      return false;
    }
  }

  // Test SockJS handshake
  static Future<bool> testSockJSHandshake() async {
    try {
      print('[TEST] Testing SockJS handshake...');

      // First, try to get the SockJS info endpoint
      final httpClient = HttpClient();
      final infoUrl = 'http://192.168.8.146:8080/ws/bus-updates/info';

      try {
        final request = await httpClient.getUrl(Uri.parse(infoUrl));
        final response = await request.close();
        print('[TEST] SockJS info response: ${response.statusCode}');
        httpClient.close();

        if (response.statusCode == 200) {
          print('[TEST] ✅ SockJS endpoint is available');
          return true;
        }
      } catch (e) {
        print('[TEST] SockJS info endpoint not available: $e');
      }

      // Try the websocket endpoint directly
      final wsUrl = 'ws://192.168.8.146:8080/ws/bus-updates/websocket';
      try {
        final channel = WebSocketChannel.connect(Uri.parse(wsUrl));
        await Future.delayed(const Duration(seconds: 1));
        channel.sink.close();
        print('[TEST] ✅ SockJS WebSocket endpoint works');
        return true;
      } catch (e) {
        print('[TEST] ❌ SockJS WebSocket endpoint failed: $e');
        return false;
      }
    } catch (e) {
      print('[TEST] ❌ SockJS handshake test error: $e');
      return false;
    }
  }
}

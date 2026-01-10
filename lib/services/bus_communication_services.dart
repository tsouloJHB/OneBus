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
  // Instance-based approach instead of static
  StompClient? _stompClient;
  StreamController<BusLocationData>? _currentController;

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

  /**
   * Calculate accurate distance between bus and user along the actual route path.
   * Uses linear referencing on the backend to snap GPS positions to the route
   * and calculate distance along the polyline instead of straight-line distance.
   * 
   * @param busNumber Bus route number (e.g., "C5")
   * @param direction Direction of travel (e.g., "Northbound", "Southbound")
   * @param busLat Current bus latitude
   * @param busLon Current bus longitude
   * @param userLat User location latitude
   * @param userLon User location longitude
   * @return Map containing distanceMeters, distanceKm, estimatedTimeMinutes, and snap indices
   */
  static Future<Map<String, dynamic>?> calculateRouteDistance({
    required String busNumber,
    required String direction,
    required double busLat,
    required double busLon,
    required double userLat,
    required double userLon,
  }) async {
    try {
      final url = '${AppConstants.apiBaseUrl}/tracking/distance';
      print('[DEBUG] Calling route distance API: $url');
      
      final requestBody = {
        'busNumber': busNumber,
        'direction': direction,
        'busLat': busLat,
        'busLon': busLon,
        'userLat': userLat,
        'userLon': userLon,
      };
      
      print('[DEBUG] Request body: $requestBody');
      
      final response = await HttpClient().postUrl(Uri.parse(url))
        .then((request) {
          request.headers.set('Content-Type', 'application/json');
          request.write(json.encode(requestBody));
          return request.close();
        });
      
      final responseBody = await response.transform(utf8.decoder).join();
      
      if (response.statusCode == 200) {
        final data = json.decode(responseBody);
        print('[DEBUG] Route distance calculated: ${data['distanceKm']} km, ETA: ${data['estimatedTimeMinutes']} min');
        return data;
      } else {
        print('[ERROR] Failed to calculate route distance: ${response.statusCode}');
        print('[ERROR] Response: $responseBody');
        return null;
      }
    } catch (e) {
      print('[ERROR] Exception calculating route distance: $e');
      return null;
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
    final controller = StreamController<BusLocationData>(); // Single-subscription is fine
    final primaryTopic = "/topic/bus/${busNumber}_${direction}";
    
    StompClient? stompClient;
    Timer? connectionTimeout;
    bool hasReceivedData = false;
    String? specificBusTopic; // Track the specific bus topic we're subscribed to

    print('[DEBUG] streamBusLocationLive: Initializing for bus $busNumber, direction $direction');
    print('[DEBUG] streamBusLocationLive: Primary topic: $primaryTopic');
    print('[DEBUG] streamBusLocationLive: WebSocket URL: ${AppConstants.webSocketUrl}');

    // Common callback for handling bus location data
    void handleBusLocationData(StompFrame frame) {
      if (frame.body != null) {
        try {
          final data = json.decode(frame.body!);
          print('[DEBUG] Received data on ${frame.headers['destination']}: $data');
          hasReceivedData = true;

          // Check if this is a bus-offline event
          if (data['event'] == 'bus-offline') {
            print('[DEBUG] Bus went offline: ${data['busId']}');
            if (!controller.isClosed) {
              controller.addError('Bus is no longer available');
              controller.close();
            }
            return;
          }

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
              // Check if this is fallback data (different direction than requested)
              isFallback: (data['tripDirection'] ?? direction).toLowerCase() != direction.toLowerCase(),
              fallbackDirection: (data['tripDirection'] ?? direction).toLowerCase() != direction.toLowerCase() 
                  ? (data['tripDirection'] ?? direction) : null,
              originalDirection: (data['tripDirection'] ?? direction).toLowerCase() != direction.toLowerCase() 
                  ? direction : null,
              // Route-based distance and ETA from backend (linear referencing)
              distanceMeters: data['distanceMeters']?.toDouble(),
              distanceKm: data['distanceKm']?.toDouble(),
              estimatedTimeMinutes: data['estimatedTimeMinutes']?.toDouble(),
            ),
          );
        } catch (e) {
          print('[ERROR] Failed to parse bus data: $e');
          print('[ERROR] Raw data: ${frame.body}');
        }
      }
    }

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
          connectionTimeout?.cancel();

          // Subscribe to the primary direction topic
          print('[DEBUG] Subscribing to primary topic: $primaryTopic');
          stompClient?.subscribe(
            destination: primaryTopic,
            callback: handleBusLocationData,
          );

          // Subscribe to the subscription status topic to get the selected bus ID
          // This MUST be done before sending the subscription request
          print('[DEBUG] Subscribing to subscription status topic');
          stompClient?.subscribe(
            destination: '/topic/bus/subscription-status',
            callback: (frame) {
              if (frame.body != null) {
                try {
                  final statusData = json.decode(frame.body!);
                  print('[DEBUG] ✅ Subscription status received: $statusData');
                  
                  // If backend selected a specific bus, we'll receive data on the primary topic
                  // No need to create a second subscription - the backend will route data appropriately
                  if (statusData['selectedBusId'] != null) {
                    final selectedBusId = statusData['selectedBusId'] as String;
                    print('[DEBUG] 🚌 Backend selected specific bus: $selectedBusId');
                    print('[DEBUG] 📡 Data will be received on primary topic: $primaryTopic');
                    // Note: We don't create a second subscription here to avoid duplicates
                  } else {
                    print('[DEBUG] ⚠️ No specific bus selected, using primary topic only');
                  }
                } catch (e) {
                  print('[ERROR] Failed to parse subscription status: $e');
                  print('[ERROR] Raw data: ${frame.body}');
                }
              }
            },
          );

          // Wait a brief moment for subscription to be registered, then send request
          Future.delayed(const Duration(milliseconds: 100), () {
            // Send subscription request to backend with smart bus selection
            print('[DEBUG] streamBusLocationLive: Sending subscription message to /app/subscribe');
            final Map<String, dynamic> payload = {
              'busNumber': busNumber,
              'direction': direction,
            };
            if (busStopIndex != null) payload['busStopIndex'] = busStopIndex;
            if (latitude != null) payload['latitude'] = latitude;
            if (longitude != null) payload['longitude'] = longitude;
            
            print('[DEBUG] Subscription payload: $payload');
            
            stompClient?.send(
              destination: '/app/subscribe',
              body: json.encode(payload),
            );
          });
        },
        onWebSocketError: (dynamic error) {
          print('[ERROR] streamBusLocationLive: WebSocket error: $error');
          print('[ERROR] streamBusLocationLive: Error type: ${error.runtimeType}');
          if (error is WebSocketException) {
            print('[ERROR] streamBusLocationLive: WebSocket exception details: ${error.message}');
          }
          print('[ERROR] streamBusLocationLive: Unable to connect to server');
          // Cancel timeouts and close stream
          connectionTimeout?.cancel();
          if (!controller.isClosed) {
            controller.addError('Unable to connect to server. Please check your internet connection and try again.');
            controller.close();
          }
        },
        onStompError: (dynamic error) {
          print('[ERROR] streamBusLocationLive: STOMP error: $error');
          print('[ERROR] streamBusLocationLive: STOMP error type: ${error.runtimeType}');
          connectionTimeout?.cancel();
          if (!controller.isClosed) {
            controller.addError('Unable to connect to server. Please check your internet connection and try again.');
            controller.close();
          }
        },
      ),
    );

    controller.onListen = () {
      print('[DEBUG] streamBusLocationLive: Activating STOMP client...');
      
      // Store references for cleanup
      _stompClient = stompClient;
      _currentController = controller;

      // Set a timeout to report error if WebSocket doesn't connect
      connectionTimeout = Timer(const Duration(seconds: 10), () {
        print('[ERROR] streamBusLocationLive: WebSocket connection timeout');
        if (!controller.isClosed) {
          controller.addError('Connection timeout. The server may be offline. Please try again later.');
          controller.close();
        }
        stompClient?.deactivate();
      });

      stompClient?.activate();
    };

    controller.onCancel = () {
      print('[DEBUG] ===== STREAM CANCELLED =====');
      print('[DEBUG] Stream cancelled at: ${DateTime.now()}');
      print('[DEBUG] Stack trace: ${StackTrace.current}');
      connectionTimeout?.cancel();
      
      // Clear references but don't force immediate closure
      // Let the explicit closeConnection() handle proper cleanup
      _stompClient = null;
      _currentController = null;
      print('[DEBUG] Stream cancelled - references cleared');
    };

    return controller.stream;
  }

  // Instance method to explicitly close connection
  Future<void> closeConnection({String? reason}) async {
    print('[DEBUG] ===== EXPLICIT CLOSE CONNECTION CALLED =====');
    print('[DEBUG] Reason: ${reason ?? "No reason provided"}');
    print('[DEBUG] StompClient exists: ${_stompClient != null}');
    print('[DEBUG] StompClient connected: ${_stompClient?.connected ?? false}');
    
    final clientToClose = _stompClient;
    final controllerToClose = _currentController;
    
    if (clientToClose != null) {
      try {
        if (clientToClose.connected) {
          print('[DEBUG] Sending cleanup message to backend');
          try {
            clientToClose.send(
              destination: '/app/cleanup',
              body: json.encode({'reason': reason ?? 'manual_cleanup'}),
            );
            // Give the cleanup message time to be sent
            await Future.delayed(const Duration(milliseconds: 100));
          } catch (e) {
            print('[WARN] Failed to send cleanup message: $e');
          }
        }
        
        // Close the stream controller first
        if (controllerToClose != null && !controllerToClose.isClosed) {
          print('[DEBUG] Closing stream controller');
          await controllerToClose.close();
        }
        
        // CRITICAL: Force deactivate the WebSocket
        print('[DEBUG] Forcing WebSocket deactivation');
        clientToClose.deactivate();
        
        print('[DEBUG] WebSocket connection closed successfully');
      } catch (e) {
        print('[ERROR] Error during WebSocket closure: $e');
        // Still try to deactivate
        try {
          clientToClose.deactivate();
        } catch (_) {}
      }
    } else {
      print('[DEBUG] No WebSocket client to close');
      
      // Still close the controller if it exists
      if (controllerToClose != null && !controllerToClose.isClosed) {
        print('[DEBUG] Closing orphaned stream controller');
        await controllerToClose.close();
      }
    }
    
    // Clear references after cleanup
    _stompClient = null;
    _currentController = null;
    print('[DEBUG] ===== EXPLICIT CLOSE CONNECTION COMPLETE =====');
  }

  // Static method to explicitly close active WebSocket connection
  static Future<void> closeActiveConnection({String? reason}) async {
    // This method is now deprecated - use instance method instead
    print('[WARN] closeActiveConnection is deprecated - use instance method closeConnection instead');
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
    final baseUrl = AppConstants.webSocketUrl.replaceFirst('ws://', '').split(':')[0];
    final port = AppConstants.webSocketUrl.split(':')[2].split('/')[0];
    
    final endpoints = [
      'ws://$baseUrl:$port/ws/bus-updates',
      'ws://$baseUrl:$port/ws/bus-updates/websocket',
      'ws://$baseUrl:$port/ws',
      'ws://$baseUrl:$port/websocket',
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
      // Test the base server endpoint using the same URL as app constants
      final httpUrl = AppConstants.apiBaseUrl.replaceFirst('/api', '');
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

      final baseUrl = AppConstants.apiBaseUrl.replaceFirst('/api', '');
      
      // First, try to get the SockJS info endpoint
      final httpClient = HttpClient();
      final infoUrl = '$baseUrl/ws/bus-updates/info';

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
      final wsUrl = AppConstants.webSocketUrl;
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

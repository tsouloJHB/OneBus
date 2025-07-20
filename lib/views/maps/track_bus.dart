import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:onebus/controllers/bus_controller.dart';
import 'package:onebus/controllers/bus_tracking_controller.dart';

import 'package:onebus/models/bus_stop.dart';
import 'package:onebus/services/bus_communication_services.dart';
import 'package:onebus/state/track_bus_state.dart';
import 'package:onebus/state/screen_state.dart';
import 'package:onebus/views/home.dart';
import 'package:geocoding/geocoding.dart' hide Location;
import 'package:onebus/views/maps/widegts/bottom_search_sheet.dart';
import 'package:onebus/views/maps/widegts/bottom_tracking_sheet.dart';

import 'package:onebus/views/maps/widegts/menu_button_widget.dart';
import 'package:onebus/views/maps/widegts/search_location_overlay.dart';
import 'package:onebus/views/maps/widegts/selection_location_sheet.dart';
import 'package:onebus/models/bus_location_data.dart';

final selectedBusStateProvider = StateProvider<String>((ref) => '');
final currentBusLocationProvider = StateProvider<LatLng?>((ref) => null);
final lastUpdateTimeProvider = StateProvider<DateTime?>((ref) => null);

class TrackBus extends ConsumerStatefulWidget {
  final String currentScreen;
  const TrackBus({super.key, required this.currentScreen});

  @override
  ConsumerState<TrackBus> createState() => TrackBusState();
}

class TrackBusState extends ConsumerState<TrackBus> {
  Set<Polyline> _routePolylines = {}; // Store polylines for the route

  late GoogleMapController _mapController;
  late BusTrackingController _busTrackingController;
  late BusController busController;
  Location _location = Location();
  Set<Marker> markers = {}; // Declare the 'markers' variable here
  BitmapDescriptor? customMarkerIcon;
  List<dynamic> _busStopsCoordinates = [];
  List<Marker> _busStopMarkers = [];
  LatLng? previousLocation; // Track the previous location
  double totalDistance = 0.0; // Track the total distance traveled
  double _childSize = 0.4;
  String selectedBus = "";
  bool _isDialogVisible = false;
  bool _isTrackingUserLocation = true; // Flag to control camera movement
  bool _isFollowingBus = true; // Flag to control bus following
  MarkerId busMarkerId =
      const MarkerId('bus_location'); // Unique ID for the bus marker
  bool _showBottomSheet = false;
  List<BusStop> _busStops = [];
  LatLng? _currentLocation;
  StreamSubscription<LocationData>? _locationSubscription;

  LatLng? _selectedLocation; // To store the selected location
  Marker? _locationSelectionMarker; // The draggable marker
  //move this
  // final String hintText;
  // final IconData icon; // Add the icon parameter
  // final TextEditingController controller;
  final TextEditingController _searchController = TextEditingController();

  // List of available buses
  List<String> _allBuses = [];
  List<String> _filteredBuses = [];

  Uint8List? busIcon;

  // Add variables to track bus movement for rotation
  LatLng? _previousBusLocation;
  double _currentBusBearing = 0.0;
  Map<double, BitmapDescriptor> _rotatedBusIcons = {};
  bool _isStreamActive = false; // Add flag to control stream activity

  @override
  void initState() {
    super.initState();
    print("DEBUG: initState called for screen: ${widget.currentScreen}");
    _busTrackingController = BusTrackingController(ref);
    busController = BusController(ref);
    _initializeBuses();
    _searchController.addListener(_handleSearchChange);
    _loadBusIcon(); // Add explicit bus icon loading

    // Initialize screen state based on currentScreen parameter
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Reset all state first
      ref.read(selectedBusStateProvider.notifier).state = '';
      ref.read(selectedBusStopProvider.notifier).state = null;
      ref.read(currentTrackedBusProvider.notifier).state = null;
      ref.read(locationScreenStepProvider.notifier).state = 1;

      if (widget.currentScreen == 'track bus') {
        print("DEBUG: Setting up track bus mode");
        ref.read(currentScreenStateProvider.notifier).state =
            ScreenState.searchBus;
        ref.read(locationScreenStateProvider.notifier).state = false;
      } else if (widget.currentScreen == 'where to') {
        print("DEBUG: Setting up where to mode");
        ref.read(currentScreenStateProvider.notifier).state =
            ScreenState.locationSelection;
        ref.read(locationScreenStateProvider.notifier).state = true;
        ref.read(locationScreenStepProvider.notifier).state = 1;

        // Ensure we clear any state that might trigger dialogs
        setState(() {
          _busStops = [];
          markers.clear();
          _hasCheckedProximity = true; // Set to true to prevent checks
          _isDialogVisible = false;
        });
      }

      // Restore tracking state if needed
      final busTracking = ref.read(busTrackingProvider);
      if (busTracking != null) {
        ref.read(busTrackingProvider.notifier).restoreTracking();
      }
    });

    startLocation();
  }

  @override
  void didUpdateWidget(TrackBus oldWidget) {
    super.didUpdateWidget(oldWidget);

    print("DEBUG: didUpdateWidget called");

    final currentScreenState = ref.read(currentScreenStateProvider);
    final selectedBusStop = ref.read(selectedBusStopProvider);
    final currentBusLocation = ref.read(currentBusLocationProvider);

    if (currentScreenState == ScreenState.tracking &&
        selectedBusStop != null &&
        currentBusLocation != null) {
      print(
          "DEBUG: Widget updated in tracking mode with valid bus stop and location");
      // Use a short delay to ensure all providers are properly initialized
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted) {
          _updateDistanceAndETA(currentBusLocation, selectedBusStop);
        }
      });
    }
  }

  Future<void> _initializeBuses() async {
    final buses = await busController.getAvailableBuses();
    if (mounted) {
      setState(() {
        _allBuses = List<String>.from(buses);
        _filteredBuses = List<String>.from(_allBuses);
      });
    }
  }

  void _handleSearchChange() {
    final searchText = _searchController.text.toLowerCase();
    setState(() {
      if (searchText.isEmpty) {
        _filteredBuses = List.from(busController.getAvailableBuses());
      } else {
        _filteredBuses = _allBuses
            .where((bus) => bus.toLowerCase().contains(searchText))
            .toList();
      }
      print('Search text: $searchText');
      print('Filtered buses: $_filteredBuses');
    });
  }

  void startLocation() {
    print("DEBUG: startLocation called for mode: ${widget.currentScreen}");
    _location.changeSettings(accuracy: LocationAccuracy.high, interval: 1000);
    _location.requestPermission().then((PermissionStatus status) {
      if (status == PermissionStatus.granted) {
        // Cancel any existing subscription first
        _locationSubscription?.cancel();

        if (widget.currentScreen == 'track bus') {
          print("DEBUG: Starting track bus mode location updates");
          startTrackBusLocationUpdates();
        } else if (widget.currentScreen == 'where to') {
          print("DEBUG: Starting where to mode location updates");
          startWhereToLocationUpdates();
        }
      }
    });
  }

  void startWhereToLocationUpdates() {
    print("DEBUG: Initializing where to location updates");

    // Clear any existing state that might trigger dialogs
    setState(() {
      _busStops = [];
      markers.clear();
      _hasCheckedProximity = true; // Set to true to prevent checks
      _isDialogVisible = false;
    });

    // Simple location updates without any proximity checks
    _location.getLocation().then((LocationData locationData) {
      if (!mounted) return;
      final initialLocation =
          LatLng(locationData.latitude!, locationData.longitude!);
      setState(() {
        _currentLocation = initialLocation;
        _updateUserLocationMarker(initialLocation);
      });

      if (_mapController != null) {
        _mapController.animateCamera(
          CameraUpdate.newLatLngZoom(initialLocation, 15.0),
        );
      }
    });

    // Simple location updates without any additional checks
    _locationSubscription =
        _location.onLocationChanged.listen((LocationData locationData) {
      if (!mounted || widget.currentScreen != 'where to') return;
      final newLocation =
          LatLng(locationData.latitude!, locationData.longitude!);
      setState(() {
        _currentLocation = newLocation;
        _updateUserLocationMarker(newLocation);
      });
    });
  }

  Future<void> startTrackBusLocationUpdates() {
    print("DEBUG: Initializing track bus location updates");

    // Reset flags for track bus mode
    setState(() {
      _hasCheckedProximity = false;
      _isDialogVisible = false;
    });

    // Load bus stops only for track bus mode
    _loadBusStopsAndMarkers();

    return _location.getLocation().then((LocationData locationData) {
      if (!mounted || widget.currentScreen != 'track bus') return;
      final initialLocation =
          LatLng(locationData.latitude!, locationData.longitude!);
      setState(() {
        _currentLocation = initialLocation;
        _updateUserLocationMarker(initialLocation);
      });

      if (_mapController != null) {
        final currentScreenState = ref.read(currentScreenStateProvider);
        _mapController.animateCamera(
          CameraUpdate.newLatLngZoom(
            initialLocation,
            _getZoomLevel(currentScreenState),
          ),
        );
      }

      _locationSubscription?.cancel(); // Cancel any existing subscription
      _locationSubscription =
          _location.onLocationChanged.listen((LocationData locationData) {
        if (!mounted || widget.currentScreen != 'track bus') return;
        final newLocation =
            LatLng(locationData.latitude!, locationData.longitude!);
        setState(() {
          _currentLocation = newLocation;
          _updateUserLocationMarker(newLocation);
        });

        // Only move camera to new location if we're not in tracking mode
        final currentScreenState = ref.read(currentScreenStateProvider);
        if (currentScreenState != ScreenState.tracking &&
            _isTrackingUserLocation) {
          _mapController.animateCamera(
            CameraUpdate.newLatLngZoom(
              newLocation,
              _getZoomLevel(currentScreenState),
            ),
          );
        }
      });
    });
  }

  void _updateDistanceAndETA(LatLng busLocation, BusStop selectedBusStop) {
    print("DEBUG: _updateDistanceAndETA called");
    if (!mounted) return;

    print("DEBUG: Updating distance and ETA calculations");
    print("DEBUG: Bus Location: $busLocation");
    print("DEBUG: Bus Stop Location: ${selectedBusStop.coordinates}");

    final distance =
        _calculateDistance(busLocation, selectedBusStop.coordinates);
    print("DEBUG: Calculated distance: $distance km");

    // Calculate ETA based on current bus speed and distance
    // Assuming average speed of 30 km/h if actual speed is not available
    final averageSpeedKmH = 30.0;
    final estimatedTimeHours = distance / averageSpeedKmH;
    final estimatedTimeMinutes = (estimatedTimeHours * 60).round();

    print("DEBUG: Calculated ETA: $estimatedTimeMinutes minutes");

    // Determine bus arrival status
    String arrivalStatus = 'On Time';
    bool isOnTime = true;

    // Convert distance to meters for more precise arrival detection
    final distanceInMeters = distance * 1000;

    if (distanceInMeters < 100 || estimatedTimeMinutes <= 0) {
      arrivalStatus = 'Bus has arrived';
      isOnTime = true;
      print("DEBUG: Bus has arrived at destination");

      // Stop tracking when bus arrives
      _stopTrackingOnArrival();

      // Show arrival notification
      _showArrivalNotification();
    } else if (distanceInMeters < 500) {
      arrivalStatus = 'Arriving';
      isOnTime = true;
      print("DEBUG: Bus is arriving at destination");
    } else if (distanceInMeters < 1000) {
      arrivalStatus = 'Very Close';
      isOnTime = true;
      print("DEBUG: Bus is very close to destination");
    } else {
      arrivalStatus = 'On Time';
      isOnTime = true;
      print("DEBUG: Bus is on time");
    }

    // Update the tracking state with new values
    if (mounted) {
      // Get current persistent values
      final currentDistance = ref.read(persistentDistanceProvider);
      final currentETA = ref.read(persistentETAProvider);

      print(
          "DEBUG: Current distance: $currentDistance km, Current ETA: $currentETA minutes");
      print(
          "DEBUG: New distance: $distance km, New ETA: $estimatedTimeMinutes minutes");
      print("DEBUG: Arrival status: $arrivalStatus");

      // Update more frequently with smaller thresholds (50m for distance, 30 seconds for ETA)
      if ((currentDistance - distance).abs() > 0.05 ||
          (currentETA - estimatedTimeMinutes).abs() > 0.5) {
        print("DEBUG: Updating tracking state with new values");
        ref.read(busTrackingProvider.notifier).updateBusTracking(
              selectedBus: ref.read(selectedBusStateProvider),
              selectedBusStop: selectedBusStop,
              distance: distance,
              estimatedArrivalTime: estimatedTimeMinutes.toDouble(),
              isOnTime: isOnTime,
              arrivalStatus: arrivalStatus, // Add arrival status
            );

        // Force UI update to ensure the BottomTrackingSheet refreshes
        setState(() {});
        print(
            "DEBUG: Updated tracking state with new values and forced UI refresh");
      } else {
        print("DEBUG: Values haven't changed significantly, skipping update");
      }
    }
  }

  void _stopTrackingOnArrival() {
    print("DEBUG: Stopping tracking on arrival");

    // Clear the rotated icons cache
    _rotatedBusIcons.clear();

    // Reset tracking state
    _previousBusLocation = null;
    _currentBusBearing = 0.0;

    // Deactivate stream
    setState(() {
      _isStreamActive = false;
    });

    // Clear all tracking state comprehensively
    ref.read(busTrackingProvider.notifier).clearAllTrackingState();

    // Invalidate the stream provider to stop the stream
    ref.invalidate(busTrackingStreamProvider);

    // Don't change screen state - let user see arrival options
    // ref.read(currentScreenStateProvider.notifier).state = ScreenState.searchBus;

    print(
        "DEBUG: Tracking stopped successfully - staying on tracking screen - stream disposed");
  }

  void _showArrivalNotification() {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Bus has arrived at destination!',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 5),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        action: SnackBarAction(
          label: 'OK',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  Future<String> _getAddressFromLatLng(LatLng latLng) async {
    try {
      final placemarks =
          await placemarkFromCoordinates(latLng.latitude, latLng.longitude);
      if (placemarks.isNotEmpty) {
        final placemark = placemarks.first;
        return '${placemark.street ?? 'Unknown'}, ${placemark.locality ?? ''}, ${placemark.country ?? ''}';
      }
    } catch (e) {
      print('Error fetching address: $e');
    }
    return 'Unknown street address';
  }

  void checkProximityToBusStops() {
    print(
        "DEBUG: checkProximityToBusStops called. Current screen: ${widget.currentScreen}");

    // Multiple safety checks
    if (widget.currentScreen != 'track bus') {
      print("DEBUG: Skipping proximity check - not in track bus mode");
      return;
    }

    if (_hasCheckedProximity) {
      print("DEBUG: Skipping proximity check - already checked");
      return;
    }

    if (_isDialogVisible) {
      print("DEBUG: Skipping proximity check - dialog already visible");
      return;
    }

    if (_currentLocation == null) {
      print("DEBUG: Skipping proximity check - no current location");
      return;
    }

    if (_busStops.isEmpty) {
      print("DEBUG: Skipping proximity check - no bus stops loaded");
      return;
    }

    // Set flags before proceeding
    setState(() {
      _hasCheckedProximity = true;
      _isDialogVisible = true;
    });

    for (var busStop in _busStops) {
      final distance = _calculateDistance(
        LatLng(_currentLocation!.latitude, _currentLocation!.longitude),
        busStop.coordinates,
      );

      if (distance <= 5.0) {
        // Within 5km
        // Show confirmation dialog for the nearest bus stop
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text("Nearest Bus Stop Found"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                      "We found a bus stop within ${distance.toStringAsFixed(1)}km:"),
                  const SizedBox(height: 8),
                  Text(
                    busStop.address ?? 'Unknown location',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Available buses: ${busStop.busNumbers.join(", ")}',
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    setState(() {
                      _isDialogVisible = false;
                    });
                    Navigator.of(context).pop();
                    // Keep in selection mode for manual selection
                  },
                  child: const Text("Choose Different Stop"),
                ),
                ElevatedButton(
                  onPressed: () {
                    final BusStop selectedStop = busStop;
                    setState(() {
                      _isDialogVisible = false;
                    });
                    Navigator.of(context).pop();

                    // Auto-select the nearest bus stop
                    ref.read(selectedBusStopProvider.notifier).state =
                        selectedStop;

                    // Animate camera to the selected bus stop
                    _mapController.animateCamera(
                      CameraUpdate.newLatLng(selectedStop.coordinates),
                    );

                    // If the selected bus is available at this stop, start tracking
                    final selectedBus = ref.read(selectedBusStateProvider);
                    if (selectedStop.busNumbers.contains(selectedBus)) {
                      startBusTracking(selectedBus, selectedStop);
                    } else {
                      showBusNotAvailableDialog(selectedStop, selectedBus);
                    }
                  },
                  child: const Text("Use This Stop"),
                ),
              ],
            );
          },
        ).then((_) {
          setState(() {
            _isDialogVisible = false;
          });
        });
      } else {
        // Show dialog to select a bus stop if not within 5km
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text("No Bus Stop Nearby"),
              content: const Text(
                "You are not within 5km of any bus stop. Please select a bus stop from the map.",
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    setState(() {
                      _isDialogVisible = false;
                    });
                    Navigator.of(context).pop();
                  },
                  child: const Text("Select Bus Stop"),
                ),
              ],
            );
          },
        ).then((_) {
          setState(() {
            _isDialogVisible = false;
          });
        });
      }
    }
  }

  // Helper method to show bus not available dialog
  void showBusNotAvailableDialog(BusStop busStop, String selectedBus) {
    setState(() {
      _isDialogVisible = true;
    });

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Bus Not Available at This Stop'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Bus $selectedBus does not stop at this location.'),
              const SizedBox(height: 8),
              const Text('Available buses at this stop:'),
              const SizedBox(height: 4),
              Text(busStop.busNumbers.join(', ')),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                _busTrackingController.changeScreenState(ScreenState.searchBus);
                Navigator.pop(context);
              },
              child: const Text('Change Bus'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Different Stop'),
            ),
            ElevatedButton(
              onPressed: () async {
                final availableBus = busStop.busNumbers.first;
                print(
                    "DEBUG: Using available bus: $availableBus at stop: ${busStop.address}");

                Navigator.pop(context);

                // First update the bus selection
                _busTrackingController.selectBus(availableBus);

                // Then start tracking
                startBusTracking(availableBus, busStop);

                // Update the bus marker and camera
                onBusSelected(availableBus);

                // Ensure we're in tracking state
                setState(() {
                  ref.read(currentScreenStateProvider.notifier).state =
                      ScreenState.tracking;
                });

                // Force UI update
                setState(() {});
              },
              child: const Text('Use Available Bus'),
            ),
          ],
        );
      },
    ).then((_) {
      setState(() {
        _isDialogVisible = false;
      });
    });
  }

  void _updateUserLocationMarker(LatLng newLocation) {
    // Remove the old user location marker
    markers.removeWhere((marker) => marker.markerId.value == 'user_location');

    // Add the new user location marker
    markers.add(
      Marker(
        markerId: const MarkerId("user_location"),
        position: newLocation,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
      ),
    );

    // Update the markers on the map
    // _mapController.updateMarkers(markers);
  }

  void _recenterMap() {
    if (_currentLocation != null) {
      final currentScreenState = ref.read(currentScreenStateProvider);
      _mapController.animateCamera(
        CameraUpdate.newLatLngZoom(
          _currentLocation!,
          _getZoomLevel(currentScreenState),
        ),
      );
    }
  }

  Future<void> _loadBusStopsAndMarkers() async {
    try {
      print("DEBUG: Starting to load bus stops and markers");
      final busStopsCoordinates =
          await BusCommunicationServices.getBusStopsFromJson();
      List<BusStop> busStops = [];

      for (var busStop in busStopsCoordinates) {
        final coordinates = busStop["coordinates"];
        final latitude = coordinates["latitude"];
        final longitude = coordinates["longitude"];
        final busNumbers = List<String>.from(busStop["bus_numbers"]);
        final latLng = LatLng(latitude, longitude);
        final address = await _getAddressFromLatLng(latLng);
        final type = busStop["type"] ?? "Bus stop";
        final busRoutes = busStop["bus_routes"] != null
            ? Map<String, Map<String, String>>.from(
                busStop["bus_routes"].map((key, value) => MapEntry(
                      key,
                      Map<String, String>.from(value),
                    )))
            : null;

        busStops.add(BusStop(
          coordinates: latLng,
          busNumbers: busNumbers,
          address: address,
          type: type,
          busRoutes: busRoutes,
        ));
      }

      print("DEBUG: Created ${busStops.length} bus stop objects");

      // Create marker icon first
      await _createMarkerIcon();
      print("DEBUG: Created marker icon");

      // Update state with bus stops and markers
      setState(() {
        _busStops = busStops;
        markers.clear();

        // Add bus stop markers
        for (var busStop in busStops) {
          final markerId = MarkerId(
              'bus_stop_${busStop.coordinates.latitude}_${busStop.coordinates.longitude}');
          final marker = Marker(
            markerId: markerId,
            position: busStop.coordinates,
            icon: customMarkerIcon ?? BitmapDescriptor.defaultMarker,
            infoWindow: InfoWindow(
              title: '${busStop.type} (${busStop.busNumbers.join(", ")})',
              snippet: busStop.address,
            ),
            consumeTapEvents: true,
            onTap: () {
              print(
                  "DEBUG: Marker tapped for bus stop at ${busStop.coordinates}");
              print("DEBUG: Available buses: ${busStop.busNumbers}");
              print(
                  "DEBUG: Current selected bus: ${ref.read(selectedBusStateProvider)}");
              _handleBusStopSelection(busStop);
            },
          );
          markers.add(marker);
          print("DEBUG: Added marker for bus stop at ${busStop.coordinates}");
        }

        // Add user location marker if available
        if (_currentLocation != null) {
          _updateUserLocationMarker(_currentLocation!);
          print("DEBUG: Added user location marker");
        }
      });

      print("DEBUG: Total markers added: ${markers.length}");
    } catch (e) {
      print('Error loading bus stops: $e');
    }
  }

  void _handleBusStopSelection(BusStop busStop) {
    print("DEBUG: _handleBusStopSelection called");
    print("DEBUG: Bus stop coordinates: ${busStop.coordinates}");
    print("DEBUG: Bus stop address: ${busStop.address}");
    print("DEBUG: Available buses: ${busStop.busNumbers}");

    final selectedBus =
        ref.read(selectedBusStateProvider); // Use the new provider
    final currentScreenState = ref.read(currentScreenStateProvider);

    print("DEBUG: Current state - Selected Bus: $selectedBus");
    print("DEBUG: Current state - Screen State: $currentScreenState");

    if (currentScreenState == ScreenState.locationSelection &&
        selectedBus.isNotEmpty) {
      print("DEBUG: Conditions met for bus stop selection");

      if (!busStop.busNumbers.contains(selectedBus)) {
        print("DEBUG: Selected bus not available at this stop");
        showBusNotAvailableDialog(busStop, selectedBus);
        return;
      }

      setState(() {
        // Update the selected bus stop state
        ref.read(selectedBusStopProvider.notifier).state = busStop;
        print("DEBUG: Updated selectedBusStopProvider state");
      });

      // Move camera to the selected stop
      _mapController.animateCamera(
        CameraUpdate.newLatLng(busStop.coordinates),
      );
      print("DEBUG: Moved camera to selected bus stop");
    } else {
      print("DEBUG: Selection conditions not met");
      print(
          "DEBUG: Screen state must be locationSelection (current: $currentScreenState)");
      print("DEBUG: Selected bus must not be empty (current: '$selectedBus')");
    }
  }

  void _showDirectionSelectionDialog(BusStop busStop, String selectedBus) {
    if (_isDialogVisible) return;

    final busRoute = busStop.busRoutes![selectedBus];
    if (busRoute == null) return;

    setState(() {
      _isDialogVisible = true;
    });

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Select Bus Direction'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('This is a bus station with multiple directions.'),
              Text('Please select your destination:'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  setState(() {
                    ref.read(selectedBusStopProvider.notifier).state = busStop;
                    _mapController.animateCamera(
                      CameraUpdate.newLatLng(busStop.coordinates),
                    );
                  });
                  startBusTracking(selectedBus, busStop);
                },
                child: Text('To ${busRoute['Northbound']}'),
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  setState(() {
                    ref.read(selectedBusStopProvider.notifier).state = busStop;
                    _mapController.animateCamera(
                      CameraUpdate.newLatLng(busStop.coordinates),
                    );
                  });
                  startBusTracking(selectedBus, busStop);
                },
                child: Text('To ${busRoute['Southbound']}'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                setState(() {
                  _isDialogVisible = false;
                });
              },
              child: Text('Cancel'),
            ),
          ],
        );
      },
    ).then((_) {
      setState(() {
        _isDialogVisible = false;
      });
    });
  }

  Future<void> _createMarkerIcon() async {
    _busStopsCoordinates = await BusCommunicationServices.getBusStopsFromJson();
    markers.addAll(_busStopMarkers);
    final ByteData imageData =
        await rootBundle.load('assets/images/bus_stop.png');
    final Uint8List byteData = imageData.buffer.asUint8List();
    final ui.Codec codec = await ui.instantiateImageCodec(
      byteData,
      targetHeight: 100,
    );
    final ui.FrameInfo frameInfo = await codec.getNextFrame();
    final ByteData? resizedImageData =
        await frameInfo.image.toByteData(format: ui.ImageByteFormat.png);
    final Uint8List? resizedByteData = resizedImageData?.buffer.asUint8List();
    final BitmapDescriptor icon = BitmapDescriptor.fromBytes(resizedByteData!);
    setState(() {
      customMarkerIcon = icon;
    });
  }

  @override
  void dispose() {
    _locationSubscription?.cancel();
    _searchController.dispose();
    _mapController.dispose();
    // Clear rotated bus icons cache to prevent memory leaks
    _rotatedBusIcons.clear();
    super.dispose();
  }

  bool _hasCheckedProximity =
      false; // Add flag to track if we've checked proximity
  void onBusSelected(String busNumber) async {
    print("DEBUG: onBusSelected called with bus number: $busNumber");

    setState(() {
      // Update the selected bus state using the new provider
      ref.read(selectedBusStateProvider.notifier).state = busNumber;
      print("DEBUG: Updated selectedBusStateProvider to: $busNumber");

      // Change to location selection mode
      ref.read(currentScreenStateProvider.notifier).state =
          ScreenState.locationSelection;
      print(
          "DEBUG: Changed screen state to: ${ref.read(currentScreenStateProvider)}");

      // Reset any existing bus stop selection
      ref.read(selectedBusStopProvider.notifier).state = null;
      print("DEBUG: Reset selectedBusStopProvider");
    });

    // Load the bus icon if needed
    if (busIcon == null) {
      busIcon = await BusController(ref).loadBusIcon();
      print("DEBUG: Loaded bus icon");
    }

    setState(() {
      _isTrackingUserLocation = false;
      print("DEBUG: Disabled user location tracking");
    });

    print("DEBUG: Bus selection complete - ready for bus stop selection");
  }

  double _getZoomLevel(ScreenState screenState) {
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

  void _moveCameraToBusLocation() {
    if (_mapController != null) {
      final busLocation = ref.read(currentBusLocationProvider);
      if (busLocation != null) {
        final currentScreenState = ref.read(currentScreenStateProvider);

        _mapController.animateCamera(
          CameraUpdate.newLatLngZoom(
              busLocation, _getZoomLevel(currentScreenState)),
        );

        // Update bus marker with rotated icon
        setState(() {
          markers.removeWhere((marker) => marker.markerId == busMarkerId);

          // Use current bearing for rotation
          _createRotatedBusIcon(_currentBusBearing).then((rotatedIcon) {
            if (mounted) {
              setState(() {
                markers.add(
                  Marker(
                    markerId: busMarkerId,
                    position: busLocation,
                    icon: rotatedIcon,
                    rotation: _currentBusBearing,
                    infoWindow: const InfoWindow(
                      title: 'Bus Location',
                      snippet: 'Your bus is here',
                    ),
                  ),
                );
              });
            }
          }).catchError((error) {
            print("DEBUG: Error creating rotated bus icon: $error");
            // Fallback to default marker
            if (mounted) {
              setState(() {
                markers.add(
                  Marker(
                    markerId: busMarkerId,
                    position: busLocation,
                    icon: busIcon != null
                        ? BitmapDescriptor.fromBytes(busIcon!)
                        : BitmapDescriptor.defaultMarker,
                    infoWindow: const InfoWindow(
                      title: 'Bus Location',
                      snippet: 'Your bus is here',
                    ),
                  ),
                );
              });
            }
          });
        });
      }
    }
  }

  void _toggleBusFollowing() {
    setState(() {
      _isFollowingBus = !_isFollowingBus;
      print("DEBUG: Bus following ${_isFollowingBus ? 'enabled' : 'disabled'}");
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentScreenState = ref.watch(currentScreenStateProvider);
    final selectedBus = ref.watch(selectedBusStateProvider);
    final selectedBusStop = ref.watch(selectedBusStopProvider);
    final busTracking = ref.watch(busTrackingProvider);
    final currentStep = ref.watch(locationScreenStepProvider);
    final locationScreen = ref.watch(locationScreenStateProvider);
    final currentBusLocation = ref.watch(currentBusLocationProvider);

    // Restore stream listener
    if (selectedBusStop != null && _currentLocation != null) {
      ref.listen<AsyncValue<BusLocationData>>(
        busTrackingStreamProvider({
          'busNumber': 'C5',
          'direction': selectedBusStop.direction ?? 'Northbound',
          'busStopIndex': selectedBusStop.busStopIndex,
          'latitude': _currentLocation!.latitude,
          'longitude': _currentLocation!.longitude,
        }),
        (previous, next) {
          next.whenData((busData) {
            if (!_isStreamActive) return; // Only process if stream is active
            print(
                "DEBUG: Received bus location update:  {busData.coordinates}");

            // Update the current bus location in the provider
            ref.read(currentBusLocationProvider.notifier).state =
                busData.coordinates;

            // Calculate bearing if we have a previous location
            double bearing = 0.0;
            if (_previousBusLocation != null && busData.coordinates != null) {
              bearing = _calculateBearing(
                  _previousBusLocation!, busData.coordinates!);
              _currentBusBearing = bearing;
              print(
                  "DEBUG: Calculated bearing:  {bearing.toStringAsFixed(2)}°");
            }

            // Update previous location for next calculation
            _previousBusLocation = busData.coordinates;

            // Update marker position and camera
            setState(() {
              markers.removeWhere((marker) => marker.markerId == busMarkerId);

              // Create rotated bus marker
              _createRotatedBusIcon(bearing).then((rotatedIcon) {
                if (mounted && busData.coordinates != null) {
                  setState(() {
                    markers.add(
                      Marker(
                        markerId: busMarkerId,
                        position: busData.coordinates!,
                        icon: rotatedIcon,
                        rotation: bearing, // Add rotation to marker
                        infoWindow: const InfoWindow(
                          title: 'Bus Location',
                          snippet: 'Your bus is here',
                        ),
                      ),
                    );
                  });
                }
              }).catchError((error) {
                print("DEBUG: Error creating rotated bus icon: $error");
                // Fallback to default marker
                if (mounted && busData.coordinates != null) {
                  setState(() {
                    markers.add(
                      Marker(
                        markerId: busMarkerId,
                        position: busData.coordinates!,
                        icon: busIcon != null
                            ? BitmapDescriptor.fromBytes(busIcon!)
                            : BitmapDescriptor.defaultMarker,
                        infoWindow: const InfoWindow(
                          title: 'Bus Location',
                          snippet: 'Your bus is here',
                        ),
                      ),
                    );
                  });
                }
              });
            });

            // Always follow bus in tracking mode
            if (currentScreenState == ScreenState.tracking &&
                _mapController != null &&
                busData.coordinates != null) {
              print("DEBUG: Moving camera to follow bus");
              _mapController.animateCamera(
                CameraUpdate.newLatLngZoom(
                  busData.coordinates!,
                  _getZoomLevel(currentScreenState),
                ),
              );
            }

            // Only update distance/ETA if we're in tracking mode and have a selected bus stop
            if (selectedBusStop != null &&
                currentScreenState == ScreenState.tracking &&
                busData.coordinates != null) {
              final distance = _calculateDistance(
                  busData.coordinates!, selectedBusStop.coordinates);

              print(
                  "DEBUG: Calculated distance from bus to stop: $distance km");

              // Always update distance and ETA, regardless of distance size
              final lastUpdate = ref.read(lastUpdateTimeProvider);
              final now = DateTime.now();

              // Update more frequently (every 1 second instead of 2)
              if (lastUpdate == null ||
                  now.difference(lastUpdate).inSeconds >= 1) {
                _updateDistanceAndETA(busData.coordinates!, selectedBusStop);
                ref.read(lastUpdateTimeProvider.notifier).state = now;
                print("DEBUG: Updated distance and ETA values");
              }
            }
          });
        },
      );
    }

    return Scaffold(
      body: Stack(
        children: [
          GoogleMap(
            polylines: _routePolylines,
            onMapCreated: (GoogleMapController controller) {
              _mapController = controller;
              // If we're tracking, move to bus location
              if (currentScreenState == ScreenState.tracking) {
                _moveCameraToBusLocation();
              }
              // Otherwise use current location with appropriate zoom
              else if (_currentLocation != null) {
                controller.animateCamera(
                  CameraUpdate.newLatLngZoom(
                    _currentLocation!,
                    _getZoomLevel(currentScreenState),
                  ),
                );
              }
            },
            initialCameraPosition: CameraPosition(
              target: _currentLocation ??
                  const LatLng(-26.204671616333215, 28.04047198650632),
              zoom: _getZoomLevel(currentScreenState),
            ),
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            markers: markers,
            onCameraMove: (CameraPosition position) {
              // Update tracking flag based on user interaction
              if (position.zoom != _getZoomLevel(currentScreenState)) {
                setState(() {
                  _isTrackingUserLocation = false;
                });
              }
            },
          ),
          if (currentScreenState == ScreenState.searchBus &&
              widget.currentScreen == 'track bus') ...[
            const MenuButtonWidget(),
            BottomSearchSheet(
              filteredBuses: _filteredBuses,
              searchController: _searchController,
              onSearchChanged: (String value) {
                final searchText = value.toLowerCase();
                setState(() {
                  if (searchText.isEmpty) {
                    _filteredBuses = List.from(_allBuses);
                  } else {
                    _filteredBuses = _allBuses
                        .where((bus) => bus.toLowerCase().contains(searchText))
                        .toList();
                  }
                });
              },
              onSearchPressed: () {},
              onBusSelected: (String busNumber) {
                final selectedBusStop = ref.read(selectedBusStopProvider);
                if (selectedBusStop != null) {
                  startBusTracking(busNumber, selectedBusStop);
                }
                _busTrackingController
                    .changeScreenState(ScreenState.locationSelection);
              },
            ),
          ],
          if (widget.currentScreen == 'where to') ...[
            SearchLocation(onClose: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const HomeScreen()),
              );
              _busTrackingController.setLocationScreenStep(1);
            }),
          ],
          if (selectedBus.isEmpty && currentStep == 2) ...[
            LocationTrackingConfirmView(
              startLocation: '21 ondekers road',
              destination: 'creasta bysernodia road',
            ),
          ],
          if (currentScreenState == ScreenState.locationSelection &&
              widget.currentScreen == 'track bus') ...[
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: MediaQuery.of(context).size.height,
              child: SelectionLocationSheet(
                busStops: _busStops,
                currentLocation: _currentLocation,
                selectedBusStop: selectedBusStop,
                selectedBus: selectedBus,
                onConfirm: () {
                  if (selectedBusStop != null) {
                    final busAvailable =
                        _busTrackingController.validateBusAtStop(
                      selectedBusStop,
                      selectedBus,
                    );

                    if (!busAvailable) {
                      showDialog(
                        context: context,
                        barrierDismissible: false,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: const Text('Bus Not Available at This Stop'),
                            content: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                    'Bus $selectedBus does not stop at this location.'),
                                const SizedBox(height: 8),
                                const Text('Available buses at this stop:'),
                                const SizedBox(height: 4),
                                Text(selectedBusStop.busNumbers.join(', ')),
                              ],
                            ),
                            actions: [
                              TextButton(
                                onPressed: () {
                                  _busTrackingController
                                      .changeScreenState(ScreenState.searchBus);
                                  Navigator.pop(context);
                                },
                                child: const Text('Change Bus'),
                              ),
                              TextButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                },
                                child: const Text('Different Stop'),
                              ),
                              ElevatedButton(
                                onPressed: () {
                                  _busTrackingController.selectBus(
                                      selectedBusStop.busNumbers.first);
                                  startBusTracking(
                                    selectedBusStop.busNumbers.first,
                                    selectedBusStop,
                                  );
                                  Navigator.pop(context);
                                },
                                child: const Text('Use Available Bus'),
                              ),
                            ],
                          );
                        },
                      );
                    } else {
                      startBusTracking(selectedBus, selectedBusStop);
                    }
                  }
                },
              ),
            ),
          ],
          if (currentScreenState == ScreenState.tracking) ...[
            BottomTrackingSheet(
              filteredBuses: selectedBusStop?.busNumbers ?? [],
              searchController: _searchController,
              onSearchChanged: (String value) {},
              onSearchPressed: () {},
              previousPage: 'tracking',
              selectedBusStop: selectedBusStop,
              onChangeBus: () {
                _stopTracking(changeScreenState: false);
              },
              onStopTracking: _stopTracking,
            ),
          ],
        ],
      ),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Check conditions and schedule the callback
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final selectedBus = ref.read(selectedBusStateProvider);
      final locationScreen = ref.read(locationScreenStateProvider);
      final currentScreenState = ref.read(currentScreenStateProvider);

      // Show tracking mode dialog only when switching from home screen
      if (widget.currentScreen == 'track bus' &&
          currentScreenState == ScreenState.locationSelection &&
          selectedBus.isNotEmpty &&
          !_isDialogVisible) {
        _showBusTrackingDialog(context);
      }
    });
  }

  void _showBusTrackingDialog(BuildContext context) {
    if (_isDialogVisible) return;
    setState(() {
      _isDialogVisible = true;
    });

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Container(
            padding: const EdgeInsets.all(16),
            height: 200,
            width: 300,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Do you wish to track the bus by location?',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        ref.read(locationScreenStateProvider.notifier).state =
                            true;
                        Navigator.of(context).pop();
                        setState(() {
                          _isDialogVisible = false;
                        });
                      },
                      child: const Text('Yes'),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        ref.read(locationScreenStateProvider.notifier).state =
                            false;
                        Navigator.of(context).pop();
                        setState(() {
                          _isDialogVisible = false;
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey,
                      ),
                      child: const Text('No'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    ).then((_) {
      setState(() {
        _isDialogVisible = false;
      });
    });
  }

  /// Start tracking a bus and draw the route polyline
  void startBusTracking(String selectedBus, BusStop selectedBusStop) async {
    print("DEBUG: Starting bus tracking");
    print("DEBUG: Selected bus: $selectedBus");
    print("DEBUG: Selected bus stop: ${selectedBusStop.address}");

    // Reset bus tracking state for new session
    _previousBusLocation = null;
    _currentBusBearing = 0.0;

    // Activate stream
    setState(() {
      _isStreamActive = true;
    });

    ref.read(selectedBusStateProvider.notifier).state = selectedBus;
    ref.read(selectedBusStopProvider.notifier).state = selectedBusStop;
    _busTrackingController.changeScreenState(ScreenState.tracking);
    print("DEBUG: Starting bus tracking stream");
    // Prepare parameters for the provider
    final busStopIndex = selectedBusStop.busStopIndex;
    final direction = selectedBusStop.direction ?? 'Northbound';
    final location = _currentLocation;
    ref.read(busTrackingStreamProvider({
      'busNumber': 'C5',
      'direction': direction,
      'busStopIndex': busStopIndex,
      'latitude': location?.latitude,
      'longitude': location?.longitude,
    }));
    await _loadAndDrawRoutePolyline(selectedBus, direction);
    print(
        "DEBUG: Bus tracking initialized - waiting for real bus location data");

    // Force immediate distance/ETA update to avoid UI 'loading' state
    final currentBusLocation = ref.read(currentBusLocationProvider);
    if (currentBusLocation != null) {
      print("DEBUG: Updating initial distance and ETA");
      _updateDistanceAndETA(currentBusLocation, selectedBusStop);
    } else {
      // If no current bus location, set initial values
      print("DEBUG: No current bus location, setting initial values");
      ref.read(busTrackingProvider.notifier).updateBusTracking(
            selectedBus: selectedBus,
            selectedBusStop: selectedBusStop,
            distance: 0.0,
            estimatedArrivalTime: 0.0,
            isOnTime: true,
            arrivalStatus: 'On Time', // Add initial arrival status
          );
    }

    // Force UI update
    setState(() {});
  }

  /// Load and draw the route polyline for the given bus and direction
  Future<void> _loadAndDrawRoutePolyline(String bus, String direction) async {
    final routePath =
        await BusCommunicationServices.loadBusPath(bus, direction);
    print("DEBUG: Loaded route path: ");
    print(routePath);
    if (routePath.isNotEmpty) {
      setState(() {
        _routePolylines = {
          Polyline(
            polylineId: PolylineId('route_polyline'),
            color: Colors.blue,
            width: 5,
            points: routePath,
          ),
        };
      });
    }
  }

  double _calculateDistance(LatLng from, LatLng to) {
    // Approximate Haversine formula for kilometers
    const double earthRadiusKm = 6371.0;
    final double dLat = (to.latitude - from.latitude) * math.pi / 180.0;
    final double dLon = (to.longitude - from.longitude) * math.pi / 180.0;
    final double lat1 = from.latitude * math.pi / 180.0;
    final double lat2 = to.latitude * math.pi / 180.0;
    final double a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.sin(dLon / 2) *
            math.sin(dLon / 2) *
            math.cos(lat1) *
            math.cos(lat2);
    final double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadiusKm * c;
  }

  /// Calculate bearing between two points in degrees
  double _calculateBearing(LatLng from, LatLng to) {
    final double lat1 = from.latitude * math.pi / 180.0;
    final double lat2 = to.latitude * math.pi / 180.0;
    final double dLon = (to.longitude - from.longitude) * math.pi / 180.0;

    final double y = math.sin(dLon) * math.sin(lat2);
    final double x = math.cos(lat1) * math.sin(lat2) -
        math.sin(lat1) * math.cos(lat2) * math.cos(dLon);

    double bearing = math.atan2(y, x) * 180.0 / math.pi;

    // Normalize to 0-360 degrees
    bearing = (bearing + 360.0) % 360.0;

    return bearing;
  }

  /// Create a rotated bus icon for the given bearing angle
  Future<BitmapDescriptor> _createRotatedBusIcon(double bearing) async {
    // Round bearing to nearest 2 degrees for smoother rotation (reduced from 5)
    final double roundedBearing = (bearing / 2.0).round() * 2.0;

    // Check if we already have this rotated icon cached
    if (_rotatedBusIcons.containsKey(roundedBearing)) {
      return _rotatedBusIcons[roundedBearing]!;
    }

    if (busIcon == null) {
      // If no bus icon is loaded, return default marker
      return BitmapDescriptor.defaultMarker;
    }

    try {
      // Load the original bus icon
      final ui.Codec codec = await ui.instantiateImageCodec(
        busIcon!,
        targetHeight: 110, // Increased from 23 to 50
      );
      final ui.FrameInfo frameInfo = await codec.getNextFrame();
      final ui.Image originalImage = frameInfo.image;

      // Calculate the size needed for the rotated image
      // Use a larger canvas to accommodate the rotated image without clipping
      final double originalWidth = originalImage.width.toDouble();
      final double originalHeight = originalImage.height.toDouble();

      // Calculate the maximum dimension needed for rotation
      final double maxDimension = math.sqrt(
          originalWidth * originalWidth + originalHeight * originalHeight);
      final double canvasSize =
          maxDimension + 20; // Increased padding for better quality

      // Create a canvas with sufficient size to hold the rotated image
      final ui.PictureRecorder recorder = ui.PictureRecorder();
      final ui.Canvas canvas = ui.Canvas(recorder);

      // Calculate the center of the canvas
      final double canvasCenterX = canvasSize / 2.0;
      final double canvasCenterY = canvasSize / 2.0;

      // Calculate the offset to center the original image on the canvas
      final double imageOffsetX = (canvasSize - originalWidth) / 2.0;
      final double imageOffsetY = (canvasSize - originalHeight) / 2.0;

      // Move to canvas center, rotate, then move back
      canvas.translate(canvasCenterX, canvasCenterY);
      canvas.rotate(roundedBearing * math.pi / 180.0);
      canvas.translate(-canvasCenterX, -canvasCenterY);

      // Draw the original image centered on the canvas
      canvas.drawImage(
          originalImage, ui.Offset(imageOffsetX, imageOffsetY), ui.Paint());

      // Convert to image
      final ui.Picture picture = recorder.endRecording();
      final ui.Image rotatedImage = await picture.toImage(
        canvasSize.toInt(),
        canvasSize.toInt(),
      );

      // Convert to bytes
      final ByteData? imageData = await rotatedImage.toByteData(
        format: ui.ImageByteFormat.png,
      );

      if (imageData != null) {
        final Uint8List bytes = imageData.buffer.asUint8List();
        final BitmapDescriptor rotatedIcon = BitmapDescriptor.fromBytes(bytes);

        // Cache the rotated icon
        _rotatedBusIcons[roundedBearing] = rotatedIcon;

        return rotatedIcon;
      }
    } catch (e) {
      print('Error creating rotated bus icon: $e');
    }

    // Fallback to default marker if rotation fails
    return BitmapDescriptor.defaultMarker;
  }

  /// Debug method to check current tracking state
  void _debugTrackingState() {
    final busTracking = ref.read(busTrackingProvider);
    final selectedBus = ref.read(selectedBusStateProvider);
    final selectedBusStop = ref.read(selectedBusStopProvider);
    final currentBusLocation = ref.read(currentBusLocationProvider);

    print("DEBUG: === Tracking State Debug ===");
    print("DEBUG: Selected Bus: $selectedBus");
    print("DEBUG: Selected Bus Stop: ${selectedBusStop?.address}");
    print("DEBUG: Current Bus Location: $currentBusLocation");
    print(
        "DEBUG: Bus Tracking State: ${busTracking?.distance} km, ${busTracking?.estimatedArrivalTime} min");
    print(
        "DEBUG: Persistent Distance: ${ref.read(persistentDistanceProvider)} km");
    print("DEBUG: Persistent ETA: ${ref.read(persistentETAProvider)} min");
    print("DEBUG: ===========================");
  }

  /// Force refresh the distance and ETA display
  void _forceRefreshDistanceAndETA() {
    final selectedBusStop = ref.read(selectedBusStopProvider);
    final currentBusLocation = ref.read(currentBusLocationProvider);

    if (selectedBusStop != null && currentBusLocation != null) {
      print("DEBUG: Force refreshing distance and ETA");
      _updateDistanceAndETA(currentBusLocation, selectedBusStop);
    }
  }

  /// Clear the rotated bus icons cache (useful for debugging or when changing icon size)
  void _clearRotatedIconsCache() {
    _rotatedBusIcons.clear();
    print("DEBUG: Cleared rotated bus icons cache");
  }

  Future<void> _loadBusIcon() async {
    print("DEBUG: Loading bus icon");

    // Clear the rotated icons cache when loading a new icon
    _rotatedBusIcons.clear();

    try {
      final ByteData imageData = await rootBundle.load('assets/busIcon.png');
      final Uint8List byteData = imageData.buffer.asUint8List();
      final ui.Codec codec = await ui.instantiateImageCodec(
        byteData,
        targetHeight: 50, // Increased from 23 to 50
      );
      final ui.FrameInfo frameInfo = await codec.getNextFrame();
      final ByteData? resizedImageData =
          await frameInfo.image.toByteData(format: ui.ImageByteFormat.png);
      final Uint8List? resizedByteData = resizedImageData?.buffer.asUint8List();

      setState(() {
        busIcon = resizedByteData;
        print("DEBUG: Bus icon loaded successfully");
      });
    } catch (e) {
      print("DEBUG: Error loading bus icon: $e");
      // Try loading from the alternative path if the first one fails
      try {
        final ByteData imageData =
            await rootBundle.load('assets/images/busIcon.png');
        final Uint8List byteData = imageData.buffer.asUint8List();
        final ui.Codec codec = await ui.instantiateImageCodec(
          byteData,
          targetHeight: 50, // Increased from 23 to 50
        );
        final ui.FrameInfo frameInfo = await codec.getNextFrame();
        final ByteData? resizedImageData =
            await frameInfo.image.toByteData(format: ui.ImageByteFormat.png);
        final Uint8List? resizedByteData =
            resizedImageData?.buffer.asUint8List();

        setState(() {
          busIcon = resizedByteData;
          print("DEBUG: Bus icon loaded successfully from alternative path");
        });
      } catch (e2) {
        print("DEBUG: Error loading bus icon from both paths: $e2");
      }
    }
  }

  void _stopTracking({bool changeScreenState = true}) {
    print("DEBUG: Stopping tracking manually");

    // Clear the rotated icons cache
    _rotatedBusIcons.clear();

    // Reset tracking state
    _previousBusLocation = null;
    _currentBusBearing = 0.0;

    // Deactivate stream
    setState(() {
      _isStreamActive = false;
    });

    // Clear the current tracked bus
    ref.read(currentTrackedBusProvider.notifier).state = null;

    // Clear the bus tracking state
    ref.read(busTrackingProvider.notifier).clearAllTrackingState();

    // Invalidate the stream provider to stop the stream
    ref.invalidate(busTrackingStreamProvider);

    // Only change screen state if requested
    if (changeScreenState) {
      ref.read(currentScreenStateProvider.notifier).state =
          ScreenState.searchBus;
    }

    print("DEBUG: Manual tracking stop completed - stream disposed");
  }
}

class SomeConst {
  showLoaderDialog(BuildContext context, double width, height, String text) {
    showDialog(
      barrierDismissible: false,
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15.0)),
            content: Container(
              height: height * .1,
              width: width * .95,
              alignment: Alignment.center,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  const CircularProgressIndicator(),
                  Text(
                    text,
                  )
                ],
              ),
            ));
      },
    );
  }
}

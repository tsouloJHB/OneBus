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
import 'package:onebus/services/bus_route_service.dart';
import 'package:onebus/services/full_route_service.dart';
import 'package:onebus/models/full_route.dart';
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
  bool _isLoadingDialogVisible = false;
  ProviderSubscription<AsyncValue<BusLocationData>>? _busStreamSubscription;

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
      }
    });
  }

  Future<void> _initializeBuses() async {
    try {
      // Use the controller to get buses (which now uses the new service)
      final buses = await busController.getAvailableBuses();

      if (mounted) {
        setState(() {
          _allBuses = List<String>.from(buses);
          _filteredBuses = List<String>.from(_allBuses);
        });
        print('[DEBUG] Initialized ${_allBuses.length} buses from controller');
      }
    } catch (e) {
      print('[ERROR] Failed to initialize buses: $e');
      // Fallback to empty list
      if (mounted) {
        setState(() {
          _allBuses = [];
          _filteredBuses = [];
        });
      }
    }
  }

  void _handleSearchChange() {
    final searchText = _searchController.text.toLowerCase();
    setState(() {
      if (searchText.isEmpty) {
        _filteredBuses = List<String>.from(_allBuses);
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

    // Don't load bus stops here - wait until a bus is selected
    // _loadBusStopsAndMarkers(); // Removed - will be called in onBusSelected()

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

    _hideLoadingDialog();

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

  void _showNoServiceDialog(String errorMessage) {
    if (!mounted || _isDialogVisible) return;
    
    setState(() {
      _isDialogVisible = true;
    });
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          icon: Icon(Icons.error_outline, color: Colors.red, size: 48),
          title: const Text('Service Unavailable'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                errorMessage,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info, color: Colors.orange.shade700, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Please check your internet connection or try again later.',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.orange.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
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
                // Go back to bus selection
                ref.read(currentScreenStateProvider.notifier).state = ScreenState.searchBus;
                _stopTracking(changeScreenState: false);
              },
              child: const Text('Go Back'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                setState(() {
                  _isDialogVisible = false;
                });
                // Try again by resetting the stream
                _isStreamActive = true;
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
              ),
              child: const Text('Try Again'),
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

  void _showLoadingDialog() {
    if (!mounted || _isLoadingDialogVisible) return;
    _isLoadingDialogVisible = true;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        content: Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 20),
              const Text(
                'Connecting to bus...',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 10),
              Text(
                'Please wait while we locate your bus',
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    ).then((_) {
      _isLoadingDialogVisible = false;
    });
  }

  void _hideLoadingDialog() {
    if (_isLoadingDialogVisible) {
      Navigator.of(context, rootNavigator: true).maybePop();
      _isLoadingDialogVisible = false;
    }
  }

  void _showBusNotAvailableDialog() {
    if (!mounted || _isDialogVisible) return;
    
    setState(() {
      _isDialogVisible = true;
    });
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          icon: Icon(Icons.directions_bus_outlined, color: Colors.orange, size: 48),
          title: const Text('Bus Not Available'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'The selected bus is currently not available or not in service.',
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info, color: Colors.blue.shade700, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'This could mean the bus is not currently running or the tracking system is offline.',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.blue.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
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
                // Go back to bus selection
                ref.read(currentScreenStateProvider.notifier).state = ScreenState.searchBus;
                _stopTracking(changeScreenState: false);
              },
              child: const Text('Select Different Bus'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                setState(() {
                  _isDialogVisible = false;
                });
                // Try again by restarting tracking
                final selectedBus = ref.read(selectedBusStateProvider);
                final selectedBusStop = ref.read(selectedBusStopProvider);
                if (selectedBus.isNotEmpty && selectedBusStop != null) {
                  startBusTracking(selectedBus, selectedBusStop);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
              ),
              child: const Text('Try Again'),
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
                    'Stop address: ${busStop.address ?? ''}',
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

                    // Start tracking the selected bus at this stop
                    final selectedBus = ref.read(selectedBusStateProvider);
                    startBusTracking(selectedBus, selectedStop);
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

      // Get the selected bus and company
      final selectedBus = ref.read(selectedBusStateProvider);
      final selectedCompany = busController.getBusCompany();

      List<BusStop> busStops = [];

      // Try to load from API if we have a selected bus and company
      if (selectedBus.isNotEmpty && selectedCompany.isNotEmpty) {
        print(
            "DEBUG: Loading bus stops from API for bus: $selectedBus, company: $selectedCompany");
        print("DEBUG: Making API call to: http://localhost:8080/api/routes/$selectedBus/$selectedCompany");

        try {
          final busRouteResponse = await BusRouteService.getBusRoutesAndStops(
              selectedBus, selectedCompany);

          if (busRouteResponse != null && busRouteResponse.routes.isNotEmpty) {
            print("DEBUG: API call successful! Received ${busRouteResponse.routes.length} routes");
            
            // Get all stops from all routes
            for (var route in busRouteResponse.routes) {
              if (route.active && route.stops.isNotEmpty) {
                print("DEBUG: Processing route ${route.routeName} with ${route.stops.length} stops");
                final routeStops =
                    BusRouteService.convertApiStopsToBusStops(route.stops);
                
                busStops.addAll(routeStops);
              }
            }

            if (busStops.isNotEmpty) {
              print(
                  "DEBUG: Successfully loaded ${busStops.length} bus stops from API");
            } else {
              print("DEBUG: API returned no stops, falling back to JSON");
              await _loadBusStopsFromJson();
              return;
            }
          } else {
            print("DEBUG: API returned no routes, falling back to JSON");
            await _loadBusStopsFromJson();
            return;
          }
        } catch (e) {
          print("DEBUG: API call failed with error: $e");
          print("DEBUG: Falling back to local JSON file");
          await _loadBusStopsFromJson();
          return;
        }
      } else {
        print("DEBUG: No bus/company selected (bus: '$selectedBus', company: '$selectedCompany'), loading from JSON");
        await _loadBusStopsFromJson();
        return;
      }

      print("DEBUG: Created ${busStops.length} bus stop objects from API");

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
              title: '${busStop.type} (${busStop.direction ?? ""})',
              snippet: busStop.address,
            ),
            consumeTapEvents: true,
            onTap: () {
              print(
                  "DEBUG: Marker tapped for bus stop at ${busStop.coordinates}");
              print("DEBUG: Available buses: ${busStop.direction}");
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

  /// Load bus stops from JSON file (fallback method)
  Future<void> _loadBusStopsFromJson() async {
    try {
      print("DEBUG: Loading bus stops from JSON file");
      final busStopsCoordinates =
          await BusCommunicationServices.getBusStopsFromJson();
      List<BusStop> busStops = [];

      for (var busStop in busStopsCoordinates) {
        final coordinates = busStop["coordinates"];
        final latitude = coordinates["latitude"];
        final longitude = coordinates["longitude"];
        final latLng = LatLng(latitude, longitude);
        final address = await _getAddressFromLatLng(latLng);
        final type = busStop["type"] ?? "Bus stop";

        busStops.add(BusStop(
          coordinates: latLng,
          address: address,
          type: type,
        ));
      }

      print("DEBUG: Created ${busStops.length} bus stop objects from JSON");

      // Create marker icon first
      await _createMarkerIcon();
      print("DEBUG: Created marker icon");

      // Update state with bus stops and markers
      setState(() {
        _busStops = busStops;
        markers.clear();

        // Add bus stop markers using centralized helper
        for (var busStop in busStops) {
          final marker = _createStopMarker(busStop);
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
      print('Error loading bus stops from JSON: $e');
    }
  }

  void _handleBusStopSelection(BusStop busStop) {
    print("DEBUG: _handleBusStopSelection called");
    print("DEBUG: Bus stop coordinates: ${busStop.coordinates}");
    print("DEBUG: Bus stop address: ${busStop.address}");

    final selectedBus = ref.read(selectedBusStateProvider);
    final currentScreenState = ref.read(currentScreenStateProvider);

    print("DEBUG: Current state - Selected Bus: $selectedBus");
    print("DEBUG: Current state - Screen State: $currentScreenState");
    print("DEBUG: Bus stop direction: '${busStop.direction}'");
    print("DEBUG: Bus stop busStopIndices: ${busStop.busStopIndices}");

    // Allow bus stop selection in both locationSelection and tracking states
    if ((currentScreenState == ScreenState.locationSelection || 
         currentScreenState == ScreenState.tracking) &&
        selectedBus.isNotEmpty) {
      print("DEBUG: Conditions met for bus stop selection");

      // If the stop is bidirectional, prompt for direction
      if (busStop.direction?.toLowerCase() == 'bidirectional') {
        print("DEBUG: Bus stop is bidirectional, showing direction selection dialog");
        if (busStop.busStopIndices != null) {
          _showDirectionSelectionDialog(busStop, selectedBus);
        } else {
          // Fallback: show simple direction selection without indices
          _showSimpleDirectionSelectionDialog(busStop, selectedBus);
        }
        return;
      }

      setState(() {
        ref.read(selectedBusStopProvider.notifier).state = busStop;
        print("DEBUG: Updated selectedBusStopProvider state");
      });

      _mapController.animateCamera(
        CameraUpdate.newLatLng(busStop.coordinates),
      );
      print("DEBUG: Moved camera to selected bus stop");
      
      // If we're already in tracking mode, restart tracking with the new stop
      if (currentScreenState == ScreenState.tracking) {
        print("DEBUG: Already in tracking mode, restarting tracking with new stop");
        startBusTracking(selectedBus, busStop);
      }
    } else {
      print("DEBUG: Selection conditions not met");
      print(
          "DEBUG: Screen state must be locationSelection or tracking (current: $currentScreenState)");
      print("DEBUG: Selected bus must not be empty (current: '$selectedBus')");
    }
  }

  void _showSimpleDirectionSelectionDialog(BusStop busStop, String selectedBus) {
    if (_isDialogVisible) return;
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
              Text('This stop serves buses in both directions. Please select your direction:'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  setState(() {
                    // Create a new BusStop with Northbound direction
                    final updatedStop = BusStop(
                      coordinates: busStop.coordinates,
                      address: busStop.address,
                      type: busStop.type,
                      direction: 'Northbound',
                      busStopIndex: busStop.busStopIndex,
                      busStopIndices: busStop.busStopIndices,
                    );
                    ref.read(selectedBusStopProvider.notifier).state = updatedStop;
                    _mapController.animateCamera(
                      CameraUpdate.newLatLng(busStop.coordinates),
                    );
                    startBusTracking(selectedBus, updatedStop);
                  });
                },
                child: const Text('Northbound'),
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  setState(() {
                    // Create a new BusStop with Southbound direction
                    final updatedStop = BusStop(
                      coordinates: busStop.coordinates,
                      address: busStop.address,
                      type: busStop.type,
                      direction: 'Southbound',
                      busStopIndex: busStop.busStopIndex,
                      busStopIndices: busStop.busStopIndices,
                    );
                    ref.read(selectedBusStopProvider.notifier).state = updatedStop;
                    _mapController.animateCamera(
                      CameraUpdate.newLatLng(busStop.coordinates),
                    );
                    startBusTracking(selectedBus, updatedStop);
                  });
                },
                child: const Text('Southbound'),
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
              child: const Text('Cancel'),
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

  void _showDirectionSelectionDialog(BusStop busStop, String selectedBus) {
    if (_isDialogVisible) return;
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
              Text('This stop is bidirectional. Please select your direction:'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  setState(() {
                    // Create a new BusStop with direction and busStopIndex set for Northbound
                    final updatedStop = BusStop(
                      coordinates: busStop.coordinates,
                      address: busStop.address,
                      type: busStop.type,
                      direction: 'Northbound',
                      busStopIndex: busStop.busStopIndices?['northbound'],
                      busStopIndices: busStop.busStopIndices,
                    );
                    ref.read(selectedBusStopProvider.notifier).state =
                        updatedStop;
                    _mapController.animateCamera(
                      CameraUpdate.newLatLng(busStop.coordinates),
                    );
                    startBusTracking(selectedBus, updatedStop);
                  });
                },
                child: const Text('Northbound'),
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  setState(() {
                    // Create a new BusStop with direction and busStopIndex set for Southbound
                    final updatedStop = BusStop(
                      coordinates: busStop.coordinates,
                      address: busStop.address,
                      type: busStop.type,
                      direction: 'Southbound',
                      busStopIndex: busStop.busStopIndices?['southbound'],
                      busStopIndices: busStop.busStopIndices,
                    );
                    ref.read(selectedBusStopProvider.notifier).state =
                        updatedStop;
                    _mapController.animateCamera(
                      CameraUpdate.newLatLng(busStop.coordinates),
                    );
                    startBusTracking(selectedBus, updatedStop);
                  });
                },
                child: const Text('Southbound'),
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
              child: const Text('Cancel'),
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

  // Enhanced method to create stop markers with direction-based colors and highlighting
  Marker _createStopMarker(BusStop busStop, {bool isHighlighted = false}) {
    final direction = busStop.direction ?? 'unknown';
    final index = _getDisplayIndex(busStop);
    
    // Determine marker color based on highlight status and direction
    BitmapDescriptor markerIcon;
    if (isHighlighted) {
      markerIcon = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueYellow);
    } else {
      switch (direction.toLowerCase()) {
        case 'northbound':
          markerIcon = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue);
          break;
        case 'southbound':
          markerIcon = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed);
          break;
        case 'bidirectional':
          markerIcon = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen);
          break;
        default:
          markerIcon = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange);
      }
    }

    return Marker(
      markerId: MarkerId('stop_${busStop.coordinates.latitude}_${busStop.coordinates.longitude}'),
      position: busStop.coordinates,
      icon: markerIcon,
      infoWindow: InfoWindow(
        title: '${isHighlighted ? '🚌 ' : ''}Stop $index',
        snippet: '${busStop.address} • $direction',
        onTap: () => _handleBusStopSelection(busStop),
      ),
      onTap: () => _handleBusStopSelection(busStop),
    );
  }

  // Get display index for bus stop
  String _getDisplayIndex(BusStop busStop) {
    if (busStop.busStopIndex != null) {
      return busStop.busStopIndex.toString();
    }
    if (busStop.busStopIndices != null) {
      final indices = busStop.busStopIndices!;
      if (indices.containsKey('northbound') && indices.containsKey('southbound')) {
        return '${indices['northbound']}/${indices['southbound']}';
      }
      return indices.values.first.toString();
    }
    return '?';
  }

  // Enhanced method to filter and display stops based on current route
  void _filterStopsByRoute(String? routeId) {
    if (routeId == null) {
      _updateAllMarkers();
      return;
    }

    setState(() {
      markers.clear();
      
      // Filter bus stops for the current route
      final routeStops = _busStops.where((stop) {
        // Check if stop is associated with this route
        return stop.busStopIndices?.containsKey(routeId) == true ||
               stop.type?.toLowerCase().contains(routeId.toLowerCase()) == true;
      }).toList();
      
      // Add filtered stop markers
      for (var busStop in routeStops) {
        final marker = _createStopMarker(busStop);
        markers.add(marker);
      }
      
      // Add user location marker if available
      if (_currentLocation != null) {
        _updateUserLocationMarker(_currentLocation!);
      }
    });
    
    print("DEBUG: Filtered ${markers.length - 1} stops for route: $routeId");
  }

  // Method to highlight the nearest stops to current bus location
  void _highlightNearestStops(LatLng busLocation) {
    if (_busStops.isEmpty) return;

    // Find stops within 500 meters of the bus
    final nearbyStops = _busStops.where((stop) {
      final distance = _calculateDistance(busLocation, stop.coordinates);
      return distance <= 0.5; // 500 meters
    }).toList();

    // Sort by distance
    nearbyStops.sort((a, b) {
      final distanceA = _calculateDistance(busLocation, a.coordinates);
      final distanceB = _calculateDistance(busLocation, b.coordinates);
      return distanceA.compareTo(distanceB);
    });

    // Update markers with highlighted nearby stops
    setState(() {
      markers.removeWhere((marker) => marker.markerId.value.startsWith('stop_'));
      
      for (var busStop in _busStops) {
        final isNearby = nearbyStops.contains(busStop);
        final marker = _createStopMarker(busStop, isHighlighted: isNearby);
        markers.add(marker);
      }
    });

    print("DEBUG: Highlighted ${nearbyStops.length} nearby stops");
  }

  // Enhanced method to clear and update all markers
  void _updateAllMarkers() {
    setState(() {
      markers.clear();
      
      // Add all bus stop markers
      for (var busStop in _busStops) {
        final marker = _createStopMarker(busStop);
        markers.add(marker);
      }
      
      // Add user location marker if available
      if (_currentLocation != null) {
        _updateUserLocationMarker(_currentLocation!);
      }
      
      // Add bus location markers if tracking
      // Add any other markers as needed
    });
    
    print("DEBUG: Updated all markers - total: ${markers.length}");
  }

  // Show detailed information about the selected bus stop
  void _showBusStopDetails(BusStop busStop) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.4,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[400],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              
              // Stop header
              Row(
                children: [
                  Icon(
                    Icons.bus_alert,
                    color: _getStopColorByDirection(busStop.direction ?? ''),
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      busStop.type ?? 'Bus Stop',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // Address
              Text(
                busStop.address ?? 'Unknown address',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 20),
              
              // Stop indices information
              if (busStop.busStopIndices != null || busStop.busStopIndex != null)
                _buildStopIndicesInfo(busStop),
              
              // Direction information
              if (busStop.direction != null) ...[
                const SizedBox(height: 16),
                Row(
                  children: [
                    Icon(
                      _getDirectionIcon(busStop.direction!),
                      color: _getStopColorByDirection(busStop.direction!),
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Direction: ${busStop.direction}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
              
              const Spacer(),
              
              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _navigateToStop(busStop);
                      },
                      icon: const Icon(Icons.navigation),
                      label: const Text('Navigate'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _shareStopLocation(busStop);
                      },
                      icon: const Icon(Icons.share),
                      label: const Text('Share'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Build stop indices information widget
  Widget _buildStopIndicesInfo(BusStop busStop) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Stop Information',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          if (busStop.busStopIndices != null) ...[
            if (busStop.busStopIndices!['northbound'] != null)
              _buildIndexRow('Northbound', busStop.busStopIndices!['northbound']!, Colors.blue),
            if (busStop.busStopIndices!['southbound'] != null)
              _buildIndexRow('Southbound', busStop.busStopIndices!['southbound']!, Colors.red),
          ] else if (busStop.busStopIndex != null) ...[
            _buildIndexRow('Stop Index', busStop.busStopIndex!, Colors.orange),
          ],
        ],
      ),
    );
  }

  // Build individual index row
  Widget _buildIndexRow(String label, int index, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '$label: $index',
            style: const TextStyle(fontSize: 14),
          ),
        ],
      ),
    );
  }

  // Get color based on direction
  Color _getStopColorByDirection(String direction) {
    switch (direction.toLowerCase()) {
      case 'northbound':
        return Colors.blue;
      case 'southbound':
        return Colors.red;
      case 'bidirectional':
        return Colors.green;
      default:
        return Colors.orange;
    }
  }

  // Get icon based on direction
  IconData _getDirectionIcon(String direction) {
    switch (direction.toLowerCase()) {
      case 'northbound':
        return Icons.north;
      case 'southbound':
        return Icons.south;
      case 'eastbound':
        return Icons.east;
      case 'westbound':
        return Icons.west;
      case 'bidirectional':
        return Icons.swap_vert;
      default:
        return Icons.location_on;
    }
  }

  // Navigate to the selected stop
  void _navigateToStop(BusStop busStop) {
    // Implement navigation logic here
    // This could integrate with Google Maps, Apple Maps, or in-app navigation
    print("DEBUG: Navigate to ${busStop.address} at ${busStop.coordinates}");
    
    // Example: Open in Google Maps
    // final url = 'https://www.google.com/maps/dir/?api=1&destination=${busStop.coordinates.latitude},${busStop.coordinates.longitude}';
    // launchUrl(Uri.parse(url));
  }

  // Share stop location
  void _shareStopLocation(BusStop busStop) {
    // Implement sharing logic here
    final text = 'Bus Stop: ${busStop.address}\nLocation: ${busStop.coordinates.latitude}, ${busStop.coordinates.longitude}';
    print("DEBUG: Share stop location: $text");
    
    // Example using share_plus package:
    // Share.share(text);
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
    _busStreamSubscription?.close();
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

    // Set default company if not already set (for C5 bus, it's Rea Vaya)
    if (busController.getBusCompany().isEmpty) {
      busController.setBusComapny('Rea Vaya');
      print("DEBUG: Set default bus company to 'Rea Vaya'");
    }

    // Show direction selection dialog
    _showRouteDirectionSelectionDialog(busNumber, busController.getBusCompany());
  }

  Future<void> _showRouteDirectionSelectionDialog(String busNumber, String companyName) async {
    try {
      // Show loading dialog while fetching directions
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return const AlertDialog(
            content: Row(
              children: [
                CircularProgressIndicator(),
                SizedBox(width: 20),
                Text('Loading route directions...'),
              ],
            ),
          );
        },
      );

      // Fetch route directions from the server
      final routeData = await BusRouteService.getRouteDirections(busNumber, companyName);
      
      if (!mounted) return;
      
      // Close loading dialog
      Navigator.of(context).pop();

      if (routeData == null || routeData['routes'] == null) {
        // Fallback to continue without direction selection
        await _continueWithBusSelection(busNumber, null);
        return;
      }

      final routes = routeData['routes'] as List<dynamic>;
      final directions = routeData['directions'] as List<dynamic>? ?? [];

      if (routes.isEmpty) {
        // Fallback to continue without direction selection
        await _continueWithBusSelection(busNumber, null);
        return;
      }

      // Show direction selection dialog
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: true,
        builder: (BuildContext context) {
          return Dialog(
            backgroundColor: Colors.transparent,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.red.shade50,
                    Colors.white,
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    spreadRadius: 3,
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header with bus icon and title
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.red.withOpacity(0.3),
                                spreadRadius: 2,
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.directions_bus,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Select Direction',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey[800],
                                ),
                              ),
                              Text(
                                'Bus $busNumber',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.red,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    // Direction options
                    ...directions.map<Widget>((direction) {
                      final route = routes.firstWhere(
                        (r) => r['direction'] == direction,
                        orElse: () => null,
                      );

                      final routeName = route?['routeName'] ?? 'Route';
                      final description = route?['description'] ?? 'No description available';
                      final startPoint = route?['startPoint'] ?? '';
                      final endPoint = route?['endPoint'] ?? '';

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: InkWell(
                          onTap: () {
                            Navigator.of(context).pop();
                            _continueWithBusSelection(busNumber, direction);
                          },
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: Colors.grey.shade200,
                                width: 1,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.withOpacity(0.1),
                                  spreadRadius: 1,
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                // Direction icon
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: direction.toLowerCase().contains('north')
                                        ? Colors.blue.shade50
                                        : Colors.orange.shade50,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(
                                    direction.toLowerCase().contains('north')
                                        ? Icons.north
                                        : Icons.south,
                                    color: direction.toLowerCase().contains('north')
                                        ? Colors.blue
                                        : Colors.orange,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                // Route info
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '$direction - $routeName',
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black87,
                                        ),
                                      ),
                                      if (startPoint.isNotEmpty && endPoint.isNotEmpty) ...[
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.trip_origin,
                                              size: 12,
                                              color: Colors.grey[600],
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              startPoint,
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey[600],
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 2),
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.location_on,
                                              size: 12,
                                              color: Colors.grey[600],
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              endPoint,
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey[600],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                      if (description != 'No description available') ...[
                                        const SizedBox(height: 4),
                                        Text(
                                          description,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey[500],
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                // Arrow icon
                                Icon(
                                  Icons.arrow_forward_ios,
                                  size: 16,
                                  color: Colors.grey[400],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                    const SizedBox(height: 16),
                    // Cancel button
                    SizedBox(
                      width: double.infinity,
                      child: TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(color: Colors.grey.shade300),
                          ),
                        ),
                        child: Text(
                          'Cancel',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    } catch (e) {
      if (!mounted) return;
      
      // Close loading dialog if open
      Navigator.of(context).pop();
      
      print('[ERROR] Failed to load route directions: $e');
      
      // Show error and continue without direction selection
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to load route directions. Continuing with default route.'),
        ),
      );
      
      await _continueWithBusSelection(busNumber, null);
    }
  }

  Future<void> _continueWithBusSelection(String busNumber, String? selectedDirection) async {
    print("DEBUG: Continuing with bus selection - Bus: $busNumber, Direction: $selectedDirection");

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

    // Reload bus stops for the selected bus - this will try API first, then fallback to JSON
    // TODO: In the future, we could filter stops by selected direction
    print("DEBUG: Fetching bus stops from server for bus: $busNumber, company: ${busController.getBusCompany()}, direction: $selectedDirection");
    await _loadBusStopsAndMarkers();

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
          // Handle errors
          if (next.hasError) {
            final error = next.error;
            final stackTrace = next.stackTrace;
            print('[ERROR] Bus tracking stream error: $error');
            if (!_isStreamActive) return;
            
            String errorMessage = 'Unable to connect to bus tracking service';
            if (error.toString().contains('timeout')) {
              errorMessage = 'Connection timeout. The server may be offline. Please try again later.';
            } else if (error.toString().contains('internet') || error.toString().contains('Connection refused')) {
              errorMessage = 'No internet connection. Please check your connection and try again.';
            }
            
            _showNoServiceDialog(errorMessage);
            setState(() {
              _isStreamActive = false;
            });
            return;
          }
          
          // Handle loading
          if (next.isLoading) {
            print('[DEBUG] Bus tracking stream loading...');
            return;
          }
          
          // Handle data
          next.whenData((busData) {
            if (!_isStreamActive) return; // Only process if stream is active
            _hideLoadingDialog();
            print(
                "DEBUG: Received bus location update: ${busData.coordinates}");

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
              print("DEBUG: Moving camera to follow bus at ${busData.coordinates}");
              _mapController.animateCamera(
                CameraUpdate.newLatLngZoom(
                  busData.coordinates!,
                  _getZoomLevel(currentScreenState),
                ),
              );
            } else {
              print("DEBUG: Not moving camera - screenState: $currentScreenState, controller: ${_mapController != null}, coords: ${busData.coordinates}");
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
              onBusSelected: onBusSelected,
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
                    startBusTracking(selectedBus, selectedBusStop);
                  }
                },
              ),
            ),
          ],
          // Only show tracking sheet when we have an active stream and a real bus location
          if (currentScreenState == ScreenState.tracking &&
              _isStreamActive &&
              currentBusLocation != null) ...[
            BottomTrackingSheet(
              filteredBuses: [],
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

  void _processBusLocationUpdate(BusLocationData busData, BusStop selectedBusStop) {
    if (!mounted || !_isStreamActive) return;
    
    print('[DEBUG] Processing bus location update: ${busData.coordinates}');
    print('[DEBUG] Bus speed: ${busData.speed} km/h');
    print('[DEBUG] Bus direction: ${busData.direction}');
    
    // Update the current bus location in the provider
    ref.read(currentBusLocationProvider.notifier).state = busData.coordinates;
    
    // Calculate bearing if we have a previous location
    double bearing = 0.0;
    if (_previousBusLocation != null) {
      bearing = _calculateBearing(_previousBusLocation!, busData.coordinates);
      _currentBusBearing = bearing;
      print('[DEBUG] Calculated bearing: ${bearing.toStringAsFixed(2)}°');
    }
    
    // Update previous location for next calculation
    _previousBusLocation = busData.coordinates;
    
    // Update bus marker on map
    setState(() {
      // Remove old bus marker
      markers.removeWhere((marker) => marker.markerId == busMarkerId);
      
      // Add new bus marker with rotation
      _createRotatedBusIcon(bearing).then((rotatedIcon) {
        if (mounted) {
          setState(() {
            markers.add(
              Marker(
                markerId: busMarkerId,
                position: busData.coordinates,
                icon: rotatedIcon,
                rotation: bearing,
                infoWindow: InfoWindow(
                  title: 'Bus ${busData.busNumber}',
                  snippet: 'Speed: ${busData.speed.toStringAsFixed(1)} km/h',
                ),
              ),
            );
          });
        }
      });
    });
    
    // Update distance and ETA calculations
    _updateDistanceAndETA(busData.coordinates, selectedBusStop);
    
    // Redraw polyline with updated bus position
    final currentBus = ref.read(selectedBusStateProvider);
    if (currentBus.isNotEmpty) {
      _loadAndDrawRoutePolyline(currentBus, busData.direction ?? 'Northbound');
    }
    
    // Move camera to follow bus if enabled
    if (_isFollowingBus) {
      _mapController.animateCamera(
        CameraUpdate.newLatLng(busData.coordinates),
      );
    }
  }

  /// Start tracking a bus and draw the route polyline
  void startBusTracking(String selectedBus, BusStop selectedBusStop) async {
    print("DEBUG: Starting bus tracking");
    print("DEBUG: Selected bus: $selectedBus");
    print("DEBUG: Selected bus stop: ${selectedBusStop.address}");

    // Show loading immediately while attempting connection
    _showLoadingDialog();

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

    // Listen for stream errors immediately so we can show a modal on failure
    _busStreamSubscription?.close();
    _busStreamSubscription = ref.listenManual<AsyncValue<BusLocationData>>(
      busTrackingStreamProvider({
        'busNumber': 'C5',
        'direction': direction,
        'busStopIndex': busStopIndex,
        'latitude': location?.latitude,
        'longitude': location?.longitude,
      }),
      (previous, next) {
        if (next.hasError) {
          final error = next.error;
          print('[ERROR] Bus tracking stream error: $error');
          if (!_isStreamActive) return;

          String errorMessage = 'Unable to connect to bus tracking service';
          String errorTitle = 'Connection Error';
          
          if (error.toString().contains('timeout') || error.toString().contains('Connection timed out')) {
            errorMessage = 'Connection timeout. The server may be offline or unreachable. Please check your internet connection and try again.';
            errorTitle = 'Connection Timeout';
          } else if (error.toString().contains('internet') || error.toString().contains('Connection refused') || error.toString().contains('SocketException')) {
            errorMessage = 'Unable to reach the server. Please check your internet connection and try again.';
            errorTitle = 'Network Error';
          } else if (error.toString().contains('Unable to connect to server')) {
            errorMessage = 'The bus tracking server is currently unavailable. Please try again later.';
            errorTitle = 'Server Unavailable';
          }

          // Ensure loader is hidden and show dialog
          Future.delayed(const Duration(milliseconds: 100), () {
            if (!mounted) return;
            _hideLoadingDialog();
            _showNoServiceDialog(errorMessage);
            setState(() {
              _isStreamActive = false;
            });
          });
          return;
        }
        
        // Hide loading dialog when we get data (success case)
        if (next.hasValue) {
          print('[DEBUG] Received bus location data, hiding loading dialog');
          _hideLoadingDialog();
          
          // Check if this is just a connection status message (inactive with 0,0 coordinates)
          final data = next.value!;
          if (!data.isActive && data.coordinates.latitude == 0.0 && data.coordinates.longitude == 0.0) {
            print('[DEBUG] Received connection status - WebSocket is ready');
            // Don't process this as actual bus data, just acknowledge connection
            return;
          }
          
          // Process actual bus location data
          print('[DEBUG] Processing bus location data: ${data.coordinates}');
          _processBusLocationUpdate(data, selectedBusStop);
        }
      },
    );
    
    // Hide loading dialog after a reasonable timeout even if no data arrives
    // This prevents infinite loading when WebSocket connects but no bus data is available
    Timer(const Duration(seconds: 8), () {
      if (mounted && _isLoadingDialogVisible) {
        print('[DEBUG] Initial timeout reached, hiding loading dialog');
        _hideLoadingDialog();
        // Update status to show we're waiting for bus data
        ref.read(busTrackingProvider.notifier).updateBusTracking(
          selectedBus: selectedBus,
          selectedBusStop: selectedBusStop,
          distance: 0.0,
          estimatedArrivalTime: 0.0,
          isOnTime: true,
          arrivalStatus: 'Searching for bus...', // Show searching status
        );
        setState(() {}); // Force UI update
      }
    });
    
    // Show "no bus data" message after a longer timeout if no real bus data arrives
    Timer(const Duration(seconds: 15), () {
      if (mounted && _isStreamActive) {
        final currentBusLocation = ref.read(currentBusLocationProvider);
        if (currentBusLocation == null) {
          print('[DEBUG] No bus data received after 15 seconds, showing bus not available dialog');
          _hideLoadingDialog(); // Ensure loading dialog is hidden
          _showBusNotAvailableDialog();
        }
      }
    });
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
            arrivalStatus: 'Connecting to bus...', // More informative initial status
          );
    }

    // Force UI update
    setState(() {});
  }

  /// Load and draw the route polyline from bus position to selected bus stop only
  /// Ensures polyline does not extend beyond the user's selected stop
  Future<void> _loadAndDrawRoutePolyline(String bus, String direction) async {
    print('[DEBUG] Loading route polyline for bus: $bus, direction: $direction');
    
    final selectedBusStop = ref.read(selectedBusStopProvider);
    if (selectedBusStop == null) {
      print('[DEBUG] No selected bus stop, skipping polyline drawing');
      return;
    }
    
    try {
      // Fetch full route from backend API
      final fullRoute = await FullRouteService.findFullRouteByBusAndDirection(
        busNumber: bus,
        direction: direction,
        companyId: 1,
      );

      if (fullRoute != null && fullRoute.coordinates.isNotEmpty) {
        print('[DEBUG] Found full route with ${fullRoute.coordinates.length} coordinates');
        
        final routeCoordinates = fullRoute.toLatLngList();
        final busLocation = ref.read(currentBusLocationProvider);
        final stopLocation = selectedBusStop.coordinates;

        List<LatLng> polylinePoints = [];

        if (busLocation != null) {
          print('[DEBUG] Drawing route from bus location: $busLocation to stop: $stopLocation');
          
          // Find the nearest point on the route to the bus
          int nearestBusIndex = _findNearestPointIndex(busLocation, routeCoordinates);
          print('[DEBUG] Nearest route point to bus at index: $nearestBusIndex');
          
          // Find the nearest point on the route to the selected bus stop
          int nearestStopIndex = _findNearestPointIndex(stopLocation, routeCoordinates);
          print('[DEBUG] Nearest route point to stop at index: $nearestStopIndex');
          
          // Only draw route from bus to stop, ensuring we don't go beyond the stop
          if (nearestBusIndex <= nearestStopIndex) {
            // Bus is behind the stop - draw forward along route to the stop only
            polylinePoints.add(busLocation);
            polylinePoints.addAll(routeCoordinates.sublist(nearestBusIndex, nearestStopIndex + 1));
            // End at the selected stop - do not add stop location to avoid extending beyond
          } else {
            // Bus is ahead of the stop - draw backward along route to the stop only
            polylinePoints.add(busLocation);
            polylinePoints.addAll(routeCoordinates.sublist(nearestStopIndex, nearestBusIndex + 1).reversed);
            // End at the selected stop - do not add stop location to avoid extending beyond
          }
          
          print('[DEBUG] Polyline will show route from bus to selected stop only (${polylinePoints.length} points)');
        } else {
          // No bus location yet - draw from start of route to selected stop only
          print('[DEBUG] No bus location yet, drawing from route start to selected stop');
          int nearestStopIndex = _findNearestPointIndex(stopLocation, routeCoordinates);
          
          // Draw from beginning of route to the stop only
          polylinePoints.addAll(routeCoordinates.sublist(0, nearestStopIndex + 1));
          // End at the route point nearest to the stop - do not add stop location
        }

        setState(() {
          _routePolylines = {
            Polyline(
              polylineId: const PolylineId('route_polyline'),
              color: Colors.blue,
              width: 5,
              points: polylinePoints,
              patterns: [
                PatternItem.dash(20),
                PatternItem.gap(10),
              ],
            ),
          };
        });
        
        print('[DEBUG] Polyline drawn with ${polylinePoints.length} points (bus to stop only, no extension beyond)');
      } else {
        print('[DEBUG] No full route found, falling back to JSON path');
        // Fallback to old method if no full route in backend
        await _drawFallbackPolyline(bus, direction, selectedBusStop);
      }
    } catch (e) {
      print('[ERROR] Failed to load and draw route polyline: $e');
      // Fallback to old method on error
      await _drawFallbackPolyline(bus, direction, selectedBusStop);
    }
  }

  /// Fallback method to draw polyline using JSON data
  /// Ensures polyline does not extend beyond the user's selected stop
  Future<void> _drawFallbackPolyline(String bus, String direction, BusStop selectedBusStop) async {
    final routePath = await BusCommunicationServices.loadBusPath(bus, direction);
    if (routePath.isNotEmpty) {
      final busLocation = ref.read(currentBusLocationProvider);
      final stopLocation = selectedBusStop.coordinates;
      
      List<LatLng> polylinePoints = [];
      
      if (busLocation != null) {
        // Find relevant portion of route from bus to stop
        int nearestBusIndex = _findNearestPointIndex(busLocation, routePath);
        int nearestStopIndex = _findNearestPointIndex(stopLocation, routePath);
        
        // Only draw route from bus to stop, ensuring we don't go beyond the stop
        if (nearestBusIndex <= nearestStopIndex) {
          polylinePoints.add(busLocation);
          polylinePoints.addAll(routePath.sublist(nearestBusIndex, nearestStopIndex + 1));
          // End at the route point nearest to the stop - do not add stop location
        } else {
          polylinePoints.add(busLocation);
          polylinePoints.addAll(routePath.sublist(nearestStopIndex, nearestBusIndex + 1).reversed);
          // End at the route point nearest to the stop - do not add stop location
        }
      } else {
        // No bus location - draw from start to stop only
        int nearestStopIndex = _findNearestPointIndex(stopLocation, routePath);
        polylinePoints.addAll(routePath.sublist(0, nearestStopIndex + 1));
        // End at the route point nearest to the stop - do not add stop location
      }
      
      setState(() {
        _routePolylines = {
          Polyline(
            polylineId: const PolylineId('route_polyline'),
            color: Colors.blue,
            width: 5,
            points: polylinePoints,
          ),
        };
      });
      
      print('[DEBUG] Fallback polyline drawn with ${polylinePoints.length} points (no extension beyond stop)');
    }
  }

  /// Find the index of the nearest point in a list to the given location
  int _findNearestPointIndex(LatLng target, List<LatLng> points) {
    if (points.isEmpty) return 0;
    
    int nearestIndex = 0;
    double minDistance = double.infinity;
    
    for (int i = 0; i < points.length; i++) {
      final distance = _calculateDistance(target, points[i]);
      if (distance < minDistance) {
        minDistance = distance;
        nearestIndex = i;
      }
    }
    
    return nearestIndex;
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

    // Close stream listener
    _busStreamSubscription?.close();
    _busStreamSubscription = null;

    // Close stream listener

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

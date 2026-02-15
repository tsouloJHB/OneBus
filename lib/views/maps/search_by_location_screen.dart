import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'dart:math' show min, max;
import 'dart:async';
import 'package:onebus/models/location_search_models.dart';
import 'package:onebus/services/location_search_service.dart';
import 'package:onebus/services/bus_route_service.dart';
import 'package:onebus/views/maps/track_bus.dart';

enum WorkflowState { searchingLocation, selectingRoute, selectingStop, confirmingTracking, tracking }

class SearchByLocationScreen extends StatefulWidget {
  final String? initialQuery;

  const SearchByLocationScreen({Key? key, this.initialQuery}) : super(key: key);

  @override
  State<SearchByLocationScreen> createState() => _SearchByLocationScreenState();
}

class _SearchByLocationScreenState extends State<SearchByLocationScreen> {
  final MapController _mapController = MapController();
  final LocationSearchService _searchService = LocationSearchService();
  final TextEditingController _searchController = TextEditingController();
  
  LocationSearchResponse? _searchResponse;
  bool _isLoading = false;
  String _errorMessage = '';
  
  // Default map center (Johannesburg)
  LatLng _mapCenter = LatLng(-26.2041, 28.0473);
  double _zoom = 12.0;
  
  List<Marker> _markers = [];
  List<Polyline> _routeLines = [];
  
  // For route selection
  LatLng? _userLocation;
  RouteProximityResult? _selectedRoute;
  NearbyStop? _selectedStop;
  
  // Workflow state
  WorkflowState _currentWorkflowState = WorkflowState.searchingLocation;
  
  // Debounce timer for search
  Timer? _searchDebounce;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    if (widget.initialQuery != null && widget.initialQuery!.isNotEmpty) {
      _performSearch(widget.initialQuery!);
    }
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _searchDebounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged() {
    // Cancel previous debounce timer
    if (_searchDebounce?.isActive ?? false) {
      _searchDebounce!.cancel();
    }

    final query = _searchController.text.trim();

    // Only search if minimum 3 characters
    if (query.length >= 3) {
      // Set debounce timer with 500ms delay
      _searchDebounce = Timer(const Duration(milliseconds: 500), () {
        _performSearch(query);
      });
    } else if (query.isEmpty) {
      // Clear results if search is empty
      setState(() {
        _searchResponse = null;
        _errorMessage = '';
        _markers.clear();
      });
    }
  }

  Future<void> _performSearch(String query, {double radiusKm = 5.0}) async {
    if (query.trim().isEmpty) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
      _markers.clear();
    });

    try {
      final request = LocationSearchRequest(
        query: query,
        radiusKm: radiusKm,
      );

      final response = await _searchService.searchByLocation(request);

      setState(() {
        _searchResponse = response;
        _isLoading = false;
        
        if (response.geocodingResult != null) {
          // Store user location
          _userLocation = LatLng(
            response.geocodingResult!.latitude,
            response.geocodingResult!.longitude,
          );
          
          // Update map center to searched location
          _mapCenter = _userLocation!;
          _zoom = 13.0;
          
          // Move map to the new center
          _mapController.move(_mapCenter, _zoom);
          
          // Create markers for nearby stops
          _updateMarkers();
          
          // Log results for debugging
          print('🔍 Search Results:');
          print('  Location: ${response.geocodingResult!.displayName}');
          print('  Routes Found: ${response.totalRoutesFound}');
          print('  Search Radius: ${response.searchRadiusKm} km');
          if (response.nearbyRoutes.isNotEmpty) {
            print('  Routes: ${response.nearbyRoutes.map((r) => r.routeName).join(", ")}');
            for (var route in response.nearbyRoutes) {
              print('    - ${route.routeName}: ${route.nearbyStops.length} stops');
            }
          } else {
            print('  ⚠️  No routes found!');
          }
        } else {
          _errorMessage = 'Location "$query" not found.\n\nTry:\n• Use the autocomplete suggestions\n• Be more specific (e.g., "Auckland Park, Johannesburg")\n• Check spelling';
          print('❌ Geocoding failed for: $query');
        }
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error: $e';
      });
      print('❌ Search Error: $e');
    }
  }

  void _fitMapToBounds(List<LatLng> points) {
    if (points.isEmpty) return;

    double minLat = points[0].latitude;
    double maxLat = points[0].latitude;
    double minLon = points[0].longitude;
    double maxLon = points[0].longitude;

    for (var point in points) {
      minLat = min(minLat, point.latitude);
      maxLat = max(maxLat, point.latitude);
      minLon = min(minLon, point.longitude);
      maxLon = max(maxLon, point.longitude);
    }

    final center = LatLng((minLat + maxLat) / 2, (minLon + maxLon) / 2);
    _mapController.move(center, 13.0);
  }

  void _updateMarkers() {
    _markers.clear();
    
    if (_searchResponse?.geocodingResult != null) {
      _markers.add(
        Marker(
          point: LatLng(
            _searchResponse!.geocodingResult!.latitude,
            _searchResponse!.geocodingResult!.longitude,
          ),
          width: 40,
          height: 40,
          child: Icon(
            Icons.place,
            color: Colors.red,
            size: 40,
          ),
        ),
      );
    }

    if (_searchResponse?.nearbyRoutes != null) {
      for (var route in _searchResponse!.nearbyRoutes) {
        for (var stop in route.nearbyStops) {
          _markers.add(
            Marker(
              point: LatLng(stop.latitude, stop.longitude),
              width: 30,
              height: 30,
              child: Icon(
                Icons.bus_alert,
                color: Colors.blue,
                size: 30,
              ),
            ),
          );
        }
      }
    }
  }

  // Workflow callback methods
  void _onRouteSelected(RouteProximityResult route) async {
    print("[DEBUG] Route selected: ${route.routeName} with ${route.nearbyStops.length} nearby stops");
    
    // If no nearby stops found via location search, fetch from route API
    List<NearbyStop> stopsToUse = route.nearbyStops;
    
    if (route.nearbyStops.isEmpty) {
      print("[DEBUG] No nearby stops from location search, fetching all stops for route");
      try {
        // Fetch all stops for this route
        final busRouteResponse = await BusRouteService.getBusRoutesAndStops(
          route.routeName, // Bus number
          route.companyName, // Company name
        );
        
        if (busRouteResponse != null && busRouteResponse.routes.isNotEmpty) {
          // Get stops from the first route (or matching direction)
          for (var r in busRouteResponse.routes) {
            // If we have a direction from location search, try to match it
            if (route.direction != null &&
                (r.direction.toLowerCase().contains(route.direction!.toLowerCase()) ||
                 route.direction!.toLowerCase().contains(r.direction.toLowerCase()))) {
              stopsToUse = BusRouteService.convertApiStopsToBusStops(r.stops)
                  .map((stop) => NearbyStop(
                    stopId: stop.busStopIndex ?? 0,
                    address: stop.address ?? 'Unknown',
                    latitude: stop.coordinates.latitude,
                    longitude: stop.coordinates.longitude,
                    distanceKm: 0, // Set distance as 0 since we don't have it
                    stopIndex: stop.busStopIndex ?? 0,
                  ))
                  .toList();
              break;
            }
            if (stopsToUse.isEmpty) {
              // If no direction match or no direction specified, use the first route
              stopsToUse = BusRouteService.convertApiStopsToBusStops(r.stops)
                  .map((stop) => NearbyStop(
                    stopId: stop.busStopIndex ?? 0,
                    address: stop.address ?? 'Unknown',
                    latitude: stop.coordinates.latitude,
                    longitude: stop.coordinates.longitude,
                    distanceKm: 0,
                    stopIndex: stop.busStopIndex ?? 0,
                  ))
                  .toList();
              break;
            }
          }
          print("[DEBUG] Loaded ${stopsToUse.length} stops from API");
        }
      } catch (e) {
        print("[ERROR] Failed to fetch stops from API: $e");
      }
    }
    
    setState(() {
      // Update the selected route with the stops we found
      _selectedRoute = RouteProximityResult(
        routeId: route.routeId,
        routeName: route.routeName,
        direction: route.direction,
        distanceKm: route.distanceKm,
        nearbyStops: stopsToUse,
        companyName: route.companyName,
        companyId: route.companyId,
      );
      _currentWorkflowState = WorkflowState.selectingStop;
      
      // Update map to show route stops
      _markers.clear();
      _routeLines.clear();
      
      // Add stop markers
      for (var stop in stopsToUse) {
        _markers.add(
          Marker(
            point: LatLng(stop.latitude, stop.longitude),
            width: 36,
            height: 36,
            child: Icon(
              Icons.location_on,
              color: Colors.orange,
              size: 36,
            ),
          ),
        );
      }
      
      // Add route polyline
      final routePoints = stopsToUse
          .map((stop) => LatLng(stop.latitude, stop.longitude))
          .toList();
      
      if (routePoints.isNotEmpty) {
        _routeLines.add(
          Polyline(
            points: routePoints,
            color: Colors.blue,
            strokeWidth: 2.5,
          ),
        );
        
        // Fit map to route bounds
        _fitMapToBounds(routePoints);
      }
    });
  }

  void _onStopSelected(NearbyStop stop) {
    setState(() {
      _selectedStop = stop;
      _currentWorkflowState = WorkflowState.confirmingTracking;
      
      // Highlight selected stop on map
      _markers.clear();
      
      // Add user location marker
      _markers.add(
        Marker(
          point: _userLocation ?? _mapCenter,
          width: 36,
          height: 36,
          child: Icon(
            Icons.person_pin_circle,
            color: Colors.green,
            size: 36,
          ),
        ),
      );
      
      // Add selected stop marker
      if (_selectedRoute != null) {
        for (var s in _selectedRoute!.nearbyStops) {
          _markers.add(
            Marker(
              point: LatLng(s.latitude, s.longitude),
              width: 36,
              height: 36,
              child: Icon(
                Icons.location_on,
                color: s.stopId == stop.stopId ? Colors.red : Colors.blue,
                size: 36,
              ),
            ),
          );
        }
        
        // Draw route polyline
        final routePoints = _selectedRoute!.nearbyStops
            .map((s) => LatLng(s.latitude, s.longitude))
            .toList();
        
        if (routePoints.isNotEmpty) {
          _routeLines.add(
            Polyline(
              points: routePoints,
              color: Colors.blue,
              strokeWidth: 2.5,
            ),
          );
        }
      }
    });
  }

  void _onStartTracking() {
    if (_selectedRoute == null || _selectedStop == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a route and stop first'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    
    // Navigate to TrackBus with pre-selected route data
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => TrackBus(
          currentScreen: 'where to',
          preselectedRoute: PreselectedRouteData(
            routeId: _selectedRoute!.routeId,
            routeName: _selectedRoute!.routeName,
            direction: _selectedRoute!.direction,
            companyName: _selectedRoute!.companyName,
            companyId: _selectedRoute!.companyId,
            destinationAddress: _selectedStop!.address,
            destinationLat: _selectedStop!.latitude,
            destinationLng: _selectedStop!.longitude,
          ),
        ),
      ),
    );
  }

  void _onStopTracking() {
    setState(() {
      _currentWorkflowState = WorkflowState.searchingLocation;
      _selectedRoute = null;
      _selectedStop = null;
      _searchResponse = null;
      _markers.clear();
      _routeLines.clear();
      _searchController.clear();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Tracking stopped'),
          backgroundColor: Colors.grey[700],
          duration: Duration(seconds: 2),
        ),
      );
    });
  }

  // Build content based on workflow state
  Widget _buildWorkflowContent(ScrollController scrollController) {
    switch (_currentWorkflowState) {
      case WorkflowState.searchingLocation:
        return _buildSearchLocationSheet(scrollController);
      case WorkflowState.selectingRoute:
        return _buildRouteSelectionSheet(scrollController);
      case WorkflowState.selectingStop:
        return _buildStopSelectionSheet(scrollController);
      case WorkflowState.confirmingTracking:
        return _buildTrackingConfirmationSheet(scrollController);
      case WorkflowState.tracking:
        return _buildTrackingSheet(scrollController);
    }
  }

  // Search location stage UI
  Widget _buildSearchLocationSheet(ScrollController scrollController) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Handle bar
        Container(
          margin: EdgeInsets.symmetric(vertical: 8),
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        
        // Search field
        Padding(
          padding: EdgeInsets.all(16),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search location...',
              helperText: 'Type at least 3 characters to search',
              prefixIcon: Icon(Icons.search, color: Colors.red),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        setState(() {
                          _searchResponse = null;
                        });
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.red),
              ),
              filled: true,
              fillColor: Colors.grey[50],
            ),
          ),
        ),

        // Status messages
        if (_searchController.text.isNotEmpty && _searchController.text.length < 3)
          Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.grey[600], size: 18),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Type at least ${3 - _searchController.text.length} more character${3 - _searchController.text.length == 1 ? '' : 's'} to search',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                    ),
                  ),
                ),
              ],
            ),
          )
        else if (_isLoading)
          Padding(
            padding: EdgeInsets.all(24),
            child: CircularProgressIndicator(),
          )
        else if (_errorMessage.isNotEmpty)
          Padding(
            padding: EdgeInsets.all(16),
            child: Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red[50],
                border: Border.all(color: Colors.red[200]!),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.error_outline, color: Colors.red),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _errorMessage,
                      style: TextStyle(color: Colors.red[900], fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          )
        else if (_searchResponse != null && _searchResponse!.nearbyRoutes.isNotEmpty)
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Result summary
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${_searchResponse!.nearbyRoutes.length} routes found',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        'within ${_searchResponse!.searchRadiusKm.toStringAsFixed(1)} km',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                ),
                
                Divider(height: 1),
                
                // Routes list with proper spacing for autocomplete
                Expanded(
                  child: ListView.builder(
                    controller: scrollController,
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    itemCount: _searchResponse!.nearbyRoutes.length,
                    itemBuilder: (context, index) {
                      final route = _searchResponse!.nearbyRoutes[index];
                      return _buildRouteCard(route, () {
                        _onRouteSelected(route);
                      });
                    },
                  ),
                ),
              ],
            ),
          )
        else if (_searchResponse == null && _searchController.text.isEmpty)
          Padding(
            padding: EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.location_searching,
                  size: 48,
                  color: Colors.grey[400],
                ),
                SizedBox(height: 16),
                Text(
                  'Search for a location',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[700],
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Enter an address, area name, or landmark',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  // Route selection stage UI
  Widget _buildRouteSelectionSheet(ScrollController scrollController) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Handle bar
        Container(
          margin: EdgeInsets.symmetric(vertical: 8),
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        
        // Back button + location name
        Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.arrow_back, color: Colors.red),
                    onPressed: () {
                      setState(() {
                        _currentWorkflowState = WorkflowState.searchingLocation;
                      });
                    },
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Select a route',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey[700],
                          ),
                        ),
                        if (_searchResponse?.geocodingResult != null)
                          Text(
                            _searchResponse!.geocodingResult!.displayName,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        Divider(height: 1),

        // Routes list
        if (_searchResponse != null && _searchResponse!.nearbyRoutes.isNotEmpty)
          Expanded(
            child: ListView.builder(
              controller: scrollController,
              padding: EdgeInsets.all(8),
              itemCount: _searchResponse!.nearbyRoutes.length,
              itemBuilder: (context, index) {
                final route = _searchResponse!.nearbyRoutes[index];
                return _buildRouteCard(route, () {
                  _onRouteSelected(route);
                });
              },
            ),
          )
        else
          Expanded(
            child: Center(
              child: Text('No routes available'),
            ),
          ),
      ],
    );
  }

  // Stop selection stage UI
  Widget _buildStopSelectionSheet(ScrollController scrollController) {
    if (_selectedRoute == null) {
      return Center(child: Text('No route selected'));
    }

    return Column(
      children: [
        // Handle bar
        Container(
          margin: EdgeInsets.symmetric(vertical: 8),
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(2),
          ),
        ),

        // Back button + route info
        Padding(
          padding: EdgeInsets.all(16),
          child: Row(
            children: [
              IconButton(
                icon: Icon(Icons.arrow_back, color: Colors.red),
                onPressed: () {
                  setState(() {
                    _currentWorkflowState = WorkflowState.searchingLocation;
                  });
                },
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Select your bus stop',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[700],
                      ),
                    ),
                    Text(
                      'Route ${_selectedRoute!.routeName}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        Divider(height: 1),

        // Stops list
        if (_selectedRoute!.nearbyStops.isEmpty)
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.info_outline, size: 48, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'No bus stops available',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[700],
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Please select a different route',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          Expanded(
            child: ListView.builder(
              controller: scrollController,
              padding: EdgeInsets.all(8),
              itemCount: _selectedRoute!.nearbyStops.length,
              itemBuilder: (context, index) {
                final stop = _selectedRoute!.nearbyStops[index];
                return _buildStopCard(stop, () {
                  _onStopSelected(stop);
                });
              },
            ),
          ),
      ],
    );
  }

  // Tracking confirmation stage UI
  Widget _buildTrackingConfirmationSheet(ScrollController scrollController) {
    if (_selectedRoute == null || _selectedStop == null) {
      return Center(child: Text('Missing route or stop information'));
    }

    return Column(
      children: [
        // Handle bar
        Container(
          margin: EdgeInsets.symmetric(vertical: 8),
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(2),
          ),
        ),

        // Confirmation header
        Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Confirm tracking',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Start tracking this route to your destination?',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),

        Divider(height: 1),

        // Route and destination summary
        Expanded(
          child: SingleChildScrollView(
            controller: scrollController,
            padding: EdgeInsets.all(16),
            child: Column(
              children: [
                // Route info card
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue[200]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.directions_bus, color: Colors.blue),
                          SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Route',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                Text(
                                  _selectedRoute!.routeName,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      Text(
                        _selectedRoute!.companyName,
                        style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                      ),
                      if (_selectedRoute!.direction != null)
                        Padding(
                          padding: EdgeInsets.only(top: 4),
                          child: Text(
                            '→ ${_selectedRoute!.direction}',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.blue[700],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                SizedBox(height: 16),

                // Destination info card
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red[200]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.location_on, color: Colors.red),
                          SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Destination',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                Text(
                                  'Stop ${_selectedStop!.stopId}',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      Text(
                        _selectedStop!.address,
                        style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 4),
                      Text(
                        '${_selectedStop!.distanceKm.toStringAsFixed(2)} km away',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 24),

                // Action buttons
                Column(
                  children: [
                    ElevatedButton.icon(
                      onPressed: () {
                        _onStartTracking();
                      },
                      icon: Icon(Icons.play_arrow),
                      label: Text('Start Tracking'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        minimumSize: Size(double.infinity, 48),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    SizedBox(height: 8),
                    OutlinedButton(
                      onPressed: () {
                        setState(() {
                          _currentWorkflowState = WorkflowState.selectingStop;
                        });
                      },
                      child: Text('Change Destination'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        minimumSize: Size(double.infinity, 48),
                        side: BorderSide(color: Colors.red),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // Tracking stage UI
  Widget _buildTrackingSheet(ScrollController scrollController) {
    if (_selectedRoute == null || _selectedStop == null) {
      return Center(child: Text('Tracking information unavailable'));
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Handle bar
        Container(
          margin: EdgeInsets.symmetric(vertical: 8),
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(2),
          ),
        ),

        // Active tracking header
        Container(
          width: double.infinity,
          margin: EdgeInsets.all(8),
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.green[400]!, Colors.green[300]!],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.location_on,
                    color: Colors.white,
                    size: 24,
                  ),
                  SizedBox(width: 12),
                  Text(
                    'Tracking Active',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        SizedBox(height: 8),

        // Journey info
        Expanded(
          child: SingleChildScrollView(
            controller: scrollController,
            padding: EdgeInsets.all(16),
            child: Column(
              children: [
                // Route card
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue[200]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Your Route',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                      SizedBox(height: 8),
                      Text(
                        _selectedRoute!.routeName,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        _selectedRoute!.companyName,
                        style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 12),

                // Destination card
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red[200]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Your Destination',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Stop ${_selectedStop!.stopId}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        _selectedStop!.address,
                        style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 16),

                // Stop tracking button
                OutlinedButton.icon(
                  onPressed: _onStopTracking,
                  icon: Icon(Icons.stop_circle),
                  label: Text('Stop Tracking'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    minimumSize: Size(double.infinity, 48),
                    side: BorderSide(color: Colors.red),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // Build route card widget
  Widget _buildRouteCard(RouteProximityResult route, VoidCallback onTap) {
    // Extract direction components (e.g., "Northbound" and "Johannesburg → Florida")
    String directionLabel = route.direction ?? 'Route';
    String routeDestination = '';
    
    if (route.direction != null && route.direction!.isNotEmpty) {
      // Parse direction to extract the main direction (e.g., "Northbound")
      final directionParts = route.direction!.split(':');
      if (directionParts.length > 1) {
        directionLabel = directionParts[0].trim();
        routeDestination = directionParts[1].trim();
      } else if (route.direction!.contains('→')) {
        routeDestination = route.direction!;
        directionLabel = '';
      } else {
        directionLabel = route.direction!;
      }
    }
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
          color: Colors.white,
        ),
        child: Padding(
          padding: EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Bus number and direction header
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Icon(
                        Icons.directions_bus,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Bus ${route.routeName}',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        // Direction label (e.g., "Northbound", "Southbound")
                        if (directionLabel.isNotEmpty)
                          Text(
                            directionLabel,
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.green,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right, color: Colors.grey[400]),
                ],
              ),
              
              SizedBox(height: 10),
              
              // Explicit route destination (e.g., "Johannesburg → Florida")
              if (routeDestination.isNotEmpty)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.amber[50],
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.amber[200]!),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.location_on, size: 14, color: Colors.amber[700]),
                      SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          routeDestination,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.amber[900],
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              
              SizedBox(height: 8),
              
              // Company and distance row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      '🚌 ${route.companyName}',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    '${route.distanceKm.toStringAsFixed(2)} km',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[700],
                    ),
                  ),
                ],
              ),
              
              SizedBox(height: 4),
              
              // Nearby stops info
              Text(
                '📍 ${route.nearbyStops.length} stops nearby',
                style: TextStyle(fontSize: 11, color: Colors.orange),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Build stop card widget
  Widget _buildStopCard(NearbyStop stop, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 2,
              offset: Offset(0, 1),
            ),
          ],
          color: Colors.white,
        ),
        child: Padding(
          padding: EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.red[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Icon(
                    Icons.location_on,
                    color: Colors.red,
                    size: 20,
                  ),
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Stop ${stop.stopId}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      stop.address,
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 2),
                    Text(
                      '${stop.distanceKm.toStringAsFixed(2)} km away',
                      style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: Colors.grey[400]),
            ],
          ),
        ),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Full screen map
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _mapCenter,
              initialZoom: _zoom,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.onebus.app',
              ),
              MarkerLayer(markers: _markers),
              PolylineLayer(polylines: _routeLines),
            ],
          ),

          // Loading overlay
          if (_isLoading && _currentWorkflowState != WorkflowState.tracking)
            Container(
              color: Colors.black26,
              child: Center(
                child: CircularProgressIndicator(),
              ),
            ),

          // Bottom sheet with gradient background
          DraggableScrollableSheet(
            initialChildSize: 0.5,
            minChildSize: 0.1,
            maxChildSize: 0.9,
            builder: (context, scrollController) {
              return Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.red.shade50,
                      Colors.white,
                    ],
                  ),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(46),
                    topRight: Radius.circular(46),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 10,
                      offset: Offset(0, -2),
                    ),
                  ],
                ),
                child: _buildWorkflowContent(scrollController),
              );
            },
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:haversine_distance/haversine_distance.dart';

import '../../../models/bus_stop.dart';
import '../track_bus.dart';

class SelectionLocationSheet extends ConsumerStatefulWidget {
  final List<BusStop> busStops;
  final LatLng? currentLocation;
  final BusStop? selectedBusStop;
  final String selectedBus;
  final VoidCallback onConfirm;

  const SelectionLocationSheet({
    Key? key,
    required this.busStops,
    this.currentLocation,
    this.selectedBusStop,
    required this.selectedBus,
    required this.onConfirm,
  }) : super(key: key);

  @override
  ConsumerState<SelectionLocationSheet> createState() =>
      _SelectionLocationSheetState();
}

class _SelectionLocationSheetState
    extends ConsumerState<SelectionLocationSheet> {
  final TextEditingController _searchController = TextEditingController();
  String _selectionMode = 'list'; // 'map', 'list', or 'search'
  List<BusStop> _filteredBusStops = [];

  @override
  void initState() {
    super.initState();
    _filteredBusStops = widget.busStops;
    _searchController.addListener(() {
      setState(() {
        _filteredBusStops = widget.busStops
            .where((busStop) =>
                busStop.address
                    ?.toLowerCase()
                    .contains(_searchController.text.toLowerCase()) ??
                false)
            .toList();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<BusStop> _getNearestBusStops() {
    if (widget.currentLocation == null) {
      return widget.busStops.take(10).toList();
    }

    final haversine = HaversineDistance();
    List<BusStop> sortedBusStops = List.from(widget.busStops);
    sortedBusStops.sort((a, b) {
      final distanceA = haversine.haversine(
        Location(widget.currentLocation!.latitude,
            widget.currentLocation!.longitude),
        Location(a.coordinates.latitude, a.coordinates.longitude),
        Unit.KM,
      );
      final distanceB = haversine.haversine(
        Location(widget.currentLocation!.latitude,
            widget.currentLocation!.longitude),
        Location(b.coordinates.latitude, b.coordinates.longitude),
        Unit.KM,
      );
      return distanceA.compareTo(distanceB);
    });
    return sortedBusStops.take(10).toList();
  }

  String _formatDistance(double distanceInMeters) {
    if (distanceInMeters < 1000) {
      return '${distanceInMeters.round()} meters';
    } else {
      return '${(distanceInMeters / 1000).toStringAsFixed(1)} km';
    }
  }

  @override
  Widget build(BuildContext context) {
    final nearestBusStops = _getNearestBusStops();
    final haversine = HaversineDistance();

    return DraggableScrollableSheet(
      initialChildSize: 0.41,
      minChildSize: 0.1,
      maxChildSize: 0.9,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.red.shade100,
                Colors.white,
              ],
            ),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(46.0),
              topRight: Radius.circular(46.0),
            ),
          ),
          child: Column(
            children: [
              // Centered draggable handle
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10.0),
                child: Container(
                  width: 50,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),

              // Title text
              const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Select ",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 25,
                    ),
                  ),
                  Text(
                    "Bus Stop",
                    style: TextStyle(
                      fontSize: 25,
                    ),
                  ),
                  SizedBox(width: 10),
                  Text(
                    "below ",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 25,
                    ),
                  ),
                ],
              ),
              const Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  SizedBox(width: 50),
                ],
              ),
              const SizedBox(height: 10),

              // Main content
              Expanded(
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: widget.selectedBusStop == null
                        ? Container(
                            padding: const EdgeInsets.all(16),
                            margin: const EdgeInsets.only(bottom: 16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.withOpacity(0.3),
                                  spreadRadius: 1,
                                  blurRadius: 3,
                                  offset: const Offset(1, 1),
                                ),
                              ],
                            ),
                            child: const Text(
                              'Tap on a bus stop marker on the map to select your pickup location',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey,
                              ),
                            ),
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(16),
                                margin: const EdgeInsets.only(bottom: 16),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.grey.withOpacity(0.3),
                                      spreadRadius: 1,
                                      blurRadius: 3,
                                      offset: const Offset(1, 1),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Selected Bus Stop',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.grey[600],
                                        fontSize: 14,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      widget.selectedBusStop!.address ??
                                          'Unknown location',
                                      style: const TextStyle(fontSize: 16),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Direction: ${widget.selectedBusStop!.direction ?? 'Unknown'}',
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(28),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.grey.withOpacity(0.3),
                                      spreadRadius: 1,
                                      blurRadius: 3,
                                      offset: const Offset(1, 1),
                                    ),
                                  ],
                                ),
                                child: ElevatedButton(
                                  onPressed: widget.selectedBusStop != null
                                      ? widget.onConfirm
                                      : null,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor:
                                        widget.selectedBusStop != null
                                            ? Colors.white
                                            : Colors.grey[300],
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 16),
                                    shape: RoundedRectangleBorder(
                                      side: BorderSide(
                                        color: widget.selectedBusStop != null
                                            ? Colors.red
                                            : Colors.grey,
                                        width: 3.0,
                                      ),
                                      borderRadius: BorderRadius.circular(28),
                                    ),
                                    elevation: 0,
                                  ),
                                  child: Text(
                                    'Confirm Bus Stop',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: widget.selectedBusStop != null
                                          ? Colors.black
                                          : Colors.grey[600],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

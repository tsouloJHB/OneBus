import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:onebus/models/bus_stop.dart';
import '../../../state/track_bus_state.dart';
import '../../../views/home.dart';
import '../../../controllers/bus_tracking_controller.dart';

class BottomTrackingSheet extends ConsumerWidget {
  final List<String> filteredBuses;
  final TextEditingController searchController;
  final Function(String) onSearchChanged;
  final VoidCallback onSearchPressed;
  final String previousPage;
  final BusStop? selectedBusStop;
  final VoidCallback onChangeBus;
  final VoidCallback onStopTracking;

  const BottomTrackingSheet({
    Key? key,
    required this.filteredBuses,
    required this.searchController,
    required this.onSearchChanged,
    required this.onSearchPressed,
    required this.previousPage,
    this.selectedBusStop,
    required this.onChangeBus,
    required this.onStopTracking,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final busTrackingState = ref.watch(busTrackingProvider);
    final bool busHasArrived =
        busTrackingState?.arrivalStatus == 'Bus has arrived';

    return DraggableScrollableSheet(
      initialChildSize: 0.4,
      minChildSize: 0.1,
      maxChildSize: 0.7,
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Bus number, status, and action buttons in one row
                        Row(
                          children: [
                            // Bus number
                            Text(
                              busTrackingState?.selectedBus ??
                                  'No Bus Selected',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 12),
                            // Status badge
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: _getStatusColor(
                                        busTrackingState?.arrivalStatus ??
                                            'On Time')
                                    .withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (_shouldPulse(
                                      busTrackingState?.arrivalStatus ??
                                          'On Time'))
                                    Icon(
                                      _getStatusIcon(
                                          busTrackingState?.arrivalStatus ??
                                              'On Time'),
                                      color: _getStatusColor(
                                          busTrackingState?.arrivalStatus ??
                                              'On Time'),
                                      size: 12,
                                    ),
                                  if (_shouldPulse(
                                      busTrackingState?.arrivalStatus ??
                                          'On Time'))
                                    const SizedBox(width: 4),
                                  Text(
                                    busTrackingState?.arrivalStatus ??
                                        'On Time',
                                    style: TextStyle(
                                      color: _getStatusColor(
                                          busTrackingState?.arrivalStatus ??
                                              'On Time'),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Spacer(),
                            // Action buttons - only show if bus hasn't arrived
                            if (!busHasArrived)
                              Row(
                                children: [
                                  // Change Bus Button
                                  Container(
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                          color: Colors.blue, width: 1.5),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.grey.withOpacity(0.2),
                                          spreadRadius: 1,
                                          blurRadius: 2,
                                          offset: const Offset(1, 1),
                                        ),
                                      ],
                                    ),
                                    child: IconButton(
                                      onPressed: onChangeBus,
                                      icon: const Icon(Icons.swap_horiz,
                                          color: Colors.blue, size: 18),
                                      tooltip: 'Change Bus',
                                      padding: const EdgeInsets.all(6),
                                      constraints: const BoxConstraints(
                                        minWidth: 22,
                                        minHeight: 22,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  // Return to Home Button
                                  Container(
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                          color: Colors.red, width: 1.5),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.grey.withOpacity(0.2),
                                          spreadRadius: 1,
                                          blurRadius: 2,
                                          offset: const Offset(1, 1),
                                        ),
                                      ],
                                    ),
                                    child: IconButton(
                                      onPressed: () {
                                        // Clear all tracking state before returning to home
                                        BusTrackingController(ref)
                                            .clearAllTrackingState();
                                        Navigator.pushAndRemoveUntil(
                                          context,
                                          MaterialPageRoute(
                                              builder: (context) =>
                                                  const HomeScreen()),
                                          (route) => false,
                                        );
                                      },
                                      icon: const Icon(Icons.home,
                                          color: Colors.red, size: 18),
                                      tooltip: 'Return to Home',
                                      padding: const EdgeInsets.all(6),
                                      constraints: const BoxConstraints(
                                        minWidth: 12,
                                        minHeight: 12,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        // Show arrival message when bus has arrived
                        if (busHasArrived) ...[
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(15),
                              border: Border.all(color: Colors.green, width: 1),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.check_circle,
                                    color: Colors.green, size: 24),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Bus has arrived!',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.green,
                                        ),
                                      ),
                                      Text(
                                        'Your bus has reached the destination',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.green.shade700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                        ],
                        Row(
                          children: [
                            Icon(
                              _getDestinationIcon(
                                  busTrackingState?.arrivalStatus ?? 'On Time'),
                              color: _getStatusColor(
                                  busTrackingState?.arrivalStatus ?? 'On Time'),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _getDestinationLabel(
                                        busTrackingState?.arrivalStatus ??
                                            'On Time'),
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  Text(
                                    busTrackingState
                                            ?.selectedBusStop?.address ??
                                        'Loading location...',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: _isDestinationHighlighted(
                                              busTrackingState?.arrivalStatus ??
                                                  'On Time')
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                      color: _isDestinationHighlighted(
                                              busTrackingState?.arrivalStatus ??
                                                  'On Time')
                                          ? _getStatusColor(
                                              busTrackingState?.arrivalStatus ??
                                                  'On Time')
                                          : Colors.black,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 5),
                        // Info cards with shadow - only show if bus hasn't arrived
                        if (!busHasArrived) ...[
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(15),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.withOpacity(0.2),
                                  spreadRadius: 1,
                                  blurRadius: 2,
                                  offset: const Offset(1, 1),
                                ),
                              ],
                            ),
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                _buildInfoColumn(
                                  'Estimated',
                                  busTrackingState?.estimatedArrivalTime != null
                                      ? '${busTrackingState!.estimatedArrivalTime.round()} min'
                                      : 'N/A',
                                  Icons.access_time,
                                ),
                                Container(
                                  height: 30,
                                  width: 1,
                                  color: Colors.grey[300],
                                ),
                                _buildInfoColumn(
                                  'Distance',
                                  busTrackingState?.distance != null
                                      ? '${busTrackingState!.distance.toStringAsFixed(1)} km'
                                      : 'N/A',
                                  Icons.directions_bus,
                                ),
                              ],
                            ),
                          ),
                        ],
                        // Action buttons when bus has arrived
                        if (busHasArrived) ...[
                          const SizedBox(height: 20),
                          Row(
                            children: [
                              Expanded(
                                child: Container(
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
                                  child: ElevatedButton(
                                    onPressed: () {
                                      // Clear all tracking state before stopping tracking
                                      BusTrackingController(ref)
                                          .clearAllTrackingState();
                                      // Stop tracking and return to home
                                      onStopTracking();
                                      Navigator.pushAndRemoveUntil(
                                        context,
                                        MaterialPageRoute(
                                            builder: (context) =>
                                                const HomeScreen()),
                                        (route) => false,
                                      );
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 16),
                                      shape: RoundedRectangleBorder(
                                        side: const BorderSide(
                                            color: Colors.red, width: 2),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      elevation: 0,
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.home,
                                            color: Colors.red, size: 20),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Return to Home',
                                          style: TextStyle(
                                            fontSize: 16,
                                            color: Colors.red,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Container(
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
                                  child: ElevatedButton(
                                    onPressed: () {
                                      // Stop current tracking and start new bus selection
                                      onStopTracking();
                                      onChangeBus();
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 16),
                                      shape: RoundedRectangleBorder(
                                        side: const BorderSide(
                                            color: Colors.blue, width: 2),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      elevation: 0,
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.directions_bus,
                                            color: Colors.blue, size: 20),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Track New Bus',
                                          style: TextStyle(
                                            fontSize: 16,
                                            color: Colors.blue,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
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

  Widget _buildInfoColumn(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.blue, size: 20),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            color: Colors.grey,
            fontSize: 10,
          ),
        ),
        const SizedBox(height: 2),
        value == 'N/A'
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(
                      strokeWidth: 1.5,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    'Loading...',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.blue,
                    ),
                  ),
                ],
              )
            : Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ],
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Bus has arrived':
        return Colors.green;
      case 'Arriving':
        return Colors.blue;
      case 'Very Close':
        return Colors.orange;
      case 'On Time':
        return Colors.green;
      case 'Delayed':
        return Colors.orange;
      case 'Cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getDestinationIcon(String status) {
    switch (status) {
      case 'Bus has arrived':
        return Icons.check_circle;
      case 'Arriving':
        return Icons.directions_bus;
      case 'Very Close':
        return Icons.near_me;
      case 'On Time':
        return Icons.location_on;
      case 'Delayed':
        return Icons.schedule;
      case 'Cancelled':
        return Icons.cancel;
      default:
        return Icons.location_on;
    }
  }

  String _getDestinationLabel(String status) {
    switch (status) {
      case 'Bus has arrived':
        return 'Destination Reached';
      case 'Arriving':
        return 'Arriving at Destination';
      case 'Very Close':
        return 'Approaching Destination';
      case 'On Time':
        return 'Destination';
      case 'Delayed':
        return 'Delayed to Destination';
      case 'Cancelled':
        return 'Trip Cancelled';
      default:
        return 'Destination';
    }
  }

  bool _isDestinationHighlighted(String status) {
    switch (status) {
      case 'Bus has arrived':
        return true;
      case 'Arriving':
        return true;
      case 'Very Close':
        return true;
      case 'On Time':
        return false;
      case 'Delayed':
        return false;
      case 'Cancelled':
        return false;
      default:
        return false;
    }
  }

  bool _shouldPulse(String status) {
    switch (status) {
      case 'Arriving':
      case 'Bus has arrived':
        return true;
      default:
        return false;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'Arriving':
        return Icons.directions_bus;
      case 'Bus has arrived':
        return Icons.check_circle;
      default:
        return Icons.location_on;
    }
  }
}

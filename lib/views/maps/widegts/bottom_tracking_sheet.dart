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
      minChildSize: 0.12,
      maxChildSize: 0.75,
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
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(30.0),
              topRight: Radius.circular(30.0),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                spreadRadius: 0,
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Column(
            children: [
              // Modern drag handle
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12.0),
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[400],
                    borderRadius: BorderRadius.circular(2),
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
                    child: SingleChildScrollView(
                      controller: scrollController,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                        // Header with bus info and actions
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                              colors: [
                                Colors.red.shade50,
                                Colors.white,
                              ],
                            ),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.red.shade100),
                          ),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  // Bus icon with background
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.red,
                                      borderRadius: BorderRadius.circular(12),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.red.withOpacity(0.3),
                                          spreadRadius: 1,
                                          blurRadius: 4,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: const Icon(
                                      Icons.directions_bus,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  // Bus info
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Bus ${busTrackingState?.selectedBus ?? 'N/A'}',
                                          style: const TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black87,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        // Status badge
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: _getStatusColor(
                                                    busTrackingState?.arrivalStatus ??
                                                        'On Time')
                                                .withOpacity(0.15),
                                            borderRadius: BorderRadius.circular(20),
                                            border: Border.all(
                                              color: _getStatusColor(
                                                  busTrackingState?.arrivalStatus ??
                                                      'On Time'),
                                              width: 1,
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                _getStatusIcon(
                                                    busTrackingState?.arrivalStatus ??
                                                        'On Time'),
                                                color: _getStatusColor(
                                                    busTrackingState?.arrivalStatus ??
                                                        'On Time'),
                                                size: 14,
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                busTrackingState?.arrivalStatus ??
                                                    'On Time',
                                                style: TextStyle(
                                                  color: _getStatusColor(
                                                      busTrackingState?.arrivalStatus ??
                                                          'On Time'),
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  // Action buttons - only show if bus hasn't arrived
                                  if (!busHasArrived)
                                    Column(
                                      children: [
                                        // Change Bus Button
                                        Container(
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.circular(10),
                                            border: Border.all(
                                                color: Colors.red.shade300, width: 1),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.grey.withOpacity(0.1),
                                                spreadRadius: 1,
                                                blurRadius: 3,
                                                offset: const Offset(0, 1),
                                              ),
                                            ],
                                          ),
                                          child: IconButton(
                                            onPressed: onChangeBus,
                                            icon: const Icon(Icons.swap_horiz,
                                                color: Colors.red, size: 18),
                                            tooltip: 'Change Bus',
                                            padding: const EdgeInsets.all(8),
                                            constraints: const BoxConstraints(
                                              minWidth: 36,
                                              minHeight: 36,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        // Return to Home Button
                                        Container(
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.circular(10),
                                            border: Border.all(
                                                color: Colors.grey.shade300, width: 1),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.grey.withOpacity(0.1),
                                                spreadRadius: 1,
                                                blurRadius: 3,
                                                offset: const Offset(0, 1),
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
                                            icon: Icon(Icons.home,
                                                color: Colors.grey[600], size: 18),
                                            tooltip: 'Return to Home',
                                            padding: const EdgeInsets.all(8),
                                            constraints: const BoxConstraints(
                                              minWidth: 36,
                                              minHeight: 36,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                ],
                              ),
                            ],
                          ),
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
                        // Trip info cards - only show if bus hasn't arrived
                        if (!busHasArrived) ...[
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              // Time card
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        Colors.blue.shade50,
                                        Colors.white,
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: Colors.blue.shade100),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.blue.withOpacity(0.1),
                                        spreadRadius: 1,
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: Colors.blue,
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: const Icon(
                                          Icons.access_time,
                                          color: Colors.white,
                                          size: 16,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        busTrackingState?.estimatedArrivalTime != null
                                            ? '${busTrackingState!.estimatedArrivalTime.round()} min'
                                            : 'N/A',
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black87,
                                        ),
                                      ),
                                      Text(
                                        'Estimated',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[600],
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              // Distance card
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        Colors.green.shade50,
                                        Colors.white,
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: Colors.green.shade100),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.green.withOpacity(0.1),
                                        spreadRadius: 1,
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: Colors.green,
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: const Icon(
                                          Icons.straighten,
                                          color: Colors.white,
                                          size: 16,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        busTrackingState?.distance != null
                                            ? '${busTrackingState!.distance.toStringAsFixed(1)} km'
                                            : 'N/A',
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black87,
                                        ),
                                      ),
                                      Text(
                                        'Distance',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[600],
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
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
              ),
            ],
          ),
        );
      },
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

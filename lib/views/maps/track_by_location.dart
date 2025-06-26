import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../state/user_location_state.dart';

final isMinimizedProvider = StateProvider<bool>((ref) {
  return false;
});

class TrackByLocation extends ConsumerStatefulWidget {
  const TrackByLocation({Key? key}) : super(key: key);

  @override
  _TrackByLocationState createState() => _TrackByLocationState();
}

class _TrackByLocationState extends ConsumerState<TrackByLocation> {
  late GoogleMapController _mapController;
  bool _mapInitialized = false;
  bool _isWidgetPushedDown = false; // To detect when the widget is pushed down

  @override
  Widget build(BuildContext context) {
    final locationState = ref.watch(locationProvider);
    final locationNotifier = ref.read(locationProvider.notifier);
    final isMinimized = ref.watch(isMinimizedProvider);

    if (_mapInitialized && locationState.currentLocation != null) {
      _mapController.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: locationState.currentLocation!,
            zoom: 15.0,
          ),
        ),
      );
    }

    return Scaffold(
      body: Stack(
        children: [
          // Google Map widget
          GoogleMap(
            onMapCreated: (GoogleMapController controller) {
              _mapController = controller;
              _mapInitialized = true;
              locationNotifier.getUserLocation();
            },
            initialCameraPosition: CameraPosition(
              target: locationState.currentLocation ??
                  const LatLng(37.7749, -122.4194), // Default to San Francisco
              zoom: 15.0,
            ),
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
          ),
          DraggableScrollableSheet(
            initialChildSize: 0.9, // Starting height
            minChildSize: 0.25, // Minimum height
            maxChildSize: 0.90, // Maximum height
            builder: (BuildContext context, ScrollController scrollController) {
              return LayoutBuilder(
                  builder: (BuildContext context, BoxConstraints constraints) {
                double height = constraints.maxHeight;

                // Determine if we are at minimum size
                bool isMinimized = height <= 0.3;
                ref.read(isMinimizedProvider.notifier).state = isMinimized;
                return Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(16.0),
                      topRight: Radius.circular(16.0),
                    ),
                  ),
                  child: SingleChildScrollView(
                    controller: scrollController,
                    child: Column(
                      children: [
                        // Gray strip indicating adjustability
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              vertical: 8.0), // Space around the strip
                          child: Container(
                            width: 50, // Width of the strip
                            height: 5, // Height of the strip
                            decoration: BoxDecoration(
                              color:
                                  Colors.grey[300], // Gray color for the strip
                              borderRadius:
                                  BorderRadius.circular(10), // Rounded corners
                            ),
                          ),
                        ),

                        // Row with back arrow and title
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // Back arrow
                              IconButton(
                                icon: Icon(Icons.arrow_back),
                                onPressed: () {
                                  Navigator.of(context).pop();
                                },
                              ),

                              // Centered bold title
                              Text(
                                'Set Destination',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 20,
                                ),
                              ),

                              // To keep the title centered, add a SizedBox
                              SizedBox(
                                  width: 48), // Balance the arrow icon size
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white, // White background
                              border: Border.all(
                                color: Colors.black, // Black border
                                width: 4.0, // Increased border width
                              ),
                              borderRadius: BorderRadius.circular(
                                  15.0), // Rounded corners
                            ),
                            child: Column(
                              children: [
                                // First line for "Current Location"
                                TextField(
                                  maxLines:
                                      1, // Allow single line input for the first line
                                  decoration: InputDecoration(
                                    hintText: "Current Location",
                                    hintStyle: TextStyle(
                                      height: 0.1,
                                      color: Colors.grey, // Gray hint color
                                    ),
                                    border: InputBorder.none, // No border
                                    contentPadding: EdgeInsets.symmetric(
                                      vertical: 0.1,
                                      horizontal: 20.0,
                                    ),
                                  ),
                                ),

                                // Divider
                                Divider(color: Colors.grey, thickness: 1),

                                // Second line for "Where to"
                                TextField(
                                  maxLines:
                                      1, // Allow single line input for the second line
                                  decoration: InputDecoration(
                                    hintText: "Where to",
                                    hintStyle: TextStyle(
                                      height: 0.1,
                                      color: Colors.grey, // Gray hint color
                                    ),
                                    border: InputBorder.none, // No border
                                    contentPadding: EdgeInsets.symmetric(
                                      vertical: 0.1,
                                      horizontal: 20.0,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        // Conditional content based on the draggable sheet size
                        if (isMinimized) ...[
                          // Show back arrow and title when not minimized
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                // Back arrow
                                IconButton(
                                  icon: Icon(Icons.arrow_back),
                                  onPressed: () {
                                    Navigator.of(context).pop();
                                  },
                                ),

                                // Centered bold title
                                Text(
                                  'Set Destination',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 20,
                                  ),
                                ),

                                // SizedBox to keep the title centered
                                SizedBox(width: 48),
                              ],
                            ),
                          ),

                          // Expanded ListView or scrollable content
                          // Expanded(
                          //   child: ListView.builder(
                          //     controller: scrollController,
                          //     itemCount: 25,
                          //     itemBuilder: (BuildContext context, int index) {
                          //       return ListTile(title: Text('Item $index'));
                          //     },
                          //   ),
                          // ),
                        ],
                        // ListView or scrollable content
                        ListView.builder(
                          controller: scrollController,
                          shrinkWrap:
                              true, // Allows the ListView to take up as much height as it needs
                          physics:
                              ClampingScrollPhysics(), // Disables bouncing behavior
                          itemCount: 10,
                          itemBuilder: (BuildContext context, int index) {
                            return ListTile(title: Text('Item $index'));
                          },
                        ),
                      ],
                    ),
                  ),
                );
              });
            },
          ),

          // Overlay widget for "Set your destination" and search
          // Positioned(
          //   top: 20, // Fixed top position for the search bar
          //   left: 10,
          //   right: 10,
          //   child: Container(
          //     padding: const EdgeInsets.all(10),
          //     decoration: BoxDecoration(
          //       color: Colors.white,
          //       borderRadius: BorderRadius.circular(8),
          //       boxShadow: [
          //         BoxShadow(
          //           color: Colors.black26,
          //           blurRadius: 4,
          //           offset: Offset(0, 4),
          //         ),
          //       ],
          //     ),
          //     child: Column(
          //       mainAxisSize: MainAxisSize.min,
          //       children: [
          //         const Text(
          //           'Set your destination',
          //           style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          //         ),
          //         const SizedBox(height: 10),
          //         TextField(
          //           decoration: InputDecoration(
          //             hintText: 'Where to?',
          //             prefixIcon: Icon(Icons.search),
          //             border: OutlineInputBorder(
          //               borderRadius: BorderRadius.circular(8),
          //             ),
          //           ),
          //           onSubmitted: (value) {
          //             // Implement search functionality
          //             setState(() {
          //               _isWidgetPushedDown = true;
          //             });
          //           },
          //         ),
          //       ],
          //     ),
          //   ),
          // ),

          // List of suggested locations below the search bar
          // if (_isWidgetPushedDown)
          //   Positioned(
          //     top: 200,
          //     left: 10,
          //     right: 10,
          //     child: Container(
          //       height: 300, // Height for the list
          //       padding: const EdgeInsets.all(10),
          //       decoration: BoxDecoration(
          //         color: Colors.white,
          //         borderRadius: BorderRadius.circular(8),
          //         boxShadow: [
          //           BoxShadow(
          //             color: Colors.black26,
          //             blurRadius: 4,
          //             offset: Offset(0, 4),
          //           ),
          //         ],
          //       ),
          //       child: ListView(
          //         children: [
          //           ListTile(
          //             leading: Icon(Icons.location_on),
          //             title: Text('St John\'s Apostolic Faith Mission'),
          //             subtitle: Text('Orlando, Soweto'),
          //             onTap: () {
          //               // Handle location tap
          //             },
          //           ),
          //           ListTile(
          //             leading: Icon(Icons.location_on),
          //             title: Text('22 Sloane Street'),
          //             subtitle: Text('Bryanston, City of Johannesburg'),
          //             onTap: () {
          //               // Handle location tap
          //             },
          //           ),
          //           ListTile(
          //             leading: Icon(Icons.location_on),
          //             title: Text('35 Wood Rd'),
          //             subtitle: Text('Blackheath, Randburg'),
          //             onTap: () {
          //               // Handle location tap
          //             },
          //           ),
          //           ListTile(
          //             leading: Icon(Icons.location_on),
          //             title: Text('Cresta Shopping Centre'),
          //             subtitle: Text('Randburg'),
          //             onTap: () {
          //               // Handle location tap
          //             },
          //           ),
          //           ListTile(
          //             leading: Icon(Icons.location_on),
          //             title: Text('64 Wolmarans St'),
          //             subtitle: Text('Hillbrow, Johannesburg'),
          //             onTap: () {
          //               // Handle location tap
          //             },
          //           ),
          //           ListTile(
          //             leading: Icon(Icons.location_on),
          //             title: Text('Royal Park Hotel'),
          //             subtitle: Text('Joubert Park, Johannesburg'),
          //             onTap: () {
          //               // Handle location tap
          //             },
          //           ),
          //           // Add more locations if needed
          //         ],
          //       ),
          //     ),
          //   ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }
}

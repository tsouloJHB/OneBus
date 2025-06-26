import 'dart:typed_data';
import 'dart:ui';

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:flutter/services.dart' show ByteData, rootBundle;
import 'package:flutter/services.dart' show SystemNavigator;

import 'services/bus_communication_services.dart';
import 'state/bus_info_state.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  late GoogleMapController _mapController;
  Location _location = Location();
  Set<Marker> markers = {}; // Declare the 'markers' variable here
  BitmapDescriptor? customMarkerIcon;
  List<dynamic> _busStopsCoordinates = [];
  List<Marker> _busStopMarkers = [];
  LatLng? previousLocation; // Track the previous location
  double totalDistance = 0.0; // Track the total distance traveled

  @override
  void initState() {
    super.initState();

    _createMarkerIcon(); // Load the custom marker icon
  }

  void startLocation() {
    _location.changeSettings(accuracy: LocationAccuracy.high, interval: 1000);
    _location.requestPermission().then((PermissionStatus status) {
      if (status == PermissionStatus.granted) {
        _location.onLocationChanged.listen((LocationData locationData) {
          setState(() {
            // Clear all markers
            markers.clear();

            // Create the custom marker
            Marker customMarker = Marker(
              markerId: const MarkerId("user_location"),
              position: LatLng(locationData.latitude!, locationData.longitude!),
              icon: customMarkerIcon ??
                  BitmapDescriptor.defaultMarkerWithHue(
                      BitmapDescriptor.hueAzure),
            );

            // Update the map's camera position to the user's location
            _mapController
                .animateCamera(
              CameraUpdate.newCameraPosition(
                CameraPosition(
                  target:
                      LatLng(locationData.latitude!, locationData.longitude!),
                  zoom: 15.0,
                ),
              ),
            )
                .then((_) {
              // Add the custom marker
              markers.add(customMarker);
            });

            // Calculate distance between consecutive locations
            if (previousLocation != null) {
              // double distance = _calculateDistance(
              //   previousLocation!,
              //   LatLng(locationData.latitude!, locationData.longitude!),
              // );

              // Send updates to the server if the distance threshold is exceeded
              // if (distance >= 10.0) {
              //   BusInfo busState = context.read<BusInfoState>().getBusInfo;
              //   BusPosition busPosition = BusPosition(
              //     busNumber: busState.busNumber,
              //     busId: busState.busId,
              //     latitude: locationData.latitude!.toString(),
              //     longitude: locationData.longitude!.toString(),
              //   );
              //   BusCommunicationServices.sendBusCoordinates(
              //       busPosition, busState);
              // }
            }

            previousLocation =
                LatLng(locationData.latitude!, locationData.longitude!);
          });
        });
      }
    });
  }

  void _createMarkers(busStopsCoordinates) {
    setState(() {
      _busStopMarkers = busStopsCoordinates.map((dynamic busStop) {
        dynamic coordinates = busStop["coordinates"];
        double latitude = coordinates["latitude"];
        double longitude = coordinates["longitude"];
        List bus = busStop["bus_numbers"];

        LatLng latLng = LatLng(latitude, longitude);

        return Marker(
          markerId: MarkerId(latLng.toString()),
          position: latLng,
          infoWindow: InfoWindow(title: 'Reya vaya', snippet: bus.toString()),
          onTap: () {},
        );
      }).toList();
    });
  }

  Future<void> _createMarkerIcon() async {
    _busStopsCoordinates = await BusCommunicationServices.getBusStopsFromJson();
    _createMarkers(_busStopsCoordinates);
    markers.addAll(_busStopMarkers);
    final ByteData imageData = await rootBundle.load('assets/busIcon.png');
    final Uint8List byteData = imageData.buffer.asUint8List();
    final Codec codec = await instantiateImageCodec(
      byteData,
      targetHeight: 50, // Increased from 23 to 50
    );
    final FrameInfo frameInfo = await codec.getNextFrame();
    final ByteData? resizedImageData =
        await frameInfo.image.toByteData(format: ImageByteFormat.png);
    final Uint8List? resizedByteData = resizedImageData?.buffer.asUint8List();
    final BitmapDescriptor icon = BitmapDescriptor.fromBytes(resizedByteData!);
    setState(() {
      customMarkerIcon = icon;
    });
  }

  double _toRadians(double degree) {
    return degree * (math.pi / 180);
  }

  void _sendLocationUpdateToServer(double latitude, double longitude) {
    // Implement your logic to send location updates to the server
    // using HTTP requests or WebSocket connections.
    // Use the 'latitude' and 'longitude' values to send the updated location.
    // Example:
    // HttpClient client = HttpClient();
    // client.postUrl(Uri.parse('your_server_url')).then((HttpClientRequest request) {
    //   // Add necessary headers and parameters to the request
    //   request.headers.set('Content-Type', 'application/json');
    //   request.write('{"latitude": $latitude, "longitude": $longitude}');
    //
    //   // Send the request
    //   return request.close();
    // }).then((HttpClientResponse response) {
    //   // Process the response from the server
    //   // ...
    // }).catchError((error) {
    //   // Handle any errors that occur during the request
    //   // ...
    // });
  }

  @override
  Widget build(BuildContext context) {
    final busInfo = ref.watch(busInfoProvider);
    return Stack(
      children: [
        GoogleMap(
          onMapCreated: (GoogleMapController controller) {
            _mapController = controller;
            startLocation();
          },
          initialCameraPosition: CameraPosition(
            target: LatLng(0, 0), // Initial camera position
            zoom: 15.0,
          ),
          myLocationEnabled: false, // Show the user's location button
          myLocationButtonEnabled: false, // Hide the default location button
          markers: markers,
        ),
        Positioned(
          top: 32,
          left: 16,
          child: Material(
            shape: CircleBorder(),
            color: Colors.white,
            child: IconButton(
              icon: Icon(
                Icons.menu,
                color: Colors.black,
              ),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) {
                    return AlertDialog(
                      title: Text('Menu'),
                      content: Text('Options'),
                      actions: [
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context); // Close the dialog
                          },
                          child: Text('Close'),
                        ),
                        TextButton(
                          onPressed: closeApp,
                          child: Text('Close App'),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ),
        ),
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            height: 200,
            width: double.infinity, // Increase the height as desired
            color: Colors.white,
            child: Padding(
              padding: const EdgeInsets.all(21.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Bus ride started',
                    style: TextStyle(
                        color: Colors.black,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        decoration: TextDecoration.none),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        "Bus Number: ${busInfo.busNumber}", // Access the desired value from BusInfo
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 14,
                          decoration: TextDecoration.none,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 0),
                  const Text(
                    'Bus driver info',
                    style: TextStyle(
                        color: Colors.grey,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        decoration: TextDecoration.none),
                  ),
                  SizedBox(height: 38),
                  Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(25),
                        child: Image.asset(
                          'assets/profilepicture1.png',
                          width: 50,
                          height: 50,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        busInfo.name, // Access the desired value from BusInfo
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 14,
                          decoration: TextDecoration.none,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  void closeApp() {
    // Close the app
    SystemNavigator.pop();
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';


import '../../../state/track_bus_state.dart';
import 'route_plan_widget.dart';
import '../../../controllers/bus_tracking_controller.dart';

class SearchLocation extends ConsumerStatefulWidget {
  final VoidCallback onClose;

  const SearchLocation({Key? key, required this.onClose}) : super(key: key);

  @override
  ConsumerState<SearchLocation> createState() => _SearchLocationState();
}

class _SearchLocationState extends ConsumerState<SearchLocation> {
  final TextEditingController _currentLocationController =
      TextEditingController(); // For the current location field
  final TextEditingController _destinationController =
      TextEditingController(); // For the destination field
  // Hard-coded list of locations for search results
  final List<Map<String, dynamic>> _allResults = [
    {
      'name': 'Bus station/stop',
      'icon': null,
      'image': 'assets/images/bus_stop.png'
    },
    {'name': 'Los Angeles', 'icon': null, 'image': null},
    {'name': 'Chicago', 'icon': null, 'image': null},
    {'name': 'Philadelphia', 'icon': null, 'image': null},
    {'name': 'San Antonio', 'icon': null, 'image': null},
    {'name': 'Dallas', 'icon': null, 'image': null},
  ];

  List<Map<String, dynamic>> _filteredResults = [];
  late BusTrackingController _controller;

  // Search query
  void _onSearchQueryChanged(String query) {
    setState(() {
      _filteredResults = _allResults
          .where((location) =>
              location['name'].toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  void _onResultSelected(Map<String, dynamic> result) {
    // Example: Navigate to another page or update the UI
    String currentLocation = _currentLocationController.text;
    String destination = _destinationController.text;

    print('Selected Result: ${result['name']}');
    print('Current Location: $currentLocation');
    print('Destination: $destination');

    // Update state or navigate

    result['name']; // Example of updating a selected location
    ref.read(locationScreenStepProvider.notifier).state = 2;
    // Navigate to a new screen (if needed)
    // Navigator.push(context, MaterialPageRoute(builder: (context) => DetailsPage(result: result)));
  }

  @override
  void initState() {
    super.initState();
    _filteredResults = _allResults; // Show all results initially
    _controller = BusTrackingController(ref);
  }

  // Update the step navigation
  void _goToNextStep() {
    _controller.nextLocationStep();
  }

  @override
  Widget build(BuildContext context) {
    final currentStep = ref.watch(locationScreenStepProvider);

    return Stack(
      children: [
        Positioned(
          top: 220, // Adjust this to move results down slightly
          left: 0,
          right: 0,
          child: Material(
              color: Colors.white, // Set white background
              elevation: 4, // Add elevation for a shadow effect
              child: _filteredResults.isEmpty
                  ? Center(child: Text('No results found.'))
                  : SizedBox(
                      height: 800, // Adjust the height as needed
                      width: double.infinity,
                      child: ListView.separated(
                        itemCount: _filteredResults.length,
                        itemBuilder: (context, index) {
                          final result = _filteredResults[index];
                          return ListTile(
                            leading: result['icon'] != null
                                ? Icon(result['icon'],
                                    color: Colors.black) // FontAwesome icon
                                : result['image'] != null
                                    ? Image.asset(
                                        result['image'],
                                        width: 20,
                                        height: 20,
                                      ) // PNG image
                                    : Icon(Icons.location_on,
                                        color: Colors.grey), // Fallback icon
                            title: Text(result['name']),
                            subtitle: result.containsKey('subtitle') &&
                                    result['subtitle'] != null
                                ? Text(result['subtitle'],
                                    style: TextStyle(color: Colors.grey))
                                : null,
                            onTap: () {
                              // Perform action when a result is clicked
                              _onResultSelected(result);
                            }, // Optional subtitle
                          );
                        },
                        separatorBuilder: (context, index) => Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16.0), // Left and right padding
                          child: Divider(
                            height: 1, // Adjust the height of the divider
                            thickness: 1, // Adjust the thickness of the divider
                            color: Colors.grey[300], // Light grey divider
                          ),
                        ),
                      ),
                    )),
        ),
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: Material(
            color: Colors.white,
            elevation: 4,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 50),
                // Header Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.close),
                      iconSize: 28, // Increase icon size
                      onPressed: widget.onClose,
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        "Enter destination",
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                  ],
                ),
                // Location Inputs with Icons
                Padding(
                  padding: const EdgeInsets.fromLTRB(10, 10, 10, 0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Left Icons with Dotted Line
                      // Space between edge and icons
                      Column(
                        children: [
                          SizedBox(height: 5),
                          Icon(Icons.circle,
                              color: Colors.purple,
                              size: 20), // Current location icon
                          CustomPaint(
                            size: Size(
                                2, 55), // Width and height of the dotted line
                            painter: DottedLinePainter(),
                          ),
                          Icon(Icons.location_on,
                              color: Colors.orange,
                              size: 30), // Destination icon
                        ],
                      ),
                      SizedBox(width: 2), // Space between icons and text fields
                      // Input Fields
                      Expanded(
                        child: Column(
                          children: [
                            // Current Location Input
                            FocusAwareTextField(
                              hintText: "Enter current location",
                              controller: _currentLocationController,
                              defaultIcon: UnconstrainedBox(
                                child: SizedBox(
                                  width: 20,
                                  height: 25,
                                  child: Image.asset(
                                    'assets/images/location.png', // Add your image
                                    height: 14,
                                    width: 14,
                                  ),
                                ),
                              ),
                              focusIcon: Icon(Icons.search, size: 28),
                              onChanged: (String query) =>
                                  _onSearchQueryChanged(query),
                            ),
                            SizedBox(height: 8), // Space between inputs
                            // Destination Input
                            FocusAwareTextField(
                              hintText: "Enter destination",
                              controller: _destinationController,
                              defaultIcon: UnconstrainedBox(
                                child: SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                          color: Colors.grey, width: 1.5),
                                      color: Colors.grey.withOpacity(0.3),
                                    ),
                                  ),
                                ),
                              ),
                              focusIcon: Icon(Icons.search, size: 28),
                              onChanged: (query) {},
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 10),
              ],
            ),
          ),
        ),

        // Display Search Results
      ],
    );
  }
}

class FocusAwareTextField extends StatefulWidget {
  final String hintText;
  final Widget defaultIcon;
  final Widget focusIcon;
  final TextEditingController controller;

  const FocusAwareTextField({
    Key? key,
    required this.controller,
    required this.hintText,
    required this.defaultIcon,
    required this.focusIcon,
    required this.onChanged,
  }) : super(key: key);

  final void Function(String query) onChanged;

  @override
  _FocusAwareTextFieldState createState() => _FocusAwareTextFieldState();
}

class _FocusAwareTextFieldState extends State<FocusAwareTextField> {
  final FocusNode _focusNode = FocusNode();
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      setState(() {
        _isFocused = _focusNode.hasFocus;
      });
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      focusNode: _focusNode,
      controller: widget.controller,
      decoration: InputDecoration(
        hintText: widget.hintText,
        hintStyle: TextStyle(color: Colors.grey.shade400),
        prefixIcon: _isFocused ? widget.focusIcon : widget.defaultIcon,
        filled: true,
        fillColor: const Color.fromARGB(255, 243, 243, 243),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.red, width: 2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.red, width: 2),
        ),
      ),
    );
  }
}

// Dotted Line Painter
class DottedLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    double dashHeight = 4, dashSpace = 4, startY = 0;
    final paint = Paint()
      ..color = Colors.grey
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    while (startY < size.height) {
      canvas.drawLine(
        Offset(0, startY),
        Offset(0, startY + dashHeight),
        paint,
      );
      startY += dashHeight + dashSpace;
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

class LocationTrackingConfirmView extends ConsumerWidget {
  final String destination;
  final String startLocation;
  final List<String> interChanges = [
    "Interchange 1",
    "Interchange 1",
    "Interchange 1",
    "Interchange 1",
    "Interchange 1",
    "Interchange 1",
    "Interchange 1",
    "Interchange 1",
  ];

  LocationTrackingConfirmView({
    Key? key,
    required this.startLocation,
    required this.destination,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = BusTrackingController(ref);
    double containerHeightConst = 280;
    int listLength = interChanges.length;
    // num containerDynamicHeight = (interChanges.length + 2) *
    //     (listLength == 0 ? 35 : 35 * (1.3 * listLength));
    num containerDynamicHeight = (listLength + 2) * (50 + 3 * listLength);

    double screenHeight = MediaQuery.of(context).size.height;
    double dynamicChildSize =
        ((containerDynamicHeight + containerHeightConst) / screenHeight)
            .clamp(0.1, 0.98);
    print(dynamicChildSize);
    return DraggableScrollableSheet(
      initialChildSize: dynamicChildSize, // Initial size of the bottom sheet
      minChildSize: 0.3, // Minimum size
      maxChildSize: 1, // Maximum size (fits the content)
      builder: (BuildContext context, ScrollController scrollController) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20.0),
              topRight: Radius.circular(20.0),
            ),
          ),
          height: containerDynamicHeight + containerHeightConst,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle for dragging
              Container(
                width: 50,
                height: 5,
                margin: const EdgeInsets.only(bottom: 16.0),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(10),
                ),
              ),

              // Header
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  const Expanded(
                    child: Text(
                      "Confirm Your Route",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 48), // Spacer for symmetry
                ],
              ),

              const SizedBox(height: 70.0),
              SizedBox(
                height: screenHeight / 2.2,
                child: RoutePlanWidget(
                  startLocation: startLocation,
                  destination: destination,
                  interchanges: interChanges,
                ),
              ),

              // Route Plan
              // Row(
              //   crossAxisAlignment: CrossAxisAlignment.start,
              //   children: [
              //     Column(
              //       children: [
              //         Icon(
              //           Icons.circle,
              //           color: Colors.purple,
              //           size: 20,
              //         ), // Current location icon
              //         CustomPaint(
              //           size: const Size(2, 50),
              //           painter: DottedLinePainter(),
              //         ),
              //         Icon(
              //           Icons.directions_bus,
              //           color: Colors.blue,
              //           size: 30,
              //         ),

              //         CustomPaint(
              //           size: const Size(2, 50),
              //           painter: DottedLinePainter(),
              //         ),
              //         Icon(
              //           Icons.directions_bus,
              //           color: Colors.blue,
              //           size: 30,
              //         ), // Bus interchange icon
              //         CustomPaint(
              //           size: const Size(2, 50),
              //           painter: DottedLinePainter(),
              //         ),
              //         Icon(
              //           Icons.location_on,
              //           color: Colors.orange,
              //           size: 30,
              //         ), // Destination icon
              //       ],
              //     ),
              //     const SizedBox(width: 16.0),
              //     Expanded(
              //       child: Column(
              //         crossAxisAlignment: CrossAxisAlignment.start,
              //         children: [
              //           Text(
              //             "Start Location: $startLocation",
              //             style: const TextStyle(
              //               fontSize: 16.0,
              //               fontWeight: FontWeight.bold,
              //             ),
              //           ),
              //           const SizedBox(height: 16.0),
              //           Text(
              //             "Bus Interchange: Milpark Station",
              //             style: const TextStyle(
              //               fontSize: 16.0,
              //               color: Colors.grey,
              //             ),
              //           ),
              //           const SizedBox(height: 16.0),
              //           Text(
              //             "Bus Interchange: Milpark Station",
              //             style: const TextStyle(
              //               fontSize: 16.0,
              //               color: Colors.grey,
              //             ),
              //           ),
              //           const SizedBox(height: 16.0),
              //           Text(
              //             "Destination: $destination",
              //             style: const TextStyle(
              //               fontSize: 16.0,
              //               fontWeight: FontWeight.bold,
              //             ),
              //           ),
              //         ],
              //       ),
              //     ),
              //   ],
              // ),

              const SizedBox(height: 24.0),

              // Navigate to bus stop text
              const Text(
                "Navigate to bus stop",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.blue,
                ),
              ),

              const SizedBox(height: 24.0),

              // Confirm Button
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.withOpacity(0.7),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.0),
                    side: const BorderSide(color: Colors.red),
                  ),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 40.0, vertical: 12.0),
                ),
                onPressed: () {
                  // Confirm button action
                  print("Route confirmed");
                  ref.read(selectedBusState.notifier).state = "C5";
                  controller.nextLocationStep();
                },
                child: const Text(
                  "Confirm",
                  style: TextStyle(
                    fontSize: 16.0,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              const SizedBox(height: 16.0),
            ],
          ),
        );
      },
    );
  }
}

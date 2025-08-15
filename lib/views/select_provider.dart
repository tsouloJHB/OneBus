import 'package:flutter/material.dart';
import 'package:onebus/controllers/bus_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'home.dart';

class SelectProviderScreen extends ConsumerWidget {
  final List<Map<String, String>> providers = [
    {
      "name": "metrobus",
      "image": "assets/images/metrobus.png",
      "height": "80",
      "width": "150"
    },
    {
      "name": "putco",
      "image": "assets/images/putco.png",
      "height": "50",
      "width": "190"
    },
    {
      "name": "rea vaya",
      "image": "assets/images/rea_yea_vaya.png",
      "height": "80",
      "width": "100"
    },
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    BusController busController = BusController(ref);
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.red.shade100, // Light color at the top
              Colors.white, // Fades into white
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Image.asset('assets/images/driverprovider.png',
                  height: 200, width: 200),
              Text(
                'Choose a bus provider:',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 20),
              Expanded(
                child: ListView.builder(
                  itemCount: providers.length,
                  itemBuilder: (context, index) {
                    final provider = providers[index];
                    final imageHeight =
                        double.tryParse(provider['height']!) ?? 80.0;
                    final imageWidth =
                        double.tryParse(provider['width']!) ?? 80.0;

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 15.0),
                      child: GestureDetector(
                        onTap: () async {
                          // Handle selection
                          print('Selected: ${provider['name']}');

                          // Show loading dialog
                          showDialog(
                            context: context,
                            barrierDismissible: false,
                            builder: (BuildContext context) {
                              return AlertDialog(
                                content: Row(
                                  children: [
                                    CircularProgressIndicator(),
                                    SizedBox(width: 20),
                                    Text('Loading bus routes...'),
                                  ],
                                ),
                              );
                            },
                          );

                          try {
                            // Set the bus company
                            busController.setBusComapny(provider['name']!);

                            // Fetch bus routes for the selected company
                            final buses =
                                await busController.getAvailableBuses();
                            print(
                                'Fetched ${buses.length} buses for ${provider['name']}');

                            // Close loading dialog
                            Navigator.of(context).pop();

                            // Navigate to home screen
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => const HomeScreen()),
                            );
                          } catch (e) {
                            // Close loading dialog
                            Navigator.of(context).pop();

                            // Show error dialog
                            showDialog(
                              context: context,
                              builder: (BuildContext context) {
                                return AlertDialog(
                                  title: Text('Error'),
                                  content: Text(
                                      'Failed to load bus routes. Using default list.'),
                                  actions: [
                                    TextButton(
                                      onPressed: () {
                                        Navigator.of(context).pop();
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                              builder: (context) =>
                                                  const HomeScreen()),
                                        );
                                      },
                                      child: Text('Continue'),
                                    ),
                                  ],
                                );
                              },
                            );
                          }
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.transparent, // Transparent background
                            border: Border.all(
                              color: Colors.red, // Red border
                              width: 2.0,
                            ),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          height: 120,
                          width: 100,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Image.asset(
                                provider['image']!,
                                height: imageHeight,
                                width: imageWidth,
                                fit: BoxFit.cover,
                              ),
                              SizedBox(width: 20),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

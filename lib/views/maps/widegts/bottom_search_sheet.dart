import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:onebus/constants/app_cosntants.dart';
import 'package:onebus/state/track_bus_state.dart';
import 'package:onebus/state/screen_state.dart';
import '../track_bus.dart';
import '../../home.dart';

Future<List<LatLng>> loadBusPath(String bus) async {
  final data =
      await rootBundle.loadString('lib/models/data/reyaVayaPaths.json');
  final jsonResult = json.decode(data);
  final List<dynamic> coords = jsonResult[bus]['Northbound']['coordinates'];
  return coords.map((c) => LatLng(c['lat'], c['lng'])).toList();
}

final containerHeightProvider = StateProvider<double>((ref) {
  return 10;
});

class BottomSearchSheet extends ConsumerWidget {
  final List<String> filteredBuses;
  final TextEditingController searchController;
  final Function(String) onSearchChanged;
  final Function() onSearchPressed;
  final Function(String) onBusSelected;

  const BottomSearchSheet({
    Key? key,
    required this.filteredBuses,
    required this.searchController,
    required this.onSearchChanged,
    required this.onSearchPressed,
    required this.onBusSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedBus = ref.watch(selectedBusStateProvider);
    final currentTrackedBus = ref.watch(currentTrackedBusProvider);

    return DraggableScrollableSheet(
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
              // Draggable handle
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

              // Back button and title
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const HomeScreen()),
                        );
                      },
                    ),
                  ],
                ),
              ),

              // Title text
              const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Search ",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 30,
                    ),
                  ),
                  Text(
                    "By bus number",
                    style: TextStyle(
                      fontSize: 30,
                    ),
                  ),
                ],
              ),
              const Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  SizedBox(width: 50),
                  Text(
                    "below ",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 30,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Search bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Container(
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
                  child: TextField(
                    controller: searchController,
                    onChanged: onSearchChanged,
                    decoration: InputDecoration(
                      hintText: 'Search by bus number',
                      prefixIcon: const Icon(
                        Icons.search,
                        color: Colors.grey,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(28),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Filtered bus list
              Expanded(
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                  ),
                  child: ListView.builder(
                    controller: scrollController,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20.0, vertical: 10.0),
                    itemCount: filteredBuses.length,
                    itemBuilder: (context, index) {
                      final bus = filteredBuses[index];
                      final isSelected = bus == selectedBus;
                      final isTracked = bus == currentTrackedBus;

                      return Container(
                        margin: const EdgeInsets.symmetric(
                            vertical: 4, horizontal: 2),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Colors.green.withOpacity(0.1)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected ? Colors.blue : Colors.red,
                            width: 3,
                          ),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 8),
                          title: Text(
                            'Bus $bus',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              color: isSelected ? Colors.green : Colors.black,
                            ),
                          ),
                          trailing: isTracked
                              ? const Icon(Icons.gps_fixed, color: Colors.green)
                              : isSelected
                                  ? const Icon(Icons.check_circle,
                                      color: Colors.green)
                                  : null,
                          onTap: () {
                            ref.read(selectedBusStateProvider.notifier).state =
                                bus;
                            onBusSelected(bus);
                          },
                        ),
                      );
                    },
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

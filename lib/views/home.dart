import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:onebus/state/track_bus_state.dart';
import 'package:onebus/state/screen_state.dart';
import 'addRoute.dart';
import 'maps/track_bus.dart';
import 'maps/track_by_location.dart';
import 'package:onebus/controllers/bus_controller.dart';
import 'package:onebus/controllers/bus_tracking_controller.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  void initState() {
    super.initState();

    // Clear all tracking state when returning to home
    WidgetsBinding.instance.addPostFrameCallback((_) {
      print("DEBUG: Home screen initialized - clearing tracking state");
      BusTrackingController(ref).clearAllTrackingState();
    });
  }

  @override
  Widget build(BuildContext context) {
    final FocusNode searchFocusNode = FocusNode();
    BusController busController = BusController(ref);
    String busCompany = busController.getBusCompany();
    return Scaffold(
      backgroundColor: Colors.white,
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
        child: SingleChildScrollView(
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.all(30.0),
                child: Column(
                  children: [
                    SizedBox(height: 50),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Text "One Bus" with line break
                        const Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'One',
                              style: TextStyle(
                                  fontSize: 40.0,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green),
                            ),
                            SizedBox(width: 1),
                            Text(
                              'Bus',
                              style: TextStyle(
                                  fontSize: 40.0, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),

                        // Bell icon aligned with the top of the text
                        Align(
                          alignment: Alignment.topCenter,
                          child: Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.grey[300],
                            ),
                            padding: EdgeInsets.all(10.0),
                            child: Icon(
                              Icons.notifications,
                              size: 30.0,
                              color: Colors.grey[600],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Row(children: [
                      Text('Good morning',
                          style: TextStyle(
                            fontSize: 20.0,
                            fontWeight: FontWeight.bold,
                          )),
                    ]),
                    const Row(children: [
                      Text('Junior',
                          style: TextStyle(
                            fontSize: 20.0,
                            color: Colors.red,
                          )),
                    ]),
                    Image.asset('assets/busCity4.png'),
                    SizedBox(height: 40),
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20.0),
                        color: const Color.fromARGB(255, 255, 255, 255),
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
                        focusNode: searchFocusNode,
                        readOnly: true,
                        decoration: InputDecoration(
                          hintText: 'Where to?',
                          prefixIcon: const Icon(Icons.search),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20.0),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 30),
                    Center(
                      child: Column(
                        children: [
                          RichText(
                            text: TextSpan(
                              children: <TextSpan>[
                                TextSpan(
                                    text: 'Find any ',
                                    style: TextStyle(
                                        fontSize: 20, color: Colors.black)),
                                TextSpan(
                                    text: busCompany,
                                    style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black)),
                                TextSpan(
                                    text: ' bus',
                                    style: TextStyle(
                                        fontSize: 20, color: Colors.black)),
                              ],
                            ),
                          )
                        ],
                      ),
                    ),
                    SizedBox(height: 20),
                    Column(
                      children: [
                        _buildTile(
                          FontAwesomeIcons.bus,
                          text: 'Track bus',
                          onTap: () {
                            ref
                                .read(currentScreenStateProvider.notifier)
                                .state = ScreenState.searchBus;
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => const TrackBus(
                                        currentScreen: 'track bus',
                                      )),
                            );
                          },
                        ),
                        _buildTile(
                          FontAwesomeIcons.creditCard,
                          text: 'Pay now',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => AddRouteScreen()),
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.white, // Set the background color to white
        items: <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: FaIcon(
              FontAwesomeIcons.house,
              size: 20,
              color: _selectedIndex == 0
                  ? Colors.green
                  : Colors.grey, // Green for selected, grey for unselected
            ),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: FaIcon(
              FontAwesomeIcons.gear,
              size: 20,
              color: _selectedIndex == 1
                  ? Colors.green
                  : Colors.grey, // Green for selected, grey for unselected
            ),
            label: 'Settings',
          ),
          BottomNavigationBarItem(
            icon: FaIcon(
              FontAwesomeIcons.user,
              size: 20,
              color: _selectedIndex == 2
                  ? Colors.green
                  : Colors.grey, // Green for selected, grey for unselected
            ),
            label: 'Profile',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.green, // Green text for selected item
        unselectedItemColor: Colors.grey, // Grey text for unselected items
        onTap: _onItemTapped,
      ),
    );
  }

  Widget _buildTile(
    IconData icon, {
    required String text,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 20.0),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15.0),
          color: const Color.fromARGB(255, 255, 255, 255), // White background
          border: Border.all(
            color: Colors.red, // Red border color
            width: 3.0, // Border width
          ),
        ),
        child: ListTile(
          leading: FaIcon(
            icon,
            color: const Color.fromARGB(255, 6, 6, 6),
            size: 30,
          ),
          title: Center(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 20.0,
                color: const Color.fromARGB(255, 8, 8, 8),
              ),
            ),
          ),
          trailing: const Icon(
            Icons.arrow_forward,
            color: Colors.green,
          ),
          onTap: onTap,
        ),
      ),
    );
  }
}

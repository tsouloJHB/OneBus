import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:onebus/state/track_bus_state.dart';
import 'package:onebus/state/screen_state.dart';
import 'addRoute.dart';
import 'select_provider.dart';
import 'track_history_screen.dart';
import 'payment_screen.dart';
import 'profile_screen.dart';
import 'settings_screen.dart';
import 'auth/login.dart';
import 'maps/track_bus.dart';
import 'maps/track_by_location.dart';
import 'package:onebus/controllers/bus_controller.dart';
import 'package:onebus/controllers/bus_tracking_controller.dart';
import 'package:onebus/services/auth_service.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> with SingleTickerProviderStateMixin {
  int _selectedIndex = 0;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  static bool _hasAnimated = false; // Flag to ensure it only animates once per session

  final _authService = AuthService();
  String _userName = '';
  String _greeting = '';
  late ScrollController _scrollController;
  double _scrollOffset = 0.0;

    void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    
    // Handle navigation based on selected index
    switch (index) {
      case 0:
        // Home - already on home screen
        break;
      case 1:
        // Settings - navigate to settings screen
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => SettingsScreen()),
        );
        break;
      case 2:
        // Profile - navigate to profile screen
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => ProfileScreen()),
        );
        break;
    }
  }

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    if (!_hasAnimated) {
      _animationController.forward();
      _hasAnimated = true;
    } else {
      _animationController.value = 1.0;
    }

    _setGreeting();
    _loadUserData();

    _scrollController = ScrollController()
      ..addListener(() {
        if (mounted) {
          setState(() {
            _scrollOffset = _scrollController.offset;
          });
        }
      });

    // Clear all tracking state when returning to home
    WidgetsBinding.instance.addPostFrameCallback((_) {
      print("DEBUG: Home screen initialized - clearing tracking state");
      BusTrackingController(ref).clearAllTrackingState();
    });
  }

  void _setGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      _greeting = 'Good morning';
    } else if (hour < 17) {
      _greeting = 'Good afternoon';
    } else {
      _greeting = 'Good evening';
    }
  }

  Future<void> _loadUserData() async {
    final userData = await _authService.getUserData();
    if (userData != null && userData['fullName'] != null) {
      if (mounted) {
        setState(() {
          _userName = userData['fullName'];
        });
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final FocusNode searchFocusNode = FocusNode();
    BusController busController = BusController(ref);
    String busCompany = busController.getBusCompany();
    return Scaffold(
      backgroundColor: Colors.white,
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Container(
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
          controller: _scrollController,
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

                        // Logout icon aligned with the top of the text
                        Align(
                          alignment: Alignment.topCenter,
                          child: GestureDetector(
                            onTap: () async {
                              await _authService.logout();
                              if (mounted) {
                                Navigator.of(context).pushAndRemoveUntil(
                                  MaterialPageRoute(builder: (context) => LoginPage()),
                                  (route) => false,
                                );
                              }
                            },
                            child: const Padding(
                              padding: EdgeInsets.all(10.0),
                              child: FaIcon(
                                FontAwesomeIcons.signOut,
                                size: 30.0,
                                color: Colors.red,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    Row(children: [
                      Text('$_greeting',
                          style: const TextStyle(
                            fontSize: 20.0,
                            fontWeight: FontWeight.bold,
                          )),
                    ]),
                    Row(children: [
                      Text(_userName.isNotEmpty ? _userName : 'User',
                          style: const TextStyle(
                            fontSize: 20.0,
                            color: Colors.red,
                          )),
                    ]),
                    Transform.translate(
                      offset: Offset(0, _scrollOffset * 0.3),
                      child: Image.asset('assets/busCity4.png'),
                    ),
                    SizedBox(height: 40),
                    // Location search input
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
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const TrackBus(
                                currentScreen: 'where to',
                              ),
                            ),
                          );
                        },
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
                    // Action Buttons Column
                    const SizedBox(height: 20),
                    _buildTile(
                      FontAwesomeIcons.bus,
                      text: 'Track bus',
                      onTap: () {
                        ref.read(currentScreenStateProvider.notifier).state =
                            ScreenState.searchBus;
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
                      FontAwesomeIcons.clockRotateLeft,
                      text: 'Track History',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const TrackHistoryScreen()),
                        );
                      },
                    ),
                    
                    // Company Selection Button
                    _buildTile(
                      FontAwesomeIcons.building,
                      text: 'Company',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) =>
                                  const SelectProviderScreen()),
                        );
                      },
                    ),
                    const SizedBox(height: 50), // Extra space at bottom
                  ],
                ),
              ),
            ],
          ),
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
            color: Colors.red[900],
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

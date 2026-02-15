import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:onebus/controllers/bus_controller.dart';
import 'package:onebus/services/bus_route_service.dart';

import 'home.dart';

class SelectProviderScreen extends ConsumerStatefulWidget {
  const SelectProviderScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<SelectProviderScreen> createState() => _SelectProviderScreenState();
}

class _SelectProviderScreenState extends ConsumerState<SelectProviderScreen> with SingleTickerProviderStateMixin {
  // Local fallback providers
  final List<Map<String, String>> _fallbackProviders = [
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

  List<Map<String, String>> _providers = [];
  bool _loading = true;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _loadProviders();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadProviders() async {
    setState(() {
      _loading = true;
    });

    try {
      // Fetch companies from backend endpoint `/api/bus-companies/active`
      final serverProviders = await BusRouteService.getBusCompanies();
      if (!mounted) return;
      if (serverProviders.isNotEmpty) {
        setState(() {
          _providers = serverProviders;
          _loading = false;
        });
        // Start animation after data loads
        _animationController.forward();
        return;
      }
      // If server returned empty list, try fallback
      print('[WARN] Server returned no bus companies, using local fallback');
    } catch (e) {
      print('[ERROR] Failed to fetch bus companies: $e');
      // Error occurred, show fallback with notification
    }
    
    // Fallback to local providers
    if (!mounted) return;
    setState(() {
      _providers = _fallbackProviders;
      _loading = false;
    });
    
    // Start animation after data loads
    _animationController.forward();
    
    // Show notification that using offline data
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.warning, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'No internet connection. Using offline bus company data.',
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
          backgroundColor: Colors.orange.shade700,
          duration: const Duration(seconds: 4),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
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
              Column(
                children: [
                  SizedBox(height: 50),
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
                ],
              ),
              SizedBox(height: 20),
              Expanded(
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : ListView.builder(
                        itemCount: _providers.length,
                        itemBuilder: (context, index) {
                          final provider = _providers[index];
                            // Keep aspect ratio while fitting inside the row; cap by container height.
                            final imageHeight =
                              double.tryParse(provider['height'] ?? '') ?? 100.0;
                            final imageWidth =
                              double.tryParse(provider['width'] ?? '') ?? 180.0;

                          // Create staggered animation for each item
                          final animation = Tween<double>(
                            begin: 0.0,
                            end: 1.0,
                          ).animate(
                            CurvedAnimation(
                              parent: _animationController,
                              curve: Interval(
                                (index / _providers.length) * 0.5,
                                ((index + 1) / _providers.length) * 0.5 + 0.5,
                                curve: Curves.easeOut,
                              ),
                            ),
                          );

                          return AnimatedBuilder(
                            animation: animation,
                            builder: (context, child) {
                              return Opacity(
                                opacity: animation.value,
                                child: Transform.translate(
                                  offset: Offset(0, 50 * (1 - animation.value)),
                                  child: child,
                                ),
                              );
                            },
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 15.0),
                              child: GestureDetector(
                                onTap: () {
                                  final providerName = provider['name'] ?? '';
                                  final companyIdentifier = providerName;

                                  // Set the selected company in the state
                                  ref.read(selectedBusCompanyState.notifier).state = companyIdentifier;

                                  // Navigate to home screen
                                  Navigator.of(context).pushReplacement(
                                    MaterialPageRoute(builder: (_) => const HomeScreen()),
                                  );
                                },
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.transparent,
                                    border: Border.all(
                                      color: Colors.red,
                                      width: 2.0,
                                    ),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  height: 120,
                                  width: double.infinity,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      (provider['image'] != null &&
                                              provider['image']!.startsWith('http'))
                                          ? SizedBox(
                                              height: imageHeight,
                                              width: imageWidth,
                                              child: Image.network(
                                                provider['image']!,
                                                fit: BoxFit.contain,
                                              ),
                                            )
                                          : Flexible(
                                              child: Center(
                                                child: Text(
                                                  provider['name'] ?? '',
                                                  style: const TextStyle(
                                                    fontSize: 28,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ),
                                      const SizedBox(width: 20),       
                                    ],
                                  ),
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

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

class _SelectProviderScreenState extends ConsumerState<SelectProviderScreen> {
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

  @override
  void initState() {
    super.initState();
    _loadProviders();
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

                          return Padding(
                            padding:
                                const EdgeInsets.symmetric(vertical: 15.0),
                            child: GestureDetector(
                              onTap: () {
                                final providerName = provider['name'] ?? '';
                                final companyIdentifier = providerName;

                                // Set the selected company in the state
                                ref.read(selectedBusCompanyState.notifier).state = companyIdentifier;

                                // Navigate to home screen
                                Navigator.of(context).push(
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

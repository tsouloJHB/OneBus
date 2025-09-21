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
      // Fetch companies from backend endpoint `/api/bus-companies`
      final serverProviders = await BusRouteService.getBusCompanies();
      if (!mounted) return;
      if (serverProviders.isNotEmpty) {
        setState(() {
          _providers = serverProviders;
          _loading = false;
        });
        return;
      }
    } catch (e) {
      // ignore and fall back to local providers
    }
    // Fallback to local providers
    if (!mounted) return;
    setState(() {
      _providers = _fallbackProviders;
      _loading = false;
    });
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
                          final imageHeight =
                              double.tryParse(provider['height'] ?? '') ?? 80.0;
                          final imageWidth =
                              double.tryParse(provider['width'] ?? '') ?? 80.0;

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
                                    // If server supplied an image URL, use NetworkImage; otherwise fall back to asset
                                    (provider['image'] != null &&
                                            provider['image']!
                                                .startsWith('http'))
                                        ? Image.network(
                                            provider['image']!,
                                            height: imageHeight,
                                            width: imageWidth,
                                            fit: BoxFit.cover,
                                          )
                                        : Image.asset(
                                            provider['image'] ??
                                                'assets/images/driverprovider.png',
                                            height: imageHeight,
                                            width: imageWidth,
                                            fit: BoxFit.cover,
                                          ),
                                    const SizedBox(width: 20),
                                    Expanded(
                                      child: Text(
                                        provider['name'] ?? '',
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
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

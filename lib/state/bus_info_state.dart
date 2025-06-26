import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../models/BusInfo.dart';

class BusInfoNotifier extends StateNotifier<BusInfo> {
  BusInfoNotifier()
      : super(BusInfo(
          name: '',
          busNumber: '',
          busId: '',
          busCompany: '',
          direction: '',
          currentLocation: const LatLng(0, 0),
          routeName: '',
          routeCoordinates: const [],
          status: 'inactive',
          lastUpdated: DateTime.now(),
        ));

  // Method to update the bus information
  void setBusInfo(BusInfo busInfo) {
    state = busInfo;
  }
}

// Create a provider for BusInfoNotifier
final busInfoProvider = StateNotifierProvider<BusInfoNotifier, BusInfo>((ref) {
  return BusInfoNotifier();
});

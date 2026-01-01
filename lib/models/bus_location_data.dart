  import 'package:google_maps_flutter/google_maps_flutter.dart';

  class BusLocationData {
    final String busNumber;
    final String busCompany;
    final String direction;
    final LatLng coordinates;
    final double speed;
    final bool isActive;
    final DateTime lastUpdated;
    
    // Fallback support fields
    final bool isFallback;
    final String? fallbackDirection;
    final String? originalDirection;

    BusLocationData({
      required this.busNumber,
      required this.busCompany,
      required this.direction,
      required this.coordinates,
      required this.speed,
      required this.isActive,
      required this.lastUpdated,
      this.isFallback = false,
      this.fallbackDirection,
      this.originalDirection,
    });

    factory BusLocationData.fromJson(Map<String, dynamic> json) {
      return BusLocationData(
        busNumber: json['busNumber'],
        busCompany: json['busCompany'],
        direction: json['direction'],
        coordinates: LatLng(json['latitude'], json['longitude']),
        speed: json['speed'].toDouble(),
        isActive: json['isActive'],
        lastUpdated: DateTime.parse(json['lastUpdated']),
        isFallback: json['isFallback'] ?? false,
        fallbackDirection: json['fallbackDirection'],
        originalDirection: json['originalDirection'],
      );
    }

    Map<String, dynamic> toJson() {
      return {
        'busNumber': busNumber,
        'busCompany': busCompany,
        'direction': direction,
        'latitude': coordinates.latitude,
        'longitude': coordinates.longitude,
        'speed': speed,
        'isActive': isActive,
        'lastUpdated': lastUpdated.toIso8601String(),
        'isFallback': isFallback,
        'fallbackDirection': fallbackDirection,
        'originalDirection': originalDirection,
      };
    }
  }

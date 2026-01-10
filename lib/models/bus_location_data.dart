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
    
    // Route-based distance and ETA (calculated on backend using linear referencing)
    final double? distanceMeters;
    final double? distanceKm;
    final double? estimatedTimeMinutes;

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
      this.distanceMeters,
      this.distanceKm,
      this.estimatedTimeMinutes,
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
        distanceMeters: json['distanceMeters']?.toDouble(),
        distanceKm: json['distanceKm']?.toDouble(),
        estimatedTimeMinutes: json['estimatedTimeMinutes']?.toDouble(),
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
        'distanceMeters': distanceMeters,
        'distanceKm': distanceKm,
        'estimatedTimeMinutes': estimatedTimeMinutes,
      };
    }
  }

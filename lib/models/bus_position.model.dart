import 'package:google_maps_flutter/google_maps_flutter.dart';

class BusPosition {
  final String busNumber;
  final String busId;
  final LatLng coordinates;
  final DateTime timestamp;

  BusPosition({
    required this.busNumber,
    required this.busId,
    required this.coordinates,
    required this.timestamp,
  });

  factory BusPosition.fromJson(Map<String, dynamic> json) {
    return BusPosition(
      busNumber: json['busNumber'] as String,
      busId: json['busId'] as String,
      coordinates: LatLng(
        json['coordinates']['latitude'] as double,
        json['coordinates']['longitude'] as double,
      ),
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'busNumber': busNumber,
      'busId': busId,
      'coordinates': {
        'latitude': coordinates.latitude,
        'longitude': coordinates.longitude,
      },
      'timestamp': timestamp.toIso8601String(),
    };
  }
}

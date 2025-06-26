import 'package:google_maps_flutter/google_maps_flutter.dart';

class BusInfo {
  final String name;
  final String busNumber;
  final String busId;
  final String busCompany;
  final String direction;
  final LatLng currentLocation;
  final String routeName;
  final List<LatLng> routeCoordinates;
  final String status;
  final DateTime lastUpdated;

  BusInfo({
    required this.name,
    required this.busNumber,
    required this.busId,
    required this.busCompany,
    required this.direction,
    required this.currentLocation,
    required this.routeName,
    required this.routeCoordinates,
    required this.status,
    required this.lastUpdated,
  });

  factory BusInfo.fromJson(Map<String, dynamic> json) {
    return BusInfo(
      name: json['name'] as String,
      busNumber: json['busNumber'] as String,
      busId: json['busId'] as String,
      busCompany: json['busCompany'] as String,
      direction: json['direction'] as String,
      currentLocation: LatLng(
        json['currentLocation']['latitude'] as double,
        json['currentLocation']['longitude'] as double,
      ),
      routeName: json['routeName'] as String,
      routeCoordinates: (json['routeCoordinates'] as List)
          .map((coord) => LatLng(
                coord['latitude'] as double,
                coord['longitude'] as double,
              ))
          .toList(),
      status: json['status'] as String,
      lastUpdated: DateTime.parse(json['lastUpdated'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'busNumber': busNumber,
      'busId': busId,
      'busCompany': busCompany,
      'direction': direction,
      'currentLocation': {
        'latitude': currentLocation.latitude,
        'longitude': currentLocation.longitude,
      },
      'routeName': routeName,
      'routeCoordinates': routeCoordinates
          .map((coord) => {
                'latitude': coord.latitude,
                'longitude': coord.longitude,
              })
          .toList(),
      'status': status,
      'lastUpdated': lastUpdated.toIso8601String(),
    };
  }
}

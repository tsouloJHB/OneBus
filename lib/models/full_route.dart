import 'package:google_maps_flutter/google_maps_flutter.dart';

class FullRoute {
  final int id;
  final int companyId;
  final int routeId;
  final String name;
  final String? direction;
  final String? description;
  final List<Coordinate> coordinates;
  final DateTime createdAt;
  final DateTime updatedAt;

  FullRoute({
    required this.id,
    required this.companyId,
    required this.routeId,
    required this.name,
    this.direction,
    this.description,
    required this.coordinates,
    required this.createdAt,
    required this.updatedAt,
  });

  factory FullRoute.fromJson(Map<String, dynamic> json) {
    return FullRoute(
      id: json['id'] as int,
      companyId: json['companyId'] as int,
      routeId: json['routeId'] as int,
      name: json['name'] as String,
      direction: json['direction'] as String?,
      description: json['description'] as String?,
      coordinates: (json['coordinates'] as List<dynamic>?)
              ?.map((coord) => Coordinate.fromJson(coord as Map<String, dynamic>))
              .toList() ??
          [],
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'companyId': companyId,
      'routeId': routeId,
      'name': name,
      'direction': direction,
      'description': description,
      'coordinates': coordinates.map((coord) => coord.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  /// Convert coordinates to LatLng for Google Maps
  List<LatLng> toLatLngList() {
    return coordinates.map((coord) => coord.toLatLng()).toList();
  }
}

class Coordinate {
  final double lat;
  final double lon;

  Coordinate({
    required this.lat,
    required this.lon,
  });

  factory Coordinate.fromJson(Map<String, dynamic> json) {
    return Coordinate(
      lat: (json['lat'] as num).toDouble(),
      lon: (json['lon'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'lat': lat,
      'lon': lon,
    };
  }

  LatLng toLatLng() {
    return LatLng(lat, lon);
  }
}

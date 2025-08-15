class BusRouteResponse {
  final String companyName;
  final List<String> directions;
  final int totalRoutes;
  final List<BusRoute> routes;
  final String busNumber;

  BusRouteResponse({
    required this.companyName,
    required this.directions,
    required this.totalRoutes,
    required this.routes,
    required this.busNumber,
  });

  factory BusRouteResponse.fromJson(Map<String, dynamic> json) {
    return BusRouteResponse(
      companyName: json['companyName'] ?? '',
      directions: List<String>.from(json['directions'] ?? []),
      totalRoutes: json['totalRoutes'] ?? 0,
      routes: (json['routes'] as List<dynamic>?)
              ?.map((route) => BusRoute.fromJson(route))
              .toList() ??
          [],
      busNumber: json['busNumber'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'companyName': companyName,
      'directions': directions,
      'totalRoutes': totalRoutes,
      'routes': routes.map((route) => route.toJson()).toList(),
      'busNumber': busNumber,
    };
  }
}

class BusRoute {
  final int id;
  final String company;
  final String busNumber;
  final String routeName;
  final String description;
  final bool active;
  final String direction;
  final String startPoint;
  final String endPoint;
  final List<BusStopData> stops;

  BusRoute({
    required this.id,
    required this.company,
    required this.busNumber,
    required this.routeName,
    required this.description,
    required this.active,
    required this.direction,
    required this.startPoint,
    required this.endPoint,
    required this.stops,
  });

  factory BusRoute.fromJson(Map<String, dynamic> json) {
    return BusRoute(
      id: json['id'] ?? 0,
      company: json['company'] ?? '',
      busNumber: json['busNumber'] ?? '',
      routeName: json['routeName'] ?? '',
      description: json['description'] ?? '',
      active: json['active'] ?? false,
      direction: json['direction'] ?? '',
      startPoint: json['startPoint'] ?? '',
      endPoint: json['endPoint'] ?? '',
      stops: (json['stops'] as List<dynamic>?)
              ?.map((stop) => BusStopData.fromJson(stop))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'company': company,
      'busNumber': busNumber,
      'routeName': routeName,
      'description': description,
      'active': active,
      'direction': direction,
      'startPoint': startPoint,
      'endPoint': endPoint,
      'stops': stops.map((stop) => stop.toJson()).toList(),
    };
  }
}

class BusStopData {
  final int id;
  final double latitude;
  final double longitude;
  final String address;
  final int busStopIndex;
  final String direction;
  final String type;
  final int northboundIndex;
  final int southboundIndex;

  BusStopData({
    required this.id,
    required this.latitude,
    required this.longitude,
    required this.address,
    required this.busStopIndex,
    required this.direction,
    required this.type,
    required this.northboundIndex,
    required this.southboundIndex,
  });

  factory BusStopData.fromJson(Map<String, dynamic> json) {
    return BusStopData(
      id: json['id'] ?? 0,
      latitude: (json['latitude'] ?? 0.0).toDouble(),
      longitude: (json['longitude'] ?? 0.0).toDouble(),
      address: json['address'] ?? '',
      busStopIndex: json['busStopIndex'] ?? 0,
      direction: json['direction'] ?? '',
      type: json['type'] ?? '',
      northboundIndex: json['northboundIndex'] ?? 0,
      southboundIndex: json['southboundIndex'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'latitude': latitude,
      'longitude': longitude,
      'address': address,
      'busStopIndex': busStopIndex,
      'direction': direction,
      'type': type,
      'northboundIndex': northboundIndex,
      'southboundIndex': southboundIndex,
    };
  }
}

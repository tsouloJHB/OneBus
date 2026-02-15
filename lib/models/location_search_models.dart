class LocationSearchRequest {
  final String query;
  final double radiusKm;
  final double? userLatitude;
  final double? userLongitude;

  LocationSearchRequest({
    required this.query,
    this.radiusKm = 5.0,
    this.userLatitude,
    this.userLongitude,
  });

  Map<String, dynamic> toJson() {
    return {
      'query': query,
      'radiusKm': radiusKm,
      if (userLatitude != null) 'userLatitude': userLatitude,
      if (userLongitude != null) 'userLongitude': userLongitude,
    };
  }
}

class GeocodingResult {
  final double latitude;
  final double longitude;
  final String displayName;
  final String type;
  final double confidence;

  GeocodingResult({
    required this.latitude,
    required this.longitude,
    required this.displayName,
    required this.type,
    required this.confidence,
  });

  factory GeocodingResult.fromJson(Map<String, dynamic> json) {
    return GeocodingResult(
      latitude: json['latitude']?.toDouble() ?? 0.0,
      longitude: json['longitude']?.toDouble() ?? 0.0,
      displayName: json['displayName'] ?? '',
      type: json['type'] ?? '',
      confidence: json['confidence']?.toDouble() ?? 0.0,
    );
  }
}

class NearbyStop {
  final int stopId;
  final String address;
  final double latitude;
  final double longitude;
  final double distanceKm;
  final int stopIndex;

  NearbyStop({
    required this.stopId,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.distanceKm,
    required this.stopIndex,
  });

  factory NearbyStop.fromJson(Map<String, dynamic> json) {
    return NearbyStop(
      stopId: json['stopId'] ?? 0,
      address: json['address'] ?? '',
      latitude: json['latitude']?.toDouble() ?? 0.0,
      longitude: json['longitude']?.toDouble() ?? 0.0,
      distanceKm: json['distanceKm']?.toDouble() ?? 0.0,
      stopIndex: json['stopIndex'] ?? 0,
    );
  }
}

class RouteProximityResult {
  final int routeId;
  final String routeName;
  final String? direction;
  final double distanceKm;
  final List<NearbyStop> nearbyStops;
  final String companyName;
  final int companyId;

  RouteProximityResult({
    required this.routeId,
    required this.routeName,
    this.direction,
    required this.distanceKm,
    required this.nearbyStops,
    required this.companyName,
    required this.companyId,
  });

  factory RouteProximityResult.fromJson(Map<String, dynamic> json) {
    return RouteProximityResult(
      routeId: json['routeId'] ?? 0,
      routeName: json['routeName'] ?? '',
      direction: json['direction'],
      distanceKm: json['distanceKm']?.toDouble() ?? 0.0,
      nearbyStops: (json['nearbyStops'] as List<dynamic>?)
              ?.map((stop) => NearbyStop.fromJson(stop))
              .toList() ??
          [],
      companyName: json['companyName'] ?? '',
      companyId: json['companyId'] ?? 0,
    );
  }
}

class LocationSearchResponse {
  final GeocodingResult? geocodingResult;
  final List<RouteProximityResult> nearbyRoutes;
  final int totalRoutesFound;
  final double searchRadiusKm;

  LocationSearchResponse({
    this.geocodingResult,
    required this.nearbyRoutes,
    required this.totalRoutesFound,
    required this.searchRadiusKm,
  });

  factory LocationSearchResponse.fromJson(Map<String, dynamic> json) {
    return LocationSearchResponse(
      geocodingResult: json['geocodingResult'] != null
          ? GeocodingResult.fromJson(json['geocodingResult'])
          : null,
      nearbyRoutes: (json['nearbyRoutes'] as List<dynamic>?)
              ?.map((route) => RouteProximityResult.fromJson(route))
              .toList() ??
          [],
      totalRoutesFound: json['totalRoutesFound'] ?? 0,
      searchRadiusKm: json['searchRadiusKm']?.toDouble() ?? 0.0,
    );
  }
}

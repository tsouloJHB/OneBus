import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:onebus/models/location_search_models.dart';
import 'package:onebus/constants/app_constants.dart';

class LocationSearchService {
  final String baseUrl;

  LocationSearchService({String? baseUrl})
      : baseUrl = baseUrl ?? AppConstants.apiBaseUrl;

  /// Search for bus routes by location name or query
  Future<LocationSearchResponse> searchByLocation(
      LocationSearchRequest request) async {
    try {
      final url = Uri.parse('$baseUrl/v1/search/location');
      
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(request.toJson()),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return LocationSearchResponse.fromJson(data);
      } else {
        throw Exception(
            'Failed to search location: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      throw Exception('Error searching by location: $e');
    }
  }

  /// Search for bus routes by direct coordinates
  Future<LocationSearchResponse> searchByCoordinates({
    required double latitude,
    required double longitude,
    double radiusKm = 5.0,
  }) async {
    try {
      final url = Uri.parse('$baseUrl/v1/search/coordinates').replace(
        queryParameters: {
          'latitude': latitude.toString(),
          'longitude': longitude.toString(),
          'radiusKm': radiusKm.toString(),
        },
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return LocationSearchResponse.fromJson(data);
      } else {
        throw Exception(
            'Failed to search coordinates: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      throw Exception('Error searching by coordinates: $e');
    }
  }

  /// Get location suggestions for autocomplete (using Nominatim OSM)
  Future<List<LocationSuggestion>> getLocationSuggestions(String query) async {
    if (query.trim().isEmpty || query.length < 3) {
      return [];
    }

    try {
      // Use Nominatim API for autocomplete - South Africa only
      final url = Uri.parse('https://nominatim.openstreetmap.org/search').replace(
        queryParameters: {
          'q': query,
          'format': 'json',
          'addressdetails': '1',
          'limit': '8',
          'countrycodes': 'za',
          'bounded': '0',
        },
      );

      final response = await http.get(
        url,
        headers: {
          'User-Agent': 'OneBusApp/1.0',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((item) => LocationSuggestion.fromJson(item)).toList();
      } else {
        print('Failed to get suggestions: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('Error getting location suggestions: $e');
      return [];
    }
  }
}

class LocationSuggestion {
  final String displayName;
  final double lat;
  final double lon;
  final String type;

  LocationSuggestion({
    required this.displayName,
    required this.lat,
    required this.lon,
    required this.type,
  });

  factory LocationSuggestion.fromJson(Map<String, dynamic> json) {
    return LocationSuggestion(
      displayName: json['display_name'] ?? '',
      lat: double.tryParse(json['lat']?.toString() ?? '0') ?? 0.0,
      lon: double.tryParse(json['lon']?.toString() ?? '0') ?? 0.0,
      type: json['type'] ?? '',
    );
  }
}

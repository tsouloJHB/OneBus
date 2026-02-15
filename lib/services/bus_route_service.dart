import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../models/bus_route_info.dart';
import '../models/bus_route_response.dart';
import '../models/bus_stop.dart';
import '../constants/app_constants.dart';

class BusRouteService {
  // Points to the backend server URL from AppConstants
  static const String baseUrl = AppConstants.rootUrl;
  static const String apiBaseUrl = AppConstants.apiBaseUrl;

  /// Fetch list of provider companies from server
  /// Expects backend endpoint `/api/companies` returning a JSON array of objects with `name` and optional `image`.
  static Future<List<Map<String, String>>> getProviders() async {
    return _retry(() async {
      final url = '$apiBaseUrl/companies';
      print('[DEBUG] Fetching providers from: $url');
      final response = await http
          .get(Uri.parse(url), headers: {'accept': 'application/json'})
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final List<dynamic> jsonData = json.decode(response.body);
        final providers = jsonData.map<Map<String, String>>((item) {
          return {
            'name': (item['name'] ?? '').toString(),
            'image': (item['image'] ?? '').toString(),
            'height': (item['height'] ?? '80').toString(),
            'width': (item['width'] ?? '150').toString(),
          };
        }).where((p) => p['name']!.isNotEmpty).toList();

        print('[DEBUG] Providers fetched: ${providers.length}');
        return providers;
      } else {
        print('[WARN] Failed to fetch providers: ${response.statusCode}');
        return [];
      }
    });
  }

  /// Fetch only active bus companies from backend endpoint `/api/bus-companies/active`.
  /// Returns a list of maps with keys: `id`, `name`, `image`, `height`, `width`.
  /// Uses backend image URL when provided; falls back to a local placeholder.
  static Future<List<Map<String, String>>> getBusCompanies() async {
    return _retry(() async {
      final url = '$apiBaseUrl/bus-companies/active';
      print('[DEBUG] Fetching bus companies from: $url');
      final response = await http
          .get(Uri.parse(url), headers: {'accept': 'application/json'})
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final List<dynamic> jsonData = json.decode(response.body);
        final companies = jsonData.map<Map<String, String>>((item) {
          var imageUrl = (item['imageUrl'] ?? (item['image'] ?? '')).toString();
          final fallbackImage = 'assets/images/driverprovider.png';
          
          if (imageUrl.isNotEmpty && !imageUrl.startsWith('http')) {
            imageUrl = '$baseUrl$imageUrl';
          }
          
          return {
            'id': (item['id'] ?? '').toString(),
            'name': (item['name'] ?? '').toString(),
            'image': imageUrl.isNotEmpty ? imageUrl : fallbackImage,
            'height': (item['height'] ?? '80').toString(),
            'width': (item['width'] ?? '150').toString(),
          };
        }).where((c) => c['name']!.isNotEmpty).toList();

        print('[DEBUG] Companies fetched: ${companies.length}');
        return companies;
      } else {
        print('[WARN] Failed to fetch bus companies: ${response.statusCode}');
        return [];
      }
    });
  }

  /// Fetch bus routes for a specific company from the server
  static Future<List<BusRouteInfo>> getBusRoutesByCompany(
    String companyIdentifier) async {
    return _retry(() async {
      final encoded = Uri.encodeComponent(companyIdentifier);
      final url = '$apiBaseUrl/bus-numbers/search/company?busCompanyId=$encoded';

      print('[DEBUG] Fetching bus routes for company identifier: $companyIdentifier');
      print('[DEBUG] URL: $url');

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'accept': 'application/json',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final List<dynamic> jsonData = json.decode(response.body);
        final List<BusRouteInfo> busRoutes = jsonData
            .map((json) => BusRouteInfo.fromJson(json))
            .where((route) => route.isActive) // Only return active routes
            .toList();

        print('[DEBUG] Successfully fetched ${busRoutes.length} bus routes');
        return busRoutes;
      } else {
        print('[ERROR] Failed to fetch bus routes. Status code: ${response.statusCode}');
        return [];
      }
    });
  }

  /// Get just the bus numbers as a list of strings
  static Future<List<String>> getBusNumbersByCompany(String companyIdentifier) async {
    try {
      final busRoutes = await getBusRoutesByCompany(companyIdentifier);
      return busRoutes.map((route) => route.busNumber.toUpperCase()).toList();
    } catch (e) {
      print('[ERROR] Exception while getting bus numbers: $e');
      return [];
    }
  }

  /// Fetch bus routes and stops for a specific bus number and company
  static Future<BusRouteResponse?> getBusRoutesAndStops(
      String busNumber, String companyName) async {
    return _retry(() async {
      final encodedBusNumber = Uri.encodeComponent(busNumber);
      final encodedCompanyName = Uri.encodeComponent(companyName);
      final url = '$apiBaseUrl/routes/$encodedBusNumber/$encodedCompanyName';

      print('[DEBUG] Fetching bus routes and stops for bus: $busNumber, company: $companyName');
      print('[DEBUG] URL: $url');

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'accept': 'application/json',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        final busRouteResponse = BusRouteResponse.fromJson(jsonData);

        print('[DEBUG] Successfully fetched bus routes and stops');
        return busRouteResponse;
      } else {
        print('[ERROR] Failed to fetch bus routes and stops. Status code: ${response.statusCode}');
        return null;
      }
    });
  }

  /// Fetch route directions for a specific bus number and company
  /// Returns route data with directions info for user to choose from
  static Future<Map<String, dynamic>?> getRouteDirections(
      String busNumber, String companyName) async {
    return _retry(() async {
      final encodedBusNumber = Uri.encodeComponent(busNumber);
      final encodedCompanyName = Uri.encodeComponent(companyName);
      final url = '$apiBaseUrl/routes/$encodedBusNumber/$encodedCompanyName';

      print('[DEBUG] Fetching route directions for bus: $busNumber, company: $companyName');
      print('[DEBUG] URL: $url');

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'accept': 'application/json',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        print('[DEBUG] Successfully fetched route directions');
        return jsonData;
      } else {
        print('[ERROR] Failed to fetch route directions. Status code: ${response.statusCode}');
        return null;
      }
    });
  }

  /// Convert API bus stop data to app's BusStop model
  static List<BusStop> convertApiStopsToBusStops(List<BusStopData> apiStops) {
    return apiStops
        .map((apiStop) => BusStop(
              coordinates: LatLng(apiStop.latitude, apiStop.longitude),
              address: apiStop.address,
              type: apiStop.type,
              busStopIndex: apiStop.busStopIndex,
              direction: apiStop.direction,
              busStopIndices: {
                'northbound': apiStop.northboundIndex,
                'southbound': apiStop.southboundIndex,
              },
            ))
        .toList();
  }

  /// Helper method to retry a network call with backoff
  static Future<T> _retry<T>(Future<T> Function() call, {int maxAttempts = 2}) async {
    int attempts = 0;
    while (true) {
      try {
        attempts++;
        return await call();
      } catch (e) {
        if (attempts >= maxAttempts) {
          print('[ERROR] Max retry attempts reached ($maxAttempts). Error: $e');
          rethrow;
        }
        print('[WARN] Network attempt $attempts failed, retrying... Error: $e');
        // Wait a bit before retrying (1s, 2s, etc.)
        await Future.delayed(Duration(seconds: attempts));
      }
    }
  }
}

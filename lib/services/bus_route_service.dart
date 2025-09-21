import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../models/bus_route_info.dart';
import '../models/bus_route_response.dart';
import '../models/bus_stop.dart';

class BusRouteService {
  // For development: when the backend runs on the development machine and you
  // use `adb reverse tcp:8080 tcp:8080`, the app on a physical Android device
  // can reach the host via `http://localhost:8080`.
  // If you run the app on an emulator, change this to `http://10.0.2.2:8080`.
  // For production builds set this to your real backend URL.
  // When running on the Android emulator, use 10.0.2.2 to reach the host's
  // localhost. If you're running on a physical device with `adb reverse` set up
  // use `http://localhost:8080` instead.
  static const String baseUrl = 'http://10.0.2.2:8080';

  /// Fetch list of provider companies from server
  /// Expects backend endpoint `/api/companies` returning a JSON array of objects with `name` and optional `image`.
  static Future<List<Map<String, String>>> getProviders() async {
    try {
      final url = '$baseUrl/api/companies';
      print('[DEBUG] Fetching providers from: $url');
      final response = await http
          .get(Uri.parse(url), headers: {'accept': 'application/json'})
          .timeout(const Duration(seconds: 8));

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
    } catch (e) {
      print('[ERROR] Exception while fetching providers: $e');
      return [];
    }
  }

  /// Fetch bus companies from backend endpoint `/api/bus-companies`.
  /// Returns a list of maps with keys: `id`, `name`, `image`, `height`, `width`.
  /// Uses a local placeholder image for now; backend will be updated later to include images.
  static Future<List<Map<String, String>>> getBusCompanies() async {
    try {
      final url = '$baseUrl/api/bus-companies';
      print('[DEBUG] Fetching bus companies from: $url');
      final response = await http
          .get(Uri.parse(url), headers: {'accept': 'application/json'})
          .timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final List<dynamic> jsonData = json.decode(response.body);
        final companies = jsonData.map<Map<String, String>>((item) {
          return {
            'id': (item['id'] ?? '').toString(),
            'name': (item['name'] ?? '').toString(),
            // placeholder asset for now; backend will supply `image` in the future
            'image': 'assets/images/driverprovider.png',
            'height': '80',
            'width': '150',
          };
        }).where((c) => c['name']!.isNotEmpty).toList();

        print('[DEBUG] Companies fetched: ${companies.length}');
        return companies;
      } else {
        print('[WARN] Failed to fetch bus companies: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('[ERROR] Exception while fetching bus companies: $e');
      return [];
    }
  }

  /// Fetch bus routes for a specific company from the server
  static Future<List<BusRouteInfo>> getBusRoutesByCompany(
    String companyIdentifier) async {
    try {
    final encoded = Uri.encodeComponent(companyIdentifier);
    // backend expects query param name `busCompanyId` (accepts name or id)
    final url =
      '$baseUrl/api/bus-numbers/search/company?busCompanyId=$encoded';

    print('[DEBUG] Fetching bus routes for company identifier: $companyIdentifier');
    print('[DEBUG] URL: $url');

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'accept': 'application/json',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 10));

      print('[DEBUG] Response status code: ${response.statusCode}');
      print('[DEBUG] Response body: ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> jsonData = json.decode(response.body);
        final List<BusRouteInfo> busRoutes = jsonData
            .map((json) => BusRouteInfo.fromJson(json))
            .where((route) => route.isActive) // Only return active routes
            .toList();

        print('[DEBUG] Successfully fetched ${busRoutes.length} bus routes');
        return busRoutes;
      } else {
        print(
            '[ERROR] Failed to fetch bus routes. Status code: ${response.statusCode}');
        print('[ERROR] Response body: ${response.body}');
        return [];
      }
    } catch (e) {
      print('[ERROR] Exception while fetching bus routes: $e');
      return [];
    }
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
    try {
      final encodedBusNumber = Uri.encodeComponent(busNumber);
      final encodedCompanyName = Uri.encodeComponent(companyName);
      final url = '$baseUrl/api/routes/$encodedBusNumber/$encodedCompanyName';

      print(
          '[DEBUG] Fetching bus routes and stops for bus: $busNumber, company: $companyName');
      print('[DEBUG] URL: $url');

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'accept': 'application/json',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 10));

      print('[DEBUG] Response status code: ${response.statusCode}');
      print('[DEBUG] Response body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        final busRouteResponse = BusRouteResponse.fromJson(jsonData);

        print('[DEBUG] Successfully fetched bus routes and stops');
        print('[DEBUG] Total routes: ${busRouteResponse.totalRoutes}');
        print(
            '[DEBUG] Total stops: ${busRouteResponse.routes.fold(0, (sum, route) => sum + route.stops.length)}');

        return busRouteResponse;
      } else {
        print(
            '[ERROR] Failed to fetch bus routes and stops. Status code: ${response.statusCode}');
        print('[ERROR] Response body: ${response.body}');
        return null;
      }
    } catch (e) {
      print('[ERROR] Exception while fetching bus routes and stops: $e');
      return null;
    }
  }

  /// Fetch route directions for a specific bus number and company
  /// Returns route data with directions info for user to choose from
  static Future<Map<String, dynamic>?> getRouteDirections(
      String busNumber, String companyName) async {
    try {
      final encodedBusNumber = Uri.encodeComponent(busNumber);
      final encodedCompanyName = Uri.encodeComponent(companyName);
      final url = '$baseUrl/api/routes/$encodedBusNumber/$encodedCompanyName';

      print('[DEBUG] Fetching route directions for bus: $busNumber, company: $companyName');
      print('[DEBUG] URL: $url');

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'accept': 'application/json',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 10));

      print('[DEBUG] Response status code: ${response.statusCode}');
      print('[DEBUG] Response body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        print('[DEBUG] Successfully fetched route directions');
        return jsonData;
      } else {
        print('[ERROR] Failed to fetch route directions. Status code: ${response.statusCode}');
        print('[ERROR] Response body: ${response.body}');
        return null;
      }
    } catch (e) {
      print('[ERROR] Exception while fetching route directions: $e');
      return null;
    }
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
}

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../models/bus_route_info.dart';
import '../models/bus_route_response.dart';
import '../models/bus_stop.dart';

class BusRouteService {
  static const String baseUrl = 'http://192.168.8.146:8080';

  /// Fetch bus routes for a specific company from the server
  static Future<List<BusRouteInfo>> getBusRoutesByCompany(
      String companyName) async {
    try {
      final encodedCompanyName = Uri.encodeComponent(companyName);
      final url =
          '$baseUrl/api/bus-numbers/search/company?companyName=$encodedCompanyName';

      print('[DEBUG] Fetching bus routes for company: $companyName');
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
  static Future<List<String>> getBusNumbersByCompany(String companyName) async {
    try {
      final busRoutes = await getBusRoutesByCompany(companyName);
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

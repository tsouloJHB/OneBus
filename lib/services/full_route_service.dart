import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants/app_constants.dart';
import '../models/full_route.dart';

class FullRouteService {
  /// In-memory cache for full routes to avoid redundant network requests
  static final Map<int, List<FullRoute>> _companyRoutesCache = {};
  static final Map<int, List<FullRoute>> _routeIdCache = {};

  /// Clear the in-memory cache
  static void clearCache() {
    _companyRoutesCache.clear();
    _routeIdCache.clear();
    print('[DEBUG] FullRouteService cache cleared');
  }

  /// Fetch full routes by company ID
  static Future<List<FullRoute>> getFullRoutesByCompany(int companyId) async {
    // Return from cache if available
    if (_companyRoutesCache.containsKey(companyId)) {
      print('[DEBUG] Returning ${_companyRoutesCache[companyId]!.length} full routes from cache for company $companyId');
      return _companyRoutesCache[companyId]!;
    }

    try {
      final url = Uri.parse('${AppConstants.apiBaseUrl}/full-routes?companyId=$companyId');
      print('[DEBUG] Fetching full routes for company $companyId from: $url');
      
      final response = await http.get(url);
      
      if (response.statusCode == 200) {
        final List<dynamic> jsonList = json.decode(response.body) as List<dynamic>;
        final routes = jsonList
            .map((json) => FullRoute.fromJson(json as Map<String, dynamic>))
            .toList();
        
        // Store in cache for future use
        if (routes.isNotEmpty) {
          _companyRoutesCache[companyId] = routes;
        }

        print('[DEBUG] Successfully loaded ${routes.length} full routes');
        return routes;
      } else {
        print('[ERROR] Failed to load full routes: ${response.statusCode}');
        print('[ERROR] Response body: ${response.body}');
        return [];
      }
    } catch (e) {
      print('[ERROR] Exception loading full routes: $e');
      return [];
    }
  }

  /// Fetch full routes by route ID
  static Future<List<FullRoute>> getFullRoutesByRouteId(int routeId) async {
    // Return from cache if available
    if (_routeIdCache.containsKey(routeId)) {
      print('[DEBUG] Returning ${_routeIdCache[routeId]!.length} full routes from cache for route $routeId');
      return _routeIdCache[routeId]!;
    }

    try {
      final url = Uri.parse('${AppConstants.apiBaseUrl}/full-routes?routeId=$routeId');
      print('[DEBUG] Fetching full routes for route $routeId from: $url');
      
      final response = await http.get(url);
      
      if (response.statusCode == 200) {
        final List<dynamic> jsonList = json.decode(response.body) as List<dynamic>;
        final routes = jsonList
            .map((json) => FullRoute.fromJson(json as Map<String, dynamic>))
            .toList();
        
        // Store in cache for future use
        if (routes.isNotEmpty) {
          _routeIdCache[routeId] = routes;
        }

        print('[DEBUG] Successfully loaded ${routes.length} full routes for route $routeId');
        return routes;
      } else {
        print('[ERROR] Failed to load full routes: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('[ERROR] Exception loading full routes: $e');
      return [];
    }
  }

  /// Fetch full routes by both company and route ID
  static Future<List<FullRoute>> getFullRoutes({
    required int companyId,
    required int routeId,
  }) async {
    try {
      final url = Uri.parse(
          '${AppConstants.apiBaseUrl}/full-routes?companyId=$companyId&routeId=$routeId');
      print('[DEBUG] Fetching full routes for company $companyId, route $routeId from: $url');
      
      final response = await http.get(url);
      
      if (response.statusCode == 200) {
        final List<dynamic> jsonList = json.decode(response.body) as List<dynamic>;
        final routes = jsonList
            .map((json) => FullRoute.fromJson(json as Map<String, dynamic>))
            .toList();
        print('[DEBUG] Successfully loaded ${routes.length} full routes');
        return routes;
      } else {
        print('[ERROR] Failed to load full routes: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('[ERROR] Exception loading full routes: $e');
      return [];
    }
  }

  /// Find matching full route by bus number and direction
  /// This is a helper method to find the right route when you have bus number and direction
  static Future<FullRoute?> findFullRouteByBusAndDirection({
    required String busNumber,
    required String direction,
    required int companyId,
  }) async {
    try {
      print('[DEBUG] Finding full route for bus: $busNumber, direction: $direction, company: $companyId');
      
      // Get all routes for the company
      final routes = await getFullRoutesByCompany(companyId);
      
      if (routes.isEmpty) {
        print('[DEBUG] No routes found for company $companyId');
        return null;
      }

      // Try to match by name (bus number) and direction
      final matchingRoutes = routes.where((route) {
        final nameMatch = route.name.toLowerCase().contains(busNumber.toLowerCase());
        final directionMatch = route.direction?.toLowerCase() == direction.toLowerCase();
        return nameMatch && directionMatch;
      }).toList();

      if (matchingRoutes.isEmpty) {
        print('[DEBUG] No matching route found for bus $busNumber, direction $direction');
        return null;
      }

      print('[DEBUG] Found ${matchingRoutes.length} matching route(s)');
      return matchingRoutes.first;
    } catch (e) {
      print('[ERROR] Exception finding full route: $e');
      return null;
    }
  }

  /// Get a single full route by ID
  static Future<FullRoute?> getFullRouteById(int id) async {
    try {
      final url = Uri.parse('${AppConstants.apiBaseUrl}/full-routes/$id');
      print('[DEBUG] Fetching full route $id from: $url');
      
      final response = await http.get(url);
      
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        return FullRoute.fromJson(json);
      } else {
        print('[ERROR] Failed to load full route: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('[ERROR] Exception loading full route: $e');
      return null;
    }
  }
}

import 'package:flutter/material.dart';
import 'bus_company_strategy.dart';

/// Rea Vaya bus company strategy.
/// 
/// Rea Vaya supports smart bus selection with Shadow Bus strategy,
/// enhanced fallback visualization, and company-specific UI elements.
class ReaVayaStrategy extends BusCompanyStrategy {
  @override
  String getCompanyName() {
    return 'Rea Vaya';
  }
  
  @override
  bool supportsSmartBusSelection() {
    return true; // Rea Vaya supports Shadow Bus strategy
  }
  
  @override
  bool supportsFallbackVisualization() {
    return true; // Show enhanced route visualization for fallback buses
  }
  
  @override
  Map<String, String> getFallbackNotificationMessage(String originalDirection, String fallbackDirection) {
    return {
      'title': 'No $originalDirection buses available',
      'message': 'Showing $fallbackDirection bus instead - it will turn around to serve your route',
    };
  }
  
  @override
  Map<String, String> getArrivalStatusMessages() {
    return {
      'arriving': 'Arriving at your stop',
      'veryClose': 'Very close to your stop',
      'onTime': 'On time',
      'fallbackApproaching': 'Fallback Bus - Approaching (wrong direction)',
      'fallbackNearby': 'Fallback Bus - Nearby (will turn around)',
      'fallbackEnRoute': 'Fallback Bus - En Route (will serve your route)',
      'arrived': 'Bus has arrived at your stop',
    };
  }
  
  @override
  bool shouldIgnoreArrivalForFallbackBus() {
    return true; // Ignore arrival detection until bus turns around
  }
  
  @override
  List<String> getLoadingMessages() {
    return [
      'Connecting to Rea Vaya tracking system...',
      'Searching for your bus on the BRT network...',
      'Checking alternative directions...',
      'Looking for the best available bus...',
      'Almost ready - preparing route visualization...',
    ];
  }
  
  @override
  Map<String, dynamic> getCompanyColors() {
    return {
      'primary': Colors.red,
      'secondary': Colors.orange,
      'accent': Colors.red.shade700,
      'fallbackRoute': Colors.orange,
      'requestedRoute': Colors.green,
      'connectionRoute': Colors.red.shade300,
    };
  }
}
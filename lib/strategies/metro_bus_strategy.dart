import 'package:flutter/material.dart';
import 'bus_company_strategy.dart';

/// Metro Bus company strategy.
/// 
/// Metro Bus supports smart bus selection with Shadow Bus strategy,
/// similar to Rea Vaya but with Metro Bus branding and colors.
class MetroBusStrategy extends BusCompanyStrategy {
  @override
  String getCompanyName() {
    return 'Metro Bus';
  }
  
  @override
  bool supportsSmartBusSelection() {
    return true; // Metro Bus supports Shadow Bus strategy
  }
  
  @override
  bool supportsFallbackVisualization() {
    return true; // Show enhanced route visualization for fallback buses
  }
  
  @override
  Map<String, String> getFallbackNotificationMessage(String originalDirection, String fallbackDirection) {
    return {
      'title': 'No $originalDirection Metro buses available',
      'message': 'Showing $fallbackDirection Metro bus instead - it will turn around to serve your route',
    };
  }
  
  @override
  Map<String, String> getArrivalStatusMessages() {
    return {
      'arriving': 'Metro bus arriving at your stop',
      'veryClose': 'Metro bus very close to your stop',
      'onTime': 'Metro bus on time',
      'fallbackApproaching': 'Fallback Metro Bus - Approaching (wrong direction)',
      'fallbackNearby': 'Fallback Metro Bus - Nearby (will turn around)',
      'fallbackEnRoute': 'Fallback Metro Bus - En Route (will serve your route)',
      'arrived': 'Metro bus has arrived at your stop',
    };
  }
  
  @override
  bool shouldIgnoreArrivalForFallbackBus() {
    return true; // Ignore arrival detection until bus turns around
  }
  
  @override
  List<String> getLoadingMessages() {
    return [
      'Connecting to Metro Bus tracking system...',
      'Searching for your Metro bus...',
      'Checking alternative Metro bus directions...',
      'Looking for the best available Metro bus...',
      'Almost ready - preparing Metro bus route...',
    ];
  }
  
  @override
  Map<String, dynamic> getCompanyColors() {
    return {
      'primary': Colors.blue,
      'secondary': Colors.lightBlue,
      'accent': Colors.blue.shade700,
      'fallbackRoute': Colors.orange,
      'requestedRoute': Colors.green,
      'connectionRoute': Colors.blue.shade300,
    };
  }
}
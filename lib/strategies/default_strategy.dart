import 'package:flutter/material.dart';
import 'bus_company_strategy.dart';

/// Default bus company strategy for unknown or unsupported companies.
/// 
/// This strategy provides basic functionality without smart bus selection
/// or advanced fallback features. Companies using this strategy will have
/// traditional bus tracking only.
class DefaultStrategy extends BusCompanyStrategy {
  @override
  String getCompanyName() {
    return 'Default';
  }
  
  @override
  bool supportsSmartBusSelection() {
    return false; // Default strategy does not support Shadow Bus strategy
  }
  
  @override
  bool supportsFallbackVisualization() {
    return false; // No enhanced fallback visualization
  }
  
  @override
  Map<String, String> getFallbackNotificationMessage(String originalDirection, String fallbackDirection) {
    return {
      'title': 'Bus service information',
      'message': 'Showing available bus information',
    };
  }
  
  @override
  Map<String, String> getArrivalStatusMessages() {
    return {
      'arriving': 'Bus arriving',
      'veryClose': 'Bus very close',
      'onTime': 'Bus on time',
      'fallbackApproaching': 'Bus approaching',
      'fallbackNearby': 'Bus nearby',
      'fallbackEnRoute': 'Bus en route',
      'arrived': 'Bus has arrived',
    };
  }
  
  @override
  bool shouldIgnoreArrivalForFallbackBus() {
    return false; // Default behavior - don't ignore arrival
  }
  
  @override
  List<String> getLoadingMessages() {
    return [
      'Connecting to bus tracking system...',
      'Searching for your bus...',
      'Loading bus information...',
      'Preparing route information...',
      'Almost ready...',
    ];
  }
  
  @override
  Map<String, dynamic> getCompanyColors() {
    return {
      'primary': Colors.grey,
      'secondary': Colors.grey.shade400,
      'accent': Colors.grey.shade700,
      'fallbackRoute': Colors.orange,
      'requestedRoute': Colors.green,
      'connectionRoute': Colors.grey.shade300,
    };
  }
}
/// Base abstract class for bus company strategies in Flutter.
/// 
/// This mirrors the backend routing strategy pattern but focuses on
/// client-side behavior like fallback bus handling, visualization, and
/// company-specific UI logic.
abstract class BusCompanyStrategy {
  /// Get the company name this strategy is designed for
  String getCompanyName();
  
  /// Check if this company supports smart bus selection (Shadow Bus strategy).
  /// Companies that don't support it will use traditional subscription only.
  bool supportsSmartBusSelection();
  
  /// Check if this company supports fallback bus visualization.
  /// When a fallback bus is selected, should we show the enhanced route visualization?
  bool supportsFallbackVisualization();
  
  /// Get the fallback notification message for this company.
  /// Returns a map with 'title' and 'message' keys for the notification.
  Map<String, String> getFallbackNotificationMessage(String originalDirection, String fallbackDirection);
  
  /// Get the arrival status messages for this company.
  /// Different companies might have different terminology.
  Map<String, String> getArrivalStatusMessages();
  
  /// Check if arrival detection should be ignored for fallback buses.
  /// Some companies might want to show arrival even for wrong-direction buses.
  bool shouldIgnoreArrivalForFallbackBus();
  
  /// Get the loading messages for this company during bus selection.
  List<String> getLoadingMessages();
  
  /// Get company-specific colors for UI elements.
  Map<String, dynamic> getCompanyColors();
}
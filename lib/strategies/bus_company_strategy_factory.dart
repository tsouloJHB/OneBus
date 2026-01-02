import 'bus_company_strategy.dart';
import 'rea_vaya_strategy.dart';
import 'metro_bus_strategy.dart';
import 'default_strategy.dart';

/// Factory for creating bus company strategies in Flutter.
/// 
/// This factory selects the appropriate strategy based on the bus company name.
/// If a company-specific strategy exists, it's used; otherwise, the default strategy is used.
class BusCompanyStrategyFactory {
  static BusCompanyStrategy? _cachedStrategy;
  static String? _cachedCompanyName;
  
  /// Get the strategy for a bus company.
  /// 
  /// @param companyName The name of the bus company
  /// @return The strategy for this company
  static BusCompanyStrategy getStrategy(String companyName) {
    // Use cached strategy if company hasn't changed
    if (_cachedStrategy != null && _cachedCompanyName == companyName) {
      return _cachedStrategy!;
    }
    
    BusCompanyStrategy strategy;
    
    if (companyName.toLowerCase().contains('rea vaya')) {
      strategy = ReaVayaStrategy();
    } else if (companyName.toLowerCase().contains('metro bus') || 
               companyName.toLowerCase().contains('metrobus')) {
      strategy = MetroBusStrategy();
    } else {
      strategy = DefaultStrategy();
    }
    
    // Cache the strategy
    _cachedStrategy = strategy;
    _cachedCompanyName = companyName;
    
    print('[DEBUG] Using ${strategy.runtimeType} strategy for company: $companyName');
    return strategy;
  }
  
  /// Clear the cached strategy (useful when company changes)
  static void clearCache() {
    _cachedStrategy = null;
    _cachedCompanyName = null;
  }
  
  /// Check if a company supports smart bus selection
  static bool supportsSmartBusSelection(String companyName) {
    return getStrategy(companyName).supportsSmartBusSelection();
  }
  
  /// Check if a company supports fallback visualization
  static bool supportsFallbackVisualization(String companyName) {
    return getStrategy(companyName).supportsFallbackVisualization();
  }
}
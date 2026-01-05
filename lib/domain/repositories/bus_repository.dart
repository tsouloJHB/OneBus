/// Repository interface for bus-related operations
abstract class BusRepository {
  /// Get available buses for a company
  Future<List<String>> getAvailableBuses(String companyName);
}
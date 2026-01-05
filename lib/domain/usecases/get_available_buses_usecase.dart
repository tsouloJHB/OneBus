import 'package:onebus/domain/repositories/bus_repository.dart';

/// Use case for getting available buses for a company
class GetAvailableBusesUseCase {
  final BusRepository busRepository;

  GetAvailableBusesUseCase({required this.busRepository});

  /// Execute the use case to get available buses
  Future<List<String>> execute(String companyName) async {
    if (companyName.isEmpty) {
      return [];
    }

    try {
      return await busRepository.getAvailableBuses(companyName);
    } catch (error) {
      // Return fallback buses based on company
      return _getFallbackBuses(companyName);
    }
  }

  /// Fallback hardcoded bus list based on company
  List<String> _getFallbackBuses(String companyName) {
    switch (companyName.toLowerCase()) {
      case 'rea vaya':
        return ["C5", "C4", "C6", "T1", "T3", "T2"];
      case 'metrobus':
      case 'metro bus':
        return ["M1", "M2", "M3", "M4"];
      case 'putco':
        return ["P1", "P2", "P3", "P4"];
      default:
        return ["C5", "C4", "C6", "T1", "T3", "T2"];
    }
  }
}
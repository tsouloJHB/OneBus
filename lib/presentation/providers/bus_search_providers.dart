import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:onebus/domain/usecases/get_available_buses_usecase.dart';
import 'package:onebus/data/repositories/bus_repository_impl.dart';

// Bus search state providers
final selectedBusCompanyProvider = StateProvider<String>((ref) => 'Rea Vaya'); // Default company
final busSearchQueryProvider = StateProvider<String>((ref) => '');
final selectedBusNumberProvider = StateProvider<String>((ref) => '');

// Use case provider
final getAvailableBusesUseCaseProvider = Provider<GetAvailableBusesUseCase>((ref) {
  return GetAvailableBusesUseCase(
    busRepository: BusRepositoryImpl(),
  );
});

// Available buses provider
final availableBusesProvider = FutureProvider.autoDispose<List<String>>((ref) async {
  final companyName = ref.watch(selectedBusCompanyProvider);
  final useCase = ref.read(getAvailableBusesUseCaseProvider);
  
  return await useCase.execute(companyName);
});

// Filtered buses provider (based on search query)
final filteredBusesProvider = Provider.autoDispose<AsyncValue<List<String>>>((ref) {
  final availableBusesAsync = ref.watch(availableBusesProvider);
  final searchQuery = ref.watch(busSearchQueryProvider);
  
  return availableBusesAsync.when(
    data: (buses) {
      if (searchQuery.isEmpty) {
        return AsyncValue.data(buses);
      } else {
        final filtered = buses
            .where((bus) => bus.toLowerCase().contains(searchQuery.toLowerCase()))
            .toList();
        return AsyncValue.data(filtered);
      }
    },
    loading: () => const AsyncValue.loading(),
    error: (error, stack) => AsyncValue.error(error, stack),
  );
});
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:onebus/presentation/providers/bus_search_providers.dart';
import 'package:onebus/views/home.dart';

/// Clean architecture version of BottomSearchSheet
/// Preserves original UI design but uses clean architecture providers
class BottomSearchSheetClean extends ConsumerStatefulWidget {
  final Function(String) onBusSelected;

  const BottomSearchSheetClean({
    super.key,
    required this.onBusSelected,
  });

  @override
  ConsumerState<BottomSearchSheetClean> createState() => _BottomSearchSheetCleanState();
}

class _BottomSearchSheetCleanState extends ConsumerState<BottomSearchSheetClean> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    ref.read(busSearchQueryProvider.notifier).state = _searchController.text;
  }

  @override
  Widget build(BuildContext context) {
    final selectedBus = ref.watch(selectedBusNumberProvider);
    final filteredBusesAsync = ref.watch(filteredBusesProvider);

    return DraggableScrollableSheet(
      initialChildSize: 0.5,
      minChildSize: 0.1,
      maxChildSize: 0.9,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.red.shade100,
                Colors.white,
              ],
            ),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(46.0),
              topRight: Radius.circular(46.0),
            ),
          ),
          child: Column(
            children: [
              // Draggable handle
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10.0),
                child: Container(
                  width: 50,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),

              // Back button and title
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const HomeScreen()),
                        );
                      },
                    ),
                  ],
                ),
              ),

              // Title text (preserving original design)
              const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Search ",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 30,
                    ),
                  ),
                  Text(
                    "By bus number",
                    style: TextStyle(
                      fontSize: 30,
                    ),
                  ),
                ],
              ),
              const Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  SizedBox(width: 50),
                  Text(
                    "below ",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 30,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Search bar (preserving original design)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withValues(alpha: 0.3),
                        spreadRadius: 1,
                        blurRadius: 3,
                        offset: const Offset(1, 1),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search by bus number',
                      prefixIcon: const Icon(
                        Icons.search,
                        color: Colors.grey,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(28),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Filtered bus list (using clean architecture providers)
              Expanded(
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                  ),
                  child: filteredBusesAsync.when(
                    data: (buses) => _buildBusList(buses, selectedBus, scrollController),
                    loading: () => const Center(
                      child: CircularProgressIndicator(color: Colors.red),
                    ),
                    error: (error, stack) => Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error_outline, size: 48, color: Colors.red),
                          const SizedBox(height: 16),
                          Text('Error loading buses: $error'),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () => ref.refresh(availableBusesProvider),
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBusList(List<String> buses, String selectedBus, ScrollController scrollController) {
    if (buses.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 48, color: Colors.grey),
            SizedBox(height: 16),
            Text('No buses found'),
            Text('Try a different search term'),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
      itemCount: buses.length,
      itemBuilder: (context, index) {
        final bus = buses[index];
        final isSelected = bus == selectedBus;

        return Container(
          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
          decoration: BoxDecoration(
            color: isSelected
                ? Colors.green.withValues(alpha: 0.1)
                : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected ? Colors.blue : Colors.red,
              width: 3,
            ),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            title: Text(
              'Bus $bus',
              style: TextStyle(
                fontSize: 16,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? Colors.green : Colors.black,
              ),
            ),
            trailing: isSelected
                ? const Icon(Icons.check_circle, color: Colors.green)
                : null,
            onTap: () {
              // Update selected bus in provider
              ref.read(selectedBusNumberProvider.notifier).state = bus;
              // Call the callback
              widget.onBusSelected(bus);
            },
          ),
        );
      },
    );
  }
}
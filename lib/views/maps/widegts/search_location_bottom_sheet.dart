import 'package:flutter/material.dart';
import 'package:onebus/services/location_search_service.dart';
import 'dart:async';

class SearchLocationBottomSheet extends StatefulWidget {
  final Function(String query, double radius) onSearch;
  final Function(double latitude, double longitude, double radius)? onSearchWithCoordinates;
  final String initialQuery;

  const SearchLocationBottomSheet({
    Key? key,
    required this.onSearch,
    this.onSearchWithCoordinates,
    this.initialQuery = '',
  }) : super(key: key);

  @override
  State<SearchLocationBottomSheet> createState() =>
      _SearchLocationBottomSheetState();
}

class _SearchLocationBottomSheetState extends State<SearchLocationBottomSheet> {
  late TextEditingController _queryController;
  final LocationSearchService _searchService = LocationSearchService();
  double _radiusKm = 5.0;
  
  List<LocationSuggestion> _suggestions = [];
  bool _isLoadingSuggestions = false;
  Timer? _debounce;
  
  final List<String> _quickSuggestions = [
    'Soweto',
    'Sandton',
    'Johannesburg CBD',
    'Pretoria',
    'Midrand',
    'Fourways',
    'Rosebank',
    'Alexandra',
  ];

  @override
  void initState() {
    super.initState();
    _queryController = TextEditingController(text: widget.initialQuery);
    _queryController.addListener(_onSearchTextChanged);
  }

  @override
  void dispose() {
    _queryController.removeListener(_onSearchTextChanged);
    _queryController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchTextChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    
    setState(() {});
    
    if (_queryController.text.length >= 3) {
      _debounce = Timer(const Duration(milliseconds: 500), () {
        _fetchSuggestions(_queryController.text);
      });
    } else {
      setState(() {
        _suggestions = [];
      });
    }
  }

  Future<void> _fetchSuggestions(String query) async {
    if (!mounted) return;
    
    setState(() {
      _isLoadingSuggestions = true;
    });

    try {
      final suggestions = await _searchService.getLocationSuggestions(query);
      if (!mounted) return;
      
      setState(() {
        _suggestions = suggestions;
        _isLoadingSuggestions = false;
      });
    } catch (e) {
      print('Error fetching suggestions: $e');
      if (!mounted) return;
      
      setState(() {
        _isLoadingSuggestions = false;
      });
    }
  }

  void _performSearch() {
    if (_queryController.text.trim().isNotEmpty) {
      widget.onSearch(_queryController.text.trim(), _radiusKm);
    }
  }

  void _performSearchWithCoordinates(double lat, double lon) {
    if (widget.onSearchWithCoordinates != null) {
      // Use coordinates directly if callback provided
      widget.onSearchWithCoordinates!(lat, lon, _radiusKm);
      // Close the bottom sheet
      Navigator.pop(context);
    } else {
      // Fallback to text search
      _performSearch();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              
              SizedBox(height: 20),
              
              // Title
              Text(
                'Search by Location',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              
              SizedBox(height: 8),
              
              Text(
                'Find bus routes near any location',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
              
              SizedBox(height: 24),
              
              // Search input
              TextField(
                controller: _queryController,
                decoration: InputDecoration(
                  hintText: 'Enter location (e.g., Soweto, 123 Main St)',
                  prefixIcon: Icon(Icons.location_on),
                  suffixIcon: _queryController.text.isNotEmpty
                      ? IconButton(
                          icon: Icon(Icons.clear),
                          onPressed: () {
                            _queryController.clear();
                            setState(() {
                              _suggestions = [];
                            });
                          },
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.grey[100],
                ),
                onSubmitted: (_) => _performSearch(),
              ),
              
              // Autocomplete suggestions
              if (_isLoadingSuggestions)
                Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                )
              else if (_suggestions.isNotEmpty)
                Container(
                  margin: EdgeInsets.only(top: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: ListView.separated(
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    itemCount: _suggestions.length,
                    separatorBuilder: (context, index) => Divider(height: 1),
                    itemBuilder: (context, index) {
                      final suggestion = _suggestions[index];
                      return ListTile(
                        dense: true,
                        leading: Icon(Icons.place, size: 20, color: Colors.grey[600]),
                        title: Text(
                          suggestion.displayName,
                          style: TextStyle(fontSize: 14),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          suggestion.type.toUpperCase(),
                          style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                        ),
                        onTap: () {
                          _queryController.text = suggestion.displayName;
                          setState(() {
                            _suggestions = [];
                          });
                          // Automatically search using the suggestion's coordinates
                          Future.delayed(Duration(milliseconds: 100), () {
                            _performSearchWithCoordinates(suggestion.lat, suggestion.lon);
                          });
                        },
                      );
                    },
                  ),
                ),
              
              SizedBox(height: 24),
              
              // Radius slider
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Search Radius',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.red[50],
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${_radiusKm.toStringAsFixed(1)} km',
                          style: TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  Slider(
                    value: _radiusKm,
                    min: 1.0,
                    max: 20.0,
                    divisions: 19,
                    activeColor: Colors.red,
                    label: '${_radiusKm.toStringAsFixed(1)} km',
                    onChanged: (value) {
                      setState(() {
                        _radiusKm = value;
                      });
                    },
                  ),
                ],
              ),
              
              SizedBox(height: 16),
              
              // Quick suggestions
              Text(
                'Quick Suggestions',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              
              SizedBox(height: 12),
              
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _quickSuggestions.map((suggestion) {
                  return InkWell(
                    onTap: () {
                      _queryController.text = suggestion;
                      setState(() {
                        _suggestions = [];
                      });
                      // Auto-search after selecting suggestion
                      Future.delayed(Duration(milliseconds: 100), () {
                        _performSearch();
                      });
                    },
                    child: Chip(
                      label: Text(suggestion),
                      backgroundColor: Colors.grey[100],
                      side: BorderSide(color: Colors.grey[300]!),
                    ),
                  );
                }).toList(),
              ),
              
              SizedBox(height: 24),
              
              // Search button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _queryController.text.trim().isEmpty
                      ? null
                      : _performSearch,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    disabledBackgroundColor: Colors.grey[300],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.search),
                      SizedBox(width: 8),
                      Text(
                        'Search Routes',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

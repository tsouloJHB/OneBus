import 'package:flutter/material.dart';

class MapSearchLocation extends StatelessWidget {
  final VoidCallback onMyLocationPressed;

  const MapSearchLocation({Key? key, required this.onMyLocationPressed})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 60,
      left: 16,
      right: 16,
      child: Material(
        elevation: 4,
        borderRadius: BorderRadius.circular(16),
        child: TextField(
          decoration: InputDecoration(
            hintText: 'Search location',
            prefixIcon: const Icon(Icons.search),
            suffixIcon: IconButton(
              icon: const Icon(Icons.my_location),
              onPressed: onMyLocationPressed,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            filled: true,
            fillColor: Colors.white,
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

import 'search_location_overlay.dart';

import 'package:flutter/material.dart';

class RoutePlanWidget extends StatelessWidget {
  final String startLocation;
  final String destination;
  final List<String> interchanges;

  // Customization options
  final double iconSize;
  final Color startIconColor;
  final Color destinationIconColor;
  final Color interchangeIconColor;
  final List<Color> interchangeIconColors;
  final IconData startIcon;
  final IconData destinationIcon;
  final IconData interchangeIcon;
  final double lineHeight;

  const RoutePlanWidget({
    Key? key,
    required this.startLocation,
    required this.destination,
    this.interchanges = const [],
    this.interchangeIconColors = const [Colors.grey],
    this.iconSize = 20.0,
    this.startIconColor = Colors.purple,
    this.destinationIconColor = Colors.orange,
    this.interchangeIconColor = Colors.blue,
    this.startIcon = Icons.circle,
    this.destinationIcon = Icons.location_on,
    this.interchangeIcon = Icons.directions_bus,
    this.lineHeight = 30.0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Static Start Location
        _buildLocationRow(startLocation, true, false),

        // Scrollable Interchanges
        Expanded(
          child: ListView.builder(
            shrinkWrap: true,
            physics: const ClampingScrollPhysics(),
            itemCount: interchanges.length,
            itemBuilder: (context, index) {
              return _buildLocationRow(interchanges[index], false, false);
            },
          ),
        ),

        // Static Destination
        _buildLocationRow(destination, false, true),
      ],
    );
  }

  Widget _buildLocationRow(String location, bool isStart, bool isDestination) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(30, 0, 0, 0), // Adjust left padding
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon
          Column(
            children: [
              Icon(
                isStart
                    ? startIcon
                    : isDestination
                        ? destinationIcon
                        : interchangeIcon,
                color: isStart
                    ? startIconColor
                    : isDestination
                        ? destinationIconColor
                        : interchangeIconColor,
                size: iconSize,
              ),
              if (!isDestination && !isStart) ...[
                CustomPaint(
                  size: Size(2, lineHeight),
                  painter: DottedLinePainter(),
                ),
              ],
            ],
          ),
          const SizedBox(width: 8.0), // Reduced spacing between icon and text

          // Text
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 0.0), // Removed top padding
              child: Text(
                isStart
                    ? "Start Location: $location"
                    : isDestination
                        ? "Destination: $location"
                        : "Bus Interchange: $location",
                style: TextStyle(
                  fontSize: 16.0,
                  fontWeight: isStart || isDestination
                      ? FontWeight.bold
                      : FontWeight.normal,
                  color: isStart || isDestination ? Colors.black : Colors.grey,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class DottedLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey
      ..strokeWidth = 2;

    const double dashHeight = 4;
    const double dashSpace = 4;
    double startY = 0;

    while (startY < size.height) {
      canvas.drawLine(
        Offset(0, startY),
        Offset(0, startY + dashHeight),
        paint,
      );
      startY += dashHeight + dashSpace;
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

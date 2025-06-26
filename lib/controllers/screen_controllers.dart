import 'package:flutter/material.dart';

Widget trackBusScreenController(List<Widget> widgetScreens, int stage) {
  switch (stage) {
    case 0:
      return widgetScreens[0];
    case 1:
      return widgetScreens[1];
    case 2:
      return widgetScreens[2];
    default:
      return widgetScreens[0];
  }
}
    
import 'package:flutter/material.dart';
import 'utils/connection_test_widget.dart';

void main() {
  runApp(const WebSocketTestApp());
}

class WebSocketTestApp extends StatelessWidget {
  const WebSocketTestApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'WebSocket Connection Test',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const ConnectionTestWidget(),
    );
  }
}
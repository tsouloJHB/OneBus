import 'package:flutter/material.dart';
import '../services/bus_communication_services.dart';
import '../constants/app_constants.dart';

class ConnectionTestWidget extends StatefulWidget {
  const ConnectionTestWidget({Key? key}) : super(key: key);

  @override
  State<ConnectionTestWidget> createState() => _ConnectionTestWidgetState();
}

class _ConnectionTestWidgetState extends State<ConnectionTestWidget> {
  String _testResults = '';
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Connection Test'),
        backgroundColor: Colors.blue,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Current Configuration:',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text('WebSocket URL: ${AppConstants.webSocketUrl}'),
                    Text('API Base URL: ${AppConstants.apiBaseUrl}'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isLoading ? null : _runConnectionTests,
              child: _isLoading
                  ? const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        SizedBox(width: 8),
                        Text('Testing...'),
                      ],
                    )
                  : const Text('Run Connection Tests'),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Test Results:',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: SingleChildScrollView(
                          child: Text(
                            _testResults.isEmpty ? 'No tests run yet.' : _testResults,
                            style: const TextStyle(fontFamily: 'monospace'),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _runConnectionTests() async {
    setState(() {
      _isLoading = true;
      _testResults = 'Starting connection tests...\n\n';
    });

    // Test 1: HTTP Server Reachability
    _updateResults('1. Testing HTTP Server Reachability...');
    try {
      final isReachable = await BusCommunicationServices.testServerReachability();
      _updateResults(isReachable ? '✅ HTTP Server is reachable' : '❌ HTTP Server is not reachable');
    } catch (e) {
      _updateResults('❌ HTTP Server test failed: $e');
    }

    _updateResults('');

    // Test 2: WebSocket Connection
    _updateResults('2. Testing WebSocket Connection...');
    try {
      final wsConnected = await BusCommunicationServices.testWebSocketConnection();
      _updateResults(wsConnected ? '✅ WebSocket connection successful' : '❌ WebSocket connection failed');
    } catch (e) {
      _updateResults('❌ WebSocket test failed: $e');
    }

    _updateResults('');

    // Test 3: SockJS Handshake
    _updateResults('3. Testing SockJS Handshake...');
    try {
      final sockJSWorking = await BusCommunicationServices.testSockJSHandshake();
      _updateResults(sockJSWorking ? '✅ SockJS handshake successful' : '❌ SockJS handshake failed');
    } catch (e) {
      _updateResults('❌ SockJS test failed: $e');
    }

    _updateResults('');

    // Test 4: Multiple WebSocket Endpoints
    _updateResults('4. Testing Multiple WebSocket Endpoints...');
    try {
      final endpointResults = await BusCommunicationServices.testAllWebSocketEndpoints();
      for (final entry in endpointResults.entries) {
        final status = entry.value ? '✅' : '❌';
        _updateResults('$status ${entry.key}');
      }
    } catch (e) {
      _updateResults('❌ Endpoint tests failed: $e');
    }

    _updateResults('\n=== Test Summary ===');
    _updateResults('Configuration: ${AppConstants.webSocketUrl}');
    _updateResults('Tests completed at: ${DateTime.now()}');

    setState(() {
      _isLoading = false;
    });
  }

  void _updateResults(String message) {
    setState(() {
      _testResults += '$message\n';
    });
  }
}
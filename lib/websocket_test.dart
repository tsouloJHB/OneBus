import 'package:flutter/material.dart';
import 'services/bus_communication_services.dart';

class WebSocketTestWidget extends StatefulWidget {
  const WebSocketTestWidget({Key? key}) : super(key: key);

  @override
  State<WebSocketTestWidget> createState() => _WebSocketTestWidgetState();
}

class _WebSocketTestWidgetState extends State<WebSocketTestWidget> {
  String _testResult = 'Click "Test Connection" to start';
  bool _isTesting = false;

  Future<void> _testConnection() async {
    setState(() {
      _isTesting = true;
      _testResult = 'Testing connection...';
    });

    try {
      // First test if server is reachable via HTTP
      final serverReachable =
          await BusCommunicationServices.testServerReachability();

      if (!serverReachable) {
        setState(() {
          _testResult =
              '❌ Server is not reachable. Check if your server is running on 192.168.8.146:8080';
        });
        return;
      }

      // Test direct WebSocket connection first
      final directWsConnected = await BusCommunicationServices.testDirectWebSocketConnection();
      
      if (directWsConnected) {
        setState(() {
          _testResult = '✅ Direct WebSocket connection successful!\n\nYour server supports WebSocket connections, but STOMP might need different configuration.';
        });
        return;
      }
      
      // Test all STOMP WebSocket endpoints
      final endpointResults = await BusCommunicationServices.testAllWebSocketEndpoints();
      
      final successfulEndpoints = endpointResults.entries
          .where((entry) => entry.value)
          .map((entry) => entry.key)
          .toList();
      
      if (successfulEndpoints.isNotEmpty) {
        setState(() {
          _testResult = '✅ STOMP WebSocket connection successful!\n\nWorking endpoints:\n${successfulEndpoints.join('\n')}';
        });
      } else {
        final failedEndpoints = endpointResults.entries
            .where((entry) => !entry.value)
            .map((entry) => entry.key)
            .toList();
        
        setState(() {
          _testResult = '❌ All WebSocket endpoints failed.\n\nFailed endpoints:\n${failedEndpoints.join('\n')}\n\nServer is reachable but WebSocket upgrade failed. Check your Spring Boot WebSocket configuration.';
        });
      }
    } catch (e) {
      setState(() {
        _testResult = '❌ Test failed with error: $e';
      });
    } finally {
      setState(() {
        _isTesting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('WebSocket Connection Test'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'WebSocket Connection Test',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'This will test if your WebSocket server is reachable and can accept WebSocket connections.',
                      style: TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _isTesting ? null : _testConnection,
                      child: _isTesting
                          ? const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SizedBox(
                                  width: 16,
                                  height: 16,
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2),
                                ),
                                SizedBox(width: 8),
                                Text('Testing...'),
                              ],
                            )
                          : const Text('Test Connection'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Test Result:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _testResult,
                      style: const TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Troubleshooting Tips:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '1. Make sure your WebSocket server is running\n'
                      '2. Check if the IP address 192.168.8.146 is correct\n'
                      '3. Verify the server supports WebSocket protocol\n'
                      '4. Try different WebSocket endpoints in app_constants.dart\n'
                      '5. Check server logs for any errors',
                      style: TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

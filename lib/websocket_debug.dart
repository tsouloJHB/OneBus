import 'package:flutter/material.dart';
import 'services/bus_communication_services.dart';

class WebSocketDebugWidget extends StatefulWidget {
  const WebSocketDebugWidget({Key? key}) : super(key: key);

  @override
  State<WebSocketDebugWidget> createState() => _WebSocketDebugWidgetState();
}

class _WebSocketDebugWidgetState extends State<WebSocketDebugWidget> {
  String _log = 'Click "Run Tests" to start debugging...';
  bool _isRunning = false;

  Future<void> _runAllTests() async {
    setState(() {
      _isRunning = true;
      _log = 'Running tests...\n';
    });

    try {
      // Test 1: Server reachability
      _addLog('🔍 Testing server reachability...');
      final serverReachable =
          await BusCommunicationServices.testServerReachability();
      _addLog('Server reachable: $serverReachable');

      if (!serverReachable) {
        _addLog(
            '❌ Server is not reachable. Check if your Spring Boot server is running.');
        return;
      }

      // Test 2: SockJS handshake
      _addLog('\n🔍 Testing SockJS handshake...');
      final sockJSWorks = await BusCommunicationServices.testSockJSHandshake();
      _addLog('SockJS handshake: $sockJSWorks');

      // Test 3: Direct WebSocket
      _addLog('\n🔍 Testing direct WebSocket connection...');
      final directWsWorks =
          await BusCommunicationServices.testDirectWebSocketConnection();
      _addLog('Direct WebSocket: $directWsWorks');

      // Test 4: STOMP endpoints
      _addLog('\n🔍 Testing STOMP endpoints...');
      final endpointResults =
          await BusCommunicationServices.testAllWebSocketEndpoints();

      final workingEndpoints = endpointResults.entries
          .where((entry) => entry.value)
          .map((entry) => entry.key)
          .toList();

      _addLog(
          'Working STOMP endpoints: ${workingEndpoints.isEmpty ? "None" : workingEndpoints.join(", ")}');

      // Summary
      _addLog('\n📊 SUMMARY:');
      _addLog('✅ Server reachable: $serverReachable');
      _addLog('✅ SockJS handshake: $sockJSWorks');
      _addLog('✅ Direct WebSocket: $directWsWorks');
      _addLog('✅ STOMP endpoints working: ${workingEndpoints.isNotEmpty}');

      if (workingEndpoints.isNotEmpty) {
        _addLog('\n🎉 SUCCESS: Found working endpoints!');
        _addLog('Your Flutter app should be able to connect.');
      } else if (directWsWorks) {
        _addLog('\n⚠️  PARTIAL: Direct WebSocket works but STOMP doesn\'t.');
        _addLog('You may need to configure STOMP differently.');
      } else {
        _addLog('\n❌ ISSUE: No WebSocket connections working.');
        _addLog('Check your Spring Boot WebSocket configuration.');
      }
    } catch (e) {
      _addLog('\n❌ ERROR: $e');
    } finally {
      setState(() {
        _isRunning = false;
      });
    }
  }

  void _addLog(String message) {
    setState(() {
      _log += '$message\n';
    });
  }

  void _clearLog() {
    setState(() {
      _log = 'Log cleared.\n';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('WebSocket Debug'),
        actions: [
          IconButton(
            icon: const Icon(Icons.clear),
            onPressed: _isRunning ? null : _clearLog,
            tooltip: 'Clear Log',
          ),
        ],
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
                      'WebSocket Connection Debug',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'This will test all possible connection methods to your Spring Boot server.',
                      style: TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _isRunning ? null : _runAllTests,
                      child: _isRunning
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
                                Text('Running Tests...'),
                              ],
                            )
                          : const Text('Run All Tests'),
                    ),
                  ],
                ),
              ),
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
                        'Debug Log:',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: Colors.grey[300]!),
                          ),
                          child: SingleChildScrollView(
                            child: Text(
                              _log,
                              style: const TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 12,
                              ),
                            ),
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
}

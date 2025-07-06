import 'package:flutter/material.dart';
import '../services/bus_communication_services.dart';

class ConnectionTestWidget extends StatefulWidget {
  const ConnectionTestWidget({Key? key}) : super(key: key);

  @override
  State<ConnectionTestWidget> createState() => _ConnectionTestWidgetState();
}

class _ConnectionTestWidgetState extends State<ConnectionTestWidget> {
  bool _isTesting = false;
  String _testResult = '';
  bool? _httpResult;
  bool? _websocketResult;

  Future<void> _runTests() async {
    setState(() {
      _isTesting = true;
      _testResult = 'Running tests...\n';
    });

    try {
      // Test HTTP connection first
      _testResult += 'Testing HTTP connection...\n';
      _httpResult = await BusCommunicationServices.testServerReachability();
      _testResult +=
          'HTTP test result: ${_httpResult == true ? 'SUCCESS' : 'FAILED'}\n\n';

      // Test WebSocket connection
      _testResult += 'Testing WebSocket connection...\n';
      _websocketResult =
          await BusCommunicationServices.testWebSocketConnection();
      _testResult +=
          'WebSocket test result: ${_websocketResult == true ? 'SUCCESS' : 'FAILED'}\n\n';

      if (_httpResult == false) {
        _testResult +=
            '❌ Server is not reachable. Check if your server is running on 192.168.8.146:8080\n';
      } else if (_websocketResult == false) {
        _testResult +=
            '❌ Server is reachable but WebSocket connection failed. Try different WebSocket URLs.\n';
      } else {
        _testResult += '✅ All tests passed! WebSocket connection is working.\n';
      }
    } catch (e) {
      _testResult += '❌ Error during testing: $e\n';
    }

    setState(() {
      _isTesting = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Connection Test'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton(
              onPressed: _isTesting ? null : _runTests,
              child: _isTesting
                  ? const CircularProgressIndicator()
                  : const Text('Run Connection Tests'),
            ),
            const SizedBox(height: 20),
            if (_httpResult != null || _websocketResult != null) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Test Results',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Icon(
                            _httpResult == true
                                ? Icons.check_circle
                                : Icons.error,
                            color:
                                _httpResult == true ? Colors.green : Colors.red,
                          ),
                          const SizedBox(width: 8),
                          Text(
                              'HTTP Connection: ${_httpResult == true ? 'SUCCESS' : 'FAILED'}'),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            _websocketResult == true
                                ? Icons.check_circle
                                : Icons.error,
                            color: _websocketResult == true
                                ? Colors.green
                                : Colors.red,
                          ),
                          const SizedBox(width: 8),
                          Text(
                              'WebSocket Connection: ${_websocketResult == true ? 'SUCCESS' : 'FAILED'}'),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SingleChildScrollView(
                  child: Text(
                    _testResult.isEmpty
                        ? 'Click "Run Connection Tests" to start testing...'
                        : _testResult,
                    style: const TextStyle(fontFamily: 'monospace'),
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

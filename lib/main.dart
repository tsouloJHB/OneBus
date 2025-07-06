import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'models/BusInfo.dart';
import 'state/bus_info_state.dart';
import 'firebase_options.dart';
import 'views/auth/login.dart';
import 'services/bus_communication_services.dart';

// Create a provider for your app's state (replacing ChangeNotifier)
final busInfoProvider = StateNotifierProvider<BusInfoNotifier, BusInfo>((ref) {
  return BusInfoNotifier();
});

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Test WebSocket connection on app start (optional)
  // Uncomment the next line to test WebSocket connection when app starts
  _testWebSocketOnStart();

  runApp(
    ProviderScope(
      child: const MyApp(),
    ),
  );
}

// Test WebSocket connection on app start
Future<void> _testWebSocketOnStart() async {
  print('=== WebSocket Connection Test on App Start ===');

  // Test if server is reachable
  final serverReachable =
      await BusCommunicationServices.testServerReachability();
  print('Server reachable: $serverReachable');

  if (serverReachable) {
    // Test SockJS handshake first
    final sockJSWorks = await BusCommunicationServices.testSockJSHandshake();
    print('SockJS handshake: $sockJSWorks');

    // Test direct WebSocket connection
    final directWsWorks =
        await BusCommunicationServices.testDirectWebSocketConnection();
    print('Direct WebSocket: $directWsWorks');

    // Test all STOMP WebSocket endpoints
    final endpointResults =
        await BusCommunicationServices.testAllWebSocketEndpoints();
    print('STOMP WebSocket endpoint results: $endpointResults');

    final workingEndpoints = endpointResults.entries
        .where((entry) => entry.value)
        .map((entry) => entry.key)
        .toList();

    if (workingEndpoints.isNotEmpty) {
      print('✅ Working STOMP endpoints: $workingEndpoints');
    } else {
      print('❌ No working STOMP endpoints found');
    }

    // Summary
    print('=== Connection Summary ===');
    print('Server reachable: $serverReachable');
    print('SockJS handshake: $sockJSWorks');
    print('Direct WebSocket: $directWsWorks');
    print('STOMP endpoints working: ${workingEndpoints.isNotEmpty}');
  }

  print('=== End WebSocket Test ===');
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      //home: SplashScreen(),
      home: LoginPage(), // Set SplashScreen as the home screen
    );
  }
}

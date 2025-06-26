import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'models/BusInfo.dart';
import 'splash_screen.dart';
import 'state/bus_info_state.dart';
import 'firebase_options.dart';
import 'views/auth/login.dart';
import 'views/select_provider.dart';

// Create a provider for your app's state (replacing ChangeNotifier)
final busInfoProvider = StateNotifierProvider<BusInfoNotifier, BusInfo>((ref) {
  return BusInfoNotifier();
});

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(
    ProviderScope(
      child: const MyApp(),
    ),
  );
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

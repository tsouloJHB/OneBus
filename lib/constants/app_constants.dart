class AppConstants {
  // WebSocket endpoint matching your Spring Boot server configuration
  // For Android Emulator: use 10.0.2.2 (host machine)
  // For physical device: use 192.168.8.146
  // For iOS Simulator: use localhost
  static const String webSocketUrl =
      'ws://10.0.2.2:8080/ws/bus-updates/websocket';

  // Alternative endpoints if the above doesn't work
  // static const String webSocketUrl = 'ws://192.168.8.146:8080/ws/bus-updates/websocket'; // Physical device
  // static const String webSocketUrl = 'ws://localhost:8080/ws/bus-updates/websocket'; // iOS Simulator
  // static const String webSocketUrl = 'ws://10.0.2.2:8080/ws/bus-updates';
  // static const String webSocketUrl = 'ws://10.0.2.2:8080/ws';
  // static const String webSocketUrl = 'ws://10.0.2.2:8080/websocket';
}

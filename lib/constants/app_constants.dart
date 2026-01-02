class AppConstants {
  // WebSocket endpoint matching your Spring Boot server configuration
  // For Android Emulator: use 10.0.2.2 (host machine)
  // For physical device: use your actual IP address
  // For iOS Simulator: use localhost
  // NOTE: Make sure the backend server is running on port 8080
  static const String webSocketUrl =
      'ws://10.0.2.2:8080/ws/bus-updates/websocket';

  // HTTP API endpoint for REST calls
  static const String apiBaseUrl = 'http://10.0.2.2:8080/api';

  // Alternative endpoints if the above doesn't work
  // static const String webSocketUrl = 'ws://192.168.8.173:8080/ws/bus-updates'; // Physical device
  // static const String apiBaseUrl = 'http://192.168.8.173:8080/api'; // Physical device
  // static const String webSocketUrl = 'ws://localhost:8080/ws/bus-updates'; // iOS Simulator
  // static const String apiBaseUrl = 'http://localhost:8080/api'; // iOS Simulator
}

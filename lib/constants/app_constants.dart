class AppConstants {
  // WebSocket endpoint matching your Spring Boot server configuration
  // Using localhost with adb reverse port forwarding for Android emulator
  // For physical device: use your actual IP address
  // For iOS Simulator: use localhost
  // NOTE: Make sure the backend server is running on port 8080
  // For development: Use your machine's local IP for physical devices
  // Detected IP: 192.168.8.173
  static const String serverIp = '192.168.8.173';
  static const String serverPort = '8080';

  // WebSocket endpoint matching your Spring Boot server configuration
  static const String webSocketUrl =
      'ws://$serverIp:$serverPort/ws/bus-updates/websocket';

  // Root URL for resources (images, etc.)
  static const String rootUrl = 'http://$serverIp:$serverPort';

  // HTTP API endpoint for REST calls
  static const String apiBaseUrl = '$rootUrl/api';

  // Alternative endpoints (commented out)
  // static const String webSocketUrlLocal = 'ws://localhost:8080/ws/bus-updates/websocket';
  // static const String apiBaseUrlLocal = 'http://localhost:8080/api';
}

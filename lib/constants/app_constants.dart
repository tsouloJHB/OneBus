class AppConstants {
  // WebSocket endpoint matching your Spring Boot server configuration
  // Try different SockJS-compatible endpoints
  static const String webSocketUrl =
      'ws://192.168.8.146:8080/ws/bus-updates/websocket';

  // Alternative endpoints if the above doesn't work
  // static const String webSocketUrl = 'ws://192.168.8.146:8080/ws/bus-updates';
  // static const String webSocketUrl = 'ws://192.168.8.146:8080/ws';
  // static const String webSocketUrl = 'ws://192.168.8.146:8080/websocket';
  // static const String webSocketUrl = 'ws://localhost:8080/ws/bus-updates/websocket';
}

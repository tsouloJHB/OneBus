# WebSocket Connection Troubleshooting Guide

## Current Issue
The app is getting a 404 error when trying to connect to the WebSocket server. Based on your backend code, the server uses SockJS with the endpoint `/ws/bus-updates`, and the Flutter app needs to connect to the correct WebSocket endpoint.

## Changes Made

### 1. Fixed WebSocket URL Configuration
- Updated `AppConstants.webSocketUrl` to match your backend: `ws://192.168.8.146:8080/ws/bus-updates`
- Configured STOMP subscription to match your backend's topic format: `/topic/bus/{busNumber}_{direction}`
- Added proper subscribe/unsubscribe messages to `/app/subscribe` and `/app/unsubscribe`
- Enhanced data parsing to handle your backend's BusLocation model

### 2. Added Fallback Mechanism
- If WebSocket connection fails, the app automatically falls back to simulated bus data
- Added a 10-second timeout for WebSocket connections
- Enhanced error logging to help debug connection issues

### 3. Added Connection Testing
- Created `BusCommunicationServices.testWebSocketConnection()` method to test WebSocket connectivity
- Created `BusCommunicationServices.testServerReachability()` method to test HTTP connectivity
- Created `ConnectionTestWidget` for easy testing in the app

## Testing the Connection

### Option 1: Use the Test Widget
Add the test widget to your app for easy testing:

```dart
// In your main.dart or any widget
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => const WebSocketTestWidget(),
  ),
);
```

### Option 2: Test Programmatically
Add this code to test the connections:

```dart
// Test both HTTP and WebSocket connections
void testConnections() async {
  final httpReachable = await BusCommunicationServices.testServerReachability();
  final websocketConnected = await BusCommunicationServices.testWebSocketConnection();
  
  print('HTTP reachable: $httpReachable');
  print('WebSocket connected: $websocketConnected');
}
```

### Option 3: Try Different WebSocket URLs
In `lib/constants/app_constants.dart`, try these different URLs by uncommenting them:

```dart
class AppConstants {
  // WebSocket endpoint matching your Spring Boot server configuration
  static const String webSocketUrl = 'ws://192.168.8.146:8080/ws/bus-updates';
  
  // Alternative endpoints if the above doesn't work
  // static const String webSocketUrl = 'ws://192.168.8.146:8080/ws';
  // static const String webSocketUrl = 'ws://192.168.8.146:8080/websocket';
  // static const String webSocketUrl = 'ws://localhost:8080/ws/bus-updates';
}
```

## Backend Configuration (Your Server)

Your Spring Boot server is configured with:
- **WebSocket Endpoint**: `/ws/bus-updates` (SockJS)
- **STOMP Topics**: `/topic/bus/{busNumber}_{direction}`
- **Subscribe Message**: `/app/subscribe` with JSON `{"busNumber": "...", "direction": "..."}`
- **Unsubscribe Message**: `/app/unsubscribe` with JSON `{"busNumber": "...", "direction": "..."}`
- **BusLocation Model**: Contains `busNumber`, `tripDirection`, `latitude`, `longitude`, `speed`

## Common Issues and Solutions

### 1. Server Not Running
- Make sure your Spring Boot server is running on port 8080
- Check if the server supports WebSocket protocol and STOMP

### 2. Wrong Endpoint
- Your server uses SockJS with endpoint `/ws/bus-updates`
- The Flutter app should connect to `ws://192.168.8.146:8080/ws/bus-updates`

### 3. Network Issues
- Ensure the IP address `192.168.8.146` is correct and accessible
- Check if there are any firewall rules blocking the connection

### 4. Server Configuration
- Verify your Spring Boot WebSocket configuration is correct
- Check if the server requires specific headers or authentication
- Ensure the STOMP message handlers are properly configured

## Current Behavior
- The app will try to connect to the WebSocket server
- If connection fails or times out (10 seconds), it automatically falls back to simulated data
- You'll see detailed logs in the console showing the connection attempt and any errors

## Next Steps
1. Test the connection using the test method
2. Try different WebSocket URLs if the current one doesn't work
3. Check your server configuration and ensure it supports WebSocket connections
4. If the server is working, the app should connect successfully and receive real-time bus data
5. If not, the app will continue working with simulated data 
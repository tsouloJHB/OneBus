import 'dart:typed_data';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';

/// Service to handle local notifications with vibration and sound
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() {
    return _instance;
  }

  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  /// Initialize the notification service
  Future<void> initialize() async {
    if (_isInitialized) return;

    // Android initialization settings
    const AndroidInitializationSettings androidInitSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS initialization settings
    final DarwinInitializationSettings iOSInitSettings =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
      onDidReceiveLocalNotification: _onDidReceiveLocalNotification,
    );

    final InitializationSettings initSettings = InitializationSettings(
      android: androidInitSettings,
      iOS: iOSInitSettings,
    );

    await _notificationsPlugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onDidReceiveNotificationResponse,
    );

    _isInitialized = true;
    print('[NOTIFICATION] Notification service initialized');
  }

  /// Request notification permissions (iOS 13+)
  Future<bool?> requestPermissions() async {
    final isGranted = await _notificationsPlugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
          critical: false,
        );
    return isGranted;
  }

  /// Show notification when bus is approaching (1000m away)
  Future<void> showBusApproachingNotification({
    required String busNumber,
    required String destination,
    required int distanceMeters,
  }) async {
    if (!_isInitialized) {
      await initialize();
    }

    final timeMinutes = (distanceMeters / 500).ceil(); // Rough estimate

    final AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'bus_approaching_channel',
      'Bus Approaching Notifications',
      channelDescription: 'Notifications when a bus is approaching',
      importance: Importance.high,
      priority: Priority.high,
      vibrationPattern: Int64List.fromList([0, 500, 200, 500]),
      enableVibration: true,
      playSound: true,
      showProgress: false,
      ongoing: true,
      autoCancel: false,
    );

    final DarwinNotificationDetails iOSDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      badgeNumber: 1,
    );

    final NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidDetails,
      iOS: iOSDetails,
    );

    await _notificationsPlugin.show(
      1, // notification ID
      'Bus $busNumber Approaching!',
      'Get ready! Your bus will arrive in ~$timeMinutes minutes',
      platformChannelSpecifics,
      payload: 'bus_approaching:$busNumber',
    );

    print('[NOTIFICATION] Bus approaching notification shown for bus $busNumber');
  }

  /// Show notification when bus has arrived (100m away)
  Future<void> showBusArrivedNotification({
    required String busNumber,
    required String destination,
  }) async {
    if (!_isInitialized) {
      await initialize();
    }

    final AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'bus_arrived_channel',
      'Bus Arrived Notifications',
      channelDescription: 'Notifications when a bus has arrived',
      importance: Importance.max,
      priority: Priority.max,
      vibrationPattern: Int64List.fromList([0, 300, 200, 300, 200, 300]),
      enableVibration: true,
      playSound: true,
      showProgress: false,
      ongoing: false,
      autoCancel: true,
    );

    final DarwinNotificationDetails iOSDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      badgeNumber: 2,
    );

    final NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidDetails,
      iOS: iOSDetails,
    );

    await _notificationsPlugin.show(
      2, // notification ID
      'Bus $busNumber Has Arrived!',
      'Your bus has arrived at the stop',
      platformChannelSpecifics,
      payload: 'bus_arrived:$busNumber',
    );

    print('[NOTIFICATION] Bus arrived notification shown for bus $busNumber');
  }

  /// Cancel a notification
  Future<void> cancelNotification(int id) async {
    await _notificationsPlugin.cancel(id);
  }

  /// Cancel all notifications
  Future<void> cancelAllNotifications() async {
    await _notificationsPlugin.cancelAll();
  }

  // Callbacks
  void _onDidReceiveLocalNotification(
    int id,
    String? title,
    String? body,
    String? payload,
  ) {
    print('[NOTIFICATION] Received local notification: id=$id, title=$title, body=$body, payload=$payload');
  }

  void _onDidReceiveNotificationResponse(NotificationResponse response) {
    print('[NOTIFICATION] Notification clicked: ${response.payload}');
    // Handle notification tap if needed
    // You can navigate to a specific screen based on payload
  }
}

// Global notification service instance
final notificationService = NotificationService();

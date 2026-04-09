import 'dart:async';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart';
import 'package:open_filex/open_filex.dart';
import 'dart:io';
import 'auth_service.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import '../main.dart';
import '../screens/chat_screen.dart';
import '../screens/collaborations_screen.dart';

class NotificationService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
      
  static final StreamController<RemoteMessage> _messageStreamController = StreamController<RemoteMessage>.broadcast();
  static Stream<RemoteMessage> get onMessageReceived => _messageStreamController.stream;
  static int? currentChatId;

  static Future<void> initialize() async {
    // 1. Request Permission
    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      if (kDebugMode) print('User granted notification permission');
    }

    // 2. Initialize Local Notifications for Foreground
    const initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const initializationSettingsIOS = DarwinInitializationSettings();
    const initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _localNotifications.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        if (response.payload != null) {
          final data = jsonDecode(response.payload!);
          _handleInteraction(data);
        }
      },
    );

    // 2b. Handle app opened from terminated state
    RemoteMessage? initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      _handleInteraction(initialMessage.data);
    }

    // 2c. Handle app opened from background state
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      _handleInteraction(message.data);
    });

    // 3. Handle Foreground Messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (kDebugMode) print('Got a message whilst in the foreground!');
      _messageStreamController.add(message);
      
      // Optionally suppress notification if already in this chat
      final data = message.data;
      if (data['type'] == 'chat' && currentChatId != null) {
        if (data['sender_id'].toString() == currentChatId.toString()) {
          return;
        }
      }

      _showLocalNotification(message);
    });

    // 4. Handle token refresh
    _messaging.onTokenRefresh.listen((token) {
      _uploadToken(token);
    });

    // Get initial token
    String? token = await _messaging.getToken();
    if (token != null) {
      await _uploadToken(token);
    }
  }

  static Future<void> _uploadToken(String token) async {
    try {
      final c = await AuthService.client;
      await c.post(
        '/api/update-fcm-token',
        data: {'fcm_token': token},
      );
      if (kDebugMode) print('FCM Token uploaded: $token');
    } catch (e) {
      if (kDebugMode) print('Error uploading FCM token: $e');
    }
  }

  static Future<void> _showLocalNotification(RemoteMessage message) async {
    const androidDetails = AndroidNotificationDetails(
      'messages_channel',
      'Messages',
      channelDescription: 'Notifications for new messages',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
    );

    const iosDetails = DarwinNotificationDetails();
    const platformDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      id: DateTime.now().millisecond,
      title: message.notification?.title ?? 'New Message',
      body: message.notification?.body ?? '',
      notificationDetails: platformDetails,
      payload: jsonEncode(message.data),
    );
  }

  static Future<void> showDownloadNotification(String fileName, String savePath) async {
    const androidDetails = AndroidNotificationDetails(
      'downloads_channel',
      'Downloads',
      channelDescription: 'Notifications for downloaded files',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
    );

    const iosDetails = DarwinNotificationDetails();
    const platformDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      id: DateTime.now().millisecond,
      title: 'Download Complete',
      body: savePath.contains('Download') ? 'Saved in Downloads: $fileName' : 'Saved: $fileName',
      notificationDetails: platformDetails,
      payload: jsonEncode({'type': 'download', 'path': savePath}),
    );
  }

  static void _handleInteraction(Map<String, dynamic> data) {
    if (data['type'] == 'download') {
      final savePath = data['path'];
      if (savePath != null) {
        OpenFilex.open(savePath);
      }
      return;
    }

    if (data['type'] == 'chat' && data['sender_id'] != null) {
      final senderId = int.tryParse(data['sender_id'].toString());
      if (currentChatId == senderId) return; // Already in this chat
      
      final context = navigatorKey.currentContext;
      if (context != null) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ChatScreen(
              contact: {
                'id': senderId,
                'name': data['sender_name'] ?? 'User',
              },
            ),
          ),
        );
      }
    } else if (data['type'] == 'collaboration') {
      final context = navigatorKey.currentContext;
      if (context != null) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const CollaborationsScreen()),
        );
      }
    }
  }
}

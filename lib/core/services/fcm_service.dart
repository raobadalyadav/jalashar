import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Background messages are handled here (app killed / background).
  // Firebase is already initialised by the time this runs.
  debugPrint('[FCM] Background message: ${message.messageId}');
}

class FcmService {
  FcmService._();
  static final FcmService instance = FcmService._();

  final _messaging = FirebaseMessaging.instance;

  Future<void> init() async {
    // Request permission (iOS + Android 13+)
    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    // Register background handler
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    // Foreground message handler
    FirebaseMessaging.onMessage.listen((message) {
      debugPrint('[FCM] Foreground: ${message.notification?.title}');
      // TODO: show local notification via flutter_local_notifications
    });

    // App opened from notification
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      debugPrint('[FCM] Opened from notification: ${message.data}');
      // TODO: navigate based on message.data['route']
    });

    // Get initial message (app launched from killed state via notification)
    final initial = await _messaging.getInitialMessage();
    if (initial != null) {
      debugPrint('[FCM] Initial message: ${initial.data}');
    }

    // Log token for testing
    final token = await _messaging.getToken();
    debugPrint('[FCM] Token: $token');
  }

  Future<String?> getToken() => _messaging.getToken();
}

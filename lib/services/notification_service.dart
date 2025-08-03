import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class NotificationService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static Future<void> initialize() async {
    // Request permission
    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // Initialize local notifications
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );
    
    await _localNotifications.initialize(initSettings);

    // Get and save FCM token
    final token = await _messaging.getToken();
    if (token != null) {
      await _saveTokenToFirestore(token);
    }

    // Listen for token refresh
    _messaging.onTokenRefresh.listen(_saveTokenToFirestore);

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
  }

  static Future<void> _saveTokenToFirestore(String token) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await _firestore.collection('users').doc(user.uid).update({
          'fcmToken': token,
          'tokenUpdatedAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      print('Failed to save FCM token: $e');
    }
  }

  static Future<void> _handleForegroundMessage(RemoteMessage message) async {
    const androidDetails = AndroidNotificationDetails(
      'chat_channel',
      'Chat Messages',
      channelDescription: 'Notifications for chat messages',
      importance: Importance.high,
      priority: Priority.high,
    );
    
    const iosDetails = DarwinNotificationDetails();
    const details = NotificationDetails(android: androidDetails, iOS: iosDetails);

    await _localNotifications.show(
      message.hashCode,
      message.notification?.title ?? 'New Message',
      message.notification?.body ?? 'You have a new message',
      details,
    );
  }

  static Future<void> sendChatNotification({
    required String receiverUserId,
    required String senderName,
    required String message,
    required String chatId,
  }) async {
    try {
      // Get receiver's FCM token
      final receiverDoc = await _firestore.collection('users').doc(receiverUserId).get();
      final fcmToken = receiverDoc.data()?['fcmToken'];
      
      if (fcmToken == null) return;

      // Send notification via FCM
      await _sendFCMNotification(
        token: fcmToken,
        title: senderName,
        body: _formatMessageForNotification(message),
        data: {
          'type': 'chat_message',
          'chatId': chatId,
          'senderId': FirebaseAuth.instance.currentUser!.uid,
        },
      );
    } catch (e) {
      print('Failed to send notification: $e');
    }
  }

  static String _formatMessageForNotification(String message) {
    if (message.length > 50) {
      return '${message.substring(0, 47)}...';
    }
    return message;
  }

  static Future<void> _sendFCMNotification({
    required String token,
    required String title,
    required String body,
    required Map<String, String> data,
  }) async {
    // Simplified notification - just save to Firestore for now
    try {
      await _firestore.collection('notifications').add({
        'token': token,
        'title': title,
        'body': body,
        'data': data,
        'timestamp': FieldValue.serverTimestamp(),
        'sent': false,
      });
    } catch (e) {
      print('Failed to save notification: $e');
    }
  }
}
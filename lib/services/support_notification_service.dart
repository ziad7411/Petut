import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';
import '../models/Notification.dart';
import '../app_colors.dart';

class SupportNotificationService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications = 
      FlutterLocalNotificationsPlugin();

  // إعداد الإشعارات
  static Future<void> initialize() async {
    // إعداد الإشعارات المحلية
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );
    
    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // الاستماع للرسائل في المقدمة
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    
    // الاستماع للرسائل عند النقر عليها
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);
  }

  // التعامل مع النقر على الإشعار
  static void _onNotificationTapped(NotificationResponse response) {
    final payload = response.payload;
    if (payload != null) {
      // يمكن إضافة منطق للانتقال لشاشة الدعم
      print('Notification tapped: $payload');
    }
  }

  // التعامل مع الرسائل في المقدمة
  static Future<void> _handleForegroundMessage(RemoteMessage message) async {
    if (message.data['type'] == 'support_reply') {
      await _showSupportNotification(
        title: message.notification?.title ?? 'Support Reply',
        body: message.notification?.body ?? 'You have received a reply to your support ticket',
        ticketId: message.data['ticketId'],
      );
    }
  }

  // التعامل مع النقر على الإشعار
  static void _handleNotificationTap(RemoteMessage message) {
    if (message.data['type'] == 'support_reply') {
      // يمكن إضافة منطق للانتقال لشاشة الدعم
      print('Support notification tapped: ${message.data['ticketId']}');
    }
  }

  // عرض إشعار الدعم الفني
  static Future<void> _showSupportNotification({
    required String title,
    required String body,
    required String ticketId,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'support_channel',
      'Technical Support',
      channelDescription: 'Technical support notifications',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      color: AppColors.lightSecondary,
      playSound: true,
      enableVibration: true,
    );
    
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    
    const details = NotificationDetails(
      android: androidDetails, 
      iOS: iosDetails,
    );

    await _localNotifications.show(
      ticketId.hashCode,
      title,
      body,
      details,
      payload: ticketId,
    );
  }

  // إرسال إشعار push للمستخدم
  static Future<void> sendSupportReplyNotification({
    required String userId,
    required String ticketId,
    required String subject,
    required String adminName,
  }) async {
    try {
      // جلب FCM token للمستخدم
      final userDoc = await _firestore.collection('users').doc(userId).get();
      final fcmToken = userDoc.data()?['fcmToken'];
      
      if (fcmToken == null) return;

      // حفظ الإشعار في قاعدة البيانات
      await _firestore.collection('notifications').add({
        'userId': userId,
        'title': 'Support Reply',
        'message': 'Reply received for ticket: $subject',
        'type': 'support_reply',
        'data': {
          'ticketId': ticketId,
          'adminName': adminName,
        },
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // إرسال push notification
      await _sendPushNotification(
        token: fcmToken,
        title: 'Support Reply',
        body: 'Reply received for ticket: $subject',
        data: {
          'type': 'support_reply',
          'ticketId': ticketId,
        },
      );
    } catch (e) {
      print('Error sending support notification: $e');
    }
  }

  // إرسال push notification
  static Future<void> _sendPushNotification({
    required String token,
    required String title,
    required String body,
    required Map<String, String> data,
  }) async {
    try {
      // حفظ في مجموعة FCM للمعالجة بواسطة Cloud Function
      await _firestore.collection('fcm_notifications').add({
        'token': token,
        'notification': {
          'title': title,
          'body': body,
        },
        'data': data,
        'timestamp': FieldValue.serverTimestamp(),
        'processed': false,
      });
    } catch (e) {
      print('Error sending push notification: $e');
    }
  }

  // جلب عدد الإشعارات غير المقروءة
  static Stream<int> getUnreadNotificationsCount() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return Stream.value(0);

    return _firestore
        .collection('notifications')
        .where('userId', isEqualTo: user.uid)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  // جلب إشعارات المستخدم
  static Stream<List<AppNotification>> getUserNotifications() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return Stream.value([]);

    return _firestore
        .collection('notifications')
        .where('userId', isEqualTo: user.uid)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => AppNotification.fromFirestore(doc))
            .toList());
  }

  // تحديد الإشعار كمقروء
  static Future<void> markNotificationAsRead(String notificationId) async {
    await _firestore.collection('notifications').doc(notificationId).update({
      'isRead': true,
    });
  }

  // تحديد جميع الإشعارات كمقروءة
  static Future<void> markAllNotificationsAsRead() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final batch = _firestore.batch();
    final notifications = await _firestore
        .collection('notifications')
        .where('userId', isEqualTo: user.uid)
        .where('isRead', isEqualTo: false)
        .get();

    for (final doc in notifications.docs) {
      batch.update(doc.reference, {'isRead': true});
    }

    await batch.commit();
  }
}
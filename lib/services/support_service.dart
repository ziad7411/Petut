import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/SupportTicket.dart';
import '../models/Notification.dart';
import 'support_notification_service.dart';

class SupportService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // إنشاء تذكرة دعم جديدة
  static Future<String> createSupportTicket({
    required String subject,
    required String initialMessage,
    String priority = 'medium',
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    // جلب بيانات المستخدم
    final userDoc = await _firestore.collection('users').doc(user.uid).get();
    final userData = userDoc.data() ?? {};

    final ticketId = _firestore.collection('support_tickets').doc().id;
    final now = DateTime.now();

    final firstMessage = SupportMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      senderId: user.uid,
      senderName: userData['fullName'] ?? 'User',
      senderRole: 'user',
      message: initialMessage,
      timestamp: now,
    );

    final ticket = SupportTicket(
      id: ticketId,
      userId: user.uid,
      userName: userData['fullName'] ?? 'User',
      userEmail: user.email ?? '',
      userImage: userData['profileImage'],
      subject: subject,
      status: 'open',
      priority: priority,
      createdAt: now,
      updatedAt: now,
      messages: [firstMessage],
    );

    await _firestore.collection('support_tickets').doc(ticketId).set(ticket.toMap());
    return ticketId;
  }

  // إرسال رسالة في تذكرة الدعم
  static Future<void> sendMessage({
    required String ticketId,
    required String message,
    String? imageUrl,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    final userDoc = await _firestore.collection('users').doc(user.uid).get();
    final userData = userDoc.data() ?? {};

    final newMessage = SupportMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      senderId: user.uid,
      senderName: userData['fullName'] ?? 'User',
      senderRole: 'user',
      message: message,
      timestamp: DateTime.now(),
      imageUrl: imageUrl,
    );

    await _firestore.collection('support_tickets').doc(ticketId).update({
      'messages': FieldValue.arrayUnion([newMessage.toMap()]),
      'updatedAt': Timestamp.fromDate(DateTime.now()),
      'status': 'open', // إعادة فتح التذكرة عند إرسال رسالة جديدة
    });
  }

  // جلب تذاكر الدعم للمستخدم الحالي
  static Stream<List<SupportTicket>> getUserSupportTickets() {
    final user = _auth.currentUser;
    if (user == null) return Stream.value([]);

    return _firestore
        .collection('support_tickets')
        .where('userId', isEqualTo: user.uid)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => SupportTicket.fromFirestore(doc))
            .toList());
  }

  // جلب تذكرة دعم محددة
  static Stream<SupportTicket?> getSupportTicket(String ticketId) {
    return _firestore
        .collection('support_tickets')
        .doc(ticketId)
        .snapshots()
        .map((doc) => doc.exists ? SupportTicket.fromFirestore(doc) : null);
  }

  // جلب جميع التذاكر للأدمن
  static Stream<List<SupportTicket>> getAllSupportTickets() {
    return _firestore
        .collection('support_tickets')
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => SupportTicket.fromFirestore(doc))
            .toList());
  }

  // تعيين أدمن لتذكرة
  static Future<void> assignTicketToAdmin({
    required String ticketId,
    required String adminId,
    required String adminName,
  }) async {
    await _firestore.collection('support_tickets').doc(ticketId).update({
      'assignedAdminId': adminId,
      'assignedAdminName': adminName,
      'status': 'in_progress',
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  // تغيير حالة التذكرة
  static Future<void> updateTicketStatus({
    required String ticketId,
    required String status,
  }) async {
    await _firestore.collection('support_tickets').doc(ticketId).update({
      'status': status,
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  // إرسال رد من الأدمن
  static Future<void> sendAdminReply({
    required String ticketId,
    required String message,
    required String adminId,
    required String adminName,
    String? imageUrl,
  }) async {
    final adminMessage = SupportMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      senderId: adminId,
      senderName: adminName,
      senderRole: 'admin',
      message: message,
      timestamp: DateTime.now(),
      imageUrl: imageUrl,
    );

    // تحديث التذكرة
    await _firestore.collection('support_tickets').doc(ticketId).update({
      'messages': FieldValue.arrayUnion([adminMessage.toMap()]),
      'updatedAt': Timestamp.fromDate(DateTime.now()),
      'status': 'in_progress',
      'hasUnreadMessages': true, // إضافة مؤشر للرسائل غير المقروءة
    });

    // إرسال إشعار للمستخدم
    final ticketDoc = await _firestore.collection('support_tickets').doc(ticketId).get();
    if (ticketDoc.exists) {
      final ticketData = ticketDoc.data()!;
      await SupportNotificationService.sendSupportReplyNotification(
        userId: ticketData['userId'],
        ticketId: ticketId,
        subject: ticketData['subject'],
        adminName: adminName,
      );
    }
  }



  // تحديد الرسائل كمقروءة
  static Future<void> markTicketAsRead(String ticketId) async {
    await _firestore.collection('support_tickets').doc(ticketId).update({
      'hasUnreadMessages': false,
    });
  }
}
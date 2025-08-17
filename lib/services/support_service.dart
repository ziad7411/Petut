import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/SupportTicket.dart';
import '../models/Notification.dart';
import 'support_notification_service.dart';

class SupportService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // وظيفة إنشاء تذكرة دعم جديدة
  static Future<String> createSupportTicket({
    required String subject,
    required String initialMessage,
    String priority = 'medium',
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    // التحقق من وجود Live Chat مفتوح فقط
    if (priority == 'live_chat') {
      final liveChatTickets = await _firestore
          .collection('support_tickets')
          .where('userId', isEqualTo: user.uid)
          .where('priority', isEqualTo: 'live_chat')
          .where('status', whereIn: ['open', 'in_progress'])
          .get();
      
      if (liveChatTickets.docs.isNotEmpty) {
        throw Exception('You already have an active live chat session. Please close it before starting a new one.');
      }
    }

    final userDoc = await _firestore.collection('users').doc(user.uid).get();
    final userData = userDoc.data() ?? {};
    print('Creating ticket for user: ${user.uid}, userData: $userData');

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

    try {
      await _firestore.collection('support_tickets').doc(ticketId).set(ticket.toMap());
      print('Ticket created successfully: $ticketId');
      return ticketId;
    } catch (e) {
      print('Error creating ticket: $e');
      throw Exception('Failed to create ticket: $e');
    }
  }

  // وظيفة إرسال رسالة في تذكرة الدعم (لليوزر فقط)
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

    // جلب حالة التذكرة الحالية
    final ticketDoc = await _firestore.collection('support_tickets').doc(ticketId).get();
    final currentStatus = ticketDoc.data()?['status'] ?? 'open';
    
    await _firestore.collection('support_tickets').doc(ticketId).update({
      'messages': FieldValue.arrayUnion([newMessage.toMap()]),
      'updatedAt': Timestamp.fromDate(DateTime.now()),
      'status': currentStatus == 'closed' ? 'open' : currentStatus,
    });

    // إرسال إشعار للأدمن
    if (ticketDoc.exists) {
      final ticketData = ticketDoc.data()!;
      await SupportNotificationService.sendUserMessageNotification(
        ticketId: ticketId,
        subject: ticketData['subject'],
        userName: userData['fullName'] ?? 'User',
        message: message,
      );
    }
  }

  // وظيفة جلب تذاكر الدعم للمستخدم الحالي فقط
  static Stream<List<SupportTicket>> getUserSupportTickets() {
    final user = _auth.currentUser;
    if (user == null) return Stream.value([]);

    return _firestore
        .collection('support_tickets')
        .where('userId', isEqualTo: user.uid)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((snapshot) {
          print('Raw snapshot: ${snapshot.docs.length} documents');
          final tickets = <SupportTicket>[];
          
          for (final doc in snapshot.docs) {
            try {
              final ticket = SupportTicket.fromFirestore(doc);
              tickets.add(ticket);
              print('Added ticket to list: ${ticket.subject}');
            } catch (e) {
              print('Error parsing ticket ${doc.id}: $e');
            }
          }
          
          print('Final tickets list: ${tickets.length} tickets');
          return tickets;
        });
  }

  // وظيفة جلب تذكرة دعم محددة
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

  // حذف التذكرة تماماً
  static Future<void> deleteTicket(String ticketId) async {
    await _firestore.collection('support_tickets').doc(ticketId).delete();
  }
}
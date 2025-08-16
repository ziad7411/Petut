import 'package:cloud_firestore/cloud_firestore.dart';

class SupportTicket {
  final String id;
  final String userId;
  final String userName;
  final String userEmail;
  final String? userImage;
  final String subject;
  final String status; // 'open', 'in_progress', 'closed'
  final String priority; // 'low', 'medium', 'high'
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? assignedAdminId;
  final String? assignedAdminName;
  final List<SupportMessage> messages;
  final bool hasUnreadMessages; // مؤشر للرسائل غير المقروءة

  SupportTicket({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userEmail,
    this.userImage,
    required this.subject,
    required this.status,
    required this.priority,
    required this.createdAt,
    required this.updatedAt,
    this.assignedAdminId,
    this.assignedAdminName,
    required this.messages,
    this.hasUnreadMessages = false,
  });

  factory SupportTicket.fromFirestore(DocumentSnapshot doc) {
    try {
      final data = doc.data() as Map<String, dynamic>;
      print('Parsing ticket ${doc.id}: $data');
      
      final ticket = SupportTicket(
        id: doc.id,
        userId: data['userId'] ?? '',
        userName: data['userName'] ?? '',
        userEmail: data['userEmail'] ?? '',
        userImage: data['userImage'],
        subject: data['subject'] ?? '',
        status: data['status'] ?? 'open',
        priority: data['priority'] ?? 'medium',
        createdAt: data['createdAt'] != null 
            ? (data['createdAt'] as Timestamp).toDate() 
            : DateTime.now(),
        updatedAt: data['updatedAt'] != null 
            ? (data['updatedAt'] as Timestamp).toDate() 
            : DateTime.now(),
        assignedAdminId: data['assignedAdminId'],
        assignedAdminName: data['assignedAdminName'],
        messages: (data['messages'] as List<dynamic>?)
                ?.map((m) {
                  try {
                    return SupportMessage.fromMap(m as Map<String, dynamic>);
                  } catch (e) {
                    print('Error parsing message: $e');
                    return null;
                  }
                })
                .where((m) => m != null)
                .cast<SupportMessage>()
                .toList() ??
            [],
        hasUnreadMessages: data['hasUnreadMessages'] ?? false,
      );
      
      print('Successfully parsed ticket: ${ticket.id} - ${ticket.subject}');
      return ticket;
    } catch (e) {
      print('Error parsing ticket ${doc.id}: $e');
      rethrow;
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'userName': userName,
      'userEmail': userEmail,
      'userImage': userImage,
      'subject': subject,
      'status': status,
      'priority': priority,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'assignedAdminId': assignedAdminId,
      'assignedAdminName': assignedAdminName,
      'messages': messages.map((m) => m.toMap()).toList(),
      'hasUnreadMessages': hasUnreadMessages,
    };
  }
}

class SupportMessage {
  final String id;
  final String senderId;
  final String senderName;
  final String senderRole; // 'user' or 'admin'
  final String message;
  final DateTime timestamp;
  final String? imageUrl;

  SupportMessage({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.senderRole,
    required this.message,
    required this.timestamp,
    this.imageUrl,
  });

  factory SupportMessage.fromMap(Map<String, dynamic> data) {
    return SupportMessage(
      id: data['id'] ?? '',
      senderId: data['senderId'] ?? '',
      senderName: data['senderName'] ?? '',
      senderRole: data['senderRole'] ?? 'user',
      message: data['message'] ?? '',
      timestamp: data['timestamp'] != null 
          ? (data['timestamp'] as Timestamp).toDate() 
          : DateTime.now(),
      imageUrl: data['imageUrl'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'senderId': senderId,
      'senderName': senderName,
      'senderRole': senderRole,
      'message': message,
      'timestamp': Timestamp.fromDate(timestamp),
      'imageUrl': imageUrl,
    };
  }
}
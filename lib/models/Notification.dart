import 'package:cloud_firestore/cloud_firestore.dart';

class AppNotification {
  final String id;
  final String userId;
  final String title;
  final String message;
  final String type; // 'rating_request', 'booking_confirmed', etc.
  final Map<String, dynamic>? data; // Extra data like bookingId, doctorId
  final bool isRead;
  final DateTime createdAt;

  AppNotification({
    required this.id,
    required this.userId,
    required this.title,
    required this.message,
    required this.type,
    this.data,
    required this.isRead,
    required this.createdAt,
  });

  factory AppNotification.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AppNotification(
      id: doc.id,
      userId: data['userId'] ?? '',
      title: data['title'] ?? '',
      message: data['message'] ?? '',
      type: data['type'] ?? '',
      data: data['data'],
      isRead: data['isRead'] ?? false,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'title': title,
      'message': message,
      'type': type,
      'data': data,
      'isRead': isRead,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }

  // Helper method to create rating request notification
  static Map<String, dynamic> createRatingRequest({
    required String userId,
    required String doctorName,
    required String bookingId,
    required String doctorId,
  }) {
    return {
      'userId': userId,
      'title': 'Rate Your Experience',
      'message': 'How was your appointment with Dr. $doctorName? Please rate your experience.',
      'type': 'rating_request',
      'data': {
        'bookingId': bookingId,
        'doctorId': doctorId,
        'doctorName': doctorName,
      },
      'isRead': false,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}
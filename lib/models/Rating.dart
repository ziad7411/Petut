import 'package:cloud_firestore/cloud_firestore.dart';

class Rating {
  final String id;
  final String doctorId;
  final String userId;
  final String username;
  final String bookingId;
  final double rating;
  final String? comment;
  final DateTime createdAt;

  Rating({
    required this.id,
    required this.doctorId,
    required this.userId,
    required this.username,
    required this.bookingId,
    required this.rating,
    this.comment,
    required this.createdAt,
  });

  factory Rating.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Rating(
      id: doc.id,
      doctorId: data['doctorId'] ?? '',
      userId: data['userId'] ?? '',
      username: data['username'] ?? '',
      bookingId: data['bookingId'] ?? '',
      rating: (data['rating'] as num?)?.toDouble() ?? 0.0,
      comment: data['comment'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'doctorId': doctorId,
      'userId': userId,
      'username': username,
      'bookingId': bookingId,
      'rating': rating,
      'comment': comment,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}
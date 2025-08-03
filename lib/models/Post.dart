import 'package:cloud_firestore/cloud_firestore.dart';

class Post {
  final String id;
  final String userId;
  final String topic;
  final String content;
  final DateTime timestamp;
  final String? imageUrl;
  final GeoPoint? location;
  
  // User data (fetched separately)
  String? authorName;
  String? authorImage;
  int commentsCount = 0;

  Post({
    required this.id,
    required this.userId,
    required this.topic,
    required this.content,
    required this.timestamp,
    this.imageUrl,
    this.location,
    this.authorName,
    this.authorImage,
    this.commentsCount = 0,
  });

  factory Post.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Post(
      id: doc.id,
      userId: data['userId'] ?? '',
      topic: data['topic'] ?? 'Others',
      content: data['content'] ?? '',
      timestamp: data['timestamp'] != null ? (data['timestamp'] as Timestamp).toDate() : DateTime.now(),
      imageUrl: data['imageUrl'],
      location: data['location'],
    );
  }


}

class Comment {
  final String id;
  final String userId;
  final String comment;
  final DateTime timestamp;
  
  // User data (fetched separately)
  String? authorName;
  String? authorImage;

  Comment({
    required this.id,
    required this.userId,
    required this.comment,
    required this.timestamp,
    this.authorName,
    this.authorImage,
  });

  factory Comment.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Comment(
      id: doc.id,
      userId: data['userId'] ?? '',
      comment: data['comment'] ?? '',
      timestamp: data['timestamp'] != null ? (data['timestamp'] as Timestamp).toDate() : DateTime.now(),
    );
  }
}
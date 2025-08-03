import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/Chat.dart';

class ChatService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // Create or get existing chat between two users
  static Future<String> createOrGetChat(String otherUserId) async {
    final currentUserId = _auth.currentUser!.uid;
    final participants = [currentUserId, otherUserId]..sort();
    
    try {
      // Check if chat already exists - simplified approach
      final existingChats = await _firestore
          .collection('chats')
          .where('participants', arrayContains: currentUserId)
          .get();
      
      for (var doc in existingChats.docs) {
        final chatParticipants = List<String>.from(doc.data()['participants']);
        if (chatParticipants.contains(otherUserId) && chatParticipants.length == 2) {
          return doc.id;
        }
      }
      
      // Create new chat
      final chatDoc = await _firestore.collection('chats').add({
        'participants': participants,
        'lastMessage': '',
        'lastMessageTime': FieldValue.serverTimestamp(),
        'lastMessageSenderId': '',
        'unreadCount': {
          currentUserId: 0,
          otherUserId: 0,
        },
        'createdAt': FieldValue.serverTimestamp(),
      });
      
      return chatDoc.id;
    } catch (e) {
      // If there's an error, create a new chat
      final chatDoc = await _firestore.collection('chats').add({
        'participants': participants,
        'lastMessage': '',
        'lastMessageTime': FieldValue.serverTimestamp(),
        'lastMessageSenderId': '',
        'unreadCount': {
          currentUserId: 0,
          otherUserId: 0,
        },
        'createdAt': FieldValue.serverTimestamp(),
      });
      
      return chatDoc.id;
    }
  }

  // Send message
  static Future<void> sendMessage(String chatId, String content, MessageType type) async {
    final currentUserId = _auth.currentUser!.uid;
    final timestamp = DateTime.now();
    
    // Get chat to find other participant
    final chatDoc = await _firestore.collection('chats').doc(chatId).get();
    final participants = List<String>.from(chatDoc.data()!['participants']);
    final otherUserId = participants.firstWhere((id) => id != currentUserId);
    
    // Add message
    await _firestore.collection('messages').add({
      'chatId': chatId,
      'senderId': currentUserId,
      'content': content,
      'timestamp': Timestamp.fromDate(timestamp),
      'type': type.toString().split('.').last,
      'isRead': false,
    });
    
    // Update chat
    final currentUnreadCount = Map<String, int>.from(chatDoc.data()!['unreadCount'] ?? {});
    currentUnreadCount[otherUserId] = (currentUnreadCount[otherUserId] ?? 0) + 1;
    currentUnreadCount[currentUserId] = 0;
    
    await _firestore.collection('chats').doc(chatId).update({
      'lastMessage': content,
      'lastMessageTime': Timestamp.fromDate(timestamp),
      'lastMessageSenderId': currentUserId,
      'unreadCount': currentUnreadCount,
    });
  }

  // Get user chats
  static Stream<List<Chat>> getUserChats() {
    final currentUserId = _auth.currentUser!.uid;
    
    return _firestore
        .collection('chats')
        .where('participants', arrayContains: currentUserId)
        .orderBy('lastMessageTime', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => Chat.fromFirestore(doc)).toList());
  }

  // Get chat messages
  static Stream<List<Message>> getChatMessages(String chatId) {
    return _firestore
        .collection('messages')
        .where('chatId', isEqualTo: chatId)
        .orderBy('timestamp', descending: true)
        .limit(50) // Limit to last 50 messages
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => Message.fromFirestore(doc)).toList());
  }

  // Mark messages as read
  static Future<void> markMessagesAsRead(String chatId) async {
    final currentUserId = _auth.currentUser!.uid;
    
    try {
      // Update unread count in chat
      await _firestore.collection('chats').doc(chatId).update({
        'unreadCount.$currentUserId': 0,
      });
      
      // Mark messages as read - simplified query
      final unreadMessages = await _firestore
          .collection('messages')
          .where('chatId', isEqualTo: chatId)
          .where('isRead', isEqualTo: false)
          .get();
      
      final batch = _firestore.batch();
      for (var doc in unreadMessages.docs) {
        final data = doc.data();
        if (data['senderId'] != currentUserId) {
          batch.update(doc.reference, {'isRead': true});
        }
      }
      await batch.commit();
    } catch (e) {
      // Ignore errors for now
    }
  }

  // Get user data
  static Future<Map<String, dynamic>?> getUserData(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      return userDoc.exists ? userDoc.data() : null;
    } catch (e) {
      return null;
    }
  }
}
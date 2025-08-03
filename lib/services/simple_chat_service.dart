import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/Chat.dart';
import 'notification_service.dart';

class SimpleChatService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // Create or get existing chat between two users - simplified
  static Future<String> createOrGetChat(String otherUserId) async {
    final currentUserId = _auth.currentUser!.uid;
    final participants = [currentUserId, otherUserId]..sort();
    final chatId = '${participants[0]}_${participants[1]}';
    
    try {
      // Check if chat exists
      final chatDoc = await _firestore.collection('chats').doc(chatId).get();
      
      if (chatDoc.exists) {
        return chatId;
      }
      
      // Create new chat with fixed ID
      await _firestore.collection('chats').doc(chatId).set({
        'participants': participants,
        'lastMessage': '',
        'lastMessageTime': FieldValue.serverTimestamp(),
        'lastMessageSenderId': '',
        'unreadCount': {
          currentUserId: 0,
          otherUserId: 0,
        },
        'isOnline': {
          currentUserId: true,
          otherUserId: false,
        },
        'lastSeen': {
          currentUserId: FieldValue.serverTimestamp(),
          otherUserId: FieldValue.serverTimestamp(),
        },
        'createdAt': FieldValue.serverTimestamp(),
      });
      
      return chatId;
    } catch (e) {
      throw Exception('Failed to create chat: $e');
    }
  }

  // Send message - simplified
  static Future<void> sendMessage(String chatId, String content, MessageType type) async {
    final currentUserId = _auth.currentUser!.uid;
    final timestamp = DateTime.now();
    
    try {
      // Add message with auto-generated ID
      await _firestore.collection('messages').add({
        'chatId': chatId,
        'senderId': currentUserId,
        'content': content,
        'timestamp': Timestamp.fromDate(timestamp),
        'type': type.toString().split('.').last,
        'isRead': false,
        'readBy': {currentUserId: true},
      });
      
      // Update chat info
      final chatDoc = await _firestore.collection('chats').doc(chatId).get();
      if (chatDoc.exists) {
        final participants = List<String>.from(chatDoc.data()!['participants']);
        final otherUserId = participants.firstWhere((id) => id != currentUserId);
        
        await _firestore.collection('chats').doc(chatId).update({
          'lastMessage': content,
          'lastMessageTime': Timestamp.fromDate(timestamp),
          'lastMessageSenderId': currentUserId,
          'unreadCount.$otherUserId': FieldValue.increment(1),
          'unreadCount.$currentUserId': 0,
          'isOnline.$currentUserId': true,
          'lastSeen.$currentUserId': Timestamp.fromDate(timestamp),
        });
        
        // Send notification to other user safely
        try {
          final senderDoc = await _firestore.collection('users').doc(currentUserId).get();
          final senderName = senderDoc.data()?['fullName'] ?? 'Someone';
          
          await NotificationService.sendChatNotification(
            receiverUserId: otherUserId,
            senderName: senderName,
            message: type == MessageType.image ? '📷 Photo' : 
                     type == MessageType.emoji ? content : content,
            chatId: chatId,
          );
        } catch (e) {
          // Ignore notification errors
        }
      }
    } catch (e) {
      throw Exception('Failed to send message: $e');
    }
  }

  // Get user chats - simplified
  static Stream<List<Chat>> getUserChats() {
    final currentUserId = _auth.currentUser!.uid;
    
    return _firestore
        .collection('chats')
        .where('participants', arrayContains: currentUserId)
        .snapshots()
        .map((snapshot) {
          final chats = snapshot.docs.map((doc) => Chat.fromFirestore(doc)).toList();
          chats.sort((a, b) => b.lastMessageTime.compareTo(a.lastMessageTime));
          return chats;
        });
  }

  // Get chat messages - simplified
  static Stream<List<Message>> getChatMessages(String chatId) {
    return _firestore
        .collection('messages')
        .where('chatId', isEqualTo: chatId)
        .snapshots()
        .map((snapshot) {
          final messages = snapshot.docs.map((doc) => Message.fromFirestore(doc)).toList();
          messages.sort((a, b) => b.timestamp.compareTo(a.timestamp));
          return messages.take(50).toList(); // Limit to 50 messages
        });
  }

  // Mark messages as read - simplified
  static Future<void> markMessagesAsRead(String chatId) async {
    final currentUserId = _auth.currentUser!.uid;
    
    try {
      // Just update the unread count
      await _firestore.collection('chats').doc(chatId).update({
        'unreadCount.$currentUserId': 0,
      });
    } catch (e) {
      // Ignore errors
    }
  }

  // Delete chat
  static Future<void> deleteChat(String chatId) async {
    try {
      // Delete all messages
      final messages = await _firestore
          .collection('messages')
          .where('chatId', isEqualTo: chatId)
          .get();
      
      final batch = _firestore.batch();
      for (var doc in messages.docs) {
        batch.delete(doc.reference);
      }
      
      // Delete chat
      batch.delete(_firestore.collection('chats').doc(chatId));
      await batch.commit();
    } catch (e) {
      throw Exception('Failed to delete chat: $e');
    }
  }

  // Update user online status
  static Future<void> updateOnlineStatus(bool isOnline) async {
    final currentUserId = _auth.currentUser!.uid;
    
    try {
      // Update user's online status in all chats
      final userChats = await _firestore
          .collection('chats')
          .where('participants', arrayContains: currentUserId)
          .get();
      
      final batch = _firestore.batch();
      for (var doc in userChats.docs) {
        batch.update(doc.reference, {
          'isOnline.$currentUserId': isOnline,
          'lastSeen.$currentUserId': FieldValue.serverTimestamp(),
        });
      }
      await batch.commit();
    } catch (e) {
      // Ignore errors
    }
  }

  // Send image message
  static Future<void> sendImageMessage(String chatId, String imageBase64) async {
    await sendMessage(chatId, imageBase64, MessageType.image);
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
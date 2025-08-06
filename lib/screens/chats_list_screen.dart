import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:convert';
import '../models/Chat.dart';
import '../services/simple_chat_service.dart';
import '../utils/avatar_helper.dart';
import 'chat_screen.dart';

class ChatsListScreen extends StatefulWidget {
  const ChatsListScreen({super.key});

  @override
  State<ChatsListScreen> createState() => _ChatsListScreenState();
}

class _ChatsListScreenState extends State<ChatsListScreen> {
  final String currentUserId = FirebaseAuth.instance.currentUser!.uid;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = FirebaseAuth.instance.currentUser;
    
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Messages', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
      ),
      body: user == null ? _buildLoginPrompt(theme) : _buildChatsList(theme),
    );
  }

  Widget _buildLoginPrompt(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.chat_bubble_outline,
              size: 80,
              color: theme.colorScheme.primary.withOpacity(0.5),
            ),
            const SizedBox(height: 24),
            Text(
              'Join the Conversation!',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: theme.textTheme.bodyLarge?.color,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Sign in to start chatting with other pet lovers',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: theme.hintColor,
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pushNamed(context, '/login'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Sign In',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => Navigator.pushNamed(context, '/signup'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: theme.colorScheme.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  side: BorderSide(color: theme.colorScheme.primary),
                ),
                child: const Text(
                  'Create Account',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChatsList(ThemeData theme) {
    return StreamBuilder<List<Chat>>(
      stream: SimpleChatService.getUserChats(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text('No messages yet', style: TextStyle(fontSize: 18, color: Colors.grey)),
                Text('Start a conversation from user profiles', style: TextStyle(color: Colors.grey)),
              ],
            ),
          );
        }
        
        return FutureBuilder<List<Chat>>(
          future: _loadChatsWithUserData(snapshot.data!),
          builder: (context, chatsSnapshot) {
            if (chatsSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            
            if (!chatsSnapshot.hasData) {
              return const Center(child: Text('Error loading chats'));
            }
            
            final chats = chatsSnapshot.data!;
            return ListView.builder(
              itemCount: chats.length,
              itemBuilder: (context, index) => _buildChatTile(chats[index], theme),
            );
          },
        );
      },
    );
  }

  Future<List<Chat>> _loadChatsWithUserData(List<Chat> chats) async {
    for (var chat in chats) {
      final otherUserId = chat.participants.firstWhere((id) => id != currentUserId);
      final userData = await SimpleChatService.getUserData(otherUserId);
      
      if (userData != null) {
        chat.otherUserName = userData['fullName'] ?? 'Unknown User';
        chat.otherUserImage = userData['profileImage'];
      }
    }
    return chats;
  }

  Widget _buildChatTile(Chat chat, ThemeData theme) {
    final unreadCount = chat.unreadCount[currentUserId] ?? 0;
    final isUnread = unreadCount > 0;
    final otherUserId = chat.participants.firstWhere((id) => id != currentUserId);
    final isOnline = chat.isOnline[otherUserId] ?? false;
    
    return ListTile(
      leading: Stack(
        children: [
          _buildUserAvatar(chat.otherUserImage, chat.otherUserName, 24),
          if (isOnline)
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
              ),
            ),
        ],
      ),
      title: Text(
        chat.otherUserName ?? 'Unknown User',
        style: TextStyle(
          fontWeight: isUnread ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      subtitle: Text(
        chat.lastMessage.isEmpty ? 'No messages yet' : chat.lastMessage,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: isUnread ? theme.colorScheme.primary : theme.hintColor,
          fontWeight: isUnread ? FontWeight.w500 : FontWeight.normal,
        ),
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            _formatTime(chat.lastMessageTime),
            style: TextStyle(
              color: isUnread ? theme.colorScheme.primary : theme.hintColor,
              fontSize: 12,
              fontWeight: isUnread ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          if (isUnread) ...[
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary,
                borderRadius: BorderRadius.circular(12),
              ),
              constraints: const BoxConstraints(minWidth: 20),
              child: Text(
                unreadCount > 99 ? '99+' : unreadCount.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ],
      ),
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ChatScreen(
            chatId: chat.id,
            otherUserId: chat.participants.firstWhere((id) => id != currentUserId),
            otherUserName: chat.otherUserName ?? 'Unknown User',
            otherUserImage: chat.otherUserImage,
          ),
        ),
      ),
    );
  }

  Widget _buildUserAvatar(String? imageData, String? userName, double radius) {
    if (imageData != null && imageData.isNotEmpty) {
      if (imageData == 'fluttermoji_avatar') {
        return AvatarHelper.buildAvatar(imageData, size: radius * 2);
      }
      try {
        final imageBytes = base64Decode(imageData);
        return CircleAvatar(
          radius: radius,
          backgroundImage: MemoryImage(imageBytes),
        );
      } catch (e) {
        return _buildTextAvatar(userName ?? 'U', radius);
      }
    }
    return _buildTextAvatar(userName ?? 'U', radius);
  }

  Widget _buildTextAvatar(String userName, double radius) {
    final initials = userName.isNotEmpty 
        ? userName.trim().split(' ').map((name) => name.isNotEmpty ? name[0].toUpperCase() : '').take(2).join()
        : 'U';
    
    return CircleAvatar(
      radius: radius,
      backgroundColor: Theme.of(context).colorScheme.primary,
      child: Text(
        initials,
        style: TextStyle(
          color: Colors.white,
          fontSize: radius * 0.7,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inDays > 0) {
      if (difference.inDays == 1) return 'Yesterday';
      if (difference.inDays < 7) return '${difference.inDays}d ago';
      return '${dateTime.day}/${dateTime.month}';
    }
    if (difference.inHours > 0) return '${difference.inHours}h ago';
    if (difference.inMinutes > 0) return '${difference.inMinutes}m ago';
    return 'Now';
  }
}
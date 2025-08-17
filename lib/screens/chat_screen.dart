import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';
import 'dart:io';
import '../models/Chat.dart';
import '../services/simple_chat_service.dart';
import '../utils/avatar_helper.dart';
import 'profile_view_screen.dart';
import 'emoji_picker_screen.dart';

class ChatScreen extends StatefulWidget {
  final String chatId;
  final String otherUserId;
  final String otherUserName;
  final String? otherUserImage;

  const ChatScreen({
    super.key,
    required this.chatId,
    required this.otherUserId,
    required this.otherUserName,
    this.otherUserImage,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with WidgetsBindingObserver {
  final TextEditingController _messageController = TextEditingController();
  final FocusNode _messageFocusNode = FocusNode();
  final String currentUserId = FirebaseAuth.instance.currentUser!.uid;
  final ImagePicker _picker = ImagePicker();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isLoading = false;
  bool _showEmojiPicker = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Mark messages as read and update online status
    WidgetsBinding.instance.addPostFrameCallback((_) {
      SimpleChatService.markMessagesAsRead(widget.chatId);
      SimpleChatService.updateOnlineStatus(true);
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    SimpleChatService.updateOnlineStatus(false);
    _messageController.dispose();
    _messageFocusNode.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        SimpleChatService.updateOnlineStatus(true);
        break;
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
        SimpleChatService.updateOnlineStatus(false);
        break;
      case AppLifecycleState.hidden:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        title: GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ProfileViewScreen(
                userId: widget.otherUserId,
                userName: widget.otherUserName,
                userImage: widget.otherUserImage,
              ),
            ),
          ),
          child: Row(
            children: [
              Stack(
                children: [
                  _buildUserAvatar(widget.otherUserImage, widget.otherUserName, 20),
                  StreamBuilder<Chat>(
                    stream: _firestore.collection('chats').doc(widget.chatId).snapshots()
                        .map((doc) => Chat.fromFirestore(doc)),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) return const SizedBox();
                      final isOnline = snapshot.data!.isOnline[widget.otherUserId] ?? false;
                      if (!isOnline) return const SizedBox();
                      return Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: Colors.green,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.otherUserName,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    StreamBuilder<Chat>(
                      stream: _firestore.collection('chats').doc(widget.chatId).snapshots()
                          .map((doc) => Chat.fromFirestore(doc)),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) return const SizedBox();
                        final isOnline = snapshot.data!.isOnline[widget.otherUserId] ?? false;
                        return Text(
                          isOnline ? 'Online' : 'Last seen recently',
                          style: TextStyle(
                            fontSize: 12,
                            color: isOnline ? Colors.green : theme.hintColor,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          PopupMenuButton(
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Delete Chat', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
            onSelected: (value) {
              if (value == 'delete') _deleteChat();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Messages List
          Expanded(
            child: StreamBuilder<List<Message>>(
              stream: SimpleChatService.getChatMessages(widget.chatId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(
                    child: Text('No messages yet. Start the conversation!'),
                  );
                }
                
                final messages = snapshot.data!;
                return ListView.builder(
                  reverse: true,
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) => _buildMessageBubble(messages[index], theme),
                );
              },
            ),
          ),
          
          // Message Input
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              border: Border(top: BorderSide(color: theme.dividerColor)),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    IconButton(
                      onPressed: _pickImage,
                      icon: Icon(Icons.image, color: theme.colorScheme.primary),
                    ),
                    IconButton(
                      onPressed: _showEmojiPickerDialog,
                      icon: Icon(Icons.emoji_emotions, color: theme.colorScheme.primary),
                    ),
                    Expanded(
                      child: TextField(
                        controller: _messageController,
                        focusNode: _messageFocusNode,
                        decoration: InputDecoration(
                          hintText: 'Type a message...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(25),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: theme.colorScheme.background,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        ),
                        maxLines: null,
                        textCapitalization: TextCapitalization.sentences,
                        keyboardType: TextInputType.multiline,
                        textInputAction: TextInputAction.send,
                        enableSuggestions: true,
                        autocorrect: true,
                        onSubmitted: (_) => _sendMessage(),
                        onTap: () {
                          _messageFocusNode.requestFocus();
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary,
                        borderRadius: BorderRadius.circular(25),
                      ),
                      child: IconButton(
                        onPressed: _isLoading ? null : _sendMessage,
                        icon: _isLoading 
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.send, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(Message message, ThemeData theme) {
    final isMe = message.senderId == currentUserId;
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isMe) ...[
            _buildUserAvatar(widget.otherUserImage, widget.otherUserName, 16),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: isMe ? theme.colorScheme.primary : theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildMessageContent(message, isMe, theme),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _formatTime(message.timestamp),
                        style: TextStyle(
                          color: isMe ? Colors.white70 : theme.hintColor,
                          fontSize: 12,
                        ),
                      ),
                      if (isMe) ...[
                        const SizedBox(width: 4),
                        Icon(
                          message.readBy[widget.otherUserId] == true 
                              ? Icons.done_all 
                              : Icons.done,
                          size: 16,
                          color: message.readBy[widget.otherUserId] == true 
                              ? Colors.blue 
                              : Colors.white70,
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (isMe) ...[
            const SizedBox(width: 8),
            _buildUserAvatar(null, 'Me', 16),
          ],
        ],
      ),
    );
  }

  Widget _buildMessageContent(Message message, bool isMe, ThemeData theme) {
    switch (message.type) {
      case MessageType.image:
        try {
          return ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.memory(
              base64Decode(message.content),
              width: 200,
              height: 200,
              fit: BoxFit.cover,
            ),
          );
        } catch (e) {
          return Text(
            'Image failed to load',
            style: TextStyle(
              color: isMe ? Colors.white : theme.textTheme.bodyLarge?.color,
            ),
          );
        }
      case MessageType.emoji:
        return Text(
          message.content,
          style: const TextStyle(fontSize: 32),
        );
      default:
        return Text(
          message.content,
          style: TextStyle(
            color: isMe ? Colors.white : theme.textTheme.bodyLarge?.color,
          ),
        );
    }
  }

  Future<void> _sendMessage() async {
    final content = _messageController.text.trim();
    if (content.isEmpty) return;

    setState(() => _isLoading = true);
    _messageController.clear();

    try {
      await SimpleChatService.sendMessage(widget.chatId, content, MessageType.text);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send message: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        setState(() => _isLoading = true);
        
        final bytes = await File(image.path).readAsBytes();
        final base64Image = base64Encode(bytes);
        
        await SimpleChatService.sendImageMessage(widget.chatId, base64Image);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send image: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _showEmojiPickerDialog() async {
    final emoji = await showModalBottomSheet<String>(
      context: context,
      builder: (_) => const EmojiPickerScreen(),
    );
    
    if (emoji != null) {
      _messageController.text += emoji;
    }
  }

  Future<void> _deleteChat() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Chat'),
        content: const Text('Are you sure you want to delete this chat? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await SimpleChatService.deleteChat(widget.chatId);
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Chat deleted successfully')),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete chat: $e')),
        );
      }
    }
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
    
    if (difference.inDays > 0) return '${dateTime.day}/${dateTime.month}';
    if (difference.inHours > 0) return '${difference.inHours}h ago';
    if (difference.inMinutes > 0) return '${difference.inMinutes}m ago';
    return 'Now';
  }
}
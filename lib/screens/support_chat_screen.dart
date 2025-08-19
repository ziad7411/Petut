import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/SupportTicket.dart';
import '../services/support_service.dart';

class SupportChatScreen extends StatefulWidget {
  final String ticketId;
  const SupportChatScreen({super.key, required this.ticketId});

  @override
  State<SupportChatScreen> createState() => _SupportChatScreenState();
}

class _SupportChatScreenState extends State<SupportChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final FocusNode _inputFocusNode = FocusNode();
  late final String currentUserId;

  bool _isLoading = false;

  // نتابع حالة التذكرة محليًا بدون ما نعيد بناء الـ TextField مع كل رسالة
  bool _isTicketClosed = false;
  StreamSubscription<SupportTicket?>? _ticketStatusSub;

  @override
  void initState() {
    super.initState();

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) Navigator.pop(context);
      });
      return;
    }
    currentUserId = user.uid;

    // اول دخول: تعليم الرسائل كمقروءة
    WidgetsBinding.instance.addPostFrameCallback((_) {
      SupportService.markTicketAsRead(widget.ticketId);
    });

    // اشتراك خفيف لتحديث حالة التذكرة فقط (open/closed)
    _ticketStatusSub = SupportService.getSupportTicket(widget.ticketId).listen((ticket) {
      if (!mounted || ticket == null) return;
      final closedNow = ticket.status == 'closed';
      if (closedNow != _isTicketClosed) {
        setState(() {
          _isTicketClosed = closedNow;
        });
      }
    });
  }

  @override
  void dispose() {
    _ticketStatusSub?.cancel();
    _messageController.dispose();
    _inputFocusNode.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty || _isLoading || _isTicketClosed) return;

    setState(() => _isLoading = true);
    try {
      await SupportService.sendMessage(
        ticketId: widget.ticketId,
        message: _messageController.text.trim(),
      );
      _messageController.clear();
      // نحافظ على الفوكس بعد الإرسال
      _inputFocusNode.requestFocus();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error sending message: $e')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _buildMessageBubble(SupportMessage message, ThemeData theme) {
    final isCurrentUser = message.senderId == currentUserId;
    final isAdmin = message.senderRole == 'admin';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
      child: Row(
        mainAxisAlignment: isCurrentUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isCurrentUser) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: isAdmin ? theme.colorScheme.primary : theme.colorScheme.outline,
              child: Icon(
                isAdmin ? Icons.support_agent : Icons.person,
                size: 16,
                color: theme.colorScheme.onPrimary,
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.7,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isCurrentUser ? theme.colorScheme.primary : theme.colorScheme.surfaceVariant,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: Radius.circular(isCurrentUser ? 18 : 4),
                  bottomRight: Radius.circular(isCurrentUser ? 4 : 18),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!isCurrentUser && isAdmin)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.verified, size: 12, color: theme.colorScheme.primary),
                          const SizedBox(width: 4),
                          Text(
                            'Customer Support',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  Text(
                    message.message,
                    style: TextStyle(
                      color: isCurrentUser ? theme.colorScheme.onPrimary : theme.colorScheme.onSurfaceVariant,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatTime(message.timestamp),
                    style: TextStyle(
                      fontSize: 11,
                      color: isCurrentUser
                          ? theme.colorScheme.onPrimary.withOpacity(0.8)
                          : theme.hintColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isCurrentUser) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 16,
              backgroundColor: theme.colorScheme.outline,
              child: Icon(Icons.person, size: 16, color: theme.colorScheme.onPrimary),
            ),
          ],
        ],
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${dateTime.day}/${dateTime.month} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'open':
        return Colors.orange;
      case 'in_progress':
        return Colors.blue;
      case 'closed':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  void _showCloseTicketDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: const [
            Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 28),
            SizedBox(width: 12),
            Text('End Chat Session'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Are you sure you want to delete this chat session?'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('• This chat will be permanently deleted',
                      style: TextStyle(fontSize: 13, color: Colors.red.shade700)),
                  Text('• All messages will be removed',
                      style: TextStyle(fontSize: 13, color: Colors.red.shade700)),
                  Text('• This action cannot be undone',
                      style: TextStyle(fontSize: 13, color: Colors.red.shade700)),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: Colors.grey.shade600)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await SupportService.deleteTicket(widget.ticketId);
              if (!mounted) return;
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.white),
                      SizedBox(width: 8),
                      Text('Chat session ended successfully'),
                    ],
                  ),
                  backgroundColor: Colors.green,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Delete Chat', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showTicketInfo(SupportTicket ticket) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Ticket Information'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoRow('Ticket ID', ticket.id.substring(0, 8).toUpperCase()),
            _buildInfoRow('Subject', ticket.subject),
            _buildInfoRow('Priority', ticket.priority.toUpperCase()),
            _buildInfoRow('Status', ticket.status.toUpperCase()),
            _buildInfoRow('Created', _formatDate(ticket.createdAt)),
            _buildInfoRow('Last Updated', _formatDate(ticket.updatedAt)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(label, style: TextStyle(fontWeight: FontWeight.w500, color: Colors.grey.shade600)),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: StreamBuilder<SupportTicket?>(
          stream: SupportService.getSupportTicket(widget.ticketId),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const Text('Support Chat');
            final ticket = snapshot.data!;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Support Chat', style: TextStyle(fontSize: 18)),
                Text(
                  ticket.status == 'closed' ? 'Chat Ended' : 'Agent Available',
                  style: TextStyle(
                    fontSize: 12,
                    color: ticket.status == 'closed' ? Colors.red : Colors.green,
                  ),
                ),
              ],
            );
          },
        ),
        backgroundColor: theme.colorScheme.surface,
        foregroundColor: theme.colorScheme.onSurface,
        elevation: 1,
        actions: [
          StreamBuilder<SupportTicket?>(
            stream: SupportService.getSupportTicket(widget.ticketId),
            builder: (context, snapshot) {
              if (!snapshot.hasData || snapshot.data!.status == 'closed') {
                return const SizedBox();
              }
              return PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'close') _showCloseTicketDialog();
                  if (value == 'info') _showTicketInfo(snapshot.data!);
                },
                itemBuilder: (context) => const [
                  PopupMenuItem(
                    value: 'info',
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, size: 20),
                        SizedBox(width: 8),
                        Text('Ticket Info'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'close',
                    child: Row(
                      children: [
                        Icon(Icons.close, size: 20, color: Colors.red),
                        SizedBox(width: 8),
                        Text('End Chat', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),

      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header (open/closed) — ده بيتحدث مع الستريم بس مش بيأثر على الـ TextField
            StreamBuilder<SupportTicket?>(
              stream: SupportService.getSupportTicket(widget.ticketId),
              builder: (context, snapshot) {
                final ticket = snapshot.data;
                if (ticket == null) {
                  return const SizedBox.shrink();
                }
        
                if (ticket.status != 'closed') {
                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer.withOpacity(0.1),
                      border: Border(bottom: BorderSide(color: theme.dividerColor)),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: theme.colorScheme.primary,
                          radius: 20,
                          child: Icon(Icons.support_agent, color: theme.colorScheme.onPrimary, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Customer Support',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: theme.colorScheme.onSurface),
                              ),
                              Text(
                                'We\'re here to help you',
                                style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6), fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.green,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 6, height: 6,
                                decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                              ),
                              const SizedBox(width: 4),
                              const Text('Online', style: TextStyle(color: Colors.white, fontSize: 10)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                } else {
                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    color: theme.colorScheme.errorContainer.withOpacity(0.1),
                    child: Row(
                      children: [
                        Icon(Icons.chat_bubble_outline, color: theme.colorScheme.error),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Chat Session Ended',
                                  style: TextStyle(fontWeight: FontWeight.bold, color: theme.colorScheme.error)),
                              Text(
                                'This conversation has been closed',
                                style: TextStyle(color: theme.colorScheme.error.withOpacity(0.8), fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }
              },
            ),
        
            // Messages — Stream مخصوص للرسائل فقط
            Expanded(
              child: StreamBuilder<SupportTicket?>(
                stream: SupportService.getSupportTicket(widget.ticketId),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData) {
                    return const Center(child: Text('Ticket not found'));
                  }
        
                  final ticket = snapshot.data!;
                  if (ticket.messages.isEmpty) {
                    return const Center(child: Text('No messages yet'));
                  }
        
                  final messages = ticket.messages.reversed.toList();
                  return ListView.builder(
                    reverse: true,
                    padding: const EdgeInsets.all(8),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      return _buildMessageBubble(messages[index], theme);
                    },
                  );
                },
              ),
            ),
        
            // Composer وفوتر الـ closed — الـ Composer ثابت ومش داخل أي StreamBuilder
            if (!_isTicketClosed)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  border: Border(top: BorderSide(color: theme.dividerColor)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceVariant,
                          borderRadius: BorderRadius.circular(25),
                          border: Border.all(color: theme.dividerColor),
                        ),
                        child: TextField(
                          key: const ValueKey('chat_composer'), // يحافظ على الهوية
                          controller: _messageController,
                          focusNode: _inputFocusNode,             // يحافظ على الفوكس
                          decoration: InputDecoration(
                            hintText: 'Type your message...',
                            hintStyle: TextStyle(color: theme.hintColor),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          ),
                          maxLines: null,
                          textInputAction: TextInputAction.newline,
                          onSubmitted: (_) => _sendMessage(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: theme.colorScheme.primary.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(24),
                          onTap: _isLoading ? null : _sendMessage,
                          child: Center(
                            child: _isLoading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                  )
                                : Icon(Icons.send_rounded, color: theme.colorScheme.onPrimary, size: 20),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              )
            else
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
                  border: Border(top: BorderSide(color: theme.dividerColor)),
                ),
                child: Column(
                  children: [
                    Icon(Icons.chat_bubble_outline, color: theme.hintColor, size: 32),
                    const SizedBox(height: 8),
                    Text(
                      'This chat session has ended',
                      style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.7), fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Need more help? Create a new support ticket',
                      style: TextStyle(color: theme.hintColor, fontSize: 12),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.pushNamed(context, '/support');
                      },
                      icon: const Icon(Icons.add_circle_outline, size: 18),
                      label: const Text('New Support Ticket'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: theme.colorScheme.onPrimary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
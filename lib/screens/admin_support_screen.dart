import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/SupportTicket.dart';
import '../services/support_service.dart';

class AdminSupportScreen extends StatefulWidget {
  const AdminSupportScreen({super.key});

  @override
  State<AdminSupportScreen> createState() => _AdminSupportScreenState();
}

class _AdminSupportScreenState extends State<AdminSupportScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final String currentAdminId = FirebaseAuth.instance.currentUser!.uid;
  String currentAdminName = 'Admin';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadAdminName();
  }

  Future<void> _loadAdminName() async {
    // يمكن تحسين هذا بجلب اسم الأدمن من قاعدة البيانات
    setState(() {
      currentAdminName = 'Support Admin';
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Widget _buildTicketCard(SupportTicket ticket, ThemeData theme) {
    Color statusColor = _getStatusColor(ticket.status);
    Color priorityColor = _getPriorityColor(ticket.priority);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        title: Text(
          ticket.subject,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text('From: ${ticket.userName} (${ticket.userEmail})'),
            const SizedBox(height: 4),
            Text(
              ticket.messages.isNotEmpty
                  ? ticket.messages.last.message
                  : 'No messages',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    ticket.status.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: priorityColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    ticket.priority.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  _formatDate(ticket.updatedAt),
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ],
        ),
        trailing: PopupMenuButton(
          itemBuilder: (context) => [
            if (ticket.status != 'in_progress')
              PopupMenuItem(
                value: 'assign',
                child: Row(
                  children: [
                    Icon(Icons.assignment_ind, color: theme.colorScheme.primary),
                    const SizedBox(width: 8),
                    const Text('Assign to Me'),
                  ],
                ),
              ),
            if (ticket.status != 'closed')
              PopupMenuItem(
                value: 'close',
                child: Row(
                  children: [
                    const Icon(Icons.close, color: Colors.green),
                    const SizedBox(width: 8),
                    const Text('Close Ticket'),
                  ],
                ),
              ),
            PopupMenuItem(
              value: 'chat',
              child: Row(
                children: [
                  Icon(Icons.chat, color: theme.colorScheme.primary),
                  const SizedBox(width: 8),
                  const Text('Open Chat'),
                ],
              ),
            ),
          ],
          onSelected: (value) => _handleTicketAction(value, ticket),
        ),
        onTap: () => _openAdminChat(ticket),
      ),
    );
  }

  void _handleTicketAction(String action, SupportTicket ticket) async {
    switch (action) {
      case 'assign':
        await SupportService.assignTicketToAdmin(
          ticketId: ticket.id,
          adminId: currentAdminId,
          adminName: currentAdminName,
        );
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ticket assigned successfully')),
        );
        break;
      case 'close':
        await SupportService.updateTicketStatus(
          ticketId: ticket.id,
          status: 'closed',
        );
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ticket closed successfully')),
        );
        break;
      case 'chat':
        _openAdminChat(ticket);
        break;
    }
  }

  void _openAdminChat(SupportTicket ticket) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AdminChatScreen(
          ticket: ticket,
          adminId: currentAdminId,
          adminName: currentAdminName,
        ),
      ),
    );
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

  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'high':
        return Colors.red;
      case 'medium':
        return Colors.orange;
      case 'low':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  Widget _buildTicketsList(String status) {
    return StreamBuilder<List<SupportTicket>>(
      stream: SupportService.getAllSupportTickets(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData) {
          return const Center(child: Text('No tickets found'));
        }

        List<SupportTicket> tickets = snapshot.data!;
        if (status != 'all') {
          tickets = tickets.where((t) => t.status == status).toList();
        }

        if (tickets.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.inbox, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'No ${status == 'all' ? '' : status} tickets',
                  style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          itemCount: tickets.length,
          itemBuilder: (context, index) =>
              _buildTicketCard(tickets[index], Theme.of(context)),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Support Management'),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
        bottom: TabBar(
          controller: _tabController,
          labelColor: theme.colorScheme.onPrimary,
          unselectedLabelColor: theme.colorScheme.onPrimary.withOpacity(0.7),
          indicatorColor: theme.colorScheme.onPrimary,
          tabs: const [
            Tab(text: 'All'),
            Tab(text: 'Open'),
            Tab(text: 'In Progress'),
            Tab(text: 'Closed'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildTicketsList('all'),
          _buildTicketsList('open'),
          _buildTicketsList('in_progress'),
          _buildTicketsList('closed'),
        ],
      ),
    );
  }
}

class AdminChatScreen extends StatefulWidget {
  final SupportTicket ticket;
  final String adminId;
  final String adminName;

  const AdminChatScreen({
    super.key,
    required this.ticket,
    required this.adminId,
    required this.adminName,
  });

  @override
  State<AdminChatScreen> createState() => _AdminChatScreenState();
}

class _AdminChatScreenState extends State<AdminChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _sendAdminReply() async {
    if (_messageController.text.trim().isEmpty || _isLoading) return;

    setState(() => _isLoading = true);
    try {
      await SupportService.sendAdminReply(
        ticketId: widget.ticket.id,
        message: _messageController.text.trim(),
        adminId: widget.adminId,
        adminName: widget.adminName,
      );
      _messageController.clear();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error sending message: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Widget _buildMessageBubble(SupportMessage message, ThemeData theme) {
    final isAdmin = message.senderRole == 'admin';

    return Align(
      alignment: isAdmin ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        padding: const EdgeInsets.all(12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: isAdmin
              ? Colors.green.shade100
              : theme.colorScheme.surfaceVariant,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isAdmin ? '${message.senderName} (Support)' : message.senderName,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: isAdmin ? Colors.green.shade700 : theme.hintColor,
              ),
            ),
            const SizedBox(height: 4),
            Text(message.message),
            const SizedBox(height: 4),
            Text(
              _formatTime(message.timestamp),
              style: TextStyle(fontSize: 10, color: theme.hintColor),
            ),
          ],
        ),
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Support Chat - ${widget.ticket.subject}'),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
        actions: [
          PopupMenuButton(
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'close',
                child: Row(
                  children: [
                    const Icon(Icons.close, color: Colors.red),
                    const SizedBox(width: 8),
                    const Text('Close Ticket'),
                  ],
                ),
              ),
            ],
            onSelected: (value) async {
              if (value == 'close') {
                await SupportService.updateTicketStatus(
                  ticketId: widget.ticket.id,
                  status: 'closed',
                );
                Navigator.pop(context);
              }
            },
          ),
        ],
      ),
      body: StreamBuilder<SupportTicket?>(
        stream: SupportService.getSupportTicket(widget.ticket.id),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final ticket = snapshot.data!;

          return Column(
            children: [
              // Ticket Info
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                color: theme.colorScheme.surfaceVariant,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Customer: ${ticket.userName}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text('Email: ${ticket.userEmail}'),
                    Text('Priority: ${ticket.priority}'),
                    Text('Status: ${ticket.status}'),
                  ],
                ),
              ),

              // Messages
              Expanded(
                child: ticket.messages.isEmpty
                    ? const Center(child: Text('No messages yet'))
                    : ListView.builder(
                        reverse: true,
                        padding: const EdgeInsets.all(8),
                        itemCount: ticket.messages.length,
                        itemBuilder: (context, index) {
                          final message = ticket.messages.reversed.toList()[index];
                          return _buildMessageBubble(message, theme);
                        },
                      ),
              ),

              // Reply Input
              if (ticket.status != 'closed')
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    border: Border(top: BorderSide(color: theme.dividerColor)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _messageController,
                          decoration: InputDecoration(
                            hintText: 'Type your reply...',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(25),
                              borderSide: BorderSide.none,
                            ),
                            filled: true,
                            fillColor: theme.colorScheme.background,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 10,
                            ),
                          ),
                          maxLines: null,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.green,
                          borderRadius: BorderRadius.circular(25),
                        ),
                        child: IconButton(
                          onPressed: _isLoading ? null : _sendAdminReply,
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
                ),
            ],
          );
        },
      ),
    );
  }
}
import 'package:flutter/material.dart';
import '../models/SupportTicket.dart';
import '../services/support_service.dart';
import 'support_chat_screen.dart';
import 'create_support_ticket_screen.dart';

class SupportTicketsListScreen extends StatelessWidget {
  const SupportTicketsListScreen({super.key});

  Color _getStatusColor(String status) {
    switch (status) {
      case 'open': return Colors.orange;
      case 'in_progress': return Colors.blue;
      case 'closed': return Colors.green;
      default: return Colors.grey;
    }
  }

  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'live_chat': return Colors.red;
      case 'high': return Colors.orange;
      case 'medium': return Colors.blue;
      case 'low': return Colors.grey;
      default: return Colors.grey;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    
    if (diff.inDays > 0) {
      return '${diff.inDays}d ago';
    } else if (diff.inHours > 0) {
      return '${diff.inHours}h ago';
    } else {
      return '${diff.inMinutes}m ago';
    }
  }



  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Future<void> startLiveChat() async {
      try {
        final ticketId = await SupportService.createSupportTicket(
          subject: 'Live Chat - ${DateTime.now().toString().substring(0, 16)}',
          initialMessage: 'Hello! I need immediate assistance. Please help me.',
          priority: 'live_chat',
        );

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => SupportChatScreen(ticketId: ticketId),
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: Colors.red,
          ),
        );
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Support Tickets'),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
      ),
      body: Column(
        children: [
          // Professional Live Chat Button - Always visible
          Container(
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: theme.colorScheme.primary.withOpacity(0.3),
                  blurRadius: 12,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () => startLiveChat(),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(Icons.support_agent, color: theme.colorScheme.onPrimary, size: 24),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Start Live Chat',
                              style: TextStyle(
                                color: theme.colorScheme.onPrimary,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Get instant help from our support team',
                              style: TextStyle(
                                color: theme.colorScheme.onPrimary.withOpacity(0.9),
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.arrow_forward_ios, color: theme.colorScheme.onPrimary, size: 16),
                    ],
                  ),
                ),
              ),
            ),
          ),
          
          // Tickets List
          Expanded(
            child: StreamBuilder<List<SupportTicket>>(
              stream: SupportService.getUserSupportTickets(),
              builder: (context, snapshot) {
                print('StreamBuilder - Connection: ${snapshot.connectionState}');
                print('StreamBuilder - Has data: ${snapshot.hasData}');
                print('StreamBuilder - Data length: ${snapshot.data?.length}');
                print('StreamBuilder - Error: ${snapshot.error}');
                
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error, size: 64, color: Colors.red),
                        const SizedBox(height: 16),
                        Text('Error: ${snapshot.error}'),
                      ],
                    ),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.support_agent, size: 64, color: theme.hintColor),
                        const SizedBox(height: 16),
                        Text('No support tickets yet', style: theme.textTheme.titleMedium),
                        const SizedBox(height: 8),
                        Text('Create your first support ticket', style: theme.textTheme.bodyMedium),
                      ],
                    ),
                  );
                }

                final tickets = snapshot.data!;

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: tickets.length,
                  itemBuilder: (context, index) {
              final ticket = tickets[index];
              
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: theme.dividerColor),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => SupportChatScreen(ticketId: ticket.id),
                        ),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: _getStatusColor(ticket.status).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  ticket.priority == 'live_chat' ? Icons.chat_bubble : Icons.support,
                                  color: _getStatusColor(ticket.status),
                                  size: 20,
                                ),
                              ),
                              SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      ticket.subject,
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 16,
                                        color: theme.colorScheme.onSurface,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      'Ticket #${ticket.id.substring(0, 8).toUpperCase()}',
                                      style: TextStyle(
                                        color: theme.hintColor,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (ticket.hasUnreadMessages)
                                Container(
                                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.red,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    'NEW',
                                    style: TextStyle(
                                      color: theme.colorScheme.onError,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              SizedBox(width: 8),
                              Icon(Icons.arrow_forward_ios, size: 16, color: theme.hintColor),
                            ],
                          ),
                          SizedBox(height: 12),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: _getStatusColor(ticket.status),
                                  borderRadius: BorderRadius.circular(6),
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
                                  color: theme.colorScheme.surfaceVariant,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  ticket.priority == 'live_chat' ? 'LIVE CHAT' : ticket.priority.toUpperCase(),
                                  style: TextStyle(
                                    color: theme.colorScheme.onSurfaceVariant,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              Spacer(),
                              Text(
                                _formatDate(ticket.createdAt),
                                style: TextStyle(
                                  color: theme.hintColor,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
                },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const CreateSupportTicketScreen(),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
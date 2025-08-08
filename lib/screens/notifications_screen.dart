import 'package:flutter/material.dart';
import '../models/Notification.dart';
import '../services/support_notification_service.dart';
import 'support_chat_screen.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
        actions: [
          IconButton(
            onPressed: () async {
              await SupportNotificationService.markAllNotificationsAsRead();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('All notifications marked as read')),
              );
            },
            icon: const Icon(Icons.done_all),
            tooltip: 'Mark all as read',
          ),
        ],
      ),
      body: StreamBuilder<List<AppNotification>>(
        stream: SupportNotificationService.getUserNotifications(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_none, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'No notifications',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          final notifications = snapshot.data!;
          return ListView.builder(
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final notification = notifications[index];
              return _buildNotificationCard(notification, theme);
            },
          );
        },
      ),
    );
  }

  Widget _buildNotificationCard(AppNotification notification, ThemeData theme) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      color: notification.isRead 
          ? null 
          : theme.colorScheme.primary.withOpacity(0.05),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getNotificationColor(notification.type),
          child: Icon(
            _getNotificationIcon(notification.type),
            color: Colors.white,
            size: 20,
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                notification.title,
                style: TextStyle(
                  fontWeight: notification.isRead 
                      ? FontWeight.normal 
                      : FontWeight.bold,
                ),
              ),
            ),
            if (!notification.isRead)
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              notification.message,
              style: TextStyle(
                fontWeight: notification.isRead 
                    ? FontWeight.normal 
                    : FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _formatTime(notification.createdAt),
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
        onTap: () => _handleNotificationTap(notification),
      ),
    );
  }

  Color _getNotificationColor(String type) {
    switch (type) {
      case 'support_reply':
        return Colors.blue;
      case 'rating_request':
        return Colors.orange;
      case 'booking_confirmed':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  IconData _getNotificationIcon(String type) {
    switch (type) {
      case 'support_reply':
        return Icons.support_agent;
      case 'rating_request':
        return Icons.star;
      case 'booking_confirmed':
        return Icons.check_circle;
      default:
        return Icons.notifications;
    }
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Now';
    }
  }

  void _handleNotificationTap(AppNotification notification) async {
    // تحديد الإشعار كمقروء
    if (!notification.isRead) {
      await SupportNotificationService.markNotificationAsRead(notification.id);
    }

    // التنقل حسب نوع الإشعار
    switch (notification.type) {
      case 'support_reply':
        final ticketId = notification.data?['ticketId'];
        if (ticketId != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => SupportChatScreen(ticketId: ticketId),
            ),
          );
        }
        break;
      case 'rating_request':
        // يمكن إضافة التنقل لشاشة التقييم
        break;
      case 'booking_confirmed':
        // يمكن إضافة التنقل لشاشة الحجوزات
        break;
    }
  }
}
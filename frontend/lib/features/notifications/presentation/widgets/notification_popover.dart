import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../providers/notification_provider.dart';
import '../providers/popover_provider.dart';
import '../../domain/models/notification_model.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../student/presentation/providers/dashboard_index_provider.dart';

class NotificationPopover extends ConsumerWidget {
  final Function(int)? onNavigate;
  const NotificationPopover({super.key, this.onNavigate});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsAsync = ref.watch(notificationsStreamProvider);

    return Material(
      color: Colors.transparent,
      child: Container(
        width: 400,
        constraints: const BoxConstraints(maxHeight: 500),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(ref),
            const Divider(height: 1),
            Flexible(
              child: notificationsAsync.when(
                data: (notifications) {
                  if (notifications.isEmpty) {
                    return _buildEmptyState();
                  }
                  return ListView.separated(
                    shrinkWrap: true,
                    padding: const EdgeInsets.all(12),
                    itemCount: notifications.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      return _PopoverNotificationTile(
                        notification: notifications[index],
                        onNavigate: onNavigate,
                      );
                    },
                  );
                },
                loading: () => const Padding(
                  padding: EdgeInsets.all(32.0),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (err, _) => Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Center(child: Text('Error: $err')),
                ),
              ),
            ),
            const Divider(height: 1),
            _buildFooter(ref),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Notifications',
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 20),
            onPressed: () =>
                ref.read(notificationPopoverProvider.notifier).close(),
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          TextButton(
            onPressed: () =>
                ref.read(notificationNotifierProvider.notifier).markAllAsRead(),
            child: Text(
              'Mark all as read',
              style: GoogleFonts.outfit(
                fontSize: 13,
                color: AppTheme.primaryColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          TextButton(
            onPressed: () => ref
                .read(notificationNotifierProvider.notifier)
                .deleteAllNotifications(),
            child: Text(
              'Clear all',
              style: GoogleFonts.outfit(
                fontSize: 13,
                color: Colors.red[400],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.notifications_none_rounded,
            size: 48,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 12),
          Text(
            'No new updates',
            style: GoogleFonts.outfit(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.grey[400],
            ),
          ),
        ],
      ),
    );
  }
}

class _PopoverNotificationTile extends ConsumerWidget {
  final NotificationModel notification;
  final Function(int)? onNavigate;

  const _PopoverNotificationTile({required this.notification, this.onNavigate});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return InkWell(
      onTap: () {
        if (!notification.isRead) {
          ref
              .read(notificationNotifierProvider.notifier)
              .markAsRead(notification.id);
        }
        _handleNavigation(ref);
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: notification.isRead
              ? Colors.transparent
              : Colors.blue.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: notification.isRead
                ? Colors.transparent
                : Colors.blue.withValues(alpha: 0.1),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildIcon(),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    notification.title,
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      fontWeight: notification.isRead
                          ? FontWeight.w500
                          : FontWeight.bold,
                      color: Colors.black87,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    notification.content,
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatTime(notification.createdAt),
                    style: GoogleFonts.outfit(
                      fontSize: 10,
                      color: Colors.grey[400],
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

  void _handleNavigation(WidgetRef ref) {
    ref.read(notificationPopoverProvider.notifier).close();

    int targetIndex = 0;
    switch (notification.type) {
      case NotificationType.job:
        targetIndex = 5; // Job Applications
        break;
      case NotificationType.event:
        targetIndex = 11; // Events
        break;
      case NotificationType.course:
        targetIndex = 7; // Learning Paths
        break;
      case NotificationType.connection:
        targetIndex = 12; // My Network
        break;
      case NotificationType.message:
        targetIndex = 12; // My Network (Messages)
        break;
      case NotificationType.interview:
        targetIndex = 6; // Interview Prep
        break;
      default:
        return;
    }

    if (onNavigate != null) {
      onNavigate!(targetIndex);
    } else {
      ref.read(studentDashboardIndexProvider.notifier).setIndex(targetIndex);
    }
  }

  Widget _buildIcon() {
    IconData iconData;
    Color color;

    switch (notification.type) {
      case NotificationType.job:
        iconData = Icons.work_rounded;
        color = Colors.orange;
        break;
      case NotificationType.event:
        iconData = Icons.event_rounded;
        color = Colors.purple;
        break;
      case NotificationType.course:
        iconData = Icons.school_rounded;
        color = Colors.green;
        break;
      default:
        iconData = Icons.notifications_rounded;
        color = Colors.blue;
    }

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(iconData, color: color, size: 18),
    );
  }

  String _formatTime(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    if (difference.inMinutes < 60) return '${difference.inMinutes}m ago';
    if (difference.inHours < 24) return '${difference.inHours}h ago';
    return DateFormat('MMM d').format(date);
  }
}

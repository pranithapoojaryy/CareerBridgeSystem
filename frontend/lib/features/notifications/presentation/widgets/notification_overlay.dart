import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../domain/models/notification_model.dart';
import '../../../../core/theme/app_theme.dart';

class NotificationOverlay extends StatelessWidget {
  final NotificationModel notification;
  final VoidCallback onTap;
  final VoidCallback onDismiss;

  const NotificationOverlay({
    super.key,
    required this.notification,
    required this.onTap,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
                border: Border.all(
                  color: AppTheme.primaryColor.withValues(alpha: 0.1),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  _buildIcon(),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          notification.title,
                          style: GoogleFonts.outfit(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: Colors.black87,
                          ),
                        ),
                        Text(
                          notification.content,
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: onDismiss,
                    icon: const Icon(Icons.close_rounded, size: 20),
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
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
      case NotificationType.connection:
        iconData = Icons.person_add_rounded;
        color = Colors.blue;
        break;
      default:
        iconData = Icons.notifications_rounded;
        color = AppTheme.primaryColor;
    }

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(iconData, color: color, size: 20),
    );
  }
}

// Global utility for showing overlay
void showNotificationOverlay(
  BuildContext context,
  NotificationModel notification, {
  VoidCallback? onTap,
}) {
  final overlay = Overlay.of(context);
  late OverlayEntry entry;

  entry = OverlayEntry(
    builder: (context) => TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 500),
      tween: Tween(begin: -100.0, end: 0.0),
      curve: Curves.easeOutBack,
      builder: (context, value, child) {
        return Positioned(
          top: value,
          left: 0,
          right: 0,
          child: NotificationOverlay(
            notification: notification,
            onTap: () {
              entry.remove();
              onTap?.call();
            },
            onDismiss: () => entry.remove(),
          ),
        );
      },
    ),
  );

  overlay.insert(entry);

  // Auto dismiss after 5 seconds
  Future.delayed(const Duration(seconds: 5), () {
    if (entry.mounted) {
      entry.remove();
    }
  });
}

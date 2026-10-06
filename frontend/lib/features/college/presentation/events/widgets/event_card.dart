import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../core/theme/app_theme.dart';

class EventCard extends StatelessWidget {
  final Map<String, dynamic> event;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const EventCard({
    super.key,
    required this.event,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final eventType = (event['event_type'] ?? 'event') as String;
    final status = (event['status'] ?? 'upcoming') as String;
    final startDate =
        DateTime.tryParse(event['start_date']?.toString() ?? '') ??
        DateTime.now();

    // Handle registration count from join query
    int registeredCount = 0;
    if (event['event_registrations'] != null &&
        event['event_registrations'] is List) {
      final regs = event['event_registrations'] as List;
      if (regs.isNotEmpty && regs[0] is Map) {
        registeredCount = (regs[0]['count'] as int?) ?? 0;
      }
    }

    final maxParticipants = (event['max_participants'] as int?) ?? 100;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with type badge and menu
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: _getEventTypeColor(
                          eventType,
                        ).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _getEventTypeIcon(eventType),
                            size: 14,
                            color: _getEventTypeColor(eventType),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _getEventTypeLabel(eventType),
                            style: GoogleFonts.outfit(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: _getEventTypeColor(eventType),
                            ),
                          ),
                        ],
                      ),
                    ),
                    PopupMenuButton<String>(
                      onSelected: (value) {
                        switch (value) {
                          case 'edit':
                            onEdit();
                            break;
                          case 'delete':
                            onDelete();
                            break;
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(Icons.edit_rounded, size: 16),
                              SizedBox(width: 8),
                              Text('Edit'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(
                                Icons.delete_rounded,
                                size: 16,
                                color: Colors.red,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Delete',
                                style: TextStyle(color: Colors.red),
                              ),
                            ],
                          ),
                        ),
                      ],
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Icon(
                          Icons.more_vert_rounded,
                          size: 16,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Event title
                Text(
                  event['title'] ?? 'Untitled Event',
                  style: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textColor,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),

                const SizedBox(height: 8),

                // Event description
                Text(
                  event['description'] ?? 'No description provided.',
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    color: Colors.grey[600],
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),

                const SizedBox(height: 16),

                // Event details
                Column(
                  children: [
                    _buildDetailRow(
                      Icons.calendar_today_rounded,
                      _formatDate(startDate),
                    ),
                    const SizedBox(height: 8),
                    _buildDetailRow(
                      Icons.location_on_rounded,
                      (event['is_online'] == true)
                          ? 'Online'
                          : (event['venue'] ?? 'TBA'),
                    ),
                    const SizedBox(height: 8),
                    _buildDetailRow(
                      Icons.people_rounded,
                      '$registeredCount / $maxParticipants',
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Status and progress
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _getStatusColor(status).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        status.toUpperCase(),
                        style: GoogleFonts.outfit(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: _getStatusColor(status),
                        ),
                      ),
                    ),
                    Text(
                      '${((registeredCount / maxParticipants) * 100).round()}% full',
                      style: GoogleFonts.outfit(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[600],
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
  }

  Widget _buildDetailRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 14, color: Colors.grey[500]),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey[600]),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Color _getEventTypeColor(String type) {
    switch (type) {
      case 'hackathon':
        return Colors.purple;
      case 'workshop':
        return Colors.blue;
      case 'guest_lecture':
        return Colors.green;
      case 'competition':
        return Colors.orange;
      default:
        return AppTheme.primaryColor;
    }
  }

  IconData _getEventTypeIcon(String type) {
    switch (type) {
      case 'hackathon':
        return Icons.code_rounded;
      case 'workshop':
        return Icons.build_rounded;
      case 'guest_lecture':
        return Icons.record_voice_over_rounded;
      case 'competition':
        return Icons.emoji_events_rounded;
      default:
        return Icons.event_rounded;
    }
  }

  String _getEventTypeLabel(String type) {
    switch (type) {
      case 'hackathon':
        return 'Hackathon';
      case 'workshop':
        return 'Workshop';
      case 'guest_lecture':
        return 'Guest Lecture';
      case 'competition':
        return 'Competition';
      default:
        return 'Event';
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'upcoming':
        return Colors.blue;
      case 'ongoing':
        return Colors.green;
      case 'completed':
        return Colors.grey;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = date.difference(now).inDays;

    if (difference == 0) {
      return 'Today';
    } else if (difference == 1) {
      return 'Tomorrow';
    } else if (difference > 1 && difference <= 7) {
      return 'In $difference days';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}

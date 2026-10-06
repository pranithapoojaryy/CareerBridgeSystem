import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/recruiter_repository.dart';
import 'package:intl/intl.dart';

class ActiveEventsSidebarWidget extends ConsumerWidget {
  const ActiveEventsSidebarWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventsAsync = ref.watch(activeRecruiterEventsProvider);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Company Events',
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1A1D1E),
                ),
              ),
              const Icon(
                Icons.event_note,
                color: AppTheme.primaryColor,
                size: 20,
              ),
            ],
          ),
          const SizedBox(height: 20),
          eventsAsync.when(
            data: (events) {
              if (events.isEmpty) {
                return Center(
                  child: Column(
                    children: [
                      const SizedBox(height: 10),
                      Icon(
                        Icons.event_available,
                        size: 40,
                        color: Colors.grey[300],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'No upcoming events',
                        style: GoogleFonts.outfit(
                          color: Colors.grey[400],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                );
              }

              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: events.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 16),
                itemBuilder: (context, index) {
                  final event = events[index];
                  final startDate = event['start_date'] != null
                      ? DateTime.parse(event['start_date'])
                      : null;
                  final dateStr = startDate != null
                      ? DateFormat('MMM dd, yyyy').format(startDate)
                      : 'To be announced';

                  return Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          _getEventIcon(event['event_type']),
                          color: AppTheme.primaryColor,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              event['title'] ?? 'Untitled Event',
                              style: GoogleFonts.outfit(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: Colors.black87,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              dateStr,
                              style: GoogleFonts.outfit(
                                fontSize: 12,
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              );
            },
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
            error: (err, stack) => Center(
              child: Text(
                'Error loading events',
                style: GoogleFonts.outfit(color: Colors.red[300], fontSize: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getEventIcon(String? type) {
    switch (type?.toLowerCase()) {
      case 'hackathon':
        return Icons.code;
      case 'workshop':
        return Icons.psychology;
      case 'guest_lecture':
        return Icons.record_voice_over;
      case 'webinar':
        return Icons.laptop_mac;
      default:
        return Icons.groups;
    }
  }
}

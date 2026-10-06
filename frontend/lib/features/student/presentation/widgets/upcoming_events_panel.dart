import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../screens/events_list_screen.dart';
import '../events/student_events_screen.dart'; // Added Import

import '../../../shared/data/shared_events_repository.dart';

class UpcomingEventsPanel extends ConsumerStatefulWidget {
  const UpcomingEventsPanel({super.key});

  @override
  ConsumerState<UpcomingEventsPanel> createState() =>
      _UpcomingEventsPanelState();
}

class _UpcomingEventsPanelState extends ConsumerState<UpcomingEventsPanel> {
  final _supabase = Supabase.instance.client;
  bool _isLoading = true;
  List<Map<String, dynamic>> _events = [];

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  Future<void> _loadEvents() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;

      final repo = SharedEventsRepository(_supabase);
      final events = await repo.getStudentRegisteredEvents(user.id);

      // Filter for upcoming only (start_date > now)
      final upcomingEvents = events.where((e) {
        if (e['start_date'] == null) return true;
        return DateTime.parse(e['start_date']).isAfter(DateTime.now());
      }).toList();

      if (mounted) {
        setState(() {
          _events = upcomingEvents.take(3).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading events: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white,
            const Color(0xFFFFF3E0), // Light Orange tint
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  'Upcoming Events',
                  style: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const EventsListScreen(),
                    ),
                  );
                },
                child: Text(
                  'View All',
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    color: AppTheme.primaryColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          if (_isLoading)
            const Center(child: CircularProgressIndicator())
          else if (_events.isEmpty)
            _buildEmptyState()
          else
            ..._events.map((event) => _buildEventItemFromData(event)),

          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const StudentEventsScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.calendar_today_rounded),
              label: const Text('View Calendar'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.primaryColor,
                side: BorderSide(color: AppTheme.primaryColor),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          children: [
            Icon(Icons.event_busy_rounded, color: Colors.grey[300], size: 40),
            const SizedBox(height: 8),
            Text(
              'No upcoming registered events',
              style: GoogleFonts.outfit(color: Colors.grey[500]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEventItemFromData(Map<String, dynamic> event) {
    final title = event['title'] ?? 'Event';
    final description = event['description'] ?? 'No details';
    final date = event['start_date'] != null
        ? DateFormat(
            'MMM d, h:mm a',
          ).format(DateTime.parse(event['start_date']))
        : 'TBA';
    final location = event['is_online'] == true
        ? 'Online'
        : (event['venue'] ?? 'TBA');

    // Determine color based on type
    final type = (event['event_type'] ?? 'EVENT').toString().toUpperCase();
    Color color = Colors.blue;
    if (type == 'HACKATHON') color = Colors.orange;
    if (type == 'WORKSHOP') color = Colors.green;
    if (type == 'WEBINAR') color = Colors.purple;

    return _buildEventItem(title, description, date, location, color);
  }

  Widget _buildEventItem(
    String title,
    String description,
    String time,
    String location,
    Color color,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 4,
                height: 20,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.only(left: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  description,
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.access_time_rounded,
                      size: 14,
                      color: Colors.grey[500],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      time,
                      style: GoogleFonts.outfit(
                        fontSize: 11,
                        color: Colors.grey[500],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Icon(
                      Icons.location_on_rounded,
                      size: 14,
                      color: Colors.grey[500],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      location,
                      style: GoogleFonts.outfit(
                        fontSize: 11,
                        color: Colors.grey[500],
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
}

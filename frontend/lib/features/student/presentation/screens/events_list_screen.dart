import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import '../../../shared/data/shared_events_repository.dart';

class EventsListScreen extends ConsumerStatefulWidget {
  const EventsListScreen({super.key});

  @override
  ConsumerState<EventsListScreen> createState() => _EventsListScreenState();
}

class _EventsListScreenState extends ConsumerState<EventsListScreen> {
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

      // Filter for upcoming (optional, or just show all registered)
      // Usually list screen shows all or sorted by date.
      // Let's sort descending (newest first) or ascending (closest first)?
      // For "Upcoming", closest first is better.
      // But getStudentRegisteredEvents returns desc by created_at.
      // Let's manually sort by start_date if available.

      events.sort((a, b) {
        final dateA = a['start_date'] != null
            ? DateTime.parse(a['start_date'])
            : DateTime(2100);
        final dateB = b['start_date'] != null
            ? DateTime.parse(b['start_date'])
            : DateTime(2100);
        return dateA.compareTo(dateB);
      });

      if (mounted) {
        setState(() {
          _events = events;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Your Registered Events',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _events.isEmpty
          ? Center(
              child: Text(
                'No registered events',
                style: GoogleFonts.outfit(color: Colors.grey),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: _events.length,
              separatorBuilder: (context, index) => const SizedBox(height: 16),
              itemBuilder: (context, index) => _buildEventItem(_events[index]),
            ),
    );
  }

  Widget _buildEventItem(Map<String, dynamic> event) {
    final title = event['title'] ?? 'Event';
    final description = event['description'] ?? 'No details';
    final date = event['start_date'] != null
        ? DateFormat(
            'MMM d, h:mm a',
          ).format(DateTime.parse(event['start_date']))
        : 'TBA';
    final isOnline = event['is_online'] == true;
    final location = isOnline ? 'Online' : (event['venue'] ?? 'TBA');
    final type = (event['event_type'] ?? 'EVENT').toString().toUpperCase();

    Color typeColor = Colors.blue;
    if (type == 'HACKATHON') typeColor = Colors.orange;
    if (type == 'WORKSHOP') typeColor = Colors.green;
    if (type == 'WEBINAR') typeColor = Colors.purple;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: typeColor.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: typeColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  type,
                  style: GoogleFonts.outfit(
                    color: typeColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: GoogleFonts.outfit(color: Colors.grey[600]),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.access_time_rounded, size: 16, color: Colors.grey),
              const SizedBox(width: 4),
              Text(date, style: GoogleFonts.outfit(color: Colors.grey)),
              const SizedBox(width: 16),
              Icon(
                isOnline ? Icons.wifi : Icons.place,
                size: 16,
                color: Colors.grey,
              ),
              const SizedBox(width: 4),
              Text(location, style: GoogleFonts.outfit(color: Colors.grey)),
            ],
          ),
        ],
      ),
    );
  }
}

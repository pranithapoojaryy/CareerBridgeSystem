import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import '../../data/shared_events_repository.dart';

// Create a provider-less access or use FutureBuilder
class EventParticipantsDialog extends ConsumerWidget {
  final String eventId;
  final String eventTitle;

  const EventParticipantsDialog({
    super.key,
    required this.eventId,
    required this.eventTitle,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // We can use a FutureProvider here or just call the repo directly in FutureBuilder
    // Since this is a simple dialog, direct call is fine or we can assume the repo provider is available
    final repo = SharedEventsRepository(Supabase.instance.client);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 500,
        height: 600,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Participants',
                        style: GoogleFonts.outfit(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        eventTitle,
                        style: GoogleFonts.outfit(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            Expanded(
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: repo.getEventParticipants(eventId),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }

                  final participants = snapshot.data ?? [];
                  if (participants.isEmpty) {
                    return Center(
                      child: Text(
                        'No participants registered yet.',
                        style: GoogleFonts.outfit(color: Colors.grey[500]),
                      ),
                    );
                  }

                  return ListView.separated(
                    itemCount: participants.length,
                    separatorBuilder: (context, index) => const Divider(),
                    itemBuilder: (context, index) {
                      final p = participants[index];
                      final student =
                          p['student']; // Map<String, dynamic> or null
                      final registeredAt = DateTime.parse(p['created_at']);

                      final name = student != null
                          ? (student['full_name'] ?? 'Unknown Name')
                          : 'Unknown';
                      final email = student != null
                          ? (student['email'] ?? 'No Email')
                          : '-';
                      // If avatar_url exists, we could show it

                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.blue[100],
                          child: Text(
                            name[0].toUpperCase(),
                            style: GoogleFonts.outfit(
                              fontWeight: FontWeight.bold,
                              color: Colors.blue[800],
                            ),
                          ),
                        ),
                        title: Text(
                          name,
                          style: GoogleFonts.outfit(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: Text(
                          email,
                          style: GoogleFonts.outfit(color: Colors.grey[600]),
                        ),
                        trailing: Text(
                          DateFormat('MMM d, y').format(registeredAt),
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            color: Colors.grey[500],
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
      ),
    );
  }
}

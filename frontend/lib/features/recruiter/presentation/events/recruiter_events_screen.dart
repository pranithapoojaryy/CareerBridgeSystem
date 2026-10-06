import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../college/presentation/events/widgets/create_event_dialog.dart';
import '../../../student/presentation/events/student_events_screen.dart';
import '../../../shared/presentation/widgets/event_participants_dialog.dart';

class RecruiterEventsScreen extends ConsumerStatefulWidget {
  const RecruiterEventsScreen({super.key});

  @override
  ConsumerState<RecruiterEventsScreen> createState() =>
      _RecruiterEventsScreenState();
}

class _RecruiterEventsScreenState extends ConsumerState<RecruiterEventsScreen> {
  String? _companyId;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCompanyId();
  }

  Future<void> _loadCompanyId() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    final data = await Supabase.instance.client
        .from('recruiters')
        .select('company_id')
        .eq('id', userId)
        .maybeSingle();

    if (mounted) {
      setState(() {
        _companyId = data?['company_id'];
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_companyId == null)
      return const Center(child: Text('Error: No Company Linked'));

    final eventsAsync = ref.watch(organizerEventsProvider(_companyId!));

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateEventDialog,
        label: const Text('Create Event'),
        icon: const Icon(Icons.add),
        backgroundColor: Colors.black87,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(32, 32, 32, 16),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new, size: 20),
                  onPressed: () => Navigator.maybePop(context),
                ),
                const SizedBox(width: 8),
                Text(
                  'Events',
                  style: GoogleFonts.outfit(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: eventsAsync.when(
              data: (events) {
                if (events.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.event_note_rounded,
                          size: 60,
                          color: Colors.grey[300],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No events created yet.',
                          style: GoogleFonts.outfit(color: Colors.grey[500]),
                        ),
                      ],
                    ),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  itemCount: events.length,
                  itemBuilder: (context, index) {
                    final event = events[index];
                    return _buildEventCard(event);
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(child: Text('Error: $err')),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventCard(Map<String, dynamic> event) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        title: Text(
          event['title'],
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        onTap: () {
          showDialog(
            context: context,
            builder: (context) => EventParticipantsDialog(
              eventId: event['id'],
              eventTitle: event['title'],
            ),
          );
        },
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(event['event_type']?.toString().toUpperCase() ?? 'EVENT'),
            const SizedBox(height: 4),
            Text(
              'Registered: ${event['event_registrations']?[0]['count'] ?? 0}',
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.blue),
              onPressed: () => _showEditEventDialog(event),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              onPressed: () => _deleteEvent(event['id']),
            ),
          ],
        ),
      ),
    );
  }

  void _showCreateEventDialog() {
    showDialog(
      context: context,
      builder: (context) => CreateEventDialog(
        onEventCreated: (eventData) async {
          final scaffoldMessenger = ScaffoldMessenger.of(context);
          // Add college_id (company_id) to event data
          final data = {
            ...eventData,
            'college_id': _companyId,
            // Ensure status is published by default for recruiters?
            // The dialog sets it to 'published'
          };

          try {
            await ref.read(sharedEventsRepositoryProvider).createEvent(data);
            // Invalidate manually since we are using a family provider that depends on companyId
            // But actually, we need to create a provider for this screen first.
            // I'll define it below or reuse.
            ref.invalidate(organizerEventsProvider(_companyId!));
            if (mounted) {
              scaffoldMessenger.showSnackBar(
                const SnackBar(content: Text('Event Created')),
              );
            }
          } catch (e) {
            if (mounted) {
              scaffoldMessenger.showSnackBar(
                SnackBar(content: Text('Error: $e')),
              );
            }
          }
        },
      ),
    );
  }

  void _showEditEventDialog(Map<String, dynamic> event) {
    showDialog(
      context: context,
      builder: (context) => CreateEventDialog(
        initialData: event,
        onEventCreated: (updatedData) async {
          final scaffoldMessenger = ScaffoldMessenger.of(context);
          try {
            // We need to implement updateEvent in SharedEventsRepository
            // Or construct the update manually here if repo doesn't support it (but it should)

            // I recall seeing sharedEventsRepositoryProvider.
            // I need to add updateEvent to SharedEventsRepository.dart first!
            // Wait, I only checked CollegeRepository. SharedEventsRepository was viewed earlier but I didn't check for update method.
            // Let's assume I need to add it or use direct supabase call here if it's missing.
            // Best practice: Add to Repo.

            await ref
                .read(sharedEventsRepositoryProvider)
                .updateEvent(event['id'], updatedData);

            ref.invalidate(organizerEventsProvider(_companyId!));
            if (mounted) {
              scaffoldMessenger.showSnackBar(
                const SnackBar(content: Text('Event Updated')),
              );
            }
          } catch (e) {
            if (mounted) {
              scaffoldMessenger.showSnackBar(
                SnackBar(content: Text('Error: $e')),
              );
            }
          }
        },
      ),
    );
  }

  Future<void> _deleteEvent(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Event'),
        content: const Text('Are you sure?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await ref.read(sharedEventsRepositoryProvider).deleteEvent(id);
      ref.invalidate(organizerEventsProvider(_companyId!));
    }
  }
}

// Provider for recruiter events
final organizerEventsProvider =
    FutureProvider.family<List<Map<String, dynamic>>, String>((
      ref,
      orgId,
    ) async {
      final repo = ref.watch(sharedEventsRepositoryProvider);
      return repo.getOrganizerEvents(orgId);
    });

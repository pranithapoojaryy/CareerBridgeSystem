import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/recruiter_repository.dart';
import '../../../college/presentation/events/widgets/event_card.dart';
import '../../../college/presentation/events/widgets/create_event_dialog.dart';
import '../../../college/data/college_providers.dart';

class RecruiterEventManagementScreen extends ConsumerStatefulWidget {
  const RecruiterEventManagementScreen({super.key});

  @override
  ConsumerState<RecruiterEventManagementScreen> createState() =>
      _RecruiterEventManagementScreenState();
}

class _RecruiterEventManagementScreenState
    extends ConsumerState<RecruiterEventManagementScreen> {
  String _searchQuery = '';
  String _selectedFilter = 'All';

  @override
  Widget build(BuildContext context) {
    final statsAsync = ref.watch(recruiterDashboardStatsProvider);
    final companyId = statsAsync.value?['companyId'];

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.of(context, rootNavigator: true).pop(),
        ),
        title: Text(
          'Manage Events',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: AppTheme.textColor,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Center(
              child: FilledButton.icon(
                onPressed: () => _showCreateEventDialog(companyId),
                icon: const Icon(Icons.add, size: 20),
                label: const Text('New Event'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search and Filters
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: Color(0xFFEEEEEE))),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    onChanged: (value) => setState(() => _searchQuery = value),
                    decoration: InputDecoration(
                      hintText: 'Search your events...',
                      prefixIcon: const Icon(Icons.search),
                      fillColor: Colors.grey[100],
                      filled: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 0),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedFilter,
                      items: ['All', 'Hackathon', 'Workshop', 'Fair', 'Other']
                          .map(
                            (f) => DropdownMenuItem(value: f, child: Text(f)),
                          )
                          .toList(),
                      onChanged: (v) => setState(() => _selectedFilter = v!),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Events List
          Expanded(child: _buildEventsList()),
        ],
      ),
    );
  }

  Widget _buildEventsList() {
    // Try to use the same provider that is working in the sidebar
    final eventsAsync = ref.watch(activeRecruiterEventsProvider);

    return eventsAsync.when(
      data: (events) {
        final filtered = events.where((e) {
          final title = (e['title'] ?? '').toString().toLowerCase();
          final type = (e['event_type'] ?? '').toString().toLowerCase();
          final matchesSearch = title.contains(_searchQuery.toLowerCase());
          final matchesType =
              _selectedFilter == 'All' || type == _selectedFilter.toLowerCase();
          return matchesSearch && matchesType;
        }).toList();

        if (filtered.isEmpty) {
          return Center(
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.event_available_outlined,
                    size: 80,
                    color: Colors.grey[200],
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'No events to manage',
                    style: GoogleFonts.outfit(
                      fontSize: 20,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Try changing your filters or add a new event.',
                    style: GoogleFonts.outfit(
                      fontSize: 15,
                      color: Colors.grey[400],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          itemCount: filtered.length,
          itemBuilder: (context, index) {
            final event = filtered[index];
            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              child: EventCard(
                event: event,
                onTap: () {},
                onEdit: () => _editEvent(event),
                onDelete: () => _deleteEvent(event),
              ),
            );
          },
        );
      },
      loading: () => const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading events...'),
          ],
        ),
      ),
      error: (e, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 16),
            Text(
              'Failed to load events',
              style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              '$e',
              style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _showCreateEventDialog(String? companyId) {
    if (companyId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please complete your company profile first'),
        ),
      );
      return;
    }
    showDialog(
      context: context,
      builder: (context) => CreateEventDialog(
        onEventCreated: (data) async {
          final fullData = {
            ...data,
            'college_id': companyId,
            'created_by': Supabase.instance.client.auth.currentUser?.id,
          };
          await ref.read(eventsNotifierProvider.notifier).createEvent(fullData);
          ref.invalidate(allRecruiterEventsProvider);
          ref.invalidate(activeRecruiterEventsProvider);
          if (mounted) Navigator.pop(context);
        },
      ),
    );
  }

  void _editEvent(Map<String, dynamic> event) {
    showDialog(
      context: context,
      builder: (context) => CreateEventDialog(
        initialData: event,
        onEventCreated: (data) async {
          await ref
              .read(eventsNotifierProvider.notifier)
              .updateEvent(event['id'], data);
          ref.invalidate(allRecruiterEventsProvider);
          ref.invalidate(activeRecruiterEventsProvider);
          if (mounted) Navigator.pop(context);
        },
      ),
    );
  }

  void _deleteEvent(Map<String, dynamic> event) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Event'),
        content: Text('Are you sure you want to delete "${event['title']}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              await ref
                  .read(eventsNotifierProvider.notifier)
                  .deleteEvent(event['id']);
              ref.invalidate(allRecruiterEventsProvider);
              ref.invalidate(activeRecruiterEventsProvider);
              if (mounted) Navigator.pop(context);
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

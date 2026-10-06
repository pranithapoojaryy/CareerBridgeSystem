import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/college_providers.dart';
import 'widgets/event_card.dart';
import 'widgets/create_event_dialog.dart';
import 'widgets/event_stats_overview.dart';
import '../../../shared/presentation/widgets/event_participants_dialog.dart';

class EventsManagerScreen extends ConsumerStatefulWidget {
  const EventsManagerScreen({super.key});

  @override
  ConsumerState<EventsManagerScreen> createState() =>
      _EventsManagerScreenState();
}

class _EventsManagerScreenState extends ConsumerState<EventsManagerScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedFilter = 'All';
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Column(
        children: [
          // Header Section
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
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
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Events Manager',
                          style: GoogleFonts.outfit(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Organize hackathons, workshops, guest lectures & more',
                          style: GoogleFonts.outfit(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                    FilledButton.icon(
                      onPressed: () => _showCreateEventDialog(),
                      icon: const Icon(Icons.add_rounded),
                      label: const Text('Create Event'),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 16,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Stats Overview
                const EventStatsOverview(),

                const SizedBox(height: 24),

                // Search and Filter Bar
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextField(
                        onChanged: (value) =>
                            setState(() => _searchQuery = value),
                        decoration: InputDecoration(
                          hintText: 'Search events...',
                          prefixIcon: const Icon(Icons.search_rounded),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? IconButton(
                                  onPressed: () =>
                                      setState(() => _searchQuery = ''),
                                  icon: const Icon(Icons.clear_rounded),
                                )
                              : null,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedFilter,
                          items:
                              [
                                'All',
                                'Upcoming',
                                'Ongoing',
                                'Completed',
                                'Hackathons',
                                'Workshops',
                                'Guest Lectures',
                                'Competitions',
                              ].map((filter) {
                                return DropdownMenuItem(
                                  value: filter,
                                  child: Text(filter),
                                );
                              }).toList(),
                          onChanged: (value) {
                            setState(() => _selectedFilter = value!);
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Tab Bar
          Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              labelColor: AppTheme.primaryColor,
              unselectedLabelColor: Colors.grey[600],
              indicatorColor: AppTheme.primaryColor,
              labelStyle: GoogleFonts.outfit(fontWeight: FontWeight.w600),
              tabs: const [
                Tab(text: 'All Events'),
                Tab(text: 'Hackathons'),
                Tab(text: 'Workshops'),
                Tab(text: 'Guest Lectures'),
              ],
            ),
          ),

          // Content Area
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildEventsGrid('all'),
                _buildEventsGrid('hackathon'),
                _buildEventsGrid('workshop'),
                _buildEventsGrid('guest_lecture'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventsGrid(String eventType) {
    final eventsAsync = ref.watch(
      eventsProvider(
        CollegeEventFilter(
          eventType: eventType == 'all' ? null : eventType,
          status: null,
        ),
      ),
    );

    return eventsAsync.when(
      data: (events) {
        // Apply search filter
        final filteredEvents = events.where((event) {
          if (_searchQuery.isEmpty) return true;

          final title = event['title']?.toString().toLowerCase() ?? '';
          final description =
              event['description']?.toString().toLowerCase() ?? '';
          final query = _searchQuery.toLowerCase();

          return title.contains(query) || description.contains(query);
        }).toList();

        // Apply additional filters
        final finalEvents = filteredEvents.where((event) {
          if (_selectedFilter == 'All') return true;

          switch (_selectedFilter) {
            case 'Upcoming':
              return DateTime.parse(
                event['start_date'],
              ).isAfter(DateTime.now());
            case 'Ongoing':
              final start = DateTime.parse(event['start_date']);
              final end = DateTime.parse(event['end_date']);
              final now = DateTime.now();
              return start.isBefore(now) && end.isAfter(now);
            case 'Completed':
              return DateTime.parse(event['end_date']).isBefore(DateTime.now());
            default:
              return event['event_type'] == _selectedFilter.toLowerCase();
          }
        }).toList();

        if (finalEvents.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.event_busy_rounded,
                  size: 64,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'No events found',
                  style: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Create your first event to get started',
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          );
        }

        return Padding(
          padding: const EdgeInsets.all(24),
          child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 24,
              mainAxisSpacing: 24,
              childAspectRatio: 1.2,
            ),
            itemCount: finalEvents.length,
            itemBuilder: (context, index) {
              final event = finalEvents[index];
              return EventCard(
                event: event,
                onTap: () => _viewEventDetails(event),
                onEdit: () => _editEvent(event),
                onDelete: () => _deleteEvent(event),
              );
            },
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
            const SizedBox(height: 16),
            Text('Error loading events: $error'),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => ref.invalidate(eventsProvider),
              child: const Text('Retry'),
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
          try {
            // Inject college_id
            final college = await ref.read(currentCollegeProvider.future);
            if (college == null) {
              throw Exception('College profile not found');
            }

            final fullEventData = {...eventData, 'college_id': college['id']};

            await ref
                .read(eventsNotifierProvider.notifier)
                .createEvent(fullEventData);
            if (mounted) {
              scaffoldMessenger.showSnackBar(
                SnackBar(
                  content: Text('${eventData['title']} created successfully!'),
                ),
              );
            }
          } catch (e) {
            if (mounted) {
              scaffoldMessenger.showSnackBar(
                SnackBar(content: Text('Error creating event: $e')),
              );
            }
          }
        },
      ),
    );
  }

  void _viewEventDetails(Map<String, dynamic> event) {
    showDialog(
      context: context,
      builder: (context) => EventParticipantsDialog(
        eventId: event['id'],
        eventTitle: event['title'],
      ),
    );
  }

  void _editEvent(Map<String, dynamic> event) {
    showDialog(
      context: context,
      builder: (context) => CreateEventDialog(
        initialData: event,
        onEventCreated: (updatedData) async {
          final scaffoldMessenger = ScaffoldMessenger.of(context);
          try {
            // Update existing event
            await ref
                .read(eventsNotifierProvider.notifier)
                .updateEvent(event['id'], updatedData);

            if (mounted) {
              scaffoldMessenger.showSnackBar(
                SnackBar(
                  content: Text(
                    '${updatedData['title']} updated successfully!',
                  ),
                ),
              );
            }
          } catch (e) {
            if (mounted) {
              scaffoldMessenger.showSnackBar(
                SnackBar(content: Text('Error updating event: $e')),
              );
            }
          }
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
              final scaffoldMessenger = ScaffoldMessenger.of(context);
              Navigator.pop(context);
              try {
                await ref
                    .read(eventsNotifierProvider.notifier)
                    .deleteEvent(event['id']);
                if (mounted) {
                  scaffoldMessenger.showSnackBar(
                    SnackBar(content: Text('${event['title']} deleted')),
                  );
                }
              } catch (e) {
                if (mounted) {
                  scaffoldMessenger.showSnackBar(
                    SnackBar(content: Text('Error deleting event: $e')),
                  );
                }
              }
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

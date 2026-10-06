import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../shared/data/shared_events_repository.dart';

// Provider for the repo
final sharedEventsRepositoryProvider = Provider((ref) {
  return SharedEventsRepository(Supabase.instance.client);
});

class EventFilter {
  final String? search;
  final String? type;

  const EventFilter({this.search, this.type});

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is EventFilter && other.search == search && other.type == type;
  }

  @override
  int get hashCode => search.hashCode ^ type.hashCode;
}

// Provider for events list
final studentEventsProvider =
    FutureProvider.family<List<Map<String, dynamic>>, EventFilter>((
      ref,
      filter,
    ) async {
      final repo = ref.watch(sharedEventsRepositoryProvider);
      return repo.getPublishedEvents(search: filter.search, type: filter.type);
    });

class StudentEventsScreen extends ConsumerStatefulWidget {
  const StudentEventsScreen({super.key});

  @override
  ConsumerState<StudentEventsScreen> createState() =>
      _StudentEventsScreenState();
}

class _StudentEventsScreenState extends ConsumerState<StudentEventsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  final List<String> _tabs = [
    'All',
    'Hackathon',
    'Workshop',
    'Webinar',
    'Competition',
    'Guest_Lecture',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        setState(() {}); // Rebuild to refresh provider with new type
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentType = _tabs[_tabController.index];
    final eventsAsync = ref.watch(
      studentEventsProvider(
        EventFilter(
          search: _searchQuery,
          type: currentType == 'All' ? null : currentType,
        ),
      ),
    );

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // Header & Search
          Container(
            width: double.infinity,
            padding: const EdgeInsets.only(
              top: 48,
              left: 24,
              right: 24,
              bottom: 24,
            ),
            decoration: AppTheme.gradientBackground.copyWith(
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(32),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          if (MediaQuery.of(context).size.width < 900)
                            Padding(
                              padding: const EdgeInsets.only(right: 12),
                              child: IconButton(
                                onPressed: () {
                                  Scaffold.of(context).openDrawer();
                                },
                                icon: const Icon(
                                  Icons.menu_rounded,
                                  color: AppTheme.textColor,
                                  size: 28,
                                ),
                              ),
                            ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Events Hub',
                                  style: GoogleFonts.outfit(
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.textColor,
                                  ),
                                ),
                                Text(
                                  'Expand your horizons',
                                  style: GoogleFonts.outfit(
                                    fontSize: 16,
                                    color: AppTheme.textColor.withValues(alpha: 0.7),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primaryColor.withValues(alpha: 0.2),
                            blurRadius: 15,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.calendar_month_rounded,
                        color: AppTheme.primaryColor,
                        size: 28,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                // Glassmorphism Search
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.4),
                      width: 1,
                    ),
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (val) => setState(() => _searchQuery = val),
                    style: GoogleFonts.outfit(color: AppTheme.textColor),
                    decoration: InputDecoration(
                      hintText: 'Search hackathons, workshops...',
                      hintStyle: GoogleFonts.outfit(
                        color: AppTheme.textColor.withValues(alpha: 0.5),
                      ),
                      prefixIcon: Icon(
                        Icons.search_rounded,
                        color: AppTheme.primaryColor.withValues(alpha: 0.7),
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 15,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                TabBar(
                  controller: _tabController,
                  isScrollable: true,
                  labelColor: Colors.white,
                  unselectedLabelColor: AppTheme.textColor.withValues(alpha: 0.6),
                  indicator: BoxDecoration(
                    color: AppTheme.primaryColor,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryColor.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  indicatorSize: TabBarIndicatorSize.tab,
                  dividerColor: Colors.transparent,
                  labelStyle: GoogleFonts.outfit(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                  unselectedLabelStyle: GoogleFonts.outfit(
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                  tabs: _tabs
                      .map(
                        (t) => Tab(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Text(t.replaceAll('_', ' ')),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ],
            ),
          ),

          // Content
          Expanded(
            child: eventsAsync.when(
              data: (events) {
                if (events.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.event_busy_rounded,
                          size: 60,
                          color: Colors.grey[300],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No events found',
                          style: GoogleFonts.outfit(color: Colors.grey[500]),
                        ),
                      ],
                    ),
                  );
                }
                return LayoutBuilder(
                  builder: (context, constraints) {
                    if (constraints.maxWidth > 900) {
                      return GridView.builder(
                        padding: const EdgeInsets.all(24),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 24,
                              mainAxisSpacing: 24,
                              mainAxisExtent: 220,
                            ),
                        itemCount: events.length,
                        itemBuilder: (context, index) {
                          return _buildEventCard(events[index]);
                        },
                      );
                    }
                    return ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: events.length,
                      itemBuilder: (context, index) {
                        final event = events[index];
                        return _buildEventCard(event);
                      },
                    );
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
    final startDate = DateTime.parse(event['start_date']);
    final isOnline = event['is_online'] == true;
    final type = (event['event_type'] ?? 'Event').toString().toUpperCase();
    final isRegistered = event['is_registered'] == true;

    // Month name map
    final months = [
      'JAN',
      'FEB',
      'MAR',
      'APR',
      'MAY',
      'JUN',
      'JUL',
      'AUG',
      'SEP',
      'OCT',
      'NOV',
      'DEC',
    ];

    // Determine color based on type
    Color typeColor = Colors.blue;
    IconData typeIcon = Icons.event;
    if (type == 'HACKATHON') {
      typeColor = Colors.orange;
      typeIcon = Icons.code_rounded;
    } else if (type == 'WORKSHOP') {
      typeColor = Colors.green;
      typeIcon = Icons.construction_rounded;
    } else if (type == 'WEBINAR') {
      typeColor = Colors.purple;
      typeIcon = Icons.video_camera_front_rounded;
    } else if (type == 'COMPETITION') {
      typeColor = Colors.red;
      typeIcon = Icons.emoji_events_rounded;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: AppTheme.clayDecoration.copyWith(
        borderRadius: BorderRadius.circular(24),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Calendar Block
              Container(
                width: 80,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [typeColor.withValues(alpha: 0.8), typeColor],
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      months[startDate.month - 1],
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        letterSpacing: 2,
                      ),
                    ),
                    Text(
                      '${startDate.day}',
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 32,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      width: 24,
                      height: 2,
                      color: Colors.white.withValues(alpha: 0.5),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${startDate.year}',
                      style: GoogleFonts.outfit(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontWeight: FontWeight.w500,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              // Main Content
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            isOnline
                                ? Icons.videocam_rounded
                                : Icons.location_on_rounded,
                            size: 14,
                            color: AppTheme.primaryColor,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              isOnline
                                  ? 'Online Event'
                                  : (event['venue'] ?? 'TBA'),
                              style: GoogleFonts.outfit(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey[600],
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Icon(
                            typeIcon,
                            size: 16,
                            color: typeColor.withValues(alpha: 0.3),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        event['title'] ?? 'Untitled Event',
                        style: GoogleFonts.outfit(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        event['description'] ?? 'No description provided.',
                        style: GoogleFonts.outfit(
                          fontSize: 13,
                          color: Colors.grey[600],
                          height: 1.4,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const Spacer(),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              height: 38,
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  gradient: isRegistered
                                      ? null
                                      : LinearGradient(
                                          colors: [
                                            AppTheme.primaryColor,
                                            AppTheme.primaryColor.withValues(alpha: 0.1),
                                          ],
                                        ),
                                  color: isRegistered
                                      ? Colors.green.withValues(alpha: 0.1)
                                      : null,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: ElevatedButton(
                                  onPressed: isRegistered
                                      ? null
                                      : () => _registerForEvent(event['id']),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.transparent,
                                    shadowColor: Colors.transparent,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    padding: EdgeInsets.zero,
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        isRegistered
                                            ? Icons.check_circle_rounded
                                            : Icons.flash_on_rounded,
                                        size: 16,
                                        color: isRegistered
                                            ? Colors.green
                                            : Colors.white,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        isRegistered
                                            ? 'Registered'
                                            : 'Register Now',
                                        style: GoogleFonts.outfit(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                          color: isRegistered
                                              ? Colors.green
                                              : Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _registerForEvent(String eventId) async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    try {
      final repo = ref.read(sharedEventsRepositoryProvider);

      // Confirm
      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Confirm Registration'),
          content: const Text('Do you want to register for this event?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Register'),
            ),
          ],
        ),
      );

      if (confirm == true) {
        await repo.registerForEvent(eventId, userId);

        // Refresh the list to update status
        // Force rebuild or invalidate provider
        setState(
          () {},
        ); // Simple setState to retrigger provider watch is not strict but with FutureProvider.family it depends on logic.
        // Better to invalidate provider
        // ref.invalidate(studentEventsProvider);
        // But invalidating all might be overkill? No, it's fine.
        ref.invalidate(studentEventsProvider);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Successfully registered!')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }
}

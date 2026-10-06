import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:timeago/timeago.dart' as timeago;

class ActivityHistoryScreen extends ConsumerStatefulWidget {
  const ActivityHistoryScreen({super.key});

  @override
  ConsumerState<ActivityHistoryScreen> createState() =>
      _ActivityHistoryScreenState();
}

class _ActivityHistoryScreenState extends ConsumerState<ActivityHistoryScreen> {
  final _supabase = Supabase.instance.client;
  bool _isLoading = true;
  List<Map<String, dynamic>> _activities = [];

  @override
  void initState() {
    super.initState();
    _loadActivities();
  }

  Future<void> _loadActivities() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;

      // Fetch Job Applications (Limit 20)
      final applicationsResponse = await _supabase
          .from('job_applications')
          .select('*, job:jobs(title, organization:organizations(name))')
          .eq('student_id', user.id)
          .order('applied_at', ascending: false)
          .limit(20);

      final List<Map<String, dynamic>> activities = [];

      for (var app in applicationsResponse) {
        activities.add({
          'activity_type': 'job_application',
          'created_at': app['applied_at'],
          'activity_data': {
            'job_title': app['job']['title'],
            'company': app['job']['organization']['name'],
            'status': app['status'],
          },
        });
      }

      // Fetch Course Enrollments (student_progress)
      try {
        final enrollmentsResponse = await _supabase
            .from('student_progress')
            .select(
              'updated_at, completion_percentage, course:courses!inner(title, id)',
            )
            .eq('student_id', user.id)
            .order('updated_at', ascending: false)
            .limit(20);

        for (var enroll in enrollmentsResponse) {
          activities.add({
            'activity_type': 'course_progress',
            'created_at': enroll['updated_at'],
            'activity_data': {
              'course_title': enroll['course']['title'],
              'course_id': enroll['course']['id'],
              'progress': enroll['completion_percentage'],
            },
          });
        }
      } catch (e) {
        debugPrint('Error loading enrollments: $e');
      }

      // Sort combined activities by date
      activities.sort((a, b) {
        final dateA = DateTime.parse(a['created_at']);
        final dateB = DateTime.parse(b['created_at']);
        return dateB.compareTo(dateA);
      });

      if (mounted) {
        setState(() {
          _activities = activities;
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
          'Activity History',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _activities.isEmpty
          ? Center(
              child: Text(
                'No activity history found',
                style: GoogleFonts.outfit(color: Colors.grey),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: _activities.length,
              separatorBuilder: (context, index) => const Divider(),
              itemBuilder: (context, index) {
                final activity = _activities[index];
                final type = activity['activity_type'] as String;
                final data = activity['activity_data'] as Map<String, dynamic>;
                final createdAt = DateTime.parse(activity['created_at']);

                return _buildActivityTile(type, data, createdAt);
              },
            ),
    );
  }

  Widget _buildActivityTile(
    String type,
    Map<String, dynamic> data,
    DateTime createdAt,
  ) {
    String title = 'Activity';
    String description = '';
    IconData icon = Icons.info_outline;
    Color color = Colors.grey;

    switch (type) {
      case 'job_application':
        title = 'Applied for Job';
        description = '${data['job_title']} at ${data['company']}';
        icon = Icons.work_outline_rounded;
        color = Colors.orange;
        break;
      case 'course_progress':
        title = 'Course Progress';
        description =
            'Continued ${data['course_title']} (${data['progress']}%)';
        icon = Icons.school_rounded;
        color = Colors.blueAccent;
        break;
      default:
        title = type.replaceAll('_', ' ').capitalize();
        description = data.toString();
    }

    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: color, size: 24),
      ),
      title: Text(
        title,
        style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
      ),
      subtitle: Text(
        description,
        style: GoogleFonts.outfit(color: Colors.grey[600]),
      ),
      trailing: Text(
        timeago.format(createdAt),
        style: GoogleFonts.outfit(color: Colors.grey[500], fontSize: 12),
      ),
    );
  }
}

extension ActivityStringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}

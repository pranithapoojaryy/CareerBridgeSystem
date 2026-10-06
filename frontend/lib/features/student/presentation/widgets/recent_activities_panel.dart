import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../../../core/theme/app_theme.dart';
import '../screens/activity_history_screen.dart';
import '../../../../features/interview/presentation/interview_landing_screen.dart'; // Corrected Import

class RecentActivitiesPanel extends ConsumerStatefulWidget {
  const RecentActivitiesPanel({super.key});

  @override
  ConsumerState<RecentActivitiesPanel> createState() =>
      _RecentActivitiesPanelState();
}

class _RecentActivitiesPanelState extends ConsumerState<RecentActivitiesPanel> {
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

      final List<Map<String, dynamic>> activities = [];

      // SIMULATED UPDATES (Requested by User)
      activities.add({
        'activity_type': 'interview_available',
        'created_at': DateTime.now().toUtc().toIso8601String(),
        'activity_data': {
          'title': 'Interview Available',
          'subtitle': 'New interview slots open',
        },
      });

      activities.add({
        'activity_type': 'learning_content',
        'created_at': DateTime.now()
            .toUtc()
            .subtract(const Duration(hours: 2))
            .toIso8601String(),
        'activity_data': {
          'title': 'New Learning Content',
          'subtitle': 'Practice material added',
        },
      });

      // Fetch Job Applications
      try {
        final applicationsResponse = await _supabase
            .from('job_applications')
            .select('*, job:jobs(title, organization:organizations(name))')
            .eq('student_id', user.id)
            .order('applied_at', ascending: false)
            .limit(3);

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
      } catch (e) {
        debugPrint('Error fetching jobs: $e');
      }

      // Fetch Course Enrollments
      try {
        final enrollmentsResponse = await _supabase
            .from('student_course_enrollments')
            .select(
              'created_at, progress_percent, course:learning_courses(title, id)',
            )
            .eq('student_id', user.id)
            .order('created_at', ascending: false)
            .limit(3);

        for (var enroll in enrollmentsResponse) {
          final course = enroll['course'];
          if (course != null) {
            activities.add({
              'activity_type': 'course_progress',
              'created_at':
                  enroll['created_at'] ?? DateTime.now().toIso8601String(),
              'activity_data': {
                'course_title': course['title'],
                'course_id': course['id'],
                'progress': enroll['progress_percent'] ?? 0,
              },
            });
          }
        }
      } catch (e) {
        debugPrint('Error loading enrollments: $e');
        // Continue even if enrollments fail
      }

      // Fetch Event Registrations
      try {
        final eventsResponse = await _supabase
            .from('event_registrations')
            .select('created_at, events(title, id)')
            .eq('student_id', user.id)
            .order('created_at', ascending: false)
            .limit(3);

        for (var reg in eventsResponse) {
          final event = reg['events'];
          if (event != null) {
            activities.add({
              'activity_type': 'event_registration',
              'created_at':
                  reg['created_at'] ?? DateTime.now().toIso8601String(),
              'activity_data': {
                'event_title': event['title'],
                'event_id': event['id'],
              },
            });
          }
        }
      } catch (e) {
        debugPrint('Error loading event registrations: $e');
      }

      // Sort combined activities by date
      activities.sort((a, b) {
        final dateA = DateTime.parse(a['created_at']);
        final dateB = DateTime.parse(b['created_at']);
        return dateB.compareTo(dateA); // Descending
      });

      if (mounted) {
        setState(() {
          _activities = activities.take(6).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading activities: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      // ... existing build method is fine ...
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white,
            const Color(0xFFE3F2FD), // Light Blue tint
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
              Text(
                'Recent Updates',
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              TextButton(
                onPressed: () {
                  // Navigate to Activity History (Reverted as requested)
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ActivityHistoryScreen(),
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
          else if (_activities.isEmpty)
            _buildEmptyState()
          else
            ..._activities.map((activity) {
              final type = activity['activity_type'] as String;
              final data = activity['activity_data'] as Map<String, dynamic>;
              final createdAt = DateTime.parse(activity['created_at']);

              return _buildActivityItemFromData(type, data, createdAt);
            }),

          const SizedBox(height: 16),
          Center(
            child: TextButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ActivityHistoryScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.history_rounded),
              label: const Text('View Activity History'),
              style: TextButton.styleFrom(foregroundColor: Colors.grey[600]),
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
            Icon(
              Icons.history_toggle_off_rounded,
              color: Colors.grey[300],
              size: 40,
            ),
            const SizedBox(height: 8),
            Text(
              'No recent activity',
              style: GoogleFonts.outfit(color: Colors.grey[500]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityItemFromData(
    String type,
    Map<String, dynamic> data,
    DateTime createdAt,
  ) {
    String title = 'Activity';
    String description = 'Updated account';
    IconData icon = Icons.info_outline;
    Color color = Colors.grey;
    VoidCallback? onTap;

    switch (type) {
      case 'interview_available':
        title = data['title'];
        description = data['subtitle'];
        icon = Icons.video_call_rounded;
        color = Colors.purple;
        onTap = () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const InterviewLandingScreen(),
            ),
          );
        };
        break;
      case 'learning_content':
        title = data['title'];
        description = data['subtitle'];
        icon = Icons.play_lesson_rounded;
        color = Colors.indigo;
        onTap = () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  const InterviewLandingScreen(), // Or LearningHubScreen if preferred, but keeping InterviewLanding for consistency
            ),
          );
        };
        break;
      case 'profile_update':
        title = 'Profile Updated';
        description = 'You updated your ${data['field'] ?? 'profile'}';
        icon = Icons.person_outline_rounded;
        color = Colors.blue;
        break;
      case 'assessment_complete':
        title = 'Assessment Completed';
        description = '${data['title']} - Score: ${data['score']}%';
        icon = Icons.assignment_turned_in_rounded;
        color = Colors.green;
        break;
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
      case 'certificate_upload':
        title = 'Certificate Uploaded';
        description = 'Uploaded ${data['certificate_name']}';
        icon = Icons.workspace_premium_rounded;
        color = Colors.purple;
        break;
      case 'event_registration':
        title = 'Event Registration';
        description = 'Registered for ${data['event_title']}';
        icon = Icons.event_available_rounded;
        color = Colors.teal;
        break;
      default:
        title = type.replaceAll('_', ' ');
        if (title.isNotEmpty) {
          title = '${title[0].toUpperCase()}${title.substring(1)}';
        }
        description = data.toString();
    }

    return _buildActivityItem(
      title,
      description,
      icon,
      color,
      timeago.format(createdAt),
      onTap: onTap,
    );
  }

  Widget _buildActivityItem(
    String title,
    String description,
    IconData icon,
    Color color,
    String time, {
    VoidCallback? onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    description,
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Text(
              time,
              style: GoogleFonts.outfit(fontSize: 11, color: Colors.grey[500]),
            ),
          ],
        ),
      ),
    );
  }
}

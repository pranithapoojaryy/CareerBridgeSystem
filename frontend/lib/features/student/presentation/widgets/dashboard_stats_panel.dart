import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/theme/app_theme.dart';
import '../skill_score_detail_screen.dart';

class DashboardStatsPanel extends ConsumerStatefulWidget {
  const DashboardStatsPanel({super.key});

  @override
  ConsumerState<DashboardStatsPanel> createState() =>
      _DashboardStatsPanelState();
}

class _DashboardStatsPanelState extends ConsumerState<DashboardStatsPanel> {
  Map<String, dynamic>? _stats;
  bool _isLoading = true;
  int _applicationsCount = 0; // Local state for direct count

  @override
  void initState() {
    super.initState();
    _fetchStats();
  }

  Future<void> _fetchStats() async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) return;

      // 1. Fetch Stats View (for other metrics)
      final statsFuture = Supabase.instance.client
          .from('student_stats')
          .select()
          .eq('student_id', userId)
          .maybeSingle();

      // 2. Fetch Direct Application Count (All Statuses)
      // "application sent == job application applied... and slected" -> All applications
      final countFuture = Supabase.instance.client
          .from('job_applications')
          .count()
          .eq('student_id', userId);

      final results = await Future.wait<dynamic>([statsFuture, countFuture]);

      final statsData = results[0] as Map<String, dynamic>?;
      final appCount = results[1] as int;

      if (mounted) {
        setState(() {
          _stats = statsData;
          _applicationsCount = appCount;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching stats: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const SizedBox(
        height: 100,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    final data = _stats ?? {};
    // Use the directly fetched count
    final applicationsCount = _applicationsCount;
    final skillScore = data['skill_score'] ?? 0;
    final assessmentsCount = data['assessments_completed'] ?? 0;
    final coursesCount = data['courses_enrolled'] ?? 0;

    return LayoutBuilder(
      builder: (context, constraints) {
        // Adapt grid based on width
        int crossAxisCount = 4;
        if (constraints.maxWidth < 600) crossAxisCount = 2;
        if (constraints.maxWidth < 400) crossAxisCount = 1;

        // On very small screens (phones), we might want a Wrap or Column,
        // but GridView is easy for standardizing heights.

        // However, standard Row/Wrap is often better for "Panel" behaviour
        // where we want them to fill width.

        if (constraints.maxWidth < 800) {
          // Mobile/Tablet: Use Grid
          return Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      label: 'Job',
                      subLabel: 'Applications',
                      value: '$applicationsCount',
                      icon: Icons.work_outline,
                      color: Colors.blue,
                      footer: 'Total',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatCard(
                      label: 'Skill Score',
                      subLabel: '',
                      value: '$skillScore%',
                      icon: Icons.trending_up,
                      color: Colors.green,
                      footer: 'Above Average',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                const SkillScoreDetailScreen(),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      label: 'Assessments',
                      subLabel: 'Completed',
                      value: '$assessmentsCount',
                      icon: Icons.assignment_outlined,
                      color: Colors.orange,
                      footer: 'Completed',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatCard(
                      label: 'Courses',
                      subLabel: 'Enrolled',
                      value: '$coursesCount',
                      icon: Icons.school_rounded,
                      color: AppTheme.primaryColor,
                      footer: 'Active',
                    ),
                  ),
                ],
              ),
            ],
          );
        }

        // Desktop: One Row
        return Row(
          children: [
            Expanded(
              child: _StatCard(
                label: 'Job',
                subLabel: 'Applications',
                value: '$applicationsCount',
                icon: Icons.work_outline,
                color: Colors.blue,
                footer: 'Total',
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _StatCard(
                label: 'Skill Score',
                subLabel: '',
                value: '$skillScore%',
                icon: Icons.trending_up,
                color: Colors.green,
                footer: 'Above Average',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SkillScoreDetailScreen(),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _StatCard(
                label: 'Assessments',
                subLabel: 'Completed',
                value: '$assessmentsCount',
                icon: Icons.assignment_outlined,
                color: Colors.orange,
                footer: 'Completed',
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _StatCard(
                label: 'Courses',
                subLabel: 'Enrolled',
                value: '$coursesCount',
                icon: Icons.school_rounded,
                color: AppTheme.primaryColor,
                footer: 'Active',
              ),
            ),
          ],
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String subLabel;
  final String value;
  final IconData icon;
  final Color color;
  final String footer;
  final VoidCallback? onTap;

  const _StatCard({
    required this.label,
    required this.subLabel,
    required this.value,
    required this.icon,
    required this.color,
    required this.footer,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white,
              color.withValues(alpha: 0.1), // Subtle tint of the card's theme color
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.1), // Colored shadow
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(color: color.withValues(alpha: 0.1)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: color, size: 22),
                ),
                const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
              ],
            ),
            const SizedBox(height: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: GoogleFonts.outfit(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$label $subLabel',
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  footer,
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    color: Colors.grey[400],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

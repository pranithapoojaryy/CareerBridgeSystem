import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../data/recruiter_repository.dart';
import '../jobs/job_posting_screen.dart';
import '../widgets/recruiter_feed_widget.dart';
import '../widgets/active_jobs_sidebar_widget.dart';
import '../widgets/active_events_sidebar_widget.dart';
import '../widgets/running_courses_sidebar_widget.dart';
import '../../../shared/presentation/widgets/messaging_preview_widget.dart';
import '../../../shared/presentation/widgets/connection_requests_widget.dart';
import '../../../college/presentation/events/widgets/create_event_dialog.dart';
import '../../../college/data/college_providers.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/theme/app_theme.dart';
import 'recruiter_event_management_screen.dart';

class RecruiterHomeScreen extends ConsumerStatefulWidget {
  final Function(int)? onNavigateToTab;

  const RecruiterHomeScreen({super.key, this.onNavigateToTab});

  @override
  ConsumerState<RecruiterHomeScreen> createState() =>
      _RecruiterHomeScreenState();
}

class _RecruiterHomeScreenState extends ConsumerState<RecruiterHomeScreen> {
  bool _showAnalytics = false;
  int? _hoveredActionIndex;

  @override
  Widget build(BuildContext context) {
    final statsAsync = ref.watch(recruiterDashboardStatsProvider);
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 700;
    final isTablet = screenWidth >= 700 && screenWidth < 1000;
    final showRightSidebar = screenWidth > 1300;

    return statsAsync.when(
      data: (stats) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Fixed Header (Desktop only)
          if (!isMobile && !isTablet) ...[
            Padding(
              padding: const EdgeInsets.only(
                left: 32,
                right: 32,
                top: 32,
                bottom: 16,
              ),
              child: _buildHeader(stats),
            ),
            const Divider(height: 1),
          ],

          // Combined Scrollable Body
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Central Feed
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.all(isMobile ? 12 : 32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (isMobile || isTablet) ...[
                          _buildMobileCompanyHeader(stats),
                          const SizedBox(height: 16),
                          _buildMobileCollapsibleAnalytics(context, stats),
                          const SizedBox(height: 24),
                        ] else ...[
                          _buildStatsGrid(context, stats),
                          const SizedBox(height: 32),
                        ],
                        _buildQuickActions(context, ref, isMobile),
                        const SizedBox(height: 32),
                        Row(
                          children: [
                            Text(
                              'Company Feed',
                              style: GoogleFonts.outfit(
                                fontSize: isMobile ? 18 : 20,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF1A1D1E),
                              ),
                            ),
                            const Spacer(),
                          ],
                        ),
                        const SizedBox(height: 16),
                        const RecruiterFeedWidget(),
                      ],
                    ),
                  ),
                ),

                // Right Sidebar (Desktop only)
                if (showRightSidebar && !isMobile && !isTablet) ...[
                  const VerticalDivider(width: 1),
                  SizedBox(
                    width: 380,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        children: [
                          const MessagingPreviewWidget(),
                          const SizedBox(height: 24),
                          const ConnectionRequestsWidget(),
                          const SizedBox(height: 24),
                          const RunningCoursesSidebarWidget(),
                          const SizedBox(height: 24),
                          ActiveJobsSidebarWidget(),
                          const SizedBox(height: 24),
                          ActiveEventsSidebarWidget(),
                          const SizedBox(height: 80),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(
        child: Text(
          'Error loading dashboard: $err',
          style: const TextStyle(color: Colors.red),
        ),
      ),
    );
  }

  Widget _buildMobileCollapsibleAnalytics(
    BuildContext context,
    Map<String, dynamic> stats,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        children: [
          ListTile(
            onTap: () => setState(() => _showAnalytics = !_showAnalytics),
            leading: Icon(
              Icons.analytics_outlined,
              color: Theme.of(context).primaryColor,
            ),
            title: Text(
              'Dashboard Insights',
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
            trailing: Icon(
              _showAnalytics ? Icons.expand_less : Icons.expand_more,
            ),
          ),
          if (_showAnalytics)
            Padding(
              padding: const EdgeInsets.all(12),
              child: _buildStatsGrid(context, stats),
            ),
        ],
      ),
    );
  }

  Widget _buildHeader(Map<String, dynamic> stats) {
    return Row(
      children: [
        IconButton(
          onPressed: () => Navigator.maybePop(context),
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          style: IconButton.styleFrom(
            backgroundColor: Colors.white,
            padding: const EdgeInsets.all(12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: Colors.grey.shade100),
            ),
          ),
        ),
        const SizedBox(width: 24),
        if (stats['companyLogo'] != null &&
            stats['companyLogo'].toString().isNotEmpty)
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              image: DecorationImage(
                image: NetworkImage(stats['companyLogo']),
                fit: BoxFit.cover,
              ),
              border: Border.all(color: Colors.grey.shade200),
            ),
          )
        else
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: const Color(0xFF212121),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: const Icon(Icons.business, color: Colors.white, size: 30),
          ),
        const SizedBox(width: 20),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Welcome back,',
              style: GoogleFonts.outfit(fontSize: 16, color: Colors.grey[600]),
            ),
            Text(
              stats['companyName'] ?? 'Recruiter',
              style: GoogleFonts.outfit(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1A1D1E),
              ),
            ),
          ],
        ),
        const Spacer(),
        Text(
          'CareerBridge',
          style: GoogleFonts.outfit(
            fontSize: 24,
            fontWeight: FontWeight.w900,
            color: AppTheme.primaryColor,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(width: 24),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF0E3),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              const Icon(Icons.work, size: 16, color: Color(0xFFE65100)),
              const SizedBox(width: 8),
              Text(
                'Recruiter',
                style: GoogleFonts.outfit(
                  color: const Color(0xFFE65100),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMobileCompanyHeader(Map<String, dynamic> stats) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          if (stats['companyLogo'] != null &&
              stats['companyLogo'].toString().isNotEmpty)
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                image: DecorationImage(
                  image: NetworkImage(stats['companyLogo']),
                  fit: BoxFit.cover,
                ),
                border: Border.all(color: Colors.grey.shade200),
              ),
            )
          else
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFF212121),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: const Icon(Icons.business, color: Colors.white, size: 24),
            ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome back,',
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                Text(
                  stats['companyName'] ?? 'Recruiter',
                  style: GoogleFonts.outfit(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1A1D1E),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF0E3),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'Recruiter',
              style: GoogleFonts.outfit(
                fontSize: 11,
                color: const Color(0xFFE65100),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid(BuildContext context, Map<String, dynamic> stats) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        // Adjust grid columns based on width
        int crossAxisCount = width > 1200 ? 4 : (width > 800 ? 2 : 1);
        double childAspectRatio = width > 1200
            ? 1.4
            : (width > 800 ? 1.5 : 1.8);

        return GridView.count(
          crossAxisCount: crossAxisCount,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 24,
          mainAxisSpacing: 24,
          childAspectRatio:
              childAspectRatio * 0.95, // Slightly adjust for padding
          children: [
            _buildStatCard(
              title: 'Total Jobs',
              value: stats['totalJobs'].toString(),
              icon: Icons.work_outline,
              color: const Color(0xFF2196F3),
              chartData: [4, 3, 5, 6, 8, 7, stats['totalJobs'].toDouble()],
            ),
            _buildStatCard(
              title: 'Active Jobs',
              value: stats['activeJobs'].toString(),
              icon: Icons.check_circle_outline,
              color: const Color(0xFF4CAF50),
              chartData: [2, 1, 3, 3, 4, 3, stats['activeJobs'].toDouble()],
            ),
            _buildStatCard(
              title: 'Applications',
              value: stats['totalApplications'].toString(),
              icon: Icons.assignment_outlined,
              color: const Color(0xFFFF9800),
              chartData: [
                10,
                15,
                12,
                20,
                18,
                25,
                stats['totalApplications'].toDouble(),
              ],
            ),
            _buildStatCard(
              title: 'Partner Colleges',
              value: (stats['partnerColleges'] ?? 0).toString(),
              icon: Icons.school_outlined,
              color: const Color(0xFF9C27B0),
              chartData: [
                0,
                1,
                1,
                2,
                2,
                3,
                (stats['partnerColleges'] ?? 0).toDouble(),
              ],
            ),
          ],
        ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.1, end: 0);
      },
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required List<double> chartData,
  }) {
    return Container(
      padding: const EdgeInsets.all(16), // Reduced from 24
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.05),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: color.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8), // Reduced from 12
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 20), // Reduced from 24
              ),
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    value,
                    style: GoogleFonts.outfit(
                      fontSize: 28, // Reduced from 32
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1A1D1E),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              title,
              style: GoogleFonts.outfit(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
              ),
            ),
          ),
          const Spacer(),
          SizedBox(
            height: 35, // Reduced from 40
            child: LineChart(
              LineChartData(
                gridData: const FlGridData(show: false),
                titlesData: const FlTitlesData(show: false),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: chartData
                        .asMap()
                        .entries
                        .map((e) => FlSpot(e.key.toDouble(), e.value))
                        .toList(),
                    isCurved: true,
                    color: color,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: color.withValues(alpha: 0.1),
                    ),
                  ),
                ],
                minY: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(
    BuildContext context,
    WidgetRef ref,
    bool isMobile,
  ) {
    return Container(
      height: 90, // Increased for better vertical clearance on mobile
      child: Row(
        children: [
          Expanded(
            child: ListView(
              scrollDirection: Axis.horizontal,
              clipBehavior: Clip.none,
              children: [
                _buildActionCard(
                  context,
                  0,
                  'Post Job',
                  Icons.add_circle_outline,
                  const Color(0xFFFFF3E0),
                  const Color(0xFFFF9800),
                  isMobile,
                  () {
                    showDialog(
                      context: context,
                      builder: (context) => Dialog(
                        backgroundColor: Colors.transparent,
                        insetPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 24,
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            width: double.infinity,
                            height: MediaQuery.of(context).size.height * 0.85,
                            color: Colors.white,
                            child: const JobPostingScreen(),
                          ),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(width: 12),
                _buildActionCard(
                  context,
                  1,
                  'Candidates',
                  Icons.search,
                  const Color(0xFFE3F2FD),
                  const Color(0xFF2196F3),
                  isMobile,
                  () {
                    widget.onNavigateToTab?.call(3);
                  },
                ),
                const SizedBox(width: 12),
                _buildActionCard(
                  context,
                  2,
                  'Event',
                  Icons.event_available,
                  const Color(0xFFE8F5E9),
                  const Color(0xFF4CAF50),
                  isMobile,
                  () {
                    showDialog(
                      context: context,
                      builder: (context) => CreateEventDialog(
                        onEventCreated: (eventData) async {
                          try {
                            final stats = ref
                                .read(recruiterDashboardStatsProvider)
                                .value;
                            final companyId = stats?['companyId'];
                            if (companyId == null) {
                              throw Exception('Missing organization ID.');
                            }
                            final fullEventData = {
                              ...eventData,
                              'college_id': companyId,
                              'created_by':
                                  Supabase.instance.client.auth.currentUser?.id,
                            };
                            await ref
                                .read(eventsNotifierProvider.notifier)
                                .createEvent(fullEventData);
                            ref.invalidate(activeRecruiterEventsProvider);
                            ref.invalidate(recruiterDashboardStatsProvider);
                            if (context.mounted) Navigator.pop(context);
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Error: $e')),
                              );
                            }
                          }
                        },
                      ),
                    );
                  },
                ),
                const SizedBox(width: 12),
                _buildActionCard(
                  context,
                  3,
                  'Manage',
                  Icons.settings_suggest_outlined,
                  const Color(0xFFF3E5F5),
                  const Color(0xFF9C27B0),
                  isMobile,
                  () {
                    showDialog(
                      context: context,
                      builder: (dialogContext) => Dialog(
                        insetPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 24,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 900),
                          child: SizedBox(
                            width: double.infinity,
                            height:
                                MediaQuery.of(dialogContext).size.height * 0.85,
                            child: const RecruiterEventManagementScreen(),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard(
    BuildContext context,
    int index,
    String title,
    IconData icon,
    Color bgColor,
    Color iconColor,
    bool isMobile,
    VoidCallback onTap,
  ) {
    final isHovered = _hoveredActionIndex == index;

    return MouseRegion(
      onEnter: (_) => setState(() => _hoveredActionIndex = index),
      onExit: (_) => setState(() => _hoveredActionIndex = null),
      child: GestureDetector(
        onTap: () {
          setState(() => _hoveredActionIndex = index);
          Future.delayed(const Duration(seconds: 2), () {
            if (mounted) setState(() => _hoveredActionIndex = null);
          });
          onTap();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(32),
            boxShadow: [
              BoxShadow(
                color: iconColor.withValues(alpha: isHovered ? 0.2 : 0.05),
                blurRadius: isHovered ? 12 : 8,
                offset: const Offset(0, 4),
              ),
            ],
            border: Border.all(
              color: isHovered
                  ? iconColor.withValues(alpha: 0.3)
                  : Colors.grey.shade100,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: bgColor.withValues(alpha: 0.8),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: iconColor, size: 22),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: const Color(0xFF1A1D1E),
                ),
                maxLines: 1,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

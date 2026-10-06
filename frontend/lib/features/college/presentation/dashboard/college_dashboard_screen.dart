import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';
import '../../../../../core/theme/app_theme.dart';
import 'widgets/active_drives_panel.dart';
import 'widgets/college_sidebar.dart';

import 'widgets/dashboard_stats_card.dart';
// import 'widgets/student_snapshot_panel.dart'; // Can remove if unused, but kept for safe-delete/history
import 'widgets/college_running_courses_panel.dart';
import 'widgets/program_distribution_chart.dart';
import '../students/student_management_screen.dart';
import '../students/student_management_debug.dart';
import '../students/student_test_simple.dart';
import '../settings/college_settings_screen.dart';
import '../events/events_manager_screen.dart';
import '../assessments/skill_assessments_screen.dart';
import '../assessments/question_bank_screen.dart'; // Verified Import
import '../feed/college_feed_screen.dart'; // Verified Import
import 'widgets/feed_preview_widget.dart'; // New Import
import '../../../networking/presentation/screens/network_screen.dart';
import '../../data/college_providers.dart';
import '../../../interview/presentation/college/college_interview_dashboard.dart';
import '../resume_hub/resume_hub_screen.dart'; // Resume Hub Import
import 'manage_learning_courses_screen.dart';
import '../verification/certificate_verification_screen.dart';
import '../jobs/placement_management_hub.dart';
import '../../../shared/presentation/widgets/ai_assistant_widget.dart';

class CollegeDashboardScreen extends ConsumerStatefulWidget {
  final int? initialIndex;

  const CollegeDashboardScreen({super.key, this.initialIndex});

  @override
  ConsumerState<CollegeDashboardScreen> createState() =>
      _CollegeDashboardScreenState();
}

class _CollegeDashboardScreenState
    extends ConsumerState<CollegeDashboardScreen> {
  @override
  void initState() {
    super.initState();
    if (widget.initialIndex != null) {
      Future.microtask(() {
        ref
            .read(collegeDashboardIndexProvider.notifier)
            .setIndex(widget.initialIndex!);
      });
    }
  }

  bool _isSidebarCollapsed = false;
  bool _isInit = true; // To track if we've checked screen size

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_isInit) {
      final width = MediaQuery.of(context).size.width;
      if (width < 1100) {
        _isSidebarCollapsed = true;
      }
      _isInit = false;
    }
  }

  // Placeholder Screens for navigation
  // Note: These MUST match the CollegeSidebar indices exactly (0-29)
  final List<Widget> _screens = [
    // 0. Dashboard Home
    const _DashboardHomeContent(),
    // 1. Team & Roles (REMOVED)
    const SizedBox(),
    // 2. Students
    const StudentManagementScreen(),
    // 3. Placement Management Hub (was Placement Drives)
    const PlacementManagementHub(),
    // 4. Resume Hub
    const ResumeHubScreen(),
    // 5. Skill Assessments
    const SkillAssessmentsScreen(),
    // 6. Interview Management
    const CollegeInterviewDashboard(),
    // 7. Learning Paths
    const Center(child: Text("Learning Paths Module")),
    // 8. Skill Validation
    const Center(child: Text("Skill Validation Module")),
    // 9. Certifications
    const CertificateVerificationScreen(),
    // 10. Events Manager
    // 10. Events Manager
    const EventsManagerScreen(),
    // 11. Company Network (Was 14)
    const Center(child: Text("Company Network Module")),
    // 12. Alumni Connect (Was 15)
    const Center(child: Text("Alumni Connect Module")),
    // 13. Mentorship (Was 16)
    const Center(child: Text("Mentorship Module")),
    // 14. Campus Feed (Was 17)
    const CollegeFeedScreen(),
    // 15. My Network (Was 18)
    const NetworkScreen(),
    // 16. Notifications (Was 19)
    const Center(child: Text("Notifications Module")),
    // 17. Analytics Dashboard (REMOVED)
    const SizedBox(),
    // 18. Placement Reports (Was 21)
    const Center(child: Text("Placement Reports Module")),
    // 19. Skill Analytics (Was 22)
    const Center(child: Text("Skill Analytics Module")),
    // 20. NAAC Reports (Was 23)
    const Center(child: Text("NAAC Reports Module")),
    // 21. Question Bank (Was 24)
    const QuestionBankScreen(),
    // 22. Learning Content (Was 25)
    const ManageLearningCoursesScreen(),
    // 23. Templates (Was 26)
    const Center(child: Text("Templates Module")),
    // 24. Documents (Was 27)
    const Center(child: Text("Documents Module")),
    // 25. Settings (Was 28)
    const CollegeSettingsScreen(),

    // -- HIDDEN SCREENS (Accessed via App Bar actions) --
    // 26. Logout (Placeholder, usually specific handling) - No screen needed if handled by unique ID
    const SizedBox(),
    // 27. Students Debug
    const StudentManagementDebug(),
    // 28. Students Simple Test
    const StudentTestSimple(),
  ];

  @override
  Widget build(BuildContext context) {
    final selectedIndex = ref.watch(collegeDashboardIndexProvider);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Row(
        children: [
          // Sidebar
          CollegeSidebar(
            selectedIndex: selectedIndex > 25 ? 2 : selectedIndex,
            isCollapsed: _isSidebarCollapsed,
            onToggleCollapse: () {
              setState(() => _isSidebarCollapsed = !_isSidebarCollapsed);
            },
            onItemSelected: (index) {
              if (index == 26) {
                // Logout
                _handleLogout();
              } else if (index == 99) {
                ref.read(aiAssistantProvider.notifier).toggleOpen();
              } else {
                ref
                    .read(collegeDashboardIndexProvider.notifier)
                    .setIndex(index);
              }
            },
          ),

          // Main Content
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: _screens.asMap().containsKey(selectedIndex)
                  ? _screens[selectedIndex]
                  : Center(
                      child: Text("Screen index $selectedIndex not found"),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleLogout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Logout'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );

    if (shouldLogout == true) {
      try {
        await Supabase.instance.client.auth.signOut();
        if (mounted) {
          Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error signing out: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
}

class _DashboardHomeContent extends ConsumerStatefulWidget {
  const _DashboardHomeContent();

  @override
  ConsumerState<_DashboardHomeContent> createState() =>
      _DashboardHomeContentState();
}

class _DashboardHomeContentState extends ConsumerState<_DashboardHomeContent> {
  Map<String, dynamic>? _orgData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchOrgData();
  }

  Future<void> _fetchOrgData() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        final repo = ref.read(collegeRepositoryProvider);
        final org = await repo.getOrganizationByUserId(user.id);
        if (mounted) {
          setState(() {
            _orgData = org;
            _isLoading = false;
          });
        }
      } else {
        if (mounted) {
          Navigator.of(
            context,
          ).pushNamedAndRemoveUntil('/login', (route) => false);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading college data: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _handleLogout() async {
    // Reuse specific logout logic if needed, or trigger parent
    await Supabase.instance.client.auth.signOut();
    if (mounted) context.go('/');
  }

  Color _getPrimaryColor() {
    if (_orgData != null && _orgData!['primary_color'] != null) {
      try {
        String hex = _orgData!['primary_color'].replaceAll('#', '');
        if (hex.length == 6) {
          return Color(int.parse('0xFF$hex'));
        }
      } catch (_) {}
    }
    return AppTheme.primaryColor;
  }

  @override
  Widget build(BuildContext context) {
    final collegeName = _orgData?['name'] ?? 'Loading...';
    final primaryColor = _getPrimaryColor();
    final isSetupComplete =
        _orgData != null && _orgData!['description'] != null;

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 600;
        final padding = isMobile ? 16.0 : 32.0;

        return SingleChildScrollView(
          padding: EdgeInsets.all(padding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // A. Top Bar
              // A. Top Bar - Responsive Layout
              LayoutBuilder(
                builder: (context, constraints) {
                  final isSmallScreen = constraints.maxWidth < 800;

                  if (isSmallScreen) {
                    // Mobile/Tablet: Stacked Layout
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 1. Welcome Text Section
                        Text(
                          'CareerBridge',
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            color: AppTheme.primaryColor,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Welcome, $collegeName',
                          style: GoogleFonts.outfit(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 16),
                        // College Logo
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            GestureDetector(
                              onTap: _handleLogout,
                              child: CircleAvatar(
                                radius: 20,
                                backgroundImage:
                                    _orgData != null &&
                                        _orgData!['logo_url'] != null
                                    ? NetworkImage(_orgData!['logo_url'])
                                    : null,
                                backgroundColor: primaryColor,
                                child: _orgData?['logo_url'] == null
                                    ? Text(
                                        collegeName[0].toUpperCase(),
                                        style: GoogleFonts.outfit(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      )
                                    : null,
                              ),
                            ),
                          ],
                        ),
                      ],
                    );
                  } else {
                    // Desktop: Row Layout (Existing)
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'CareerBridge'.toUpperCase(),
                                style: GoogleFonts.outfit(
                                  fontSize: 12,
                                  color: AppTheme.primaryColor,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 1.2,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Wrap(
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  Text(
                                    'Welcome, $collegeName',
                                    style: GoogleFonts.outfit(
                                      fontSize: 28,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(width: 12),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: primaryColor.withValues(
                                        alpha: 0.1,
                                      ),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      'College Portal',
                                      style: GoogleFonts.outfit(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: primaryColor,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        // College Logo
                        GestureDetector(
                          onTap: _handleLogout,
                          child: CircleAvatar(
                            radius: 20,
                            backgroundImage:
                                _orgData != null &&
                                    _orgData!['logo_url'] != null
                                ? NetworkImage(_orgData!['logo_url'])
                                : null,
                            backgroundColor: primaryColor,
                            child: _orgData?['logo_url'] == null
                                ? Text(
                                    collegeName[0].toUpperCase(),
                                    style: GoogleFonts.outfit(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  )
                                : null,
                          ),
                        ),
                      ],
                    );
                  }
                },
              ),

              const SizedBox(height: 32),

              // Setup Banner (Conditional)
              if (!isSetupComplete) ...[
                GestureDetector(
                  onTap: () => context.push('/college-setup'),
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    margin: const EdgeInsets.only(bottom: 32),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          primaryColor,
                          primaryColor.withValues(alpha: 0.8),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: primaryColor.withValues(alpha: 0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.rocket_launch_rounded,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Complete your Campus Profile',
                                style: GoogleFonts.outfit(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'Set up departments, programs, and branding to unlock full features.',
                                style: GoogleFonts.outfit(
                                  color: Colors.white.withValues(alpha: 0.9),
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'Resume Setup',
                            style: GoogleFonts.outfit(
                              color: primaryColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],

              // B. Highlight Cards & Analytics
              Consumer(
                builder: (context, ref, child) {
                  final dashboardStatsAsync = ref.watch(
                    dashboardStatsV2Provider,
                  );

                  return dashboardStatsAsync.when(
                    data: (stats) {
                      final totalStudents = stats['total_students'] ?? 0;
                      final activeEvents = stats['active_events'] ?? 0;
                      final placementRate = stats['placement_rate'] ?? 0;
                      final activeStudents = stats['active_students'] ?? 0;
                      final programData =
                          stats['program_split'] ?? []; // For pie chart

                      // -- STATS GRID --
                      final statsGrid = LayoutBuilder(
                        builder: (context, constraints) {
                          return Wrap(
                            spacing: 16,
                            runSpacing: 16,
                            children: [
                              _buildStatCardWrapper(
                                context,
                                DashboardStatsCard(
                                  title: 'Total Students',
                                  value: '$totalStudents',
                                  subtitle: 'Enrolled',
                                  icon: Icons.school_rounded,
                                  color: const Color(0xFF6C63FF), // Purple
                                  onTap: () {},
                                ),
                                constraints.maxWidth,
                              ),
                              _buildStatCardWrapper(
                                context,
                                DashboardStatsCard(
                                  title: 'Active Events',
                                  value: '$activeEvents',
                                  subtitle: 'Ongoing',
                                  icon: Icons.event_available_rounded,
                                  color: const Color(0xFFFF6584), // Pink/Red
                                  onTap: () {
                                    ref
                                        .read(
                                          collegeDashboardIndexProvider
                                              .notifier,
                                        )
                                        .setIndex(10);
                                  },
                                ),
                                constraints.maxWidth,
                              ),
                              _buildStatCardWrapper(
                                context,
                                DashboardStatsCard(
                                  title: 'Placement Rate',
                                  value: '$placementRate%',
                                  subtitle: 'Success',
                                  icon: Icons.trending_up,
                                  color: const Color(0xFF00B894), // Teal/Green
                                  onTap: () {},
                                ),
                                constraints.maxWidth,
                              ),
                              _buildStatCardWrapper(
                                context,
                                DashboardStatsCard(
                                  title: 'Active Seekers',
                                  value: '$activeStudents',
                                  subtitle: 'Job Hunting',
                                  icon: Icons.person_search_rounded,
                                  color: const Color(0xFF0984E3), // Blue
                                  onTap: () {},
                                ),
                                constraints.maxWidth,
                              ),
                            ],
                          );
                        },
                      );

                      // -- MAIN CONTENT --
                      return Column(
                        children: [
                          statsGrid,
                          const SizedBox(height: 24),
                          LayoutBuilder(
                            builder: (context, constraints) {
                              if (constraints.maxWidth < 1100) {
                                // Mobile/Tablet Layout
                                return Column(
                                  children: [
                                    // 1. Feed (Expanded to take more space)
                                    FeedPreviewWidget(
                                      orgData: _orgData,
                                      onViewAll: () {
                                        ref
                                            .read(
                                              collegeDashboardIndexProvider
                                                  .notifier,
                                            )
                                            .setIndex(18);
                                      },
                                    ),
                                    const SizedBox(height: 24),
                                    // 2. Program Distribution Chart
                                    ProgramDistributionChart(
                                      programData: programData,
                                    ),
                                    const SizedBox(height: 24),
                                    // 3. Running Courses (Replaces Snapshot)
                                    const CollegeRunningCoursesPanel(),
                                    const SizedBox(height: 24),
                                    // 4. Drives
                                    const ActiveDrivesPanel(),
                                    const SizedBox(height: 24),
                                  ],
                                );
                              } else {
                                // Desktop Layout
                                // Left Column: Feed (Full Width), Drives
                                // Right Column: Running Courses, Company Requests
                                return Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // LEFT COLUMN (Flex 3) - Campus Feed + Drives
                                    Expanded(
                                      flex: 3,
                                      child: Column(
                                        children: [
                                          // Full-width Campus Feed
                                          FeedPreviewWidget(
                                            orgData: _orgData,
                                            onViewAll: () {
                                              ref
                                                  .read(
                                                    collegeDashboardIndexProvider
                                                        .notifier,
                                                  )
                                                  .setIndex(18);
                                            },
                                          ),
                                          const SizedBox(height: 24),
                                          const ActiveDrivesPanel(),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 24),
                                    // RIGHT COLUMN (Flex 2)
                                    Expanded(
                                      flex: 2, // Slightly narrower
                                      child: Column(
                                        children: [
                                          // Program Distribution Chart
                                          ProgramDistributionChart(
                                            programData: programData,
                                          ),
                                          const SizedBox(height: 24),
                                          const CollegeRunningCoursesPanel(),
                                          const SizedBox(height: 24),
                                        ],
                                      ),
                                    ),
                                  ],
                                );
                              }
                            },
                          ),
                        ],
                      );
                    },
                    loading: () => const Center(
                      child: Padding(
                        padding: EdgeInsets.all(50),
                        child: CircularProgressIndicator(),
                      ),
                    ),
                    error: (err, stack) => Center(
                      child: Text('Failed to load dashboard data: $err'),
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatCardWrapper(
    BuildContext context,
    Widget child,
    double totalWidth,
  ) {
    double width;
    if (totalWidth > 1200) {
      width = (totalWidth - (3 * 20)) / 4;
    } else if (totalWidth > 700) {
      width = (totalWidth - 20) / 2;
    } else {
      width = totalWidth;
    }
    // Remove strict 250px floor to prevent overflow on very small devices.
    // The stats card is now flexible enough to handle smaller widths.
    return SizedBox(width: width, child: child);
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/utils/logger_service.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme/app_theme.dart';
import 'student_profile_screen_simple.dart';
import 'resume_builder_launcher.dart';
import 'certifications_screen.dart';
import 'widgets/student_sidebar.dart';
import 'projects/student_projects_screen.dart';

import '../../notifications/presentation/widgets/notification_popover.dart';
import '../../notifications/presentation/widgets/notification_overlay.dart';
import '../../notifications/presentation/providers/notification_provider.dart';
import '../../notifications/presentation/providers/popover_provider.dart';
import '../../shared/presentation/widgets/ai_assistant_widget.dart';

import 'widgets/recent_activities_panel.dart';
import 'widgets/upcoming_events_panel.dart';
import 'widgets/social_feed_panel.dart';
import '../../shared/presentation/widgets/messaging_preview_widget.dart';
import '../../shared/presentation/widgets/connection_requests_widget.dart';
import 'widgets/dashboard_stats_panel.dart';
import 'widgets/job_carousel_widget.dart';
import '../../jobs/presentation/job_listing_screen.dart';
import 'widgets/course_carousel_widget.dart';
import '../../aptitude/presentation/screens/aptitude_home_screen.dart';
import '../../networking/presentation/screens/network_screen.dart';
import '../../interview/presentation/interview_landing_screen.dart';
import '../../interview/presentation/practice_arena_screen.dart';
import 'learning_catalog_screen.dart';
import 'events/student_events_screen.dart';
import 'analytics/student_analytics_screen.dart';

class StudentDashboardScreen extends ConsumerStatefulWidget {
  final int? initialIndex;

  const StudentDashboardScreen({super.key, this.initialIndex});

  @override
  ConsumerState<StudentDashboardScreen> createState() =>
      _StudentDashboardScreenState();
}

class _StudentDashboardScreenState
    extends ConsumerState<StudentDashboardScreen> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    if (widget.initialIndex != null) {
      _selectedIndex = widget.initialIndex!;
    }
  }

  bool _isSidebarCollapsed = true;

  // Placeholder Screens for navigation
  List<Widget> get _screens => [
    // 0. Dashboard Home
    const _StudentDashboardHomeContent(),
    // 1. Notifications (Handled via popover)
    const SizedBox.shrink(),
    // 2. My Profile
    Builder(
      builder: (context) {
        return const StudentProfileScreenSimple();
      },
    ),
    // 2. My Projects
    const StudentProjectsScreen(),
    // 3. Resume Builder
    const ResumeBuilderLauncher(),
    // 4. Job Applications / Jobs
    const JobListingScreen(),
    // 5. Interview Prep
    const InterviewLandingScreen(),

    // 6. Learning Paths
    const LearningCatalogScreen(),
    // 7. Certifications
    const CertificationsScreen(),
    // 8. Practice Arena Hub
    const PracticeArenaScreen(),
    // 9. Mock Tests / Aptitude
    const AptitudeHomeScreen(),
    // 10. Events (Consolidated)
    const StudentEventsScreen(),
    // 11. My Network
    const NetworkScreen(),
    // 12. My Analytics
    const StudentAnalyticsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    _setupNotificationListener();
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 900;

        return Scaffold(
          backgroundColor: Colors.grey[50],
          // Use Drawer on mobile
          drawer: isMobile
              ? Drawer(
                  width: 300,
                  child: StudentSidebar(
                    selectedIndex: _selectedIndex,
                    isCollapsed: false, // Always expanded in drawer
                    isMobile: true, // New flag to hide collapse button
                    onToggleCollapse: () {}, // Noop in drawer
                    onItemSelected: (index) {
                      if (index == 14) {
                        _handleLogout();
                      } else if (index == 99) {
                        ref.read(aiAssistantProvider.notifier).toggleOpen();
                        Navigator.pop(context); // Close drawer
                      } else if (index == 1) {
                        // Toggle notification popover instead of navigating
                        ref.read(notificationPopoverProvider.notifier).toggle();
                        Navigator.pop(context); // Close drawer
                      } else {
                        setState(() => _selectedIndex = index);
                        Navigator.pop(context); // Close drawer
                      }
                    },
                  ),
                )
              : null,
          floatingActionButton: isMobile && _selectedIndex == 0
              ? FloatingActionButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const NetworkScreen(),
                      ),
                    );
                  },
                  backgroundColor: AppTheme.primaryColor,
                  child: const Icon(
                    Icons.chat_bubble_outline,
                    color: Colors.white,
                  ),
                )
              : null,
          body: Stack(
            children: [
              Row(
                children: [
                  // Sidebar only on Desktop
                  if (!isMobile)
                    StudentSidebar(
                      selectedIndex: _selectedIndex,
                      isCollapsed: _isSidebarCollapsed,
                      onToggleCollapse: () {
                        setState(
                          () => _isSidebarCollapsed = !_isSidebarCollapsed,
                        );
                      },
                      onItemSelected: (index) {
                        if (index == 14) {
                          _handleLogout();
                        } else if (index == 99) {
                          ref.read(aiAssistantProvider.notifier).toggleOpen();
                        } else if (index == 1) {
                          ref
                              .read(notificationPopoverProvider.notifier)
                              .toggle();
                        } else {
                          setState(() => _selectedIndex = index);
                        }
                      },
                    ),

                  // Main Content
                  Expanded(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: KeyedSubtree(
                        key: ValueKey(_selectedIndex),
                        child: _selectedIndex < _screens.length
                            ? _screens[_selectedIndex]
                            : _screens[0],
                      ),
                    ),
                  ),
                ],
              ),

              // Notification Popover Overlay
              Consumer(
                builder: (context, ref, _) {
                  final isPopoverOpen = ref.watch(notificationPopoverProvider);
                  if (!isPopoverOpen) return const SizedBox.shrink();

                  return Positioned(
                    left: _isSidebarCollapsed ? 130 : 410,
                    top: 100,
                    child: NotificationPopover(
                      onNavigate: (index) {
                        setState(() => _selectedIndex = index);
                      },
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

  void _setupNotificationListener() {
    ref.listen(notificationsStreamProvider, (previous, next) {
      next.whenData((notifications) {
        if (notifications.isNotEmpty) {
          final latest = notifications.first;
          if (latest.createdAt.isAfter(
            DateTime.now().subtract(const Duration(seconds: 10)),
          )) {
            _showNotificationOverlay(latest);
          }
        }
      });
    });
  }

  void _showNotificationOverlay(notification) {
    showNotificationOverlay(
      context,
      notification,
      onTap: () {
        ref.read(notificationPopoverProvider.notifier).open();
      },
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
          Navigator.pushNamedAndRemoveUntil(
            context,
            '/login',
            (route) => false,
          );
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

class _StudentDashboardHomeContent extends ConsumerStatefulWidget {
  const _StudentDashboardHomeContent();

  @override
  ConsumerState<_StudentDashboardHomeContent> createState() =>
      _StudentDashboardHomeContentState();
}

class _StudentDashboardHomeContentState
    extends ConsumerState<_StudentDashboardHomeContent> {
  Map<String, dynamic>? _studentProfile;
  Map<String, dynamic>? _collegeInfo;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStudentProfile();
  }

  Future<void> _loadStudentProfile() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        setState(() => _isLoading = false);
        return;
      }

      LoggerService.debug('Loading profile for user: ${user.id}');

      // First get the basic profile
      final profileResponse = await Supabase.instance.client
          .from('profiles')
          .select('*')
          .eq('id', user.id)
          .single();

      LoggerService.debug('Profile data: $profileResponse');

      // Then get related data separately if IDs exist
      Map<String, dynamic> enrichedProfile = Map<String, dynamic>.from(
        profileResponse,
      );

      // Fetch student-specific academic profile
      Map<String, dynamic>? studentProfileData;
      try {
        studentProfileData = await Supabase.instance.client
            .from('student_profiles')
            .select('*')
            .eq('id', user.id)
            .single();

        enrichedProfile.addAll(studentProfileData);
      } catch (e) {
        LoggerService.error('Student academic profile not found', e);
      }

      // Get organization info if organization_id exists (with fallback to student_profiles)
      final orgId =
          profileResponse['organization_id'] ??
          studentProfileData?['college_id'];

      if (orgId != null) {
        try {
          LoggerService.debug('Loading organization with ID: $orgId');
          final orgResponse = await Supabase.instance.client
              .from('organizations')
              .select('name, type, logo_url')
              .eq('id', orgId)
              .single();
          enrichedProfile['organization'] = orgResponse;
          LoggerService.debug('Organization loaded: $orgResponse');
        } catch (e) {
          LoggerService.error('Organization not found', e);
        }
      }

      // Get department info if department_id exists
      final deptId =
          studentProfileData?['department_id'] ??
          profileResponse['department_id'];
      if (deptId != null) {
        try {
          final deptResponse = await Supabase.instance.client
              .from('college_departments')
              .select('name')
              .eq('id', deptId)
              .single();
          enrichedProfile['college_departments'] = deptResponse;
        } catch (e) {
          // Department not found, continue without it
        }
      }

      // Get program info if program_id exists
      final programId =
          studentProfileData?['program_id'] ?? profileResponse['program_id'];
      if (programId != null) {
        try {
          final programResponse = await Supabase.instance.client
              .from('college_programs')
              .select('name, duration_years')
              .eq('id', programId)
              .single();
          enrichedProfile['college_programs'] = programResponse;
        } catch (e) {
          // Program not found, continue without it
        }
      }

      // Get batch info if batch_id exists
      final batchId =
          studentProfileData?['batch_id'] ?? profileResponse['batch_id'];
      if (batchId != null) {
        try {
          final batchResponse = await Supabase.instance.client
              .from('college_batches')
              .select('name, start_year, end_year')
              .eq('id', batchId)
              .single();
          enrichedProfile['college_batches'] = batchResponse;
        } catch (e) {
          // Batch not found, continue without it
        }
      }

      setState(() {
        _studentProfile = enrichedProfile;
        _collegeInfo = enrichedProfile['organization'];
        _isLoading = false;
      });

      if (_collegeInfo == null) {
        LoggerService.warning('COLLEGE INFO NOT LOADING: No organization data found');
      } else {
        LoggerService.info('College info loaded successfully: ${_collegeInfo!['name']}');
      }
    } catch (e) {
      LoggerService.error('Error loading student profile', e);
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading profile: $e'),
            backgroundColor: Colors.red,
            action: SnackBarAction(
              label: 'Retry',
              onPressed: _loadStudentProfile,
            ),
          ),
        );
      }
    }
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
          Navigator.pushNamedAndRemoveUntil(
            context,
            '/login',
            (route) => false,
          );
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

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;

    // Identity Logic
    final profile = _studentProfile;
    final role = profile?['role'];
    final orgInfo = _collegeInfo; // This holds organization/college info

    final bool isRecruiterOrAdmin =
        role == 'recruiter' || role == 'admin' || role == 'college_admin';

    // Name: Use Org Name if official role, else User Name
    final userName = (isRecruiterOrAdmin && orgInfo?['name'] != null)
        ? orgInfo!['name']
        : (profile?['full_name'] ??
              user?.userMetadata?['full_name'] ??
              user?.email?.split('@')[0] ??
              'Student');

    // Subtitle/Context (above name): "Recruiter At" or College Name
    final contextName = isRecruiterOrAdmin
        ? _getRoleDisplayName(role)
        : (orgInfo?['name'] ?? 'Your College');

    // Compatibility for existing code using collegeName
    final collegeName = contextName;

    // Avatar: Use Org Logo if official role, else User Photo
    final avatarUrl = (isRecruiterOrAdmin && orgInfo?['logo_url'] != null)
        ? orgInfo!['logo_url']
        : profile?['profile_photo_url'];

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    // Determine layout based on width
    final isMobile = MediaQuery.of(context).size.width < 900;
    final isTablet =
        MediaQuery.of(context).size.width >= 900 &&
        MediaQuery.of(context).size.width < 1200;
    final isDesktop = MediaQuery.of(context).size.width >= 1200;

    // Common Padding
    final padding = EdgeInsets.all(isMobile ? 16 : 32);

    if (isDesktop) {
      return Padding(
        padding: const EdgeInsets.all(32),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Center Main Content (Feed) - Independent Scroll
            Expanded(
              flex: 5,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    children: [
                      // DESKTOP: Original Row Layout (Header)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                if (Scaffold.maybeOf(context)?.hasDrawer ??
                                    false)
                                  Padding(
                                    padding: const EdgeInsets.only(right: 12),
                                    child: IconButton(
                                      onPressed: () {
                                        Scaffold.of(context).openDrawer();
                                      },
                                      icon: const Icon(
                                        Icons.menu_rounded,
                                        size: 28,
                                      ),
                                    ),
                                  ),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        contextName,
                                        style: GoogleFonts.outfit(
                                          fontSize: 16,
                                          color: Colors.grey[600],
                                          fontWeight: FontWeight.w500,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 4),
                                      Wrap(
                                        crossAxisAlignment:
                                            WrapCrossAlignment.center,
                                        spacing: 8,
                                        runSpacing: 4,
                                        children: [
                                          Text(
                                            'Welcome back, $userName',
                                            style: GoogleFonts.outfit(
                                              fontSize: 28,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.black87,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          if (isRecruiterOrAdmin) ...[
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                    vertical: 4,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: Colors.blue.withValues(
                                                  alpha: 0.1,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(
                                                    Icons.verified,
                                                    size: 14,
                                                    color: Colors.blue,
                                                  ),
                                                  SizedBox(width: 4),
                                                  Text(
                                                    _getRoleLabel(role),
                                                    style: GoogleFonts.outfit(
                                                      fontSize: 12,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: Colors.blue,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ] else if (orgInfo?['logo_url'] !=
                                                  null &&
                                              orgInfo!['logo_url']
                                                  .isNotEmpty) ...[
                                            Container(
                                              padding: const EdgeInsets.all(4),
                                              decoration: BoxDecoration(
                                                color: Colors.green.withValues(
                                                  alpha: 0.1,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  ClipRRect(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          8,
                                                        ),
                                                    child: Image.network(
                                                      orgInfo!['logo_url'],
                                                      width: 20,
                                                      height: 20,
                                                      fit: BoxFit.cover,
                                                      errorBuilder:
                                                          (
                                                            context,
                                                            error,
                                                            stackTrace,
                                                          ) {
                                                            return const Icon(
                                                              Icons
                                                                  .verified_rounded,
                                                              color:
                                                                  Colors.green,
                                                              size: 20,
                                                            );
                                                          },
                                                    ),
                                                  ),
                                                  const SizedBox(width: 4),
                                                  const Icon(
                                                    Icons.verified_rounded,
                                                    color: Colors.green,
                                                    size: 16,
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ] else ...[
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                    vertical: 4,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: AppTheme.primaryColor
                                                    .withValues(alpha: 0.1),
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                              child: Text(
                                                'Student',
                                                style: GoogleFonts.outfit(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.bold,
                                                  color: AppTheme.primaryColor,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Row(
                            children: [
                              IconButton(
                                onPressed: () {
                                  ref
                                      .read(
                                        notificationPopoverProvider.notifier,
                                      )
                                      .toggle();
                                },
                                icon: Stack(
                                  children: [
                                    const Icon(
                                      Icons.notifications_outlined,
                                      size: 28,
                                    ),
                                    Consumer(
                                      builder: (context, ref, _) {
                                        final unreadCount = ref.watch(
                                          unreadNotificationCountProvider,
                                        );
                                        if (unreadCount == 0) {
                                          return const SizedBox.shrink();
                                        }
                                        return Positioned(
                                          right: 2,
                                          top: 2,
                                          child: Container(
                                            width: 10,
                                            height: 10,
                                            decoration: BoxDecoration(
                                              color: Colors.blue,
                                              shape: BoxShape.circle,
                                              border: Border.all(
                                                color: Colors.white,
                                                width: 1.5,
                                              ),
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                onPressed: _handleLogout,
                                icon: const Icon(
                                  Icons.logout_rounded,
                                  size: 24,
                                ),
                                tooltip: 'Sign Out',
                              ),
                              const SizedBox(width: 16),
                              GestureDetector(
                                onTap: () {
                                  showDialog(
                                    context: context,
                                    builder: (context) => Dialog(
                                      insetPadding: EdgeInsets.symmetric(
                                        horizontal:
                                            MediaQuery.of(context).size.width >
                                                900
                                            ? 0
                                            : 16,
                                        vertical:
                                            MediaQuery.of(context).size.width >
                                                900
                                            ? 0
                                            : 24,
                                      ),
                                      child: Container(
                                        width:
                                            MediaQuery.of(context).size.width >
                                                900
                                            ? 1200
                                            : double.infinity,
                                        height:
                                            MediaQuery.of(context).size.height >
                                                900
                                            ? 850
                                            : MediaQuery.of(
                                                    context,
                                                  ).size.height *
                                                  0.9,
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                        ),
                                        clipBehavior: Clip.antiAlias,
                                        child:
                                            const StudentProfileScreenSimple(),
                                      ),
                                    ),
                                  );
                                },
                                child: Stack(
                                  children: [
                                    CircleAvatar(
                                      radius: 20,
                                      backgroundImage:
                                          avatarUrl != null &&
                                              avatarUrl.isNotEmpty
                                          ? NetworkImage(avatarUrl)
                                          : null,
                                      backgroundColor: AppTheme.primaryColor,
                                      child:
                                          avatarUrl == null || avatarUrl.isEmpty
                                          ? (isRecruiterOrAdmin
                                                ? const Icon(
                                                    Icons.business,
                                                    color: Colors.white,
                                                    size: 20,
                                                  )
                                                : Text(
                                                    userName.isNotEmpty
                                                        ? userName[0]
                                                              .toUpperCase()
                                                        : 'S',
                                                    style: GoogleFonts.outfit(
                                                      color: Colors.white,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ))
                                          : null,
                                    ),
                                    if (!isRecruiterOrAdmin)
                                      Positioned(
                                        bottom: 0,
                                        right: 0,
                                        child: Container(
                                          width: 12,
                                          height: 12,
                                          decoration: BoxDecoration(
                                            color: Colors.green,
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: Colors.white,
                                              width: 1,
                                            ),
                                          ),
                                          child: const Icon(
                                            Icons.edit,
                                            color: Colors.white,
                                            size: 8,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),
                      // Profile Completion Banner (if incomplete)
                      if ((_studentProfile?['profile_completion'] ?? 0) <
                          100) ...[
                        Container(
                          padding: const EdgeInsets.all(24),
                          margin: const EdgeInsets.only(bottom: 32),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppTheme.primaryColor,
                                AppTheme.primaryColor.withValues(alpha: 0.8),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.primaryColor.withValues(
                                  alpha: 0.3,
                                ),
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
                                  Icons.person_rounded,
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
                                      'Complete Your Profile',
                                      style: GoogleFonts.outfit(
                                        color: Colors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      'Add skills, experience, and projects to boost your visibility.',
                                      style: GoogleFonts.outfit(
                                        color: Colors.white.withValues(
                                          alpha: 0.9,
                                        ),
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
                                  '${_studentProfile?['profile_completion'] ?? 30}%',
                                  style: GoogleFonts.outfit(
                                    color: AppTheme.primaryColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const DashboardStatsPanel(),
                      const SizedBox(height: 24),
                      const SocialFeedPanel(),
                      const SizedBox(height: 100), // Bottom padding
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 32),
            // Right Sidebar - Independent Scroll
            Expanded(
              flex: 3,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    children: [
                      const MessagingPreviewWidget(),
                      const SizedBox(height: 24),
                      const ConnectionRequestsWidget(),
                      const SizedBox(height: 24),
                      // Featured Opportunities
                      const JobCarouselWidget(),
                      const SizedBox(height: 24),
                      // Available Courses
                      const CourseCarouselWidget(),
                      const SizedBox(height: 24),
                      const RecentActivitiesPanel(),
                      const SizedBox(height: 24),
                      const UpcomingEventsPanel(),
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Mobile & Tablet Layout (Stacked)
    return SingleChildScrollView(
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Reponsive Header (Mobile Only)
          if (isMobile) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (Scaffold.maybeOf(context)?.hasDrawer ?? false)
                  IconButton(
                    onPressed: () => Scaffold.of(context).openDrawer(),
                    icon: const Icon(Icons.menu_rounded, size: 28),
                  )
                else
                  const SizedBox.shrink(),
                Row(
                  children: [
                    IconButton(
                      onPressed: () {
                        ref.read(notificationPopoverProvider.notifier).toggle();
                      },
                      icon: Stack(
                        children: [
                          const Icon(Icons.notifications_outlined, size: 28),
                          Consumer(
                            builder: (context, ref, _) {
                              final unreadCount = ref.watch(
                                unreadNotificationCountProvider,
                              );
                              if (unreadCount == 0) {
                                return const SizedBox.shrink();
                              }
                              return Positioned(
                                right: 2,
                                top: 2,
                                child: Container(
                                  width: 10,
                                  height: 10,
                                  decoration: BoxDecoration(
                                    color: Colors.blue,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 1.5,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (_studentProfile?['profile_photo_url'] != null)
                      CircleAvatar(
                        radius: 18,
                        backgroundImage: NetworkImage(
                          _studentProfile!['profile_photo_url'],
                        ),
                      ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              'Welcome back, $userName',
              style: GoogleFonts.outfit(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
          ] else ...[
            // Tablet Header handles itself or is implicit
            // DESKTOP: Original Row Layout (Header) - Re-using the desktop header for tablet as it's a row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      if (Scaffold.maybeOf(context)?.hasDrawer ?? false)
                        Padding(
                          padding: const EdgeInsets.only(right: 12),
                          child: IconButton(
                            onPressed: () {
                              Scaffold.of(context).openDrawer();
                            },
                            icon: const Icon(Icons.menu_rounded, size: 28),
                          ),
                        ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              collegeName,
                              style: GoogleFonts.outfit(
                                fontSize: 16,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Wrap(
                              crossAxisAlignment: WrapCrossAlignment.center,
                              spacing: 8,
                              runSpacing: 4,
                              children: [
                                Text(
                                  'Welcome back, $userName',
                                  style: GoogleFonts.outfit(
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if (_collegeInfo?['logo_url'] != null &&
                                    _collegeInfo!['logo_url'].isNotEmpty) ...[
                                  Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: Colors.green.withValues(
                                        alpha: 0.1,
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          child: Image.network(
                                            _collegeInfo!['logo_url'],
                                            width: 20,
                                            height: 20,
                                            fit: BoxFit.cover,
                                            errorBuilder:
                                                (context, error, stackTrace) {
                                                  return const Icon(
                                                    Icons.verified_rounded,
                                                    color: Colors.green,
                                                    size: 20,
                                                  );
                                                },
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        const Icon(
                                          Icons.verified_rounded,
                                          color: Colors.green,
                                          size: 16,
                                        ),
                                      ],
                                    ),
                                  ),
                                ] else ...[
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppTheme.primaryColor.withValues(
                                        alpha: 0.1,
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      'Student',
                                      style: GoogleFonts.outfit(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.primaryColor,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Row(
                  children: [
                    IconButton(
                      onPressed: () {
                        ref.read(notificationPopoverProvider.notifier).toggle();
                      },
                      icon: Stack(
                        children: [
                          const Icon(Icons.notifications_outlined, size: 28),
                          Consumer(
                            builder: (context, ref, _) {
                              final unreadCount = ref.watch(
                                unreadNotificationCountProvider,
                              );
                              if (unreadCount == 0) {
                                return const SizedBox.shrink();
                              }
                              return Positioned(
                                right: 2,
                                top: 2,
                                child: Container(
                                  width: 10,
                                  height: 10,
                                  decoration: BoxDecoration(
                                    color: Colors.blue,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 1.5,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: _handleLogout,
                      icon: const Icon(Icons.logout_rounded, size: 24),
                      tooltip: 'Sign Out',
                    ),
                    const SizedBox(width: 16),
                    GestureDetector(
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (context) => Dialog(
                            insetPadding: EdgeInsets.symmetric(
                              horizontal:
                                  MediaQuery.of(context).size.width > 900
                                  ? 0
                                  : 16,
                              vertical: MediaQuery.of(context).size.width > 900
                                  ? 0
                                  : 24,
                            ),
                            child: Container(
                              width: MediaQuery.of(context).size.width > 900
                                  ? 1000
                                  : double.infinity,
                              height: MediaQuery.of(context).size.height > 900
                                  ? 800
                                  : MediaQuery.of(context).size.height * 0.9,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              clipBehavior: Clip.antiAlias,
                              child: const StudentProfileScreenSimple(),
                            ),
                          ),
                        );
                      },
                      child: Stack(
                        children: [
                          CircleAvatar(
                            radius: 20,
                            backgroundImage:
                                _studentProfile?['profile_photo_url'] != null &&
                                    _studentProfile!['profile_photo_url']
                                        .isNotEmpty
                                ? NetworkImage(
                                    _studentProfile!['profile_photo_url'],
                                  )
                                : null,
                            backgroundColor: AppTheme.primaryColor,
                            child:
                                _studentProfile?['profile_photo_url'] == null ||
                                    _studentProfile!['profile_photo_url']
                                        .isEmpty
                                ? Text(
                                    userName.isNotEmpty
                                        ? userName[0].toUpperCase()
                                        : 'S',
                                    style: GoogleFonts.outfit(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  )
                                : null,
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: Colors.green,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 1,
                                ),
                              ),
                              child: const Icon(
                                Icons.edit,
                                color: Colors.white,
                                size: 8,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 32),
          ],

          // Profile Completion Banner (if incomplete)
          if ((_studentProfile?['profile_completion'] ?? 0) < 100) ...[
            Container(
              padding: const EdgeInsets.all(24),
              margin: const EdgeInsets.only(bottom: 32),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.primaryColor,
                    AppTheme.primaryColor.withValues(alpha: 0.8),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryColor.withValues(alpha: 0.3),
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
                      Icons.person_rounded,
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
                          'Complete Your Profile',
                          style: GoogleFonts.outfit(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Add skills, experience, and projects to boost your visibility.',
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
                      '${_studentProfile?['profile_completion'] ?? 30}%',
                      style: GoogleFonts.outfit(
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          if (isTablet) ...[
            const DashboardStatsPanel(),
            const SizedBox(height: 32),
            const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 3, child: SocialFeedPanel()),
                SizedBox(width: 24),
                Expanded(
                  flex: 2,
                  child: Column(
                    children: [
                      MessagingPreviewWidget(),
                      SizedBox(height: 24),
                      JobCarouselWidget(),
                      SizedBox(height: 24),
                      CourseCarouselWidget(),
                      SizedBox(height: 24),
                      RecentActivitiesPanel(),
                      SizedBox(height: 24),
                      UpcomingEventsPanel(),
                    ],
                  ),
                ),
              ],
            ),
          ] else ...[
            // Mobile Stack
            const DashboardStatsPanel(),
            const SizedBox(height: 24),
            // const MessagingPreviewWidget(), // Important on mobile too? Or rely on FAB? Layout says FAB.
            // const SizedBox(height: 24),
            const JobCarouselWidget(),
            const SizedBox(height: 24),
            const CourseCarouselWidget(),
            const SizedBox(height: 24),
            const SocialFeedPanel(),
            const SizedBox(height: 24),
            const UpcomingEventsPanel(),
            const SizedBox(height: 24),
            const RecentActivitiesPanel(),
          ],
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  String _getRoleDisplayName(String? role) {
    if (role == 'recruiter') return 'Recruiter At';
    if (role == 'college_admin') return 'Admin At';
    if (role == 'admin') return 'Administrator';
    return 'Student At';
  }

  String _getRoleLabel(String? role) {
    if (role == 'recruiter') return 'Recruiter';
    if (role == 'college_admin') return 'College Admin';
    if (role == 'admin') return 'Admin';
    return 'User';
  }
}

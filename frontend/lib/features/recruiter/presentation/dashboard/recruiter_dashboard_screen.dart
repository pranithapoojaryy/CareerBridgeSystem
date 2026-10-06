import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/theme/app_theme.dart';
import '../widgets/recruiter_sidebar.dart';
import 'recruiter_home_screen.dart';
import '../profile/recruiter_profile_screen.dart';
import '../../../networking/presentation/screens/network_screen.dart';
import '../jobs/job_management_screen.dart';
import '../applications/applications_screen.dart';
import '../applications/resume_screening_screen.dart';
import '../students/student_search_screen.dart';
import '../../../college/presentation/dashboard/manage_learning_courses_screen.dart';
import '../../../shared/presentation/widgets/ai_assistant_widget.dart';

// Placeholder screens for features not yet fully implemented

class RecruiterCoursesScreen extends StatelessWidget {
  const RecruiterCoursesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.school, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Course Management',
              style: GoogleFonts.outfit(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'Create and manage training courses',
              style: GoogleFonts.outfit(fontSize: 14, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }
}

class RecruiterDashboardScreen extends ConsumerStatefulWidget {
  final int? initialIndex;

  const RecruiterDashboardScreen({super.key, this.initialIndex});

  @override
  ConsumerState<RecruiterDashboardScreen> createState() =>
      _RecruiterDashboardScreenState();
}

class _RecruiterDashboardScreenState
    extends ConsumerState<RecruiterDashboardScreen> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    if (widget.initialIndex != null) {
      _selectedIndex = widget.initialIndex!;
    }
  }

  bool _isSidebarCollapsed = true;

  List<Widget> get _screens => [
    RecruiterHomeScreen(
      onNavigateToTab: (index) {
        setState(() => _selectedIndex = index);
      },
    ), // 0. Home
    JobManagementScreen(onBackPressed: _goToHome), // 1. Jobs
    ApplicationsScreen(onBackPressed: _goToHome), // 2. Applications
    StudentSearchScreen(onBackPressed: _goToHome), // 3. Students
    ResumeScreeningScreen(onBackPressed: _goToHome), // 4. Resume Screening
    ManageLearningCoursesScreen(onBackPressed: _goToHome), // 5. Courses
    NetworkScreen(onBackPressed: _goToHome), // 6. Network
    RecruiterProfileScreen(onBackPressed: _goToHome), // 7. Profile
  ];

  void _goToHome() {
    setState(() => _selectedIndex = 0);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 900;

        return Scaffold(
          backgroundColor: Colors.grey[50],
          appBar: isMobile
              ? AppBar(
                  backgroundColor: Colors.white,
                  elevation: 0,
                  centerTitle: true,
                  title: Text(
                    'CareerBridge',
                    style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2.0,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                  bottom: PreferredSize(
                    preferredSize: const Size.fromHeight(1),
                    child: Divider(height: 1, color: Colors.grey.shade100),
                  ),
                )
              : null,
          drawer: isMobile
              ? Drawer(
                  width: 300,
                  child: RecruiterSidebar(
                    selectedIndex: _selectedIndex,
                    isCollapsed: false,
                    isMobile: true,
                    onToggleCollapse: () {},
                    onItemSelected: (index) {
                      if (index == 8) {
                        _handleLogout();
                      } else if (index == 99) {
                        ref.read(aiAssistantProvider.notifier).toggleOpen();
                        Navigator.pop(context);
                      } else {
                        setState(() => _selectedIndex = index);
                        Navigator.pop(context);
                      }
                    },
                  ),
                )
              : null,
          body: Row(
            children: [
              // Sidebar only on Desktop
              if (!isMobile)
                RecruiterSidebar(
                  selectedIndex: _selectedIndex,
                  isCollapsed: _isSidebarCollapsed,
                  onToggleCollapse: () {
                    setState(() => _isSidebarCollapsed = !_isSidebarCollapsed);
                  },
                  onItemSelected: (index) {
                    if (index == 8) {
                      _handleLogout();
                    } else if (index == 99) {
                      ref.read(aiAssistantProvider.notifier).toggleOpen();
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
        );
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
      final navigator = Navigator.of(context);
      final scaffoldMessenger = ScaffoldMessenger.of(context);
      try {
        await Supabase.instance.client.auth.signOut();
        if (mounted) {
          navigator.pushNamedAndRemoveUntil(
            '/login',
            (route) => false,
          );
        }
      } catch (e) {
        if (mounted) {
          scaffoldMessenger.showSnackBar(
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

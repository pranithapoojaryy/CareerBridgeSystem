import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../../../core/theme/app_theme.dart';
import '../../../../features/student/data/student_analytics_repository.dart';
import '../../data/network_repository.dart';
import 'chat_screen.dart';
import 'recruiter_profile_view.dart';
import '../../../college/presentation/profile/college_public_profile_screen.dart';

class NetworkProfileView extends ConsumerStatefulWidget {
  final String userId;
  final String userName;
  final String? userAvatar;
  final String userRole; // 'student' or 'college'

  const NetworkProfileView({
    super.key,
    required this.userId,
    required this.userName,
    this.userAvatar,
    required this.userRole,
  });

  @override
  ConsumerState<NetworkProfileView> createState() => _NetworkProfileViewState();
}

class _NetworkProfileViewState extends ConsumerState<NetworkProfileView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _supabase = Supabase.instance.client;
  final _networkRepo = NetworkRepository();
  String _connectionStatus = 'none'; // none, pending, accepted
  // State Variables
  Map<String, dynamic>? _profileData;
  Map<String, dynamic>? _studentProfileData;
  Map<String, dynamic> _studentStats = {};
  List<Map<String, dynamic>> _posts = [];
  List<Map<String, dynamic>> _projects = [];
  List<Map<String, dynamic>> _events = [];
  List<Map<String, dynamic>> _students = [];
  List<Map<String, dynamic>> _filteredStudents = [];
  List<Map<String, dynamic>> _skills = [];
  List<Map<String, dynamic>> _courses = [];
  List<Map<String, dynamic>> _aptitude = [];
  List<Map<String, dynamic>> _interviews = [];
  List<Map<String, dynamic>> _certificates = [];
  int _connectionCount = 0;
  bool _isLoading = true;
  String _displayName = "";
  String? _displayAvatar;
  String? _displayHeadline;
  String _bio = "";
  List<dynamic> _academicHistory = [];
  List<Map<String, dynamic>> _selectedJobs = [];
  String? _githubUrl;
  String? _linkedinUrl;
  String? _portfolioUrl;
  String? _resumeUrl;

  String? _organizationId; // For colleges
  String? _organizationLogo; // For displaying college logo in header
  String? _departmentName;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _displayName = widget.userName;
    _searchController.addListener(_filterStudents);
    _displayAvatar = widget.userAvatar;
    _setupTabs();
    _loadProfileData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _filterStudents() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredStudents = List.from(_students);
      } else {
        _filteredStudents = _students.where((student) {
          final name = (student['full_name'] ?? '').toString().toLowerCase();
          final email = (student['email'] ?? '').toString().toLowerCase();
          return name.contains(query) || email.contains(query);
        }).toList();
      }
    });
  }

  void _setupTabs() {
    // Define tabs based on role
    // treat college_admin same as college
    final isCollege =
        widget.userRole == 'college' || widget.userRole == 'college_admin';
    int tabCount = isCollege ? 4 : 5;

    _tabController = TabController(length: tabCount, vsync: this);
  }

  Future<void> _loadProfileData({bool silent = false}) async {
    if (!silent) {
      setState(() => _isLoading = true);
    }
    try {
      // 1. Fetch Basic Profile Details
      // Don't join immediately to avoid errors if relationship is broken
      final profileResponse = await _supabase
          .from('profiles')
          .select()
          .eq('id', widget.userId)
          .maybeSingle();

      if (profileResponse == null) {
        if (!silent && mounted) {
          setState(() => _isLoading = false);
        }
        return;
      }

      _profileData = profileResponse;

      if (mounted) {
        setState(() {
          _displayHeadline = _profileData?['headline'];
          _bio = _profileData?['bio'] ?? "";
          // ALWAYS overwrite name/avatar from fresh DB data if available
          if (_profileData?['full_name'] != null &&
              (_profileData?['full_name'] as String).isNotEmpty) {
            _displayName = _profileData!['full_name'];
          }
          // Use profile_photo_url if available, fallback to avatar_url
          final String? photoUrl =
              _profileData?['profile_photo_url'] ?? _profileData?['avatar_url'];

          if (photoUrl != null && photoUrl.isNotEmpty) {
            _displayAvatar = photoUrl;
            // Evict cache to ensure fresh image
            if (_displayAvatar != null) {
              NetworkImage(_displayAvatar!).evict();
              // Force reload by appending timestamp if not already present
              if (!_displayAvatar!.contains('?')) {
                _displayAvatar =
                    '$_displayAvatar?t=${DateTime.now().millisecondsSinceEpoch}';
              }
            }
          }
        });
      }

      // 2. Organization Details (if College or Recruiter)
      final role = _profileData?['role'] ?? widget.userRole;
      final orgId = _profileData?['organization_id'];

      if ((role == 'college' ||
              role == 'college_admin' ||
              role == 'recruiter') &&
          orgId != null) {
        try {
          final orgResponse = await _supabase
              .from('organizations')
              .select('id, name, logo_url, description')
              .eq('id', orgId)
              .maybeSingle();

          if (orgResponse != null && mounted) {
            // Redirect recruiters to RecruiterProfileView
            if (role == 'recruiter') {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) => RecruiterProfileView(
                    userId: widget.userId,
                    userName: widget.userName,
                    userAvatar: widget.userAvatar,
                  ),
                ),
              );
              return;
            }

            setState(() {
              _organizationId = orgResponse['id'];
              _displayName = orgResponse['name'] ?? _displayName;
              _organizationLogo = orgResponse['logo_url'];
              _displayAvatar = orgResponse['logo_url'] ?? _displayAvatar;
              _displayHeadline = role == 'recruiter'
                  ? 'Recruiter at ${orgResponse['name']}'
                  : (orgResponse['description'] ?? _displayHeadline);
            });
          }
        } catch (e) {
          debugPrint('Error fetching organization: $e');
        }
      }

      try {
        final countResponse = await _supabase.rpc(
          'get_user_connection_count',
          params: {'p_user_id': widget.userId},
        );

        if (mounted) {
          setState(() {
            _connectionCount = int.tryParse(countResponse.toString()) ?? 0;
          });
        }
      } catch (e) {
        debugPrint('Error fetching connection count via RPC: $e');
      }

      // Redirect Colleges to CollegePublicProfileScreen
      if ((role == 'college' || role == 'college_admin') && mounted) {
        // Import handled dynamically or at top
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => CollegePublicProfileScreen(
              userId: widget.userId,
              organizationId: _organizationId,
              userName: widget.userName,
              userAvatar: widget.userAvatar,
            ),
          ),
        );
        return;
      }

      // 4. Fetch Posts
      try {
        final postsResponse = await _supabase
            .from('posts')
            .select('*, author:profiles(*)')
            .eq('author_id', widget.userId)
            .order('created_at', ascending: false);

        if (mounted) {
          setState(() {
            _posts = List<Map<String, dynamic>>.from(postsResponse);
          });
        }
      } catch (e) {
        debugPrint('Error fetching posts: $e');
      }

      // 4b. Fetch Student Profile Details (Bio, Academic History, Socials, Stats)
      try {
        final profileResponse = await _supabase
            .from('profiles')
            .select('''
              *,
              student_profiles (
                *,
                college_departments (name)
              )
            ''')
            .eq('id', widget.userId)
            .maybeSingle();

        if (profileResponse != null && mounted) {
          setState(() {
            _profileData = profileResponse;
            _displayName = profileResponse['full_name'] ?? _displayName;
            _bio = profileResponse['bio'] ?? "";
            _displayAvatar =
                profileResponse['profile_photo_url'] ?? _displayAvatar;
            _academicHistory = profileResponse['academic_history'] ?? [];
            _portfolioUrl = profileResponse['portfolio_url'];
            _resumeUrl = profileResponse['resume_url'];
            _linkedinUrl = profileResponse['linkedin_url'];
            _githubUrl = profileResponse['github_url'];
          });

          _checkConnectionStatus();

          // Process student_profiles data
          if (role == 'student' &&
              profileResponse['student_profiles'] != null) {
            final sp = profileResponse['student_profiles'];
            // Postgrest may return a list even for 1:1 if relationship is ambiguous
            final Map<String, dynamic>? spData = (sp is List)
                ? (sp.isEmpty ? null : sp.first as Map<String, dynamic>)
                : sp as Map<String, dynamic>;

            if (spData != null && mounted) {
              setState(() {
                _studentProfileData = spData;
                final dept = spData['college_departments'];
                _departmentName = (dept is List)
                    ? (dept.isEmpty ? null : dept.first['name'])
                    : dept?['name'];

                _linkedinUrl ??= spData['linkedin_url'];
                _githubUrl ??= spData['github_url'];
                _portfolioUrl ??= spData['portfolio_url'];
                _resumeUrl ??= spData['resume_url'];
              });
            }
          }

          // Fetch College Name if user is student and headline is empty/generic
          if (role == 'student' && profileResponse['organization_id'] != null) {
            try {
              final orgResponse = await _supabase
                  .from('organizations')
                  .select('name, logo_url')
                  .eq('id', profileResponse['organization_id'])
                  .maybeSingle();

              if (orgResponse != null && mounted) {
                setState(() {
                  _organizationLogo = orgResponse['logo_url'];
                  // Prefer user's custom headline, else show College Name + Department
                  _displayHeadline =
                      (profileResponse['headline'] != null &&
                          profileResponse['headline'].toString().isNotEmpty)
                      ? profileResponse['headline']
                      : orgResponse['name'];
                });
              }
            } catch (e) {
              debugPrint('Error fetching college name: $e');
            }
          }
        }
      } catch (e) {
        debugPrint('Error fetching detailed profile info: $e');
      }

      // 5. Fetch Role Specific Data
      if (role == 'student') {
        try {
          // Explicitly selecting fields to ensure we get what we expect
          final projectsResponse = await _supabase
              .from('student_projects')
              .select('*')
              .eq('student_id', widget.userId);

          // Fetch Selected Jobs
          final selectedJobsResponse = await _supabase
              .from('job_applications')
              .select(
                '*, job:jobs(*, organization:organizations(name, logo_url))',
              )
              .eq('student_id', widget.userId)
              .eq('status', 'selected');

          if (mounted)
            setState(() {
              _projects = List<Map<String, dynamic>>.from(projectsResponse);
              _selectedJobs = List<Map<String, dynamic>>.from(
                selectedJobsResponse,
              );
            });
        } catch (e) {
          debugPrint('Error fetching projects: $e');
        }
      } else if ((role == 'college' || role == 'college_admin') &&
          _organizationId != null) {
        // Fetch Events
        try {
          final eventsResponse = await _supabase
              .from('events')
              .select()
              .eq('college_id', _organizationId!)
              .order('created_at', ascending: false);
          if (mounted)
            setState(
              () => _events = List<Map<String, dynamic>>.from(eventsResponse),
            );
        } catch (e) {
          debugPrint('Error fetching events: $e');
        }

        // Fetch Students
        try {
          final studentsResponse = await _supabase
              .from('profiles')
              .select('*, profile_photo_url')
              .eq('organization_id', _organizationId!)
              .eq('role', 'student')
              .limit(50);
          if (mounted)
            setState(() {
              _students = List<Map<String, dynamic>>.from(studentsResponse);
              _filteredStudents = List<Map<String, dynamic>>.from(
                studentsResponse,
              );
            });
        } catch (e) {
          debugPrint('Error fetching students: $e');
        }
      }

      // 6. Fetch Full Analytics (for Student)
      if (role == 'student') {
        try {
          final analyticsRepo = ref.read(studentAnalyticsRepositoryProvider);

          final skillsFuture = analyticsRepo.getSkillScores(widget.userId);
          final coursesFuture = analyticsRepo.getCourseProgress(widget.userId);
          final aptitudeFuture = analyticsRepo.getAptitudeAttempts(
            widget.userId,
          );
          final interviewsFuture = analyticsRepo.getMockInterviewAttempts(
            widget.userId,
          );
          final statsFuture = _supabase
              .from('student_stats')
              .select('skill_score')
              .eq('student_id', widget.userId)
              .maybeSingle();

          // Fetch Certificates
          final certificatesFuture = _supabase
              .from('student_certifications')
              .select('*')
              .eq('student_id', widget.userId);

          final results = await Future.wait([
            skillsFuture.then((v) => v as dynamic),
            coursesFuture.then((v) => v as dynamic),
            aptitudeFuture.then((v) => v as dynamic),
            interviewsFuture.then((v) => v as dynamic),
            statsFuture.then((v) => v as dynamic),
            certificatesFuture.then((v) => v as dynamic),
          ]);

          if (mounted) {
            setState(() {
              _skills = results[0] as List<Map<String, dynamic>>;
              _courses = results[1] as List<Map<String, dynamic>>;
              _aptitude = results[2] as List<Map<String, dynamic>>;
              _interviews = results[3] as List<Map<String, dynamic>>;
              _studentStats = results[4] as Map<String, dynamic>? ?? {};
              _certificates = List<Map<String, dynamic>>.from(
                results[5] as List,
              );
            });
          }
        } catch (e) {
          debugPrint('Error fetching analytics: $e');
        }
      }
    } catch (e) {
      debugPrint('Critical Error loading profile main: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final role = _studentProfileData?['role'] ?? 'student';
    final isCollege = role == 'college' || role == 'college_admin';

    // Resume Layout for Students
    if (!isCollege) {
      return Scaffold(
        backgroundColor: Colors.grey[50],
        body: Column(
          children: [
            // FIXED HEADER
            _buildFixedHeader(),

            // SCROLLABLE BODY
            Expanded(
              child: Builder(
                builder: (context) {
                  // Main Scrollable Content
                  final Widget scrollableContent = SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 100),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (_bio.isNotEmpty)
                              Expanded(
                                flex: 3,
                                child: _buildResumeSection(
                                  'About',
                                  Text(
                                    _bio,
                                    style: GoogleFonts.outfit(
                                      fontSize: 14,
                                      color: Colors.black87,
                                      height: 1.5,
                                    ),
                                  ),
                                ),
                              ),
                            if (_bio.isNotEmpty) const SizedBox(width: 24),
                            Expanded(
                              flex: 4,
                              child: _buildResumeSection(
                                'Education History',
                                _buildEducationSection(),
                              ),
                            ),
                            const SizedBox(width: 24),
                            Expanded(
                              flex: 3,
                              child: _buildSkillsAndInterestsCard(),
                            ),
                          ],
                        ),
                        const SizedBox(height: 32),
                        if (_selectedJobs.isNotEmpty) ...[
                          _buildResumeSection(
                            'Selected in Jobs',
                            _buildSelectedJobsSection(),
                          ),
                          const SizedBox(height: 32),
                        ],
                        _buildResumeSection(
                          'Projects',
                          _buildProjectsList(),
                        ), // Projects first
                        const SizedBox(height: 32),
                        _buildResumeSection(
                          'Certificates',
                          _buildCertificatesList(),
                        ), // Certificates second
                        const SizedBox(height: 32),
                        const SizedBox(height: 32),
                        _buildResumeSection('My Posts', _buildProfilePosts()),
                        const SizedBox(height: 32),
                        // Move Analytics section to the bottom
                        _buildRightSidebar(),
                        const SizedBox(height: 32),
                      ],
                    ),
                  );

                  // always return the scrollable content
                  return scrollableContent;
                },
              ),
            ),
          ],
        ),
      );
    }

    // Tabbed Layout for Colleges
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'College Profile',
          style: GoogleFonts.outfit(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : NestedScrollView(
              headerSliverBuilder: (context, innerBoxIsScrolled) {
                return [
                  SliverToBoxAdapter(child: _buildProfileHeader()),
                  SliverPersistentHeader(
                    delegate: _SliverAppBarDelegate(
                      TabBar(
                        controller: _tabController,
                        labelColor: AppTheme.primaryColor,
                        unselectedLabelColor: Colors.grey,
                        labelStyle: GoogleFonts.outfit(
                          fontWeight: FontWeight.bold,
                        ),
                        isScrollable: true,
                        indicatorColor: AppTheme.primaryColor,
                        tabs: const [
                          Tab(text: 'Posts'),
                          Tab(text: 'Events'),
                          Tab(text: 'Students'),
                          Tab(text: 'About'),
                        ],
                      ),
                    ),
                    pinned: true,
                  ),
                ];
              },
              body: TabBarView(
                controller: _tabController,
                children: [
                  _buildFeedTab(),
                  _buildEventsTab(),
                  _buildStudentsTab(), // Implement this
                  _buildAboutTab(),
                ],
              ),
            ),
    );
  }

  // --- RESUME LAYOUT WIDGETS ---

  Widget _buildResumeSection(String title, Widget content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ... Title logic ...
        Container(
          padding: const EdgeInsets.only(left: 10, bottom: 8),
          decoration: const BoxDecoration(
            border: Border(
              left: BorderSide(color: AppTheme.primaryColor, width: 4),
            ),
          ),
          child: Text(
            title.toUpperCase(),
            style: GoogleFonts.outfit(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
              color: AppTheme.primaryColor,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Container(
          width: double.infinity, // Ensure full width
          child: content,
        ),
      ],
    );
  }

  Widget _buildFixedHeader() {
    final bool isMobile = MediaQuery.of(context).size.width < 900;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(24, isMobile ? 40 : 32, 24, 24),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor,
        gradient: LinearGradient(
          colors: [AppTheme.primaryColor, Colors.blue.shade900],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    icon: const Icon(
                      Icons.arrow_back_ios_new,
                      color: Colors.white,
                      size: 20,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: const Icon(Icons.refresh, color: Colors.white, size: 24),
                onPressed: () => _loadProfileData(),
                tooltip: 'Refresh Profile',
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Avatar
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2.5),
                  image: _displayAvatar != null
                      ? DecorationImage(
                          image: NetworkImage(_displayAvatar!),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: _displayAvatar == null
                    ? const Icon(Icons.person, color: Colors.white, size: 40)
                    : null,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _displayName.toUpperCase(),
                      style: GoogleFonts.merriweather(
                        color: Colors.white,
                        fontSize: 24, // Optimized size
                        fontWeight: FontWeight.w900,
                        shadows: [
                          BoxShadow(
                            color: Colors.black26,
                            offset: const Offset(1, 1),
                            blurRadius: 2,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (_displayHeadline != null || _bio.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 6.0),
                        child: Row(
                          children: [
                            if (_organizationLogo != null) ...[
                              Container(
                                width: 18,
                                height: 18,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  image: DecorationImage(
                                    image: NetworkImage(_organizationLogo!),
                                    fit: BoxFit.contain,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                            ],
                            Expanded(
                              child: Text(
                                (_displayHeadline ?? _bio).toUpperCase(),
                                style: GoogleFonts.merriweather(
                                  color: Colors.white70,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.5,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (_departmentName != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Text(
                          _departmentName!.toUpperCase(),
                          style: GoogleFonts.merriweather(
                            color: Colors.white60,
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),
                    Row(
                      children: [
                        // ... Socials or Org logo ...
                        Expanded(child: _buildSocialLinksRow()),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Actions Row (Connect / Message) - Left Aligned & Elegant
          if (widget.userId != _supabase.auth.currentUser?.id)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Wrap(
                spacing: 12,
                runSpacing: 8,
                alignment: WrapAlignment.start,
                children: [
                  // Connect Button
                  _connectionStatus == 'accepted'
                      ? _buildHeaderActionButton(
                          icon: Icons.check,
                          label: 'Connected',
                          onPressed: null,
                          isOutlined: true,
                        )
                      : _buildHeaderActionButton(
                          label: _connectionStatus == 'pending'
                              ? 'Pending'
                              : 'Connect',
                          onPressed: _connectionStatus == 'pending'
                              ? null
                              : _handleConnect,
                          isOutlined: false,
                        ),
                  // Message Button
                  _buildHeaderActionButton(
                    icon: Icons.chat_bubble_outline,
                    label: 'Message',
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ChatScreen(
                            targetUserId: widget.userId,
                            targetUserName: _displayName,
                            targetUserAvatar: _displayAvatar,
                          ),
                        ),
                      );
                    },
                    isOutlined: true,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHeaderActionButton({
    required String label,
    required VoidCallback? onPressed,
    required bool isOutlined,
    IconData? icon,
  }) {
    return SizedBox(
      height: 34,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: isOutlined
                  ? Colors.white.withValues(alpha: 0.12)
                  : Colors.white.withValues(alpha: 0.95),
              borderRadius: BorderRadius.circular(10),
              border: isOutlined
                  ? Border.all(color: Colors.white30, width: 1)
                  : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(
                    icon,
                    size: 14,
                    color: isOutlined ? Colors.white : AppTheme.primaryColor,
                  ),
                  const SizedBox(width: 6),
                ],
                Text(
                  label,
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isOutlined ? Colors.white : AppTheme.primaryColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _checkConnectionStatus() async {
    final status = await _networkRepo.getConnectionStatus(widget.userId);
    if (mounted) setState(() => _connectionStatus = status ?? 'none');
  }

  Future<void> _handleConnect() async {
    if (_connectionStatus != 'none') return;
    setState(() => _connectionStatus = 'pending');
    await _networkRepo.sendConnectionRequest(widget.userId);
    if (mounted)
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Request Sent')));
  }

  Widget _buildSocialLinksRow() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        if (_linkedinUrl != null && _linkedinUrl!.isNotEmpty)
          _buildHeaderSocialIcon(Icons.link, _linkedinUrl!),
        if (_githubUrl != null && _githubUrl!.isNotEmpty)
          _buildHeaderSocialIcon(Icons.code_rounded, _githubUrl!),
        if (_portfolioUrl != null && _portfolioUrl!.isNotEmpty)
          _buildHeaderSocialIcon(Icons.language_rounded, _portfolioUrl!),

        // RESUME LINK
        if (_resumeUrl != null && _resumeUrl!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: InkWell(
              onTap: () => _launchURL(_resumeUrl!),
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.4)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.description_outlined,
                      color: Colors.white,
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      "Resume",
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

        _buildHeaderStat(
          "$_connectionCount ${_connectionCount == 1 ? 'Connection' : 'Connections'}",
          Icons.people_outline,
        ),
      ],
    );
  }

  Widget _buildHeaderSocialIcon(IconData icon, String url) {
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: InkWell(
        onTap: () => _launchURL(url),
        child: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: Colors.white, size: 18),
        ),
      ),
    );
  }

  Widget _buildHeaderStat(String label, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: Colors.white70, size: 16),
        const SizedBox(width: 4),
        Text(
          label,
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildEducationSection() {
    if (_academicHistory.isEmpty) {
      return Text(
        'No education history available.',
        style: GoogleFonts.outfit(color: Colors.grey),
      );
    }
    return Column(
      children: _academicHistory.map((edu) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 20),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.school_rounded, color: Colors.grey),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      edu['institution'] ?? 'N/A',
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      "${edu['degree'] ?? 'N/A'} - ${edu['field'] ?? 'N/A'}",
                      style: GoogleFonts.outfit(color: Colors.grey[700]),
                    ),
                    Text(
                      "${edu['start_year'] ?? 'N/A'} - ${edu['end_year'] ?? 'Present'}",
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                    if (edu['grade'] != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          "Grade: ${edu['grade']}",
                          style: GoogleFonts.outfit(
                            fontWeight: FontWeight.w500,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Future<void> _launchURL(String urlString) async {
    String formattedUrl = urlString;
    if (!formattedUrl.startsWith('http')) {
      formattedUrl = 'https://$formattedUrl';
    }
    final Uri url = Uri.parse(formattedUrl);
    try {
      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
        throw Exception('Could not launch $url');
      }
    } catch (e) {
      debugPrint('Error launching URL: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open link: $urlString')),
        );
      }
    }
  }

  Widget _buildAnalyticsDashboard() {
    if (_skills.isEmpty &&
        _courses.isEmpty &&
        _aptitude.isEmpty &&
        _interviews.isEmpty) {
      return const Center(child: Text('No analytics data available.'));
    }

    final overallSkillScore = _studentStats['skill_score'] ?? 0;

    // Calculate course stats
    final coursesEnrolled = _courses.length;
    final coursesCompleted = _courses
        .where(
          (c) =>
              c['is_completed'] == true ||
              (c['progress_percent'] as num?)?.toDouble() == 100.0,
        )
        .length;
    final coursesInProgress = coursesEnrolled - coursesCompleted;

    // Calculate interview stats
    final interviewsTaken = _interviews.length;
    final gradedInterviews = _interviews
        .where((i) => i['total_score'] != null)
        .toList();
    final avgInterviewScore = gradedInterviews.isEmpty
        ? 0.0
        : gradedInterviews
                  .map((i) => (i['total_score'] as num).toDouble())
                  .reduce((a, b) => a + b) /
              gradedInterviews.length;

    // Calculate aptitude stats
    final excellent = _aptitude
        .where((a) => ((a['percentage'] as num?)?.toDouble() ?? 0) >= 80)
        .length;
    final good = _aptitude.where((a) {
      final score = (a['percentage'] as num?)?.toDouble() ?? 0;
      return score >= 60 && score < 80;
    }).length;
    final needsWork = _aptitude
        .where((a) => ((a['percentage'] as num?)?.toDouble() ?? 0) < 60)
        .length;

    // Theme Colors (Blue-centric)
    final col1 = [Colors.blue.shade700, Colors.blue.shade400];
    final col2 = [Colors.lightBlue.shade700, Colors.lightBlue.shade400];
    final col3 = [Colors.cyan.shade700, Colors.cyan.shade400];
    final col4 = [Colors.teal.shade700, Colors.teal.shade400];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Primary Stat Cards - Unified Horizontal Row
        Row(
          children: [
            Expanded(
              child: _buildGradientStatCard(
                'Overall Score',
                '$overallSkillScore%',
                Icons.auto_graph_rounded,
                col1,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildGradientStatCard(
                _aptitude.length == 1 ? 'Test Taken' : 'Tests Taken',
                '${_aptitude.length}',
                Icons.quiz_rounded,
                col2, // Light Blue
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildGradientStatCard(
                'Courses',
                '$coursesCompleted/$coursesEnrolled',
                Icons.school_rounded,
                col3, // Cyan
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildGradientStatCard(
                interviewsTaken == 1 ? 'Mock Interview' : 'Mock Interviews',
                '$interviewsTaken',
                Icons.video_call_rounded,
                col4, // Teal
              ),
            ),
          ],
        ),
        const SizedBox(height: 32),

        // Course Progress Pie Chart
        if (_courses.isNotEmpty) ...[
          Text(
            'Course Progress',
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          _buildPieChartCard(
            sections: [
              if (coursesCompleted > 0)
                PieChartSectionData(
                  value: coursesCompleted.toDouble(),
                  color: Colors.cyan,
                  title: '$coursesCompleted',
                  radius: 50,
                  titleStyle: GoogleFonts.outfit(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              if (coursesInProgress > 0)
                PieChartSectionData(
                  value: coursesInProgress.toDouble(),
                  color: Colors.lightBlue.shade200,
                  title: '$coursesInProgress',
                  radius: 50,
                  titleStyle: GoogleFonts.outfit(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
            ],
            legendItems: [
              _buildLegendItem(Colors.cyan, 'Completed', '$coursesCompleted'),
              const SizedBox(height: 12),
              _buildLegendItem(
                Colors.lightBlue.shade200,
                'In Progress',
                '$coursesInProgress',
              ),
            ],
          ),
          const SizedBox(height: 40),
        ],

        // Aptitude Progress Pie Chart
        if (_aptitude.isNotEmpty) ...[
          Text(
            'Aptitude Performance',
            style: GoogleFonts.outfit(
              fontSize: 22, // Increased from 18
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          _buildPieChartCard(
            sections: [
              if (excellent > 0)
                PieChartSectionData(
                  value: excellent.toDouble(),
                  color: Colors.blue.shade800,
                  title: '$excellent',
                  radius: 60,
                  titleStyle: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              if (good > 0)
                PieChartSectionData(
                  value: good.toDouble(),
                  color: Colors.blue,
                  title: '$good',
                  radius: 60,
                  titleStyle: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              if (needsWork > 0)
                PieChartSectionData(
                  value: needsWork.toDouble(),
                  color: Colors.blue.shade100,
                  title: '$needsWork',
                  radius: 60,
                  titleStyle: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade900,
                  ),
                ),
            ],
            legendItems: [
              _buildLegendItem(
                Colors.blue.shade800,
                'Excellent (80%+)',
                '$excellent',
              ),
              const SizedBox(height: 12),
              _buildLegendItem(Colors.blue, 'Good (60-79%)', '$good'),
              const SizedBox(height: 12),
              _buildLegendItem(
                Colors.blue.shade100,
                'Needs Work (<60%)',
                '$needsWork',
              ),
            ],
          ),
          const SizedBox(height: 40),
        ],

        // Interview Performance
        if (gradedInterviews.isNotEmpty) ...[
          Text(
            'Interview Performance',
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.white, Colors.teal.shade50],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.teal.shade100),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.teal.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.video_call_rounded,
                    color: Colors.teal,
                    size: 32,
                  ),
                ),
                const SizedBox(width: 24),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Average Score',
                        style: GoogleFonts.outfit(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${avgInterviewScore.toStringAsFixed(1)}%',
                        style: GoogleFonts.outfit(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.teal,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${gradedInterviews.length} of $interviewsTaken graded',
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildPieChartCard({
    required List<PieChartSectionData> sections,
    required List<Widget> legendItems,
  }) {
    return Container(
      padding: const EdgeInsets.all(24),
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
          Expanded(
            flex: 3,
            child: SizedBox(
              height: 130,
              child: PieChart(
                PieChartData(
                  sectionsSpace: 2,
                  centerSpaceRadius: 35,
                  sections: sections,
                ),
              ),
            ),
          ),
          const SizedBox(width: 24),
          Expanded(
            flex: 2,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: legendItems,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGradientStatCard(
    String title,
    String value,
    IconData icon,
    List<Color> colors,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: colors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: colors.first.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: GoogleFonts.outfit(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: GoogleFonts.outfit(
              fontSize: 12,
              color: Colors.white.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label, String value) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey[600]),
          ),
        ),
        Text(
          value,
          style: GoogleFonts.outfit(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildProjectsList() {
    if (_projects.isEmpty) return const Text('No projects available.');

    return SizedBox(
      height: 280,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _projects.length,
        separatorBuilder: (_, __) => const SizedBox(width: 20),
        itemBuilder: (context, index) {
          final project = _projects[index];
          final hasMedia =
              project['media_urls'] != null &&
              (project['media_urls'] as List).isNotEmpty;
          final imageUrl = hasMedia
              ? (project['media_urls'] as List).first
              : null;

          final techStack = project['technologies'] is List
              ? List<String>.from(project['technologies'])
              : <String>[];

          final githubUrl = project['github_url'] as String?;
          final demoUrl = project['project_url'] as String?;

          return Container(
            width: 280,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
              border: Border.all(color: Colors.grey.shade100),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Media / Image Section
                Expanded(
                  flex: 12,
                  child: Container(
                    decoration: BoxDecoration(
                      color: imageUrl != null ? null : Colors.grey[50],
                      gradient: imageUrl != null
                          ? null
                          : LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                _getProjectColor(index).withValues(alpha: 0.1),
                                _getProjectColor(index).withValues(alpha: 0.2),
                              ],
                            ),
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(20),
                      ),
                      image: imageUrl != null
                          ? DecorationImage(
                              image: NetworkImage(imageUrl),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: imageUrl == null
                        ? Center(
                            child: Icon(
                              Icons.folder_open_rounded,
                              color: _getProjectColor(index),
                              size: 40,
                            ),
                          )
                        : null,
                  ),
                ),

                // Content Section
                Expanded(
                  flex: 16,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                project['title'] ?? 'Untitled',
                                style: GoogleFonts.outfit(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: AppTheme.textColor,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            // Link Icons Row
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (githubUrl != null && githubUrl.isNotEmpty)
                                  IconButton(
                                    icon: const Icon(
                                      Icons.code_rounded,
                                      size: 18,
                                    ),
                                    onPressed: () => _launchURL(githubUrl),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                    tooltip: 'GitHub Repo',
                                    color: Colors.grey[700],
                                  ),
                                if (githubUrl != null && demoUrl != null)
                                  const SizedBox(width: 12),
                                if (demoUrl != null && demoUrl.isNotEmpty)
                                  IconButton(
                                    icon: const Icon(
                                      Icons.launch_rounded,
                                      size: 18,
                                    ),
                                    onPressed: () => _launchURL(demoUrl),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                    tooltip: 'Live Demo',
                                    color: AppTheme.primaryColor,
                                  ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),

                        // Tech Stack Chips
                        if (techStack.isNotEmpty) ...[
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: techStack.take(3).map((tech) {
                              return Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryColor.withValues(alpha: 0.05),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  tech,
                                  style: GoogleFonts.outfit(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.primaryColor,
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 10),
                        ],

                        Text(
                          project['description'] ?? 'No description provided.',
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            color: Colors.grey[600],
                            height: 1.4,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Color _getProjectColor(int index) {
    final colors = [
      const Color(0xFF6366F1), // Indigo
      const Color(0xFFEC4899), // Pink
      const Color(0xFF8B5CF6), // Violet
      const Color(0xFFF59E0B), // Amber
      const Color(0xFF10B981), // Emerald
      const Color(0xFF3B82F6), // Blue
    ];
    return colors[index % colors.length];
  }

  Widget _buildRightSidebar() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(4, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Analytics & Performance',
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 24),
          _buildAnalyticsDashboard(),
        ],
      ),
    );
  }

  // Reuse the Grid logic but simplified for list or keeping it as feed

  Widget _buildProfileHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // Avatar
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: AppTheme.primaryColor.withValues(alpha: 0.2),
                width: 2,
              ),
            ),
            child: CircleAvatar(
              key: _displayAvatar != null ? ValueKey(_displayAvatar) : null,
              radius: 50,
              backgroundImage: _displayAvatar != null
                  ? NetworkImage(_displayAvatar!)
                  : null,
              child: _displayAvatar == null
                  ? Text(
                      _displayName.isNotEmpty ? _displayName[0] : '?',
                      style: GoogleFonts.outfit(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  : null,
            ),
          ),
          const SizedBox(height: 16),
          // Name
          Text(
            _displayName,
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          // Role/Tagline
          if (_displayHeadline != null)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(
                _displayHeadline!,
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
            ),

          const SizedBox(height: 24),

          // Stats Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildStatItem(
                _connectionCount == 1 ? 'Connection' : 'Connections',
                '$_connectionCount',
              ), // Real count
              // Removed Views
              if (!(widget.userRole == 'college' ||
                  widget.userRole == 'college_admin'))
                _buildStatItem(
                  _projects.length == 1 ? 'Project' : 'Projects',
                  _projects.length.toString(),
                ),
            ],
          ),

          const SizedBox(height: 24),

          // Actions
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton.icon(
                onPressed: () {}, // Already connected logic to be handled
                icon: const Icon(Icons.check, size: 18),
                label: const Text('Connected'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ChatScreen(
                        targetUserId: widget.userId,
                        targetUserName: _displayName,
                        targetUserAvatar: _displayAvatar,
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.message_rounded, size: 18),
                label: const Text('Message'),
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.outfit(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey[600]),
        ),
      ],
    );
  }

  Widget _buildFeedTab() {
    if (_posts.isEmpty) {
      return _buildEmptyState(
        'No posts yet',
        'User hasn\'t posted anything recently.',
      );
    }

    // Instagram-like Grid
    return GridView.builder(
      padding: const EdgeInsets.all(2),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 200,
        mainAxisSpacing: 2,
        crossAxisSpacing: 2,
        childAspectRatio: 1.0,
      ),
      itemCount: _posts.length,
      itemBuilder: (context, index) {
        final post = _posts[index];
        final hasImages =
            post['image_urls'] != null &&
            (post['image_urls'] as List).isNotEmpty;
        final imageUrl = hasImages ? (post['image_urls'] as List).first : null;

        return InkWell(
          onTap: () => _showPostDetails(post),
          child: Container(
            color: Colors.grey[100],
            child: hasImages
                ? Image.network(
                    imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (ctx, err, stack) => const Center(
                      child: Icon(Icons.broken_image, color: Colors.grey),
                    ),
                  )
                : Center(
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        post['content'] ?? '',
                        maxLines: 5,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.outfit(fontSize: 12),
                      ),
                    ),
                  ),
          ),
        );
      },
    );
  }

  void _showPostDetails(Map<String, dynamic> post) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.8, // Start nearly full screen
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (_, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(0),
                  children: [
                    _buildPostCard(post), // Reuse existing card widget
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEventsTab() {
    if (_events.isEmpty) {
      return _buildEmptyState('No events', 'No upcoming events.');
    }
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 400,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 1.8, // Rectangular cards
      ),
      itemCount: _events.length,
      itemBuilder: (context, index) {
        final event = _events[index];
        final date = event['event_date'] != null
            ? DateTime.parse(event['event_date'])
            : DateTime.now();

        return Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () {
              // Navigation to event details could go here
            },
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Date Box
                  Container(
                    width: 60,
                    height: 70,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '${date.day}',
                          style: GoogleFonts.outfit(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                        Text(
                          _getMonthStr(date.month),
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          event['title'] ?? 'Untitled Event',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.outfit(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(
                              Icons.access_time,
                              size: 14,
                              color: Colors.grey,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              timeago.format(date, allowFromNow: true),
                              style: GoogleFonts.outfit(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            event['status']?.toString().toUpperCase() ??
                                'UPCOMING',
                            style: GoogleFonts.outfit(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStudentsTab() {
    return Column(
      children: [
        // College Statistics Section
        if (_students.isNotEmpty)
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.primaryColor.withValues(alpha: 0.1),
                  AppTheme.primaryColor.withValues(alpha: 0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'College Overview',
                  style: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        'Total Students',
                        '${_students.length}',
                        Icons.people_rounded,
                        Colors.blue,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatCard(
                        'Connections',
                        '$_connectionCount',
                        Icons.link_rounded,
                        Colors.green,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

        // Search Bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search students by name or email...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppTheme.primaryColor),
              ),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16),
            ),
          ),
        ),

        // Results
        Expanded(
          child: _filteredStudents.isEmpty
              ? _buildEmptyState(
                  'No students found',
                  _students.isEmpty
                      ? 'College has no visible students.'
                      : 'No students match your search.',
                )
              : GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 250,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: 0.65, // Adjusted for analytics badges
                  ),
                  itemCount: _filteredStudents.length,
                  itemBuilder: (context, index) {
                    final student = _filteredStudents[index];
                    final name = student['full_name'] ?? 'Student';
                    final headline =
                        student['headline'] ?? 'Seeking Opportunities';
                    // Prioritize profile_photo_url
                    final avatar =
                        student['profile_photo_url'] ?? student['avatar_url'];
                    final studentId = student['id'];

                    return Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircleAvatar(
                              radius: 35,
                              backgroundColor: AppTheme.primaryColor
                                  .withValues(alpha: 0.1),
                              backgroundImage:
                                  avatar != null &&
                                      (avatar as String).isNotEmpty
                                  ? NetworkImage(avatar)
                                  : null,
                              child:
                                  avatar == null || (avatar as String).isEmpty
                                  ? Text(
                                      name.isNotEmpty ? name[0] : '?',
                                      style: GoogleFonts.outfit(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    )
                                  : null,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              name,
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.outfit(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              headline,
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.outfit(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 8),

                            // Analytics Badges
                            FutureBuilder<Map<String, dynamic>>(
                              future: _fetchStudentQuickStats(studentId),
                              builder: (context, snapshot) {
                                if (snapshot.hasData) {
                                  final stats = snapshot.data!;
                                  return Wrap(
                                    alignment: WrapAlignment.center,
                                    spacing: 4,
                                    runSpacing: 4,
                                    children: [
                                      if (stats['skill_score'] != null)
                                        _buildAnalyticsBadge(
                                          Icons.star_rounded,
                                          '${stats['skill_score']}',
                                          Colors.amber,
                                        ),
                                      if (stats['certificates'] != null &&
                                          stats['certificates'] > 0)
                                        _buildAnalyticsBadge(
                                          Icons.workspace_premium_rounded,
                                          '${stats['certificates']}',
                                          Colors.purple,
                                        ),
                                      if (stats['projects'] != null &&
                                          stats['projects'] > 0)
                                        _buildAnalyticsBadge(
                                          Icons.folder_rounded,
                                          '${stats['projects']}',
                                          Colors.blue,
                                        ),
                                    ],
                                  );
                                }
                                return const SizedBox(height: 20);
                              },
                            ),

                            const Spacer(),
                            // Action Buttons
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                // Connect Button (Icon Only)
                                InkWell(
                                  onTap: () async {
                                    if (studentId != null) {
                                      try {
                                        // Just instantiate repo directly for now as per pattern
                                        await NetworkRepository()
                                            .sendConnectionRequest(studentId);
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                'Connection request sent to $name',
                                              ),
                                              backgroundColor: Colors.green,
                                            ),
                                          );
                                        }
                                      } catch (e) {
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                'Failed to send request: $e',
                                              ),
                                              backgroundColor: Colors.red,
                                            ),
                                          );
                                        }
                                      }
                                    }
                                  },
                                  borderRadius: BorderRadius.circular(50),
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: AppTheme.primaryColor.withValues(alpha: 0.4),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.person_add_rounded,
                                      size: 20,
                                      color: AppTheme.primaryColor,
                                    ),
                                  ),
                                ),
                                // Message Button (Icon Only)
                                InkWell(
                                  onTap: () {
                                    // Navigate to chat
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Opening chat...'),
                                      ),
                                    );
                                  },
                                  borderRadius: BorderRadius.circular(50),
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.blue.withValues(alpha: 0.1),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.message_rounded,
                                      size: 20,
                                      color: Colors.blue,
                                    ),
                                  ),
                                ),
                                // View Profile Button
                                InkWell(
                                  onTap: () {
                                    if (studentId != null) {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => NetworkProfileView(
                                            userId: studentId,
                                            userName: name,
                                            userAvatar: avatar,
                                            userRole: 'student',
                                          ),
                                        ),
                                      );
                                    }
                                  },
                                  borderRadius: BorderRadius.circular(50),
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.withValues(alpha: 0.1),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.arrow_forward_rounded,
                                      size: 20,
                                      color: Colors.grey[700],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildSkillsAndInterestsCard() {
    final skills = _studentProfileData?['skills'] ?? _profileData?['skills'];
    final interests =
        _studentProfileData?['interests'] ?? _profileData?['interests'];

    final List<String> skillList = skills is List
        ? skills.map((e) => e.toString()).toList()
        : [];
    final List<String> interestList = interests is List
        ? interests.map((e) => e.toString()).toList()
        : [];

    /*
    if (skillList.isEmpty && interestList.isEmpty) {
      return const SizedBox.shrink();
    }
    */

    return _buildResumeSection(
      'Skills & Interests',
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20), // Increased padding
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min, // Important for layout
          children: [
            if (skillList.isNotEmpty) ...[
              Text(
                'Skills',
                style: GoogleFonts.outfit(
                  fontSize: 16, // Increased
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[700],
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 12), // Increased
              Wrap(
                spacing: 8, // Increased
                runSpacing: 8, // Increased
                children: skillList.take(20).map((skill) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ), // Increased
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(8), // Increased
                      border: Border.all(
                        color: AppTheme.primaryColor.withValues(alpha: 0.1),
                      ),
                    ),
                    child: Text(
                      skill,
                      style: GoogleFonts.outfit(
                        fontSize: 14, // Increased
                        fontWeight: FontWeight.w500,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
            if (skillList.isNotEmpty && interestList.isNotEmpty)
              const SizedBox(height: 24), // Increased
            if (interestList.isNotEmpty) ...[
              Text(
                'Interests',
                style: GoogleFonts.outfit(
                  fontSize: 16, // Increased
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[700],
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 12), // Increased
              Wrap(
                spacing: 8, // Increased
                runSpacing: 8, // Increased
                children: interestList.take(20).map((interest) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ), // Increased
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(8), // Increased
                      border: Border.all(color: Colors.orange.withValues(alpha: 0.1)),
                    ),
                    child: Text(
                      interest,
                      style: GoogleFonts.outfit(
                        fontSize: 14, // Increased
                        fontWeight: FontWeight.w500,
                        color: Colors.orange,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCertificatesList() {
    if (_certificates.isEmpty) {
      return Text(
        'No certificates added.',
        style: GoogleFonts.outfit(color: Colors.grey[500]),
      );
    }
    // Horizontal List
    return SizedBox(
      height: 140, // Height for horizontal cards
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _certificates.length,
        separatorBuilder: (_, __) => const SizedBox(width: 16),
        itemBuilder: (context, index) {
          final cert = _certificates[index];
          final String? link =
              cert['certificate_url'] ?? cert['certificate_file_url'];

          return InkWell(
            onTap: link != null ? () => _launchURL(link) : null,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: 260,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: link != null
                      ? AppTheme.primaryColor.withValues(alpha: 0.2)
                      : Colors.grey.shade200,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.shade100,
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Icon(
                        Icons.workspace_premium,
                        color: AppTheme.primaryColor,
                      ),
                      if (link != null)
                        Icon(
                          Icons.open_in_new_rounded,
                          size: 14,
                          color: AppTheme.primaryColor.withValues(alpha: 0.4),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    cert['certificate_name'] ?? 'Certificate',
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    cert['issuer_name_snapshot'] ?? 'Issuer',
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
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
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                Text(
                  label,
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Helper method to build analytics badges
  Widget _buildAnalyticsBadge(IconData icon, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            value,
            style: GoogleFonts.outfit(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  // Fetch quick stats for a student
  Future<Map<String, dynamic>> _fetchStudentQuickStats(
    String? studentId,
  ) async {
    if (studentId == null) return {};

    try {
      // Fetch skill score
      final statsResponse = await _supabase
          .from('student_stats')
          .select('skill_score')
          .eq('student_id', studentId)
          .maybeSingle();

      // Fetch certificate count
      final certResponse = await _supabase
          .from('student_certifications')
          .select('id')
          .eq('student_id', studentId)
          .eq('validation_status', 'approved');

      // Fetch project count
      final projectResponse = await _supabase
          .from('student_projects')
          .select('id')
          .eq('student_id', studentId);

      return {
        'skill_score': statsResponse?['skill_score'],
        'certificates': (certResponse as List).length,
        'projects': (projectResponse as List).length,
      };
    } catch (e) {
      debugPrint('Error fetching student stats: $e');
      return {};
    }
  }

  String _getMonthStr(int month) {
    const months = [
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
    return months[month - 1];
  }

  Widget _buildProfilePosts() {
    if (_posts.isEmpty) {
      return Text(
        'No posts yet.',
        style: GoogleFonts.outfit(color: Colors.grey[500]),
      );
    }

    // Split posts into two columns for Masonry layout
    final leftPosts = <Map<String, dynamic>>[];
    final rightPosts = <Map<String, dynamic>>[];
    for (int i = 0; i < _posts.length; i++) {
      if (i % 2 == 0) {
        leftPosts.add(_posts[i]);
      } else {
        rightPosts.add(_posts[i]);
      }
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            children: leftPosts.map((post) => _buildPostCard(post)).toList(),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            children: rightPosts.map((post) => _buildPostCard(post)).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildSelectedJobsSection() {
    if (_selectedJobs.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 160,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _selectedJobs.length,
        separatorBuilder: (_, __) => const SizedBox(width: 16),
        itemBuilder: (context, index) {
          final job = _selectedJobs[index]['job'];
          final org = job['organization'];

          return Container(
            width: 280,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.green.shade100),
              boxShadow: [
                BoxShadow(
                  color: Colors.green.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                        image: org != null && org['logo_url'] != null
                            ? DecorationImage(
                                image: NetworkImage(org['logo_url']),
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                      child: org == null || org['logo_url'] == null
                          ? const Icon(Icons.business, color: Colors.grey)
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            job['title'] ?? 'Job Role',
                            style: GoogleFonts.outfit(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            org != null ? org['name'] : 'DeepMind',
                            style: GoogleFonts.outfit(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.green.shade200),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.check_circle,
                        size: 14,
                        color: Colors.green,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Selected',
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildPostCard(Map<String, dynamic> post) {
    bool isLiked = post['is_liked'] ?? false;
    int likeCount = post['like_count'] ?? 0;
    String content = post['content'] ?? '';
    String timeAgo = timeago.format(DateTime.parse(post['created_at']));
    List<dynamic> images = post['image_urls'] ?? [];

    return StatefulBuilder(
      builder: (context, setCardState) {
        return Container(
          margin: const EdgeInsets.only(
            bottom: 16,
          ), // Spacing between masonry items
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min, // Dynamic height!
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Content Area
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          timeAgo,
                          style: GoogleFonts.outfit(
                            fontSize: 10,
                            color: Colors.grey[400],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      content,
                      maxLines: 4, // More generous for masonry
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.outfit(
                        fontSize: 13, // Standard readable size
                        color: Colors.black.withValues(alpha: 0.85),
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),

              // Image Treatment (Cinematic Aspect Ratio)
              if (images.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: AspectRatio(
                    aspectRatio: 16 / 9, // Cinematic look
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(images[0], fit: BoxFit.cover),
                    ),
                  ),
                ),

              if (images.isNotEmpty) const SizedBox(height: 16),

              // Footer
              Container(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    InkWell(
                      onTap: () {
                        setCardState(() {
                          isLiked = !isLiked;
                          likeCount = isLiked
                              ? likeCount + 1
                              : (likeCount > 0 ? likeCount - 1 : 0);
                        });
                      },
                      child: Row(
                        children: [
                          Icon(
                            isLiked ? Icons.favorite : Icons.favorite_border,
                            size: 18,
                            color: isLiked ? Colors.red : Colors.grey[400],
                          ),
                          if (likeCount > 0) ...[
                            const SizedBox(width: 4),
                            Text(
                              '$likeCount',
                              style: GoogleFonts.outfit(
                                fontSize: 12,
                                color: isLiked ? Colors.red : Colors.grey[600],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    InkWell(
                      onTap: () => _showCommentSheet(post),
                      child: Icon(
                        Icons.chat_bubble_outline,
                        size: 18,
                        color: Colors.grey[400],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showCommentSheet(Map<String, dynamic> post) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Comments',
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(24),
                ),
                child: TextField(
                  decoration: const InputDecoration(
                    hintText: 'Write a comment...',
                    border: InputBorder.none,
                    suffixIcon: Icon(Icons.send, color: AppTheme.primaryColor),
                  ),
                  onSubmitted: (val) => Navigator.pop(context),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAboutTab() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Text(
        _profileData?['bio'] ?? 'No bio available.',
        style: GoogleFonts.outfit(
          fontSize: 16,
          height: 1.5,
          color: Colors.grey[800],
        ),
      ),
    );
  }

  Widget _buildEmptyState(String title, String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inbox_rounded, size: 48, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            title,
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          Text(message, style: GoogleFonts.outfit(color: Colors.grey[500])),
        ],
      ),
    );
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar _tabBar;
  _SliverAppBarDelegate(this._tabBar);

  @override
  double get minExtent => _tabBar.preferredSize.height;
  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(color: Colors.white, child: _tabBar);
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return false;
  }
}

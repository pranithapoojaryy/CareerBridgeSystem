import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../../../core/theme/app_theme.dart';
import '../../../jobs/presentation/job_listing_screen.dart';

/// Recruiter Profile View - Displays company-focused profile for recruiters
class RecruiterProfileView extends StatefulWidget {
  final String userId;
  final String userName;
  final String? userAvatar;

  final String? organizationId;

  const RecruiterProfileView({
    super.key,
    this.userId = '',
    this.userName = 'Company',
    this.userAvatar,
    this.organizationId,
  });

  @override
  State<RecruiterProfileView> createState() => _RecruiterProfileViewState();
}

class _RecruiterProfileViewState extends State<RecruiterProfileView>
    with SingleTickerProviderStateMixin {
  final _client = Supabase.instance.client;
  bool _isLoading = true;
  String? _error;
  Map<String, dynamic>? _organization;
  List<Map<String, dynamic>> _jobs = [];
  List<Map<String, dynamic>> _courses = [];
  List<Map<String, dynamic>> _posts = [];
  String? _currentUserRole;

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadRecruiterData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadRecruiterData() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    }
    try {
      // Fetch current user role
      final currentUser = _client.auth.currentUser;
      if (currentUser != null) {
        final currentUserData = await _client
            .from('profiles')
            .select('role')
            .eq('id', currentUser.id)
            .single();
        _currentUserRole = currentUserData['role'] as String?;
      }

      String? orgId = widget.organizationId;
      String lookupUserId = widget.userId;

      // Fetch recruiter profile if no direct orgId provided
      if (orgId == null && lookupUserId.isNotEmpty) {
        final profileData = await _client
            .from('profiles')
            .select('*, organization:organizations(*)')
            .eq('id', lookupUserId)
            .single();

        _organization = profileData['organization'];
        orgId = _organization?['id'];
      } else if (orgId != null) {
        // Fetch organization directly
        final orgData = await _client
            .from('organizations')
            .select('*')
            .eq('id', orgId)
            .single();
        _organization = orgData;

        // If userId is missing, try to find an admin of this organization to show their related content (courses/posts)
        if (lookupUserId.isEmpty) {
          final adminRes = await _client
              .from('profiles')
              .select('id')
              .eq('organization_id', orgId)
              .limit(1)
              .maybeSingle();
          if (adminRes != null) {
            lookupUserId = adminRes['id'];
          }
        }
      }

      if (orgId != null) {
        // Fetch jobs from this organization (wrapped in try-catch)
        try {
          final jobsData = await _client
              .from('jobs')
              .select('*, organization:organizations(name, logo_url)')
              .eq('organization_id', orgId)
              .eq('status', 'open')
              .order('created_at', ascending: false)
              .limit(10);
          _jobs = List<Map<String, dynamic>>.from(jobsData);
        } catch (e) {
          debugPrint('Error fetching jobs: $e');
          _jobs = [];
        }

        // Fetch courses from this recruiter (using learning_courses table)
        try {
          final coursesData = await _client
              .from('learning_courses')
              .select('*')
              .eq('provider_id', lookupUserId)
              .order('created_at', ascending: false)
              .limit(10);
          _courses = List<Map<String, dynamic>>.from(coursesData);
        } catch (e) {
          debugPrint('Error fetching courses: $e');
          _courses = [];
        }

        // Fetch posts from this recruiter (wrapped in try-catch)
        try {
          final postsData = await _client
              .from('posts')
              .select('*')
              .eq('author_id', lookupUserId)
              .order('created_at', ascending: false)
              .limit(5);
          _posts = List<Map<String, dynamic>>.from(postsData);
        } catch (e) {
          debugPrint('Error fetching posts: $e');
          _posts = [];
        }

        if (mounted) {
          setState(() => _isLoading = false);
        }
      } else {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading profile: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 48),
                  const SizedBox(height: 16),
                  Text(
                    'Unable to load profile',
                    style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _error!,
                    style: GoogleFonts.outfit(color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadRecruiterData,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            )
          : CustomScrollView(
              slivers: [
                _buildCompanyHeader(),
                SliverToBoxAdapter(child: _buildTabBar()),
                SliverFillRemaining(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildJobsTab(),
                      _buildCoursesTab(),
                      _buildFeedTab(),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  // Gradient Company Header with Full Company Details
  Widget _buildCompanyHeader() {
    final companyName = _organization?['name'] ?? 'Company';
    final logoUrl = _organization?['logo_url'];
    final description = _organization?['description'] ?? '';
    final tagline = _organization?['tagline'] ?? '';
    final website = _organization?['website'] ?? '';
    final industry = _organization?['industry'] ?? '';
    final companySize = _organization?['company_size'] ?? '';
    final headquarters = _organization?['headquarters'] ?? '';
    final foundedYear = _organization?['established_year'];
    final specialties = _organization?['specialties'] as List<dynamic>?;
    final domains = _organization?['domains'] as List<dynamic>?;

    return SliverToBoxAdapter(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppTheme.primaryColor,
              AppTheme.secondaryColor,
              AppTheme.accentColor.withValues(alpha: 0.8),
            ],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 60, 24, 32),
            child: Column(
              children: [
                // Company Logo
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 20,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: logoUrl != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: Image.network(
                            logoUrl,
                            fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) => Icon(
                              Icons.business,
                              size: 50,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                        )
                      : Icon(
                          Icons.business,
                          size: 50,
                          color: AppTheme.primaryColor,
                        ),
                ),
                const SizedBox(height: 16),

                // Company Name
                Text(
                  companyName,
                  style: GoogleFonts.outfit(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),

                // Tagline
                if (tagline.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    tagline,
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.white.withValues(alpha: 0.9),
                      fontStyle: FontStyle.italic,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],

                const SizedBox(height: 4),

                // Recruiter Badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    'Recruiter',
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),

                if (description.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text(
                    description,
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],

                // Company Details Grid
                const SizedBox(height: 20),
                Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  alignment: WrapAlignment.center,
                  children: [
                    if (industry.isNotEmpty)
                      _buildInfoChip(Icons.business_center, industry),
                    if (companySize.isNotEmpty)
                      _buildInfoChip(Icons.people, companySize),
                    if (headquarters.isNotEmpty)
                      _buildInfoChip(Icons.location_on, headquarters),
                    if (foundedYear != null)
                      _buildInfoChip(
                        Icons.calendar_today,
                        'Founded $foundedYear',
                      ),
                    if (website.isNotEmpty)
                      _buildInfoChip(Icons.language, website),
                  ],
                ),

                // Specialties
                if (specialties != null && specialties.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Specialties',
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.white.withValues(alpha: 0.8),
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: specialties.map((s) {
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                s.toString(),
                                style: GoogleFonts.outfit(
                                  fontSize: 11,
                                  color: Colors.white,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                ],

                // Business Domains
                if (domains != null && domains.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Business Domains',
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.white.withValues(alpha: 0.8),
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: domains.map((d) {
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                d.toString(),
                                style: GoogleFonts.outfit(
                                  fontSize: 11,
                                  color: Colors.white,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.white),
          const SizedBox(width: 6),
          Text(
            text,
            style: GoogleFonts.outfit(fontSize: 12, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: Colors.grey[50],
      child: TabBar(
        controller: _tabController,
        labelColor: AppTheme.primaryColor,
        unselectedLabelColor: Colors.grey,
        indicatorColor: AppTheme.primaryColor,
        indicatorWeight: 3,
        labelStyle: GoogleFonts.outfit(
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
        tabs: [
          Tab(
            icon: const Icon(Icons.work_outline),
            text: 'Jobs (${_jobs.length})',
          ),
          Tab(
            icon: const Icon(Icons.school_outlined),
            text: 'Courses (${_courses.length})',
          ),
          Tab(
            icon: const Icon(Icons.article_outlined),
            text: 'Feed (${_posts.length})',
          ),
        ],
      ),
    );
  }

  Widget _buildJobsTab() {
    if (_jobs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.work_off, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              'No Active Job Postings',
              style: GoogleFonts.outfit(
                fontSize: 18,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(24),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 400,
        mainAxisExtent: 320,
        crossAxisSpacing: 24,
        mainAxisSpacing: 24,
      ),
      itemCount: _jobs.length,
      itemBuilder: (context, index) {
        final job = _jobs[index];
        return _buildJobCard(job);
      },
    );
  }

  Widget _buildJobCard(Map<String, dynamic> job) {
    final title = job['title'] ?? 'Untitled Job';
    final location = job['location'] ?? 'Not specified';
    final jobType = job['job_type'] ?? 'Full-time';
    final status = job['status'] ?? 'open';
    final statusColor = status == 'open'
        ? Colors.green
        : (status == 'closed' ? Colors.red : Colors.grey);
    final date = DateTime.tryParse(job['created_at'] ?? '') ?? DateTime.now();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Status Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(12),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  status.toUpperCase(),
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                    fontSize: 12,
                  ),
                ),
                Icon(Icons.more_horiz, size: 20, color: statusColor),
              ],
            ),
          ),

          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 16),

                  // Form-like Fields
                  _buildJobGridField('Location', location),
                  const SizedBox(height: 8),
                  _buildJobGridField('Type', jobType),
                  const SizedBox(height: 8),
                  _buildJobGridField(
                    'Posted On',
                    DateFormat('MMM d, yyyy').format(date),
                  ),

                  const Spacer(),
                ],
              ),
            ),
          ),

          // Footer with Apply Button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _currentUserRole == 'college_admin'
                    ? null // Disable for college admins
                    : () {
                        // Redirect students to job listing screen
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const JobListingScreen(),
                          ),
                        );
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.grey.shade200,
                  disabledForegroundColor: Colors.grey.shade500,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: _currentUserRole == 'college_admin' ? 0 : 2,
                ),
                child: Text(
                  _currentUserRole == 'college_admin'
                      ? 'Apply (Student Only)'
                      : 'Apply Now',
                  style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildJobGridField(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Text(
            '$label:',
            style: GoogleFonts.outfit(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.outfit(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCoursesTab() {
    if (_courses.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.school_outlined, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              'No Courses Available',
              style: GoogleFonts.outfit(
                fontSize: 18,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    // Responsive grid for courses - match login page design
    final screenWidth = MediaQuery.of(context).size.width;
    int crossAxisCount = 5; // Default for very wide screens
    if (screenWidth < 600) {
      crossAxisCount = 1;
    } else if (screenWidth < 900) {
      crossAxisCount = 2;
    } else if (screenWidth < 1200) {
      crossAxisCount = 3;
    } else if (screenWidth < 1600) {
      crossAxisCount = 4;
    }

    return GridView.builder(
      padding: const EdgeInsets.all(24),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        childAspectRatio: 0.8, // Taller cards like login page
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: _courses.length,
      itemBuilder: (context, index) {
        final course = _courses[index];
        return _buildCourseCard(course, index);
      },
    );
  }

  Widget _buildCourseCard(Map<String, dynamic> course, int index) {
    final title = course['title'] ?? 'Untitled Course';
    final category = course['category'] ?? 'General';
    final duration = course['estimated_duration_weeks'] != null
        ? '${course['estimated_duration_weeks']} weeks'
        : 'Self-paced';

    // Generate a consistent color based on the course title
    final List<Color> cardColors = [
      const Color(0xFF6C63FF), // Purple
      const Color(0xFFFF6584), // Pink
      const Color(0xFF3B82F6), // Blue
      const Color(0xFF10B981), // Emerald
      const Color(0xFFF59E0B), // Amber
      const Color(0xFF8B5CF6), // Violet
      const Color(0xFFEC4899), // Rose
      const Color(0xFF0EA5E9), // Sky
    ];
    final colorIndex = title.length % cardColors.length;
    final themeColor = cardColors[colorIndex];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: themeColor.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Thumbnail with gradient
          Expanded(
            flex: 3,
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [themeColor.withValues(alpha: 0.8), themeColor],
                      ),
                    ),
                    child: Stack(
                      children: [
                        Positioned(
                          right: -15,
                          bottom: -15,
                          child: Icon(
                            Icons.school_rounded,
                            size: 80, // Smaller background icon
                            color: Colors.white.withValues(alpha: 0.1),
                          ),
                        ),
                        Center(
                          child: Icon(
                            Icons.auto_stories_rounded,
                            size: 32, // Smaller main icon
                            color: Colors.white.withValues(alpha: 0.95),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Badge
                  if (index % 3 == 0)
                    Positioned(
                      top: 12,
                      right: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Text(
                          'FEATURED',
                          style: GoogleFonts.outfit(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // Content
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: themeColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          category.toUpperCase(),
                          style: GoogleFonts.outfit(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: themeColor,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.outfit(
                          fontWeight: FontWeight.bold,
                          fontSize: 14, // Smaller title
                          height: 1.2,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Icon(
                        Icons.access_time_filled_rounded,
                        size: 16,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(width: 6),
                      Text(
                        duration,
                        style: GoogleFonts.outfit(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey[500],
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
    );
  }

  Widget _buildFeedTab() {
    if (_posts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.article_outlined, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              'No Posts Yet',
              style: GoogleFonts.outfit(
                fontSize: 18,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    // Responsive grid for posts
    final screenWidth = MediaQuery.of(context).size.width;
    int crossAxisCount = 3; // Default for wide screens
    if (screenWidth < 700) {
      crossAxisCount = 1;
    } else if (screenWidth < 1100) {
      crossAxisCount = 2;
    }

    return GridView.builder(
      padding: const EdgeInsets.all(24),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        childAspectRatio: 0.9, // Balanced for text + optional image
        crossAxisSpacing: 24,
        mainAxisSpacing: 24,
      ),
      itemCount: _posts.length,
      itemBuilder: (context, index) {
        final post = _posts[index];
        return _buildPostCard(post);
      },
    );
  }

  Widget _buildPostCard(Map<String, dynamic> post) {
    final content = post['content'] ?? '';
    final date = DateTime.tryParse(post['created_at'] ?? '') ?? DateTime.now();
    final companyName = _organization?['name'] ?? widget.userName;
    final companyLogo = _organization?['logo_url'];

    // Get first image from image_urls array if it exists
    String? imageUrl;
    if (post['image_urls'] != null &&
        post['image_urls'] is List &&
        (post['image_urls'] as List).isNotEmpty) {
      imageUrl = (post['image_urls'] as List).first.toString();
    }

    return Container(
      padding: const EdgeInsets.all(12), // Tighter padding
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with Avatar and Name
          Row(
            children: [
              CircleAvatar(
                radius: 16, // Smaller avatar
                backgroundColor: Colors.green.withValues(alpha: 0.1),
                backgroundImage: companyLogo != null && companyLogo.isNotEmpty
                    ? NetworkImage(companyLogo)
                    : null,
                child: (companyLogo == null || companyLogo.isEmpty)
                    ? const Icon(
                        Icons.business_center_rounded,
                        color: Colors.green,
                        size: 16, // Smaller icon
                      )
                    : null,
              ),
              const SizedBox(width: 8), // Tighter spacing
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            companyName,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.outfit(
                              fontSize: 13, // Smaller name
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                        const SizedBox(width: 2), // Tighter spacing
                        const Icon(
                          Icons.verified,
                          size: 12, // Smaller icon
                          color: Colors.blue,
                        ),
                      ],
                    ),
                    Text(
                      'Recruiter',
                      style: GoogleFonts.outfit(
                        fontSize: 9, // Smaller subtitle
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                timeago.format(date, locale: 'en_short'),
                style: GoogleFonts.outfit(fontSize: 10, color: Colors.black45),
              ),
            ],
          ),

          const SizedBox(height: 8), // Tighter spacing
          // Post Content
          Text(
            content,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.outfit(
              fontSize: 13, // Smaller content
              color: Colors.black87,
              height: 1.4,
            ),
          ),

          // Post Image (if present)
          if (imageUrl != null && imageUrl.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: double.infinity,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: AspectRatio(
                  aspectRatio: 4 / 3,
                  child: Image.network(
                    imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.grey[200],
                        child: const Center(
                          child: Icon(Icons.broken_image, color: Colors.grey),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),

          // Action Buttons (Like/Comment)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Row(
              children: [
                const Icon(
                  Icons.thumb_up_alt_outlined,
                  size: 16,
                  color: Colors.grey,
                ),
                const SizedBox(width: 4),
                Text(
                  'Like',
                  style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(width: 24),
                const Icon(
                  Icons.comment_outlined,
                  size: 16,
                  color: Colors.grey,
                ),
                const SizedBox(width: 4),
                Text(
                  'Comment',
                  style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

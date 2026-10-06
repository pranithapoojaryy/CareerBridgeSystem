import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:url_launcher/url_launcher.dart'; // For social links
import 'package:flutter_animate/flutter_animate.dart'; // Import flutter_animate
import '../../../../core/theme/app_theme.dart';
import '../../../../features/networking/presentation/screens/network_profile_view.dart';

// ... (previous code)

/// Public College Profile View - Displays college-focused profile for external users
class CollegePublicProfileScreen extends ConsumerStatefulWidget {
  final String userId; // Can be college_admin ID
  final String? organizationId; // Or directly the Org ID
  final String? userName;
  final String? userAvatar;

  const CollegePublicProfileScreen({
    super.key,
    this.userId = '',
    this.organizationId,
    this.userName,
    this.userAvatar,
  });

  @override
  ConsumerState<CollegePublicProfileScreen> createState() =>
      _CollegePublicProfileScreenState();
}

class _CollegePublicProfileScreenState
    extends ConsumerState<CollegePublicProfileScreen>
    with TickerProviderStateMixin {
  final _client = Supabase.instance.client;
  bool _isLoading = true;
  String? _error;

  Map<String, dynamic>? _organization;
  List<Map<String, dynamic>> _posts = [];
  List<Map<String, dynamic>> _courses = [];
  List<Map<String, dynamic>> _students = [];
  List<Map<String, dynamic>> _network = []; // Connected Recruiters

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadCollegeData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadCollegeData() async {
    if (mounted) setState(() => _isLoading = true);

    try {
      String? orgId = widget.organizationId;
      String? adminId = widget.userId.isNotEmpty ? widget.userId : null;

      // 1. Resolve Organization ID if missing
      if (orgId == null && adminId != null) {
        final profile = await _client
            .from('profiles')
            .select('organization_id')
            .eq('id', adminId)
            .maybeSingle();
        orgId = profile?['organization_id'];
      }

      if (orgId == null) {
        throw Exception('Organization not found');
      }

      // 2. Fetch Organization Details
      final orgData = await _client
          .from('organizations')
          .select('*')
          .eq('id', orgId)
          .single();

      _organization = orgData;

      // 3. Fetch Posts (Authored by any admin of this college)
      try {
        final postsData = await _client
            .from('posts')
            .select(
              '*, author:profiles!inner(organization_id, role, full_name, avatar_url)',
            )
            .eq('author.organization_id', orgId)
            .order('created_at', ascending: false)
            .limit(20);

        _posts = List<Map<String, dynamic>>.from(postsData);
      } catch (e) {
        debugPrint('Error fetching posts: $e');
      }

      // 4. Fetch Courses (Provider ID could be Org ID OR Admin ID)
      try {
        final admins = await _client
            .from('profiles')
            .select('id')
            .eq('organization_id', orgId)
            .inFilter('role', ['college_admin', 'admin']);

        final List<String> providerIds = (admins as List)
            .map((e) => e['id'] as String)
            .toList();
        providerIds.add(orgId); // Add Org ID itself as a provider

        if (providerIds.isNotEmpty) {
          final coursesData = await _client
              .from('learning_courses')
              .select('*')
              .inFilter('provider_id', providerIds)
              .eq('is_published', true) // Only published courses
              .order('created_at', ascending: false)
              .limit(20);
          _courses = List<Map<String, dynamic>>.from(coursesData);
        }
      } catch (e) {
        debugPrint('Error fetching courses: $e');
      }

      // 5. Fetch Students (Grid View Data)
      try {
        final studentsData = await _client
            .from('profiles')
            .select(
              'id, full_name, headline, avatar_url, profile_photo_url, role, email, linkedin_url, github_url, portfolio_url',
            ) // Explicitly fetch contact info
            .eq('organization_id', orgId)
            .eq('role', 'student')
            .order('updated_at', ascending: false)
            .limit(50);
        _students = List<Map<String, dynamic>>.from(studentsData);
      } catch (e) {
        debugPrint('Error fetching students: $e');
      }

      // 6. Fetch Network (Recruiters)
      try {
        final orgId = widget.organizationId ?? _organization?['id'];

        if (orgId != null) {
          // A. Identify College Admin Profiles
          final admins = await _client
              .from('profiles')
              .select('id')
              .eq('organization_id', orgId);

          final adminIds = (admins as List)
              .map((e) => e['id'] as String)
              .toList();

          if (adminIds.isNotEmpty) {
            // Robust connection search
            final adminIdsStr = adminIds.join(',');
            final connections = await _client
                .from('connections')
                .select('requester_id, receiver_id')
                .eq('status', 'accepted')
                .or(
                  'requester_id.in.($adminIdsStr),receiver_id.in.($adminIdsStr)',
                );

            final connectedUserIds = <String>{};
            for (var c in connections) {
              final req = c['requester_id'] as String;
              final rec = c['receiver_id'] as String;
              if (!adminIds.contains(req)) connectedUserIds.add(req);
              if (!adminIds.contains(rec)) connectedUserIds.add(rec);
            }

            if (connectedUserIds.isNotEmpty) {
              // B. Fetch Profiles
              final networkData = await _client
                  .from('profiles')
                  .select('*, organizations(*)')
                  .inFilter('id', connectedUserIds.toList())
                  .eq('role', 'recruiter');

              _network = List<Map<String, dynamic>>.from(networkData);

              // C. Hiring Bar Analytics
              // 1. Get all students of this college
              try {
                // 1. Fetch placement analytics via secure RPC (bypasses RLS)
                final List<dynamic> stats = await _client.rpc(
                  'get_college_placements',
                  params: {'p_college_id': orgId},
                );

                // 2. Map results
                Map<String, int> orgHires = {};
                int maxHires = 1;

                if (stats.isNotEmpty) {
                  for (var item in stats) {
                    final orgId = item['organization_id'] as String?;
                    final count = item['hire_count'] as int?;
                    if (orgId != null && count != null) {
                      orgHires[orgId] = count;
                    }
                  }

                  if (orgHires.isNotEmpty) {
                    maxHires = orgHires.values.reduce((a, b) => a > b ? a : b);
                    if (maxHires == 0) maxHires = 1;
                  }
                }

                // 3. Assign stats to recruiters
                for (var recruiter in _network) {
                  final recOrgId = recruiter['organizations']?['id'];
                  final hires = orgHires[recOrgId] ?? 0;
                  recruiter['hires_count'] = hires;
                  recruiter['hires_percentage'] = (hires / maxHires).clamp(
                    0.0,
                    1.0,
                  );
                }
              } catch (e) {
                debugPrint('Error fetching analytics: $e');
                // Do not fail the whole network load, just leave stats as 0
              }

              // 3. Assign stats
              for (var recruiter in _network) {
                // Active Jobs
                try {
                  final countRes = await _client
                      .from('jobs')
                      .count(CountOption.exact)
                      .eq('author_id', recruiter['id'])
                      .eq('status', 'open');
                  recruiter['active_jobs_count'] = countRes;
                } catch (e) {
                  recruiter['active_jobs_count'] = 0;
                }

                // Hiring Bar (assigned above in try block or default 0)
                // final hires = orgHires[recOrgId] ?? 0; // Moved logic inside try block
                // recruiter['hires_count'] = hires;
                // recruiter['hires_percentage'] = (hires / maxHires).clamp(0.0, 1.0);
              }
            } else {
              _network = [];
            }
          }
        }
      } catch (e) {
        debugPrint('Error fetching network: $e');
        _network = [];
      }
      if (mounted) setState(() => _isLoading = false);
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = e.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null || _organization == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: Center(child: Text('Failed to load profile: $_error')),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: CustomScrollView(
        slivers: [
          _buildSliverHeader(),
          SliverPersistentHeader(
            pinned: true,
            delegate: _SliverAppBarDelegate(
              TabBar(
                controller: _tabController,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.grey[600],
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                indicator: BoxDecoration(
                  borderRadius: BorderRadius.circular(50),
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.primaryColor,
                      AppTheme.primaryColor.withValues(alpha: 0.8),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryColor.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                labelStyle: GoogleFonts.outfit(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                tabs: const [
                  Tab(text: 'POSTS'),
                  Tab(text: 'COURSES'),
                  Tab(text: 'STUDENTS'),
                  Tab(text: 'NETWORK'),
                ],
              ),
            ),
          ),
          SliverFillRemaining(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildPostsTab(), // Compact 4-Column
                _buildCoursesTab(), // Colorful 4-Column
                _buildStudentsTab(), // Refined Student Cards
                _buildNetworkTab(), // Compact 3-Column
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliverHeader() {
    final org = _organization!;
    final bannerUrl = org['banner_url'];
    final logoUrl = org['logo_url'];
    final name = org['name'] ?? 'College Name';
    final tagline = org['tagline'] ?? '';
    final location = org['headquarters'] ?? 'Location Unknown';
    final website = org['website'];
    final bool hasTagline = tagline is String && tagline.isNotEmpty;

    return SliverLayoutBuilder(
      builder: (context, constraints) {
        final isMobile = MediaQuery.of(context).size.width < 600;
        final expandedHeight = isMobile ? 340.0 : 380.0;

        return SliverAppBar(
          expandedHeight: expandedHeight,
          pinned: true,
          backgroundColor: AppTheme.primaryColor,
          iconTheme: const IconThemeData(color: Colors.white),
          flexibleSpace: FlexibleSpaceBar(
            background: Stack(
              fit: StackFit.expand,
              children: [
                // 1. Parallax Banner with Gradient Overlay
                if (bannerUrl != null)
                  Image.network(
                    bannerUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        Container(decoration: AppTheme.gradientBackground),
                  )
                else
                  Container(decoration: AppTheme.gradientBackground),

                // Gradient Overlay for readability
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.1),
                        Colors.black.withValues(alpha: 0.6),
                      ],
                    ),
                  ),
                ),

                // 2. Glassmorphic Profile Info Card
                Positioned(
                  bottom: 20,
                  left: isMobile ? 16 : 40,
                  right: isMobile ? 16 : 40,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: BackdropFilter(
                      filter:
                          // ignore: unnecessary_null_comparison
                          (bannerUrl !=
                              null) // Only blur if there is an image behind
                          ? (const ColorFilter.mode(
                                  Colors.transparent,
                                  BlendMode.srcOver,
                                )
                                as dynamic) // Placeholder if needed or use ImageFilter.blur
                          : null,
                      // Actually, Flutter's BackdropFilter takes an ImageFilter. Using explicit blur:
                      // filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      // waiting for import. For now, using a semi-transparent container fallback if import missing
                      child: Container(
                        padding: EdgeInsets.all(isMobile ? 16 : 24),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.1), // Glass effect
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.2),
                          ),
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Colors.white.withValues(alpha: 0.2),
                              Colors.white.withValues(alpha: 0.05),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          crossAxisAlignment: isMobile
                              ? CrossAxisAlignment.start
                              : CrossAxisAlignment.center,
                          children: [
                            // Logo
                            Container(
                              width: isMobile ? 60 : 80,
                              height: isMobile ? 60 : 80,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.1),
                                    blurRadius: 10,
                                  ),
                                ],
                                image: logoUrl != null
                                    ? DecorationImage(
                                        image: NetworkImage(logoUrl),
                                        fit: BoxFit.contain,
                                      )
                                    : null,
                              ),
                              child: logoUrl == null
                                  ? Icon(
                                      Icons.school_rounded,
                                      size: isMobile ? 30 : 40,
                                      color: AppTheme.primaryColor,
                                    )
                                  : null,
                            ),
                            SizedBox(width: isMobile ? 16 : 24),

                            // Text Info
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    name,
                                    style: GoogleFonts.outfit(
                                      color: Colors.white,
                                      fontSize: isMobile
                                          ? 22
                                          : 32, // Responsive Font
                                      fontWeight: FontWeight.bold,
                                      height: 1.1,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  if (hasTagline) ...[
                                    Text(
                                      tagline,
                                      style: GoogleFonts.outfit(
                                        color: Colors.white.withValues(alpha: 0.9),
                                        fontSize: isMobile ? 13 : 16,
                                        fontWeight: FontWeight.w400,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                  const SizedBox(height: 12),

                                  // Chips Row
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: [
                                      if (location != 'Location Unknown')
                                        _buildGlassChip(
                                          location,
                                          Icons.location_on_rounded,
                                        ),
                                      if (website != null)
                                        InkWell(
                                          onTap: () => _launchURL(website),
                                          child: _buildGlassChip(
                                            'Visit Website',
                                            Icons.link_rounded,
                                            isLink: true,
                                          ),
                                        ),
                                    ],
                                  ),
                                ],
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
          ),
        );
      },
    );
  }

  Widget _buildGlassChip(String label, IconData icon, {bool isLink = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isLink
            ? AppTheme.primaryColor.withValues(alpha: 0.8) // Highlight link
            : Colors.black.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 12),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.outfit(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (isLink) ...[
            const SizedBox(width: 4),
            const Icon(
              Icons.arrow_outward_rounded,
              color: Colors.white,
              size: 10,
            ),
          ],
        ],
      ),
    );
  }

  // --- TABS (Updated Design) ---

  Widget _buildPostsTab() {
    if (_posts.isEmpty) return _buildEmptyState('No updates.');
    final width = MediaQuery.of(context).size.width;
    final isMobile = width < 600;

    // Responsive Columns: 1 for Mobile, 2 for Tablet, 4 for Desktop
    final crossAxisCount = isMobile ? 1 : (width < 900 ? 2 : 4);

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: isMobile ? 1.5 : 1.0, // Wider cards on mobile
      ),
      itemCount: _posts.length,
      itemBuilder: (context, index) =>
          _buildCompactPostCard(_posts[index], index)
              .animate()
              .fadeIn(duration: 600.ms, delay: (50 * index).ms)
              .slideY(begin: 0.2, end: 0, curve: Curves.easeOutQuad),
    );
  }

  Widget _buildCompactPostCard(Map<String, dynamic> post, int index) {
    final content = post['content'] ?? '';
    final images = post['image_urls'];
    DateTime date = DateTime.now();
    if (post['created_at'] != null) {
      date = DateTime.tryParse(post['created_at'].toString()) ?? DateTime.now();
    }

    String? imageUrl;
    if (images is List && images.isNotEmpty && images[0] is String) {
      imageUrl = images[0] as String;
    }

    // Text-Only Post: "Login Page Style"
    // Clean, Centered, Typographic
    if (imageUrl == null) {
      return Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryColor.withValues(alpha: 0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.format_quote_rounded,
              color: AppTheme.primaryColor.withValues(alpha: 0.2),
              size: 28,
            ),
            const SizedBox(height: 8),
            Expanded(
              child: Center(
                child: Text(
                  content,
                  maxLines: 5,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.w600,
                    fontSize: 13, // Scaled down font
                    color: Colors.black87,
                    height: 1.3,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              timeago.format(date),
              style: GoogleFonts.outfit(color: Colors.grey[400], fontSize: 10),
            ),
          ],
        ),
      );
    }

    // Image Post: Full bleed image with overlay gradient
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.network(imageUrl, fit: BoxFit.cover),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, Colors.black.withValues(alpha: 0.7)],
                stops: const [0.6, 1.0],
              ),
            ),
          ),
          Positioned(
            bottom: 12,
            left: 12,
            right: 12,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  content,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
                Text(
                  timeago.format(date),
                  style: GoogleFonts.outfit(
                    color: Colors.white70,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCoursesTab() {
    // ignore: unnecessary_null_comparison
    if (_courses == null || _courses.isEmpty)
      return _buildEmptyState('No courses available.');

    final width = MediaQuery.of(context).size.width;
    final isMobile = width < 600;

    // Responsive Columns: 1 for Mobile, 2 for Tablet, 4 for Desktop
    final crossAxisCount = isMobile ? 1 : (width < 900 ? 2 : 4);

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: isMobile ? 1.8 : 0.9, // Wider on mobile
      ),
      itemCount: _courses.length,
      itemBuilder: (context, index) =>
          _buildColorfulCourseCard(_courses[index], index)
              .animate()
              .fadeIn(duration: 600.ms, delay: (50 * index).ms)
              .slideY(begin: 0.2, end: 0, curve: Curves.easeOutQuad),
    );
  }

  Widget _buildColorfulCourseCard(Map<String, dynamic> course, int index) {
    // Palette from reference (Orange, Pink, etc.)
    final bgColors = [
      const Color(0xFFFFA726), // Orange
      const Color(0xFFEC407A), // Pink
      const Color(0xFFAB47BC), // Purple
      const Color(0xFF26A69A), // Teal
      const Color(0xFFEF5350), // Red
      const Color(0xFF42A5F5), // Blue
    ];
    final color = bgColors[index % bgColors.length];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20), // More rounded like reference
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // Top Color Section (Reference: ~65% height)
          Expanded(
            flex: 65,
            child: Container(
              color: color,
              width: double.infinity,
              child: Stack(
                children: [
                  Center(
                    child: Icon(
                      Icons.menu_book_rounded,
                      color: Colors.white.withValues(alpha: 0.9),
                      size: 40,
                    ),
                  ),
                  Positioned(
                    right: -10,
                    bottom: -10,
                    child: Icon(
                      Icons.school,
                      size: 80,
                      color: Colors.white.withValues(alpha: 0.1),
                    ),
                  ),
                  if (index % 3 == 0) // Dummy "Featured" tag
                    Positioned(
                      top: 10,
                      right: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black26,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'FEATURED',
                          style: GoogleFonts.outfit(
                            color: Colors.white,
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          // Bottom White Section (Reference: ~35% height)
          Expanded(
            flex: 35,
            child: Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              alignment: Alignment.centerLeft,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Tag
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'COURSE',
                      style: GoogleFonts.outfit(
                        color: color,
                        fontSize: 8,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    course['title'] ?? 'Course Title',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      height: 1.1,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _launchURL(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url)) {
      debugPrint('Could not launch \$url');
    }
  }

  Widget _buildStudentsTab() {
    // ignore: unnecessary_null_comparison
    if (_students == null || _students.isEmpty)
      return _buildEmptyState('No public students.');

    final width = MediaQuery.of(context).size.width;
    final isMobile = width < 600;

    // Responsive Columns: 2 for Mobile, 3 for Tablet, 6 for Desktop
    final crossAxisCount = isMobile ? 2 : (width < 1100 ? 3 : 6);

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: isMobile
            ? 0.55
            : 0.7, // Taller on mobile to prevent overflow
      ),
      itemCount: _students.length,
      itemBuilder: (context, index) {
        final student = _students[index];
        final avatar =
            student['profile_photo_url'] ?? student['avatar_url']; // Use latest
        final name = student['full_name'] ?? 'Student';
        final headline = student['headline'] ?? 'Student';
        final userId = student['id'];
        final email = student['email'];
        final linkedin = student['linkedin_url'];
        final github = student['github_url'];
        final portfolio = student['portfolio_url'];

        return GestureDetector(
          onTap: () {
            if (userId != null) {
              _navigateToNetworkProfile(context, userId, name, avatar);
            }
          },
          child: Container(
            clipBehavior: Clip.antiAlias, // Clip for clean rounded corners
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                // 1. Top Zone (Avatar & Background)
                Expanded(
                  flex: 3, // Allocating MORE space for the image
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0F7FF), // Fresh Blueish Tint
                      border: Border(
                        bottom: BorderSide(color: Colors.blue.withValues(alpha: 0.1)),
                      ),
                    ),
                    child: Center(
                      child: CircleAvatar(
                        radius: 54, // INCREASED SIZE per user request
                        backgroundColor: Colors.white,
                        child: CircleAvatar(
                          radius: 51,
                          backgroundColor: const Color(0xFFF0F7FF), // Match BG
                          backgroundImage: avatar != null
                              ? NetworkImage(avatar)
                              : null,
                          child: avatar == null
                              ? Text(
                                  name.isNotEmpty ? name[0] : 'U',
                                  style: GoogleFonts.outfit(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 34,
                                    color: AppTheme.primaryColor,
                                  ),
                                )
                              : null,
                        ),
                      ),
                    ),
                  ),
                ),

                // 2. Bottom Zone (Info & Action)
                Expanded(
                  flex: 4, // More space for content
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 8,
                    ), // Tighter padding
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Name & Headline
                        Flexible(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                name,
                                style: GoogleFonts.outfit(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: Colors.black87,
                                ),
                                textAlign: TextAlign.center,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                headline,
                                style: GoogleFonts.outfit(
                                  fontSize: 10,
                                  color: Colors.grey[600],
                                  height: 1.1,
                                ),
                                textAlign: TextAlign.center,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),

                        // Contact & Socials (Ultra Compact)
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (email != null && email.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 6),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.email_outlined,
                                      size: 14,
                                      color: AppTheme.primaryColor.withValues(alpha: 0.1),
                                    ),
                                    const SizedBox(width: 4),
                                    Flexible(
                                      child: Text(
                                        email,
                                        style: GoogleFonts.outfit(
                                          fontSize: 11.5,
                                          color: AppTheme.primaryColor,
                                          fontWeight: FontWeight.w500,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                            // Social Icons Row
                            if ((linkedin != null && linkedin.isNotEmpty) ||
                                (github != null && github.isNotEmpty) ||
                                (portfolio != null && portfolio.isNotEmpty))
                              Padding(
                                padding: const EdgeInsets.only(bottom: 6),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    if (linkedin != null && linkedin.isNotEmpty)
                                      _buildSocialIcon(Icons.link, linkedin),
                                    if (github != null && github.isNotEmpty)
                                      _buildSocialIcon(Icons.code, github),
                                    if (portfolio != null &&
                                        portfolio.isNotEmpty)
                                      _buildSocialIcon(
                                        Icons.language,
                                        portfolio,
                                      ),
                                  ],
                                ),
                              ),
                          ],
                        ),

                        // View Profile Button
                        if (userId != null)
                          SizedBox(
                            width: double.infinity,
                            height: 28,
                            child: ElevatedButton(
                              onPressed: () => _navigateToNetworkProfile(
                                context,
                                userId,
                                name,
                                avatar,
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primaryColor,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                padding: EdgeInsets.zero,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(6),
                                ),
                              ),
                              child: Text(
                                'View',
                                style: GoogleFonts.outfit(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSocialIcon(IconData icon, String url) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: InkWell(
        onTap: () => _launchURL(url),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(8), // More pudding
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withValues(alpha: 0.08), // Light Blue Background
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            size: 18, // Bigger Icon
            color: AppTheme.primaryColor, // Blue Icon
          ),
        ),
      ),
    );
  }

  void _navigateToNetworkProfile(
    BuildContext context,
    String userId,
    String name,
    String? avatar,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => NetworkProfileView(
          userId: userId,
          userName: name,
          userAvatar: avatar,
          userRole: 'student',
        ),
      ),
    );
  }

  Widget _buildNetworkTab() {
    if (_network.isEmpty) return _buildEmptyState('No public network.');

    final width = MediaQuery.of(context).size.width;
    final isMobile = width < 600;

    // Responsive Columns: 1 for Mobile, 2 for Tablet, 6 for Desktop (matching students)
    // Actually for Network, maybe 1/3/6 is better? Or match students 2/3/6?
    // Let's go with 2 for mobile to match students card style since they are identical cards.
    final crossAxisCount = isMobile ? 2 : (width < 1100 ? 3 : 6);

    // Modern Analytics Cards (6 Columns) - Exact Match to Students
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: isMobile ? 0.55 : 0.7, // Taller on mobile
      ),
      itemCount: _network.length,
      itemBuilder: (context, index) {
        final recruiter = _network[index];
        final organizations = recruiter['organizations'];
        String companyName = 'Unknown';
        String? companyLogo;
        String recruiterName = recruiter['full_name'] ?? 'Recruiter';

        // Robust Avatar Logic
        String? recruiterAvatar = recruiter['profile_photo_url'];
        if (recruiterAvatar == null || recruiterAvatar.isEmpty) {
          recruiterAvatar = recruiter['avatar_url'];
        }

        // Social Links
        final email = recruiter['email'];
        final linkedin = recruiter['linkedin_url'];
        final userId = recruiter['id'];

        if (organizations != null && organizations is Map) {
          companyName = organizations['name'] ?? 'Company';
          companyLogo = organizations['logo_url'];
        }

        // Smart Avatar Logic: Recruiter Photo -> Company Logo -> Initials
        ImageProvider? avatarImage;
        if (recruiterAvatar != null && recruiterAvatar.isNotEmpty) {
          avatarImage = NetworkImage(recruiterAvatar);
        } else if (companyLogo != null && companyLogo.isNotEmpty) {
          avatarImage = NetworkImage(companyLogo);
        }

        return Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              // 1. Top Zone (Avatar & Background)
              Expanded(
                flex: 3,
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0F7FF),
                    border: Border(
                      bottom: BorderSide(color: Colors.blue.withValues(alpha: 0.1)),
                    ),
                  ),
                  child: Center(
                    child: CircleAvatar(
                      radius: 54,
                      backgroundColor: Colors.white,
                      child: CircleAvatar(
                        radius: 51,
                        backgroundColor: const Color(0xFFF0F7FF),
                        backgroundImage: avatarImage,
                        child: avatarImage == null
                            ? Text(
                                recruiterName.isNotEmpty
                                    ? recruiterName[0]
                                    : 'R',
                                style: GoogleFonts.outfit(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 34,
                                  color: AppTheme.primaryColor,
                                ),
                              )
                            : null,
                      ),
                    ),
                  ),
                ),
              ),

              // 2. Bottom Zone (Info, Socials, Action)
              Expanded(
                flex: 4,
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            companyName,
                            style: GoogleFonts.outfit(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: Colors.black87,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          // Recruiter Name Removed as per request
                          // const SizedBox(height: 4),
                          // Text(
                          //   recruiterName,
                          //   style: GoogleFonts.outfit(
                          //     fontSize: 12,
                          //     color: Colors.grey[600],
                          //   ),
                          //   textAlign: TextAlign.center,
                          //   maxLines: 1,
                          //   overflow: TextOverflow.ellipsis,
                          // ),

                          // Hired Students Progress Bar
                          const SizedBox(height: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Students Hired',
                                    style: GoogleFonts.outfit(
                                      fontSize: 11,
                                      color: Colors.grey[600],
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  Text(
                                    '${recruiter['hires_count'] ?? 0}',
                                    style: GoogleFonts.outfit(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: (recruiter['hires_count'] ?? 0) > 0
                                          ? AppTheme.primaryColor
                                          : Colors.grey[500],
                                    ),
                                  ),
                                ],
                              ),

                              ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value:
                                      (recruiter['hires_percentage'] as num?)
                                          ?.toDouble() ??
                                      0.0,
                                  backgroundColor: Colors.grey[100],
                                  valueColor: AlwaysStoppedAnimation(
                                    (recruiter['hires_count'] ?? 0) > 0
                                        ? AppTheme.primaryColor
                                        : Colors.grey[300],
                                  ),
                                  minHeight: 6,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),

                      // Social Icons
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (email != null && email.isNotEmpty)
                            IconButton(
                              icon: const Icon(Icons.email_outlined, size: 16),
                              onPressed: () => _launchURL('mailto:$email'),
                              color: AppTheme.primaryColor,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                          if (linkedin != null && linkedin.isNotEmpty)
                            IconButton(
                              icon: const Icon(Icons.link, size: 16),
                              onPressed: () => _launchURL(linkedin),
                              color: AppTheme.primaryColor,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                        ],
                      ),

                      // View Profile Button
                      SizedBox(
                        width: double.infinity,
                        height: 26,
                        child: ElevatedButton(
                          onPressed: () {
                            if (userId != null) {
                              _navigateToNetworkProfile(
                                context,
                                userId,
                                recruiterName,
                                recruiterAvatar ?? companyLogo,
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryColor,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: EdgeInsets.zero,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                          child: Text(
                            'View',
                            style: GoogleFonts.outfit(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(String msg) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.hourglass_empty, color: Colors.grey[300]),
          const SizedBox(height: 8),
          Text(msg, style: TextStyle(color: Colors.grey[400])),
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
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) => false;
}

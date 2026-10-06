import 'package:fl_chart/fl_chart.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../../../core/theme/app_theme.dart';
import '../../../student/data/learning_repository.dart';
import '../../../student/domain/learning_course.dart';
import '../providers/landing_stats_provider.dart';

class PlatformAnalyticsBoard extends ConsumerWidget {
  const PlatformAnalyticsBoard({super.key});

  void _showLoginRequired(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Join the Community',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Log in or Sign up to interact with posts, view full profiles, and access exclusive placement opportunities.',
          style: GoogleFonts.outfit(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Login Now'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(landingStatsProvider);
    final growthAsync = ref.watch(growthStatsProvider);
    final feedAsync = ref.watch(landingFeedProvider);
    final coursesAsync = ref.watch(allCoursesProvider);

    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final isTablet = screenWidth >= 600 && screenWidth < 900;

    return LayoutBuilder(
      builder: (context, boxConstraints) {
        return SingleChildScrollView(
          padding: EdgeInsets.all(isMobile ? 16 : (isTablet ? 32 : 48)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Header
              _buildModernHeader(context, isMobile),

              SizedBox(height: isMobile ? 32 : 64),

              // Analytics Section with Graph
              _buildAnalyticsSection(
                context,
                statsAsync,
                growthAsync,
                isMobile,
              ),

              SizedBox(height: isMobile ? 48 : 80),

              // Available Courses Section
              Text(
                'Top Learning Paths',
                style: GoogleFonts.outfit(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ).animate().fadeIn(delay: 400.ms),
              const SizedBox(height: 24),
              _buildCoursesSection(context, coursesAsync),

              SizedBox(height: isMobile ? 48 : 80),

              // Campus Updates Feed
              Text(
                'Community Buzz',
                style: GoogleFonts.outfit(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ).animate().fadeIn(delay: 500.ms),

              const SizedBox(height: 24),

              _buildFeedContent(
                context,
                feedAsync,
                constraints: boxConstraints,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildModernHeader(BuildContext context, bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(
                  color: AppTheme.primaryColor.withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                        ),
                      )
                      .animate(onPlay: (controller) => controller.repeat())
                      .scale(
                        duration: 1000.ms,
                        begin: const Offset(1, 1),
                        end: const Offset(1.5, 1.5),
                      )
                      .fadeOut(duration: 1000.ms),
                  const SizedBox(width: 8),
                  Text(
                    'Live Analytics',
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          'CareerBridge Insights',
          style: GoogleFonts.outfit(
            fontSize: isMobile ? 32 : 48,
            fontWeight: FontWeight.w900,
            color: Colors.black87,
            letterSpacing: -1,
            height: 1,
          ),
        ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.2, end: 0),
        const SizedBox(height: 12),
        Text(
          'Visualizing the bridge between education and industry.',
          style: GoogleFonts.outfit(
            fontSize: isMobile ? 16 : 20,
            color: Colors.black54,
            fontWeight: FontWeight.w400,
          ),
        ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2, end: 0),
      ],
    );
  }

  Widget _buildAnalyticsSection(
    BuildContext context,
    AsyncValue<Map<String, int>> statsAsync,
    AsyncValue<List<Map<String, dynamic>>> growthAsync,
    bool isMobile,
  ) {
    return Column(
      children: [
        growthAsync.when(
          data: (growthData) => statsAsync.when(
            data: (stats) =>
                _buildFunAnalyticsBoard(context, stats, growthData, isMobile),
            loading: () => const _LoadingPlaceholder(height: 400),
            error: (_, __) => const SizedBox.shrink(),
          ),
          loading: () => const _LoadingPlaceholder(height: 400),
          error: (_, __) => const SizedBox.shrink(),
        ),
      ],
    );
  }

  Widget _buildFunAnalyticsBoard(
    BuildContext context,
    Map<String, int> stats,
    List<Map<String, dynamic>> growthData,
    bool isMobile,
  ) {
    return Column(
      children: [
        _buildAnalyticsGraph(context, stats, growthData),
        const SizedBox(height: 40),
        _buildStatsRow(context, stats),
      ],
    );
  }

  Widget _buildCoursesSection(
    BuildContext context,
    AsyncValue<List<LearningCourse>> coursesAsync,
  ) {
    return coursesAsync.when(
      data: (courses) {
        if (courses.isEmpty) {
          return const Text('No courses available yet.');
        }

        final screenWidth = MediaQuery.of(context).size.width;

        // Responsive Grid Logic
        int crossAxisCount;
        if (screenWidth > 1200) {
          crossAxisCount = 4;
        } else if (screenWidth > 800) {
          crossAxisCount = 3;
        } else if (screenWidth > 600) {
          crossAxisCount = 2;
        } else {
          crossAxisCount = 1;
        }

        // Limit to 8 courses max for the dashboard view
        final displayCourses = courses.take(8).toList();

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            childAspectRatio: 0.8, // Taller cards to prevent overflow
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          itemCount: displayCourses.length,
          itemBuilder: (context, index) {
            final course = displayCourses[index];
            return _buildCourseCard(context, course, index * 100);
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Text('Detailed Error: $err'),
    );
  }

  Widget _buildCourseCard(
    BuildContext context,
    LearningCourse course,
    int delayMs,
  ) {
    // Generate a consistent color based on the course title length
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
    final colorIndex = course.title.length % cardColors.length;
    final themeColor = cardColors[colorIndex];

    return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: themeColor.withValues(alpha: 0.15),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Thumbnail / Placeholder
              Expanded(
                flex: 3,
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(20),
                  ),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (course.thumbnailAsset.isNotEmpty)
                        Image.network(
                          course.thumbnailAsset,
                          fit: BoxFit.cover,
                          errorBuilder: (ctx, err, stack) => Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  themeColor.withValues(alpha: 0.8),
                                  themeColor,
                                ],
                              ),
                            ),
                            child: Center(
                              child: Icon(
                                Icons.school_rounded,
                                size: 48,
                                color: Colors.white.withValues(alpha: 0.9),
                              ),
                            ),
                          ),
                        )
                      else
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
                                right: -20,
                                bottom: -20,
                                child: Icon(
                                  Icons.school_rounded,
                                  size: 120,
                                  color: Colors.white.withValues(alpha: 0.1),
                                ),
                              ),
                              Center(
                                child: Icon(
                                  Icons.auto_stories_rounded,
                                  size: 48,
                                  color: Colors.white.withValues(alpha: 0.95),
                                ),
                              ),
                            ],
                          ),
                        ),
                      // "Popular" or Tag badge
                      if (colorIndex % 3 == 0)
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
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: ClipRect(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: themeColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          course.category.toUpperCase(),
                          style: GoogleFonts.outfit(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: themeColor,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        course.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.outfit(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          height: 1.2,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Icon(
                            Icons.access_time_filled_rounded,
                            size: 12,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${course.estimatedDurationWeeks ?? 4} Weeks',
                            style: GoogleFonts.outfit(
                              fontSize: 11,
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
              ),
            ],
          ),
        )
        .animate()
        .fadeIn(delay: Duration(milliseconds: delayMs))
        .slideY(begin: 0.1, end: 0);
  }

  Widget _buildFeedContent(
    BuildContext context,
    AsyncValue<List<Map<String, dynamic>>> feedAsync, {
    required BoxConstraints constraints,
  }) {
    // Determine grid vs list based on available width
    final bool useGrid = constraints.maxWidth > 500;

    Widget content = feedAsync.when(
      data: (posts) {
        final displayPosts = posts.take(6).toList();

        if (displayPosts.isEmpty) {
          return Center(
            child: Text(
              'No updates yet.',
              style: GoogleFonts.outfit(color: Colors.grey),
            ),
          );
        }

        if (useGrid) {
          // Manual Masonry Layout: Split into two columns
          final leftParams = <Map<String, dynamic>>[];
          final rightParams = <Map<String, dynamic>>[];

          for (var i = 0; i < displayPosts.length; i++) {
            if (i % 2 == 0) {
              leftParams.add(displayPosts[i]);
            } else {
              rightParams.add(displayPosts[i]);
            }
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  children: leftParams
                      .map(
                        (post) => _buildPostItem(
                          context,
                          post,
                          displayPosts.indexOf(post),
                        ),
                      )
                      .toList(),
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: Column(
                  children: rightParams
                      .map(
                        (post) => _buildPostItem(
                          context,
                          post,
                          displayPosts.indexOf(post),
                        ),
                      )
                      .toList(),
                ),
              ),
            ],
          );
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          itemCount: displayPosts.length,
          itemBuilder: (context, index) =>
              _buildPostItem(context, displayPosts[index], index),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Text(
        'Failed to load feed',
        style: GoogleFonts.outfit(color: Colors.grey),
      ),
    );

    return content;
  }

  // Helper for Clickable Links
  Widget _buildTextWithLinks(String text) {
    final urlRegExp = RegExp(
      r'((https?:www\.)|(https?:\/\/)|(www\.))[-a-zA-Z0-9@:%._\+~#=]{1,256}\.[a-zA-Z0-9]{1,6}(\/[-a-zA-Z0-9()@:%_\+.~#?&\/=]*)?',
    );
    final spans = <InlineSpan>[];
    int start = 0;

    // Split text by URL matches
    for (final match in urlRegExp.allMatches(text)) {
      if (match.start > start) {
        spans.add(
          TextSpan(
            text: text.substring(start, match.start),
            style: GoogleFonts.outfit(
              fontSize: 14,
              color: Colors.black87,
              height: 1.5,
            ),
          ),
        );
      }

      final url = match.group(0)!;
      spans.add(
        WidgetSpan(
          child: InkWell(
            onTap: () async {
              final uri = Uri.parse(
                url.startsWith('http') ? url : 'https://$url',
              );
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri);
              }
            },
            child: Text(
              url,
              style: GoogleFonts.outfit(
                fontSize: 14,
                color: Colors.blue,
                height: 1.5,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ),
      );
      start = match.end;
    }

    if (start < text.length) {
      spans.add(
        TextSpan(
          text: text.substring(start),
          style: GoogleFonts.outfit(
            fontSize: 14,
            color: Colors.black87,
            height: 1.5,
          ),
        ),
      );
    }

    return RichText(text: TextSpan(children: spans));
  }

  Widget _buildPostItem(
    BuildContext context,
    Map<String, dynamic> post,
    int index,
  ) {
    String? imageUrl;
    if (post['image_urls'] != null) {
      try {
        final images = post['image_urls'];
        if (images is List && images.isNotEmpty) {
          imageUrl = images[0] as String?;
        }
      } catch (_) {}
    }
    return _buildActivityItem(
      context,
      post['content'] ?? '',
      post['created_at'] ?? DateTime.now().toIso8601String(),
      post['author_role'] ?? 'student',
      post['author_name'] ?? 'User',
      imageUrl,
      post,
      index * 100,
    );
  }

  Widget _buildAnalyticsGraph(
    BuildContext context,
    Map<String, int> stats,
    List<Map<String, dynamic>> growthData,
  ) {
    // Map real data to Spots
    final List<FlSpot> spots = [];
    double maxValue = 10; // Default min max for empty state

    for (int i = 0; i < growthData.length; i++) {
      final val = (growthData[i]['total_count'] as num).toDouble();
      spots.add(FlSpot(i.toDouble(), val));
      if (val > maxValue) maxValue = val;
    }

    if (spots.isEmpty) {
      return const SizedBox(
        height: 320,
        child: Center(child: Text('Connecting to platform pulse...')),
      );
    }

    return Container(
      height: 400,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white, AppTheme.primaryColor.withValues(alpha: 0.05)],
        ),
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withValues(alpha: 0.08),
            blurRadius: 40,
            offset: const Offset(0, 20),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: Stack(
          children: [
            // Background patterns or subtle circles
            Positioned(
              right: -50,
              top: -50,
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.03),
                  shape: BoxShape.circle,
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Platform Adoption',
                            style: GoogleFonts.outfit(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: Colors.black87,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Live student onboarding trajectory',
                            style: GoogleFonts.outfit(
                              fontSize: 14,
                              color: Colors.black54,
                            ),
                          ),
                        ],
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: _buildChartLegend(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 48),
                  Expanded(
                    child:
                        LineChart(
                          LineChartData(
                            gridData: FlGridData(
                              show: true,
                              drawVerticalLine: false,
                              horizontalInterval: maxValue / 4 > 0
                                  ? maxValue / 4
                                  : 1,
                              getDrawingHorizontalLine: (value) {
                                return FlLine(
                                  color: Colors.black.withValues(alpha: 0.03),
                                  strokeWidth: 1,
                                );
                              },
                            ),
                            titlesData: FlTitlesData(
                              show: true,
                              rightTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                              topTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  reservedSize: 32,
                                  interval: 1,
                                  getTitlesWidget: (value, meta) {
                                    final index = value.toInt();
                                    if (index >= 0 &&
                                        index < growthData.length) {
                                      return SideTitleWidget(
                                        meta: meta,
                                        child: Text(
                                          growthData[index]['month'] ?? '',
                                          style: GoogleFonts.outfit(
                                            color: Colors.black45,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      );
                                    }
                                    return const SizedBox.shrink();
                                  },
                                ),
                              ),
                              leftTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  interval: maxValue / 4 > 0 ? maxValue / 4 : 1,
                                  getTitlesWidget: (value, meta) {
                                    return Text(
                                      value.toInt().toString(),
                                      style: GoogleFonts.outfit(
                                        color: Colors.black38,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    );
                                  },
                                  reservedSize: 32,
                                ),
                              ),
                            ),
                            borderData: FlBorderData(show: false),
                            minX: 0,
                            maxX: (growthData.length - 1).toDouble(),
                            minY: 0,
                            maxY: maxValue * 1.3,
                            lineBarsData: [
                              LineChartBarData(
                                spots: spots,
                                isCurved: true,
                                curveSmoothness: 0.35,
                                gradient: LinearGradient(
                                  colors: [
                                    AppTheme.primaryColor,
                                    const Color(0xFF6366F1), // Indigo
                                  ],
                                ),
                                barWidth: 6,
                                isStrokeCapRound: true,
                                dotData: FlDotData(
                                  show: true,
                                  getDotPainter:
                                      (spot, percent, barData, index) {
                                        return FlDotCirclePainter(
                                          radius: 6,
                                          color: Colors.white,
                                          strokeWidth: 3,
                                          strokeColor: AppTheme.primaryColor,
                                        );
                                      },
                                ),
                                belowBarData: BarAreaData(
                                  show: true,
                                  gradient: LinearGradient(
                                    colors: [
                                      AppTheme.primaryColor.withValues(alpha: 0.2),
                                      AppTheme.primaryColor.withValues(alpha: 0),
                                    ],
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                  ),
                                ),
                              ),
                            ],
                            lineTouchData: LineTouchData(
                              touchTooltipData: LineTouchTooltipData(
                                getTooltipColor: (touchedSpot) =>
                                    Colors.black.withValues(alpha: 0.8),
                                getTooltipItems:
                                    (List<LineBarSpot> touchedBarSpots) {
                                      return touchedBarSpots.map((barSpot) {
                                        return LineTooltipItem(
                                          '${barSpot.y.toInt()} Learners',
                                          GoogleFonts.outfit(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        );
                                      }).toList();
                                    },
                              ),
                            ),
                          ),
                          duration: const Duration(milliseconds: 1500),
                          curve: Curves.elasticOut,
                        ).animate().scale(
                          duration: 800.ms,
                          curve: Curves.easeOutBack,
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 800.ms).slideY(begin: 0.05, end: 0);
  }

  Widget _buildChartLegend() {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: AppTheme.primaryColor,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          'Total Signups',
          style: GoogleFonts.outfit(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.black54,
          ),
        ),
      ],
    );
  }

  Widget _buildStatsRow(BuildContext context, Map<String, dynamic> stats) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 600;

        final children = [
          _buildMinimalStatItem(
            'Active Users',
            '${stats['total_students']}',
            Icons.people_outline_rounded,
            Colors.blue,
            isMobile,
          ),
          _buildMinimalStatItem(
            'Colleges',
            '${stats['total_colleges']}',
            Icons.school_outlined,
            Colors.orange,
            isMobile,
          ),
          _buildMinimalStatItem(
            'Recruiters',
            '${stats['total_recruiters']}',
            Icons.business_center_outlined,
            Colors.green,
            isMobile,
          ),
          _buildMinimalStatItem(
            'Hired',
            '${stats['total_placements']}',
            Icons.verified_outlined,
            Colors.purple,
            isMobile,
          ),
        ];

        if (isMobile) {
          return Column(
            children: [
              Row(
                children: [
                  Expanded(child: children[0]),
                  const SizedBox(width: 16),
                  Expanded(child: children[1]),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: children[2]),
                  const SizedBox(width: 16),
                  Expanded(child: children[3]),
                ],
              ),
            ],
          );
        } else {
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: children.map((e) => Expanded(child: e)).toList(),
          );
        }
      },
    );
  }

  Widget _buildMinimalStatItem(
    String label,
    String value,
    IconData icon,
    Color color,
    bool isMobile,
  ) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: isMobile ? 4 : 8),
      padding: EdgeInsets.symmetric(
        vertical: isMobile ? 12 : 20,
        horizontal: isMobile ? 12 : 16,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(isMobile ? 8 : 10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: isMobile ? 20 : 24),
          ),
          SizedBox(height: isMobile ? 8 : 12),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: GoogleFonts.outfit(
                fontSize: isMobile ? 20 : 24,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    ).animate().scale(delay: 200.ms);
  }

  Widget _buildActivityItem(
    BuildContext context,
    String title,
    String timeStr,
    String role,
    String author,
    String? imageUrl,
    Map<String, dynamic> postData, // Pass full post data for extra fields
    int delayMs,
  ) {
    // 1. Identity Logic
    final r = role.toLowerCase();

    // Robust Check: SQL boolean OR Client-side Role check
    final bool isCollegePost =
        (postData['is_college_post'] == true) ||
        (r == 'admin' || r == 'college_admin');

    String orgName = postData['org_name'] ?? '';
    // Fix for user request: Override default/empty with correct institute
    if (orgName == 'CareerBridge Academy' || orgName.isEmpty) {
      orgName = 'Poornaprajna Institute of Managment';
    }

    final String? orgLogo = postData['org_logo'];

    String displayName = author;
    String? displayAvatarUrl = postData['author_avatar'];

    // Subtitle Component
    Widget subtitleWidget;

    IconData fallbackIcon = Icons.person;
    Color badgeColor = AppTheme.primaryColor;
    bool isVerified = false;

    if (isCollegePost) {
      // College Admin Post
      displayName = orgName.isNotEmpty ? orgName : author;
      displayAvatarUrl = orgLogo;

      subtitleWidget = Text(
        'Official Update',
        style: GoogleFonts.outfit(fontSize: 11, color: Colors.black54),
      );

      fallbackIcon = Icons.school_rounded;
      badgeColor = Colors.orange;
      isVerified = true;
    } else if (r == 'recruiter') {
      // Recruiter Post
      // Force Org Name and Logo
      if (orgName.isNotEmpty) displayName = orgName;
      if (orgLogo != null) displayAvatarUrl = orgLogo;

      subtitleWidget = Text(
        'Recruiter', // Simplified since Title is Company Name
        overflow: TextOverflow.ellipsis,
        style: GoogleFonts.outfit(fontSize: 11, color: Colors.black54),
      );

      fallbackIcon = Icons.business_center_rounded;
      badgeColor = Colors.green;
      isVerified = true;
    } else {
      // Student Post
      // Format: [College Logo/Icon] student at [College Name]
      subtitleWidget = Row(
        children: [
          if (orgName.isNotEmpty) ...[
            Container(
              width: 14,
              height: 14,
              margin: const EdgeInsets.only(right: 4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.orange.withValues(alpha: 0.1),
                image: orgLogo != null && orgLogo.isNotEmpty
                    ? DecorationImage(
                        image: NetworkImage(orgLogo),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: (orgLogo == null || orgLogo.isEmpty)
                  ? const Icon(Icons.school, size: 8, color: Colors.orange)
                  : null,
            ),
            Flexible(
              child: Text(
                'student at $orgName',
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.outfit(fontSize: 11, color: Colors.black54),
              ),
            ),
          ] else
            Text(
              'Student',
              style: GoogleFonts.outfit(fontSize: 11, color: Colors.black54),
            ),
        ],
      );
    }

    return InkWell(
          onTap: () => _showLoginRequired(context),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            margin: const EdgeInsets.only(bottom: 24),
            padding: const EdgeInsets.all(16),
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // HEADER: Avatar + Name/Subtitle
                Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: badgeColor.withValues(alpha: 0.1),
                      backgroundImage:
                          displayAvatarUrl != null &&
                              displayAvatarUrl.isNotEmpty
                          ? NetworkImage(displayAvatarUrl)
                          : null,
                      child:
                          (displayAvatarUrl == null || displayAvatarUrl.isEmpty)
                          ? Icon(fallbackIcon, color: badgeColor, size: 20)
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  displayName,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.outfit(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                              ),
                              if (isVerified)
                                Padding(
                                  padding: const EdgeInsets.only(left: 4),
                                  child: Icon(
                                    Icons.verified,
                                    size: 14,
                                    color: Colors.blue,
                                  ),
                                ),
                            ],
                          ),
                          // Subtitle Row
                          subtitleWidget,
                        ],
                      ),
                    ),
                    Text(
                      timeago.format(
                        DateTime.parse(timeStr),
                        locale: 'en_short',
                      ),
                      style: GoogleFonts.outfit(
                        fontSize: 11,
                        color: Colors.black45,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // BODY TEXT
                _buildTextWithLinks(title),

                // LARGE IMAGE (If present)
                if (imageUrl != null)
                  Container(
                    margin: const EdgeInsets.only(top: 12),
                    width: double.infinity,
                    child: AspectRatio(
                      aspectRatio: 4 / 3, // Squarish aspect ratio
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(imageUrl, fit: BoxFit.cover),
                      ),
                    ),
                  ),

                // FOOTER (Optional Mock Actions for "Real" feel)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Row(
                    children: [
                      Icon(
                        Icons.thumb_up_alt_outlined,
                        size: 16,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Like',
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(width: 24),
                      Icon(
                        Icons.comment_outlined,
                        size: 16,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Comment',
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        )
        .animate()
        .fadeIn(delay: Duration(milliseconds: delayMs))
        .slideY(begin: 0.2, end: 0);
  }
}

class _LoadingPlaceholder extends StatelessWidget {
  final double height;
  const _LoadingPlaceholder({this.height = 200});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(32),
      ),
      child: const Center(child: CircularProgressIndicator()),
    );
  }
}

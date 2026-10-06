import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:fl_chart/fl_chart.dart'; // Add fl_chart import
import '../../../../core/theme/app_theme.dart';
import 'add_edit_project_screen.dart';

class StudentProjectsScreen extends StatefulWidget {
  const StudentProjectsScreen({super.key});

  @override
  State<StudentProjectsScreen> createState() => _StudentProjectsScreenState();
}

class _StudentProjectsScreenState extends State<StudentProjectsScreen> {
  List<Map<String, dynamic>> _projects = [];
  bool _isLoading = true;
  Map<String, int> _techCounts = {};
  int _totalTechs = 0;

  @override
  void initState() {
    super.initState();
    _loadProjects();
  }

  Future<void> _loadProjects() async {
    setState(() => _isLoading = true);
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      final response = await Supabase.instance.client
          .from('student_projects')
          .select()
          .eq('student_id', user.id)
          .order('created_at', ascending: false);

      final List<Map<String, dynamic>> projects =
          List<Map<String, dynamic>>.from(response);

      // Aggregate technologies
      final Map<String, int> techCounts = {};
      int total = 0;

      for (var project in projects) {
        final techs = project['technologies'] as List?;
        if (techs != null) {
          for (var tech in techs) {
            final t = tech.toString();
            techCounts[t] = (techCounts[t] ?? 0) + 1;
            total++;
          }
        }
      }

      // Sort by count descending
      final sortedEntries = techCounts.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      setState(() {
        _projects = projects;
        _techCounts = Map.fromEntries(sortedEntries);
        _totalTechs = total;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading projects: $e')));
      }
    }
  }

  Future<void> _launchUrl(String urlString) async {
    try {
      String finalUrl = urlString.trim();
      if (!finalUrl.startsWith('http://') && !finalUrl.startsWith('https://')) {
        finalUrl = 'https://$finalUrl';
      }

      final Uri url = Uri.parse(finalUrl);

      // Try launching directly without checking canLaunchUrl first
      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
        throw 'Could not launch $finalUrl';
      }
    } catch (e) {
      debugPrint('Error launching URL: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not launch URL: $urlString')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        title: Text(
          'My Projects',
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : LayoutBuilder(
              builder: (context, constraints) {
                final isDesktop = constraints.maxWidth > 900;

                return Padding(
                  padding: const EdgeInsets.all(24),
                  child: isDesktop
                      ? Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Project Grid (Flex 3)
                            Expanded(
                              flex: 3,
                              child: _buildProjectsGrid(isDesktop: true),
                            ),
                            const SizedBox(width: 24),
                            // Tech Analytics (Flex 1)
                            Expanded(flex: 1, child: _buildTechChart()),
                          ],
                        )
                      : SingleChildScrollView(
                          child: Column(
                            children: [
                              _buildProjectsGrid(isDesktop: false),
                              if (_totalTechs > 0) ...[
                                const SizedBox(height: 32),
                                _buildTechChart(),
                              ],
                            ],
                          ),
                        ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await showDialog<bool>(
            context: context,
            builder: (context) => const AddEditProjectScreen(),
          );
          if (result == true && mounted) {
            _loadProjects();
          }
        },
        backgroundColor: AppTheme.primaryColor,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: Text(
          'Add Project',
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildProjectsGrid({required bool isDesktop}) {
    if (_projects.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.work_outline_rounded, size: 80, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              'No projects yet',
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Start adding your projects to showcase your work',
              style: GoogleFonts.outfit(fontSize: 14, color: Colors.grey[500]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    if (isDesktop) {
      return GridView.builder(
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 320, // Match course catalog card width
          childAspectRatio: 0.75, // Standard card aspect ratio
          crossAxisSpacing: 20,
          mainAxisSpacing: 20,
        ),
        itemCount: _projects.length,
        itemBuilder: (context, index) {
          return _buildProjectCard(_projects[index]);
        },
      );
    } else {
      return ListView.builder(
        shrinkWrap: true, // Needed because it's inside SingleChildScrollView
        physics: const NeverScrollableScrollPhysics(), // Scroll parent instead
        itemCount: _projects.length,
        itemBuilder: (context, index) {
          return _buildProjectCard(_projects[index]);
        },
      );
    }
  }

  Widget _buildTechChart() {
    if (_totalTechs == 0) {
      return Container(
        padding: const EdgeInsets.all(16),
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
        child: Center(
          child: Text(
            'Add technologies to see analytics',
            style: GoogleFonts.outfit(color: Colors.grey),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(24),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tech Stack Split',
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 200,
            child: PieChart(
              PieChartData(
                sectionsSpace: 0,
                centerSpaceRadius: 40,
                sections: _getSections(),
              ),
            ),
          ),
          const SizedBox(height: 24),
          // Legend
          ..._techCounts.entries.take(5).map((entry) {
            final percentage = (entry.value / _totalTechs * 100)
                .toStringAsFixed(1);
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: _getColorForTech(entry.key),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      entry.key,
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        color: Colors.grey[700],
                      ),
                    ),
                  ),
                  Text(
                    '$percentage%',
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  List<PieChartSectionData> _getSections() {
    return _techCounts.entries.map((entry) {
      final percentage = (entry.value / _totalTechs * 100);
      return PieChartSectionData(
        color: _getColorForTech(entry.key),
        value: entry.value.toDouble(),
        title: '${percentage.toStringAsFixed(0)}%',
        radius: 50,
        titleStyle: GoogleFonts.outfit(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    }).toList();
  }

  Color _getColorForTech(String tech) {
    // Generate a consistent color based on the string hash
    final hash = tech.hashCode;
    final colors = [
      AppTheme.primaryColor,
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.teal,
      Colors.pink,
      Colors.indigo,
    ];
    return colors[hash.abs() % colors.length];
  }

  Widget _buildProjectCard(Map<String, dynamic> project) {
    final technologies = project['technologies'] as List?;
    final mediaUrls = project['media_urls'] as List?;
    final projectUrl = project['project_url'] as String?;
    final githubUrl = project['github_url'] as String?;
    final title = project['title'] ?? 'Untitled';

    // Generate dynamic color based on title hash
    final colorSeed = title.hashCode;
    final color1 = Color((colorSeed * 0xFFFFFF).toInt()).withValues(alpha: 0.85);
    final color2 = Color(
      ((colorSeed + 1) * 0xFFFFFF).toInt(),
    ).withValues(alpha: 0.65);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade100, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () async {
            final result = await showDialog<bool>(
              context: context,
              builder: (context) => AddEditProjectScreen(project: project),
            );
            if (result == true && mounted) {
              _loadProjects();
            }
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Banner Image Area
              Stack(
                children: [
                  Container(
                    height: 120,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withValues(alpha: 0.05),
                    ),
                    child: (mediaUrls != null && mediaUrls.isNotEmpty)
                        ? Image.network(
                            mediaUrls.first,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [color1, color2],
                                  ),
                                ),
                                child: Center(
                                  child: Icon(
                                    Icons.code_rounded,
                                    color: Colors.white.withValues(alpha: 0.6),
                                    size: 40,
                                  ),
                                ),
                              );
                            },
                          )
                        : Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [color1, color2],
                              ),
                            ),
                            child: Center(
                              child: Icon(
                                Icons.code_rounded,
                                color: Colors.white.withValues(alpha: 0.6),
                                size: 40,
                              ),
                            ),
                          ),
                  ),

                  // Posted Badge
                  if (project['posted_to_feed'] == true)
                    Positioned(
                      top: 12,
                      right: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.95),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.check_circle,
                              size: 14,
                              color: Colors.green.shade600,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Posted',
                              style: GoogleFonts.outfit(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Colors.green.shade700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
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
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      if (project['description'] != null &&
                          project['description'].toString().isNotEmpty)
                        Text(
                          project['description'],
                          style: GoogleFonts.outfit(
                            fontSize: 13,
                            color: Colors.grey[600],
                            height: 1.4,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),

                      const Spacer(),

                      // Technologies
                      if (technologies != null && technologies.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: technologies.take(3).map<Widget>((tech) {
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryColor.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                tech.toString(),
                                style: GoogleFonts.outfit(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.primaryColor,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        if (technologies.length > 3)
                          Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(
                              '+${technologies.length - 3} more',
                              style: GoogleFonts.outfit(
                                fontSize: 10,
                                color: Colors.grey,
                              ),
                            ),
                          ),
                      ],

                      const SizedBox(height: 16),

                      // Action Buttons
                      Row(
                        children: [
                          if (projectUrl != null && projectUrl.isNotEmpty)
                            Expanded(
                              child: SizedBox(
                                height: 36,
                                child: OutlinedButton(
                                  onPressed: () => _launchUrl(projectUrl),
                                  style: OutlinedButton.styleFrom(
                                    padding: EdgeInsets.zero,
                                    side: BorderSide(
                                      color: Colors.grey.shade300,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  child: Text(
                                    'Demo',
                                    style: GoogleFonts.outfit(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          if (projectUrl != null &&
                              projectUrl.isNotEmpty &&
                              githubUrl != null &&
                              githubUrl.isNotEmpty)
                            const SizedBox(width: 8),
                          if (githubUrl != null && githubUrl.isNotEmpty)
                            Expanded(
                              child: SizedBox(
                                height: 36,
                                child: OutlinedButton(
                                  onPressed: () => _launchUrl(githubUrl),
                                  style: OutlinedButton.styleFrom(
                                    padding: EdgeInsets.zero,
                                    side: BorderSide(
                                      color: Colors.grey.shade300,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  child: Text(
                                    'Code',
                                    style: GoogleFonts.outfit(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ),
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
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../jobs/domain/services/resume_matching_service.dart';
import '../hiring/applicant_detail_screen.dart';

class ApplicationsScreen extends ConsumerStatefulWidget {
  final VoidCallback? onBackPressed;

  const ApplicationsScreen({super.key, this.onBackPressed});

  @override
  ConsumerState<ApplicationsScreen> createState() => _ApplicationsScreenState();
}

class _ApplicationsScreenState extends ConsumerState<ApplicationsScreen> {
  List<Map<String, dynamic>> _applications = [];
  bool _isLoading = true;
  String _statusFilter = 'all';
  String _selectedCollege = 'All Colleges';
  List<String> _colleges = ['All Colleges'];
  Map<String, Map<String, dynamic>> _matchScores = {};
  bool _isAnalyzing = false;

  final List<Map<String, dynamic>> _statusFilters = [
    {'key': 'all', 'label': 'All', 'color': Colors.grey},
    {'key': 'applied', 'label': 'Applied', 'color': Colors.blue},
    {'key': 'shortlisted', 'label': 'Shortlisted', 'color': Colors.green},
    {'key': 'in_progress', 'label': 'In Progress', 'color': Colors.orange},
    {'key': 'selected', 'label': 'Selected', 'color': Colors.purple},
    {'key': 'rejected', 'label': 'Rejected', 'color': Colors.red},
  ];

  @override
  void initState() {
    super.initState();
    _loadApplications();
  }

  Future<void> _loadApplications() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      // Get recruiter's jobs first
      final jobsResponse = await Supabase.instance.client
          .from('jobs')
          .select('id')
          .eq('posted_by', user.id);

      if (jobsResponse.isEmpty) {
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      final jobIds = jobsResponse.map((j) => j['id']).toList();

      // Get applications with college data
      // Note: organizations table is joined via profiles(organization_id)
      final response = await Supabase.instance.client
          .from('job_applications')
          .select(
            '*, jobs(title, description, requirements), profiles!inner(full_name, email, organizations(name, logo_url), resume_url)',
          )
          .inFilter('job_id', jobIds)
          .order('applied_at', ascending: false);

      final apps = List<Map<String, dynamic>>.from(response);

      // Extract unique colleges
      final Set<String> collegeNames = {'All Colleges'};
      for (var app in apps) {
        final profile = app['profiles'];
        if (profile != null && profile['organizations'] != null) {
          final collegeName = profile['organizations']['name'] as String?;
          if (collegeName != null && collegeName.isNotEmpty) {
            collegeNames.add(collegeName);
          }
        }
      }

      if (mounted) {
        setState(() {
          _applications = apps;
          _colleges = collegeNames.toList()..sort();
          // Ensure "All Colleges" is first
          _colleges.remove('All Colleges');
          _colleges.insert(0, 'All Colleges');
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading applications: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _getCollegeName(Map<String, dynamic> application) {
    try {
      final profile = application['profiles'];
      if (profile != null && profile['organizations'] != null) {
        return profile['organizations']['name'] ?? 'Unknown College';
      }
    } catch (_) {}
    return 'Unknown College';
  }

  String? _getCollegeLogo(Map<String, dynamic> application) {
    try {
      final profile = application['profiles'];
      if (profile != null && profile['organizations'] != null) {
        return profile['organizations']['logo_url'] as String?;
      }
    } catch (_) {}
    return null;
  }

  List<Map<String, dynamic>> _getFilteredApplications() {
    return _applications.where((app) {
      final matchesStatus =
          _statusFilter == 'all' || app['status'] == _statusFilter;
      final matchesCollege =
          _selectedCollege == 'All Colleges' ||
          _getCollegeName(app) == _selectedCollege;
      return matchesStatus && matchesCollege;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth > 900) {
                  return _buildDesktopLayout();
                }
                return _buildMobileLayout();
              },
            ),
    );
  }

  Widget _buildDesktopLayout() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Main Application List
        Expanded(
          flex: 3,
          child: RefreshIndicator(
            // Added RefreshIndicator for consistency
            onRefresh: _loadApplications,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(32),
              physics:
                  const AlwaysScrollableScrollPhysics(), // Allow scroll even if list is small
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 24),
                  _buildFilters(),
                  const SizedBox(height: 24),
                  _buildApplicationsList(),
                ],
              ),
            ),
          ),
        ),

        // Analytics Sidebar
        Container(
          width: 350,
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(left: BorderSide(color: Colors.grey.shade200)),
          ),
          child: _buildAnalyticsSidebar(),
        ),
      ],
    );
  }

  Widget _buildMobileLayout() {
    return RefreshIndicator(
      onRefresh: _loadApplications,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 24),
            _buildFilters(), // Now includes college dropdown
            const SizedBox(height: 24),
            _buildApplicationsList(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final filteredCount = _getFilteredApplications().length;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, size: 20),
              onPressed: () {
                if (widget.onBackPressed != null) {
                  widget.onBackPressed!();
                } else {
                  Navigator.maybePop(context);
                }
              },
            ),
            const SizedBox(width: 8),
            Text(
              'Job Applications',
              style: GoogleFonts.outfit(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            '$filteredCount Total',
            style: GoogleFonts.outfit(
              fontWeight: FontWeight.w600,
              color: AppTheme.primaryColor,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFilters() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // College Dropdown
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedCollege,
              isExpanded: false, // Keep compact
              hint: const Text('Filter by College'),
              icon: const Icon(Icons.school, size: 20),
              items: _colleges.map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(
                    value,
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                );
              }).toList(),
              onChanged: (newValue) {
                if (newValue != null) {
                  setState(() => _selectedCollege = newValue);
                }
              },
            ),
          ),
        ),
        const SizedBox(height: 16),
        // Status Chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: _statusFilters.map((filter) {
              final isSelected = _statusFilter == filter['key'];

              // Calculate count valid for current college filter
              final count = filter['key'] == 'all'
                  ? _getFilteredApplicationsWithoutStatus().length
                  : _getFilteredApplicationsWithoutStatus()
                        .where((a) => a['status'] == filter['key'])
                        .length;

              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: Text('${filter['label']} ($count)'),
                  selected: isSelected,
                  onSelected: (_) {
                    setState(() => _statusFilter = filter['key']);
                  },
                  backgroundColor: Colors.white,
                  selectedColor: (filter['color'] as Color).withValues(alpha: 0.15),
                  labelStyle: GoogleFonts.outfit(
                    fontWeight: isSelected
                        ? FontWeight.w600
                        : FontWeight.normal,
                    color: isSelected
                        ? filter['color'] as Color
                        : Colors.grey[700],
                  ),
                  side: BorderSide(
                    color: isSelected
                        ? filter['color'] as Color
                        : Colors.grey[300]!,
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  // Helper to get apps filtered by college but NOT status (for chip counts)
  List<Map<String, dynamic>> _getFilteredApplicationsWithoutStatus() {
    return _applications.where((app) {
      return _selectedCollege == 'All Colleges' ||
          _getCollegeName(app) == _selectedCollege;
    }).toList();
  }

  Widget _buildApplicationsList() {
    final filteredList = _getFilteredApplications();

    if (filteredList.isEmpty) {
      return Center(
        child: Column(
          children: [
            const SizedBox(height: 64),
            Icon(Icons.assignment_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No applications found',
              style: GoogleFonts.outfit(fontSize: 18, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: filteredList.length,
      itemBuilder: (context, index) {
        return _buildApplicationCard(filteredList[index]);
      },
    );
  }

  Widget _buildApplicationCard(Map<String, dynamic> application) {
    final status = application['status'] ?? 'applied';
    final statusColors = {
      'applied': Colors.blue,
      'shortlisted': Colors.green,
      'in_progress': Colors.orange,
      'selected': Colors.purple,
      'rejected': Colors.red,
      'on_hold': Colors.grey,
    };
    final statusColor = statusColors[status] ?? Colors.grey;
    final jobTitle = application['jobs']?['title'] ?? 'Unknown Job';
    final candidateName =
        application['profiles']?['full_name'] ?? 'Unknown Candidate';
    final collegeName = _getCollegeName(application);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      candidateName,
                      style: GoogleFonts.outfit(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      collegeName,
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        color: Colors.grey[500],
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Applied for: $jobTitle',
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_matchScores.containsKey(application['id']))
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: _buildMatchChip(
                        score: _matchScores[application['id']]!['score'],
                      ),
                    ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      status.toUpperCase(),
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: statusColor,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              OutlinedButton.icon(
                onPressed: () => _openApplicantDetail(application),
                icon: const Icon(Icons.visibility, size: 16),
                label: const Text('View Details'),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: _isAnalyzing
                    ? null
                    : () => _analyzeApplication(application),
                icon: _isAnalyzing
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppTheme.primaryColor,
                        ),
                      )
                    : const Icon(Icons.auto_awesome, size: 16),
                label: Text(
                  _matchScores.containsKey(application['id'])
                      ? 'Insights'
                      : 'Analyze',
                ),
              ),
              const SizedBox(width: 8),
              if (application['current_round'] != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Round ${application['current_round']}',
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      color: Colors.grey[700],
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyticsSidebar() {
    // 1. Calculate College Participation
    Map<String, int> collegeCounts = {};
    Map<String, String?> collegeLogos = {}; // Map to store logos

    for (var app in _applications) {
      final college = _getCollegeName(app);
      if (college != 'Unknown College') {
        collegeCounts[college] = (collegeCounts[college] ?? 0) + 1;
        // Store logo if not already stored
        if (!collegeLogos.containsKey(college)) {
          collegeLogos[college] = _getCollegeLogo(app);
        }
      }
    }

    // Sort colleges by count (descending)
    var sortedColleges = collegeCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // Top 5
    final topColleges = sortedColleges.take(5).toList();
    final totalApplications = _applications.length;

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text(
          'Application Insights',
          style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          'Real-time statistics by college',
          style: GoogleFonts.outfit(fontSize: 13, color: Colors.grey[500]),
        ),
        const SizedBox(height: 32),

        _buildInfoCard(
          title: 'Total Applications',
          value: totalApplications.toString(),
          icon: Icons.people_outline,
          color: Colors.blue,
        ),
        const SizedBox(height: 24),

        Text(
          'Top Participating Colleges',
          style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),

        if (topColleges.isEmpty)
          Text(
            'No data available',
            style: GoogleFonts.outfit(color: Colors.grey),
          )
        else
          ...topColleges
              .map(
                (entry) => _buildCollegeStatRow(
                  entry.key,
                  entry.value,
                  totalApplications,
                  collegeLogos[entry.key],
                ),
              )
              .toList(),
      ],
    );
  }

  Widget _buildInfoCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.05),
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
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: GoogleFonts.outfit(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                title,
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCollegeStatRow(
    String name,
    int count,
    int total,
    String? logoUrl,
  ) {
    double percentage = total > 0 ? count / total : 0;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Logo or Initial
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                  image: logoUrl != null && logoUrl.isNotEmpty
                      ? DecorationImage(
                          image: NetworkImage(logoUrl),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: logoUrl == null || logoUrl.isEmpty
                    ? Center(
                        child: Text(
                          name.characters.first.toUpperCase(),
                          style: GoogleFonts.outfit(
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[600],
                          ),
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '$count applications',
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${(percentage * 100).toStringAsFixed(0)}%',
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: percentage,
              backgroundColor: Colors.grey[100],
              color: Colors.blueAccent,
              minHeight: 4,
            ),
          ),
        ],
      ),
    );
  }

  void _openApplicantDetail(Map<String, dynamic> application) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            ApplicantDetailScreen(applicationId: application['id']),
      ),
    ).then((_) => _loadApplications());
  }

  Future<void> _analyzeApplication(Map<String, dynamic> application) async {
    final resumeUrl = application['profiles']?['resume_url'];
    if (resumeUrl == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Candidate has not uploaded a resume.')),
      );
      return;
    }

    setState(() => _isAnalyzing = true);

    try {
      final resumeText = await ResumeMatchingService().extractTextFromPdf(
        resumeUrl,
      );
      if (resumeText == null || resumeText.isEmpty) {
        throw Exception('Could not extract text from resume.');
      }

      final job = application['jobs'];
      final result = await ResumeMatchingService().calculateMatchWithAI(
        resumeText: resumeText,
        jobTitle: job['title'] ?? 'Unknown Job',
        jobDescription: job['description'] ?? '',
        jobRequirements: job['requirements'],
      );

      if (mounted) {
        setState(() {
          _matchScores[application['id']] = result;
          _isAnalyzing = false;
        });
        _showMatchResultDialog(application, result);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isAnalyzing = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Analysis Failed: $e')));
      }
    }
  }

  void _showMatchResultDialog(
    Map<String, dynamic> application,
    Map<String, dynamic> result,
  ) {
    final score = result['score'] as int;
    final matched = List<String>.from(result['matched'] ?? []);
    final missing = List<String>.from(result['missing'] ?? []);
    final candidateName = application['profiles']?['full_name'] ?? 'Candidate';

    Color scoreColor = score >= 70
        ? Colors.green
        : (score >= 40 ? Colors.orange : Colors.red);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        titlePadding: EdgeInsets.zero,
        title: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withValues(alpha: 0.05),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: Icon(Icons.auto_awesome, color: scoreColor, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'AI Match Analysis',
                      style: GoogleFonts.outfit(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      candidateName,
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        ),
        content: SizedBox(
          width: 500,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Score Circle
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                  decoration: BoxDecoration(
                    color: scoreColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      Text(
                        '$score%',
                        style: GoogleFonts.outfit(
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                          color: scoreColor,
                        ),
                      ),
                      Text(
                        'Requirements Match',
                        style: GoogleFonts.outfit(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: scoreColor,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Sections
                _buildAnalysisSection(
                  'Matched Keywords',
                  matched,
                  Colors.green,
                  Icons.check_circle_outline,
                ),
                const SizedBox(height: 20),
                _buildAnalysisSection(
                  'Missing Requirements',
                  missing,
                  Colors.orange,
                  Icons.error_outline,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAnalysisSection(
    String title,
    List<String> items,
    Color color,
    IconData icon,
  ) {
    if (items.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 8),
            Text(
              title,
              style: GoogleFonts.outfit(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: items.map((item) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: color.withValues(alpha: 0.2)),
              ),
              child: Text(
                item,
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  color: color,
                  fontWeight: FontWeight.w500,
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildMatchChip({required int score}) {
    final color = score >= 70
        ? Colors.green
        : (score >= 40 ? Colors.orange : Colors.red);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.auto_awesome, size: 12, color: Colors.green),
          const SizedBox(width: 4),
          Text(
            '$score% Match',
            style: GoogleFonts.outfit(
              color: color,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

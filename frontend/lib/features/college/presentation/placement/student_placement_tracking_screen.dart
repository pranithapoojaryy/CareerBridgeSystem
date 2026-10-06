import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/theme/app_theme.dart';
import '../widgets/placement_roadmap_widget.dart';
import '../../../jobs/domain/job_application.dart';
import '../../../jobs/domain/job_round.dart';
import '../../../jobs/domain/offer.dart';
import '../../../networking/presentation/screens/network_profile_view.dart';

class StudentPlacementTrackingScreen extends ConsumerStatefulWidget {
  final bool embedded;

  const StudentPlacementTrackingScreen({super.key, this.embedded = false});

  @override
  ConsumerState<StudentPlacementTrackingScreen> createState() =>
      _StudentPlacementTrackingScreenState();
}

class _StudentPlacementTrackingScreenState
    extends ConsumerState<StudentPlacementTrackingScreen> {
  bool _isLoading = true;
  List<JobApplication> _applications = [];
  String _selectedFilter = 'all';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchPlacements();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  double _parseSalary(String? salary) {
    if (salary == null || salary.isEmpty) return 0.0;

    // Clean string and convert to uppercase
    final cleanSalary = salary.toUpperCase().replaceAll(RegExp(r'[^0-9.]'), '');
    if (cleanSalary.isEmpty) return 0.0;

    try {
      return double.parse(cleanSalary);
    } catch (e) {
      return 0.0;
    }
  }

  Future<void> _fetchPlacements() async {
    try {
      setState(() => _isLoading = true);

      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      // Get college admin's organization ID
      final profile = await Supabase.instance.client
          .from('profiles')
          .select('organization_id')
          .eq('id', user.id)
          .single();

      final orgId = profile['organization_id'];
      if (orgId == null) {
        setState(() => _isLoading = false);
        return;
      }

      // Fetch job applications for students in this organization
      final response = await Supabase.instance.client
          .from('job_applications')
          .select('''
            *,
            job:jobs(
              id,
              title,
              description,
              recruiter_id,
              created_at,
              salary_range,
              organization:organizations(name, logo_url),
              rounds:job_rounds(
                id,
                job_id,
                round_number,
                round_type,
                title,
                instructions,
                deadline
              )
            ),
            student:profiles!job_applications_student_id_fkey(
              id,
              full_name,
              avatar_url,
              profile_photo_url,
              email,
              role
            ),
            offer:offers(
              id,
              offer_type,
              package_amount,
              currency,
              joining_date,
              status
            )
          ''')
          .eq('student.organization_id', orgId)
          .order('applied_at', ascending: false);

      final applications = (response as List)
          .map((data) {
            try {
              // Parse rounds from nested job object
              final jobData = data['job'] as Map<String, dynamic>?;
              final roundsData = jobData?['rounds'] as List?;
              final rounds = roundsData
                  ?.map((r) => JobRound.fromJson(r as Map<String, dynamic>))
                  .toList();

              // Parse offer
              final offerDataRaw = data['offer'];
              Map<String, dynamic>? offerData;

              if (offerDataRaw is List && offerDataRaw.isNotEmpty) {
                offerData = offerDataRaw.first as Map<String, dynamic>;
              } else if (offerDataRaw is Map<String, dynamic>) {
                offerData = offerDataRaw;
              }

              Offer? offer;
              if (offerData != null) {
                // If package_amount is null or zero, try fallback to job.salary_range
                final packageAmount =
                    (offerData['package_amount'] as num?)?.toDouble() ?? 0.0;

                if (packageAmount == 0.0 && jobData?['salary_range'] != null) {
                  final fallbackPackage = _parseSalary(
                    jobData!['salary_range'].toString(),
                  );
                  if (fallbackPackage > 0) {
                    offerData['package_amount'] = fallbackPackage;
                  }
                }

                offer = Offer.fromJson(offerData);
              }

              return JobApplication.fromJson({
                ...data,
                'rounds': rounds,
                'offer': offer,
              });
            } catch (e) {
              print('Error parsing application: $e');
              return null;
            }
          })
          .whereType<JobApplication>()
          .toList();

      setState(() {
        _applications = applications;
        _isLoading = false;
      });
    } catch (e) {
      print('Error fetching placements: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading placements: $e')));
      }
    }
  }

  List<JobApplication> get _filteredApplications {
    var filtered = _applications;

    // Apply status filter
    if (_selectedFilter != 'all') {
      filtered = filtered.where((app) {
        switch (_selectedFilter) {
          case 'applied':
            return app.status == 'applied';
          case 'in_progress':
            return app.status == 'in_progress' || app.status == 'shortlisted';
          case 'selected':
            return app.status == 'selected';
          case 'rejected':
            return app.status == 'rejected';
          default:
            return true;
        }
      }).toList();
    }

    // Apply search query
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((app) {
        final studentName =
            app.student?['full_name']?.toString().toLowerCase() ?? '';
        final companyName =
            app.job?.organization?['name']?.toString().toLowerCase() ?? '';
        final jobTitle = app.job?.title.toLowerCase() ?? '';
        final query = _searchQuery.toLowerCase();

        return studentName.contains(query) ||
            companyName.contains(query) ||
            jobTitle.contains(query);
      }).toList();
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final content = _isLoading
        ? const Center(child: CircularProgressIndicator())
        : Column(
            children: [
              _buildFilterBar(),
              Expanded(
                child: _filteredApplications.isEmpty
                    ? _buildEmptyState()
                    : RefreshIndicator(
                        onRefresh: _fetchPlacements,
                        child: ListView.separated(
                          padding: const EdgeInsets.all(24),
                          itemCount: _filteredApplications.length,
                          separatorBuilder: (context, index) =>
                              const SizedBox(height: 16),
                          itemBuilder: (context, index) {
                            final application = _filteredApplications[index];
                            return _StudentPlacementCard(
                              application: application,
                            );
                          },
                        ),
                      ),
              ),
            ],
          );

    // If embedded, return content without Scaffold
    if (widget.embedded) {
      return content;
    }

    // Otherwise return full Scaffold with AppBar
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Student Placements',
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.bold,
            color: AppTheme.textColor,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchPlacements,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: content,
    );
  }

  Widget _buildFilterBar() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10),
        ],
      ),
      child: Column(
        children: [
          // Search bar
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search by student name, company, or job title...',
              hintStyle: GoogleFonts.outfit(color: Colors.grey[400]),
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _searchQuery = '');
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppTheme.primaryColor),
              ),
              filled: true,
              fillColor: Colors.grey[50],
            ),
            onChanged: (value) {
              setState(() => _searchQuery = value);
            },
          ),
          const SizedBox(height: 16),
          // Filter chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip('All', 'all'),
                const SizedBox(width: 8),
                _buildFilterChip('Applied', 'applied'),
                const SizedBox(width: 8),
                _buildFilterChip('In Progress', 'in_progress'),
                const SizedBox(width: 8),
                _buildFilterChip('Selected', 'selected'),
                const SizedBox(width: 8),
                _buildFilterChip('Rejected', 'rejected'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _selectedFilter == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() => _selectedFilter = value);
      },
      labelStyle: GoogleFonts.outfit(
        color: isSelected ? Colors.white : AppTheme.textColor,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      backgroundColor: Colors.grey[100],
      selectedColor: AppTheme.primaryColor,
      checkmarkColor: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.work_outline, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            _searchQuery.isNotEmpty || _selectedFilter != 'all'
                ? 'No placements found'
                : 'No student applications yet',
            style: GoogleFonts.outfit(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _searchQuery.isNotEmpty || _selectedFilter != 'all'
                ? 'Try adjusting your filters'
                : 'Applications will appear here once students apply',
            style: GoogleFonts.outfit(fontSize: 14, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }
}

class _StudentPlacementCard extends StatelessWidget {
  final JobApplication application;

  const _StudentPlacementCard({required this.application});

  @override
  Widget build(BuildContext context) {
    final student = application.student;
    final job = application.job;
    final offer = application.offer;
    final studentName = student?['full_name'] ?? 'Unknown Student';
    final avatarUrl = student?['profile_photo_url'] ?? student?['avatar_url'];
    final companyName = job?.organization?['name'] ?? 'Unknown Company';
    final companyLogo = job?.organization?['logo_url'];
    final jobTitle = job?.title ?? 'Unknown Position';

    // Get current stage/round info
    final currentStage = _getCurrentStageInfo();

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => NetworkProfileView(
              userId: student?['id'] ?? '',
              userName: studentName,
              userAvatar: avatarUrl,
              userRole: student?['role'] ?? 'student',
            ),
          ),
        );
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[200]!, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryColor.withValues(alpha: 0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
              spreadRadius: 0,
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Premium Company Header with vibrant gradient
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.primaryColor.withValues(alpha: 0.12),
                    AppTheme.primaryColor.withValues(alpha: 0.04),
                    Colors.white.withValues(alpha: 0.5),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  stops: const [0.0, 0.5, 1.0],
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              child: Row(
                children: [
                  // Enhanced Company logo
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(6),
                    child: companyLogo != null && companyLogo.isNotEmpty
                        ? Image.network(
                            companyLogo,
                            fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) => Icon(
                              Icons.business_rounded,
                              size: 24,
                              color: AppTheme.primaryColor,
                            ),
                          )
                        : Icon(
                            Icons.business_rounded,
                            size: 24,
                            color: AppTheme.primaryColor,
                          ),
                  ),
                  const SizedBox(width: 12),
                  // Company name & job title
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          companyName,
                          style: GoogleFonts.outfit(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textColor,
                            letterSpacing: 0.3,
                            height: 1.2,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 3),
                        Text(
                          jobTitle,
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            color: Colors.grey[700],
                            fontWeight: FontWeight.w500,
                            letterSpacing: 0.1,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  // Status badge
                  _buildStatusBadge(application.status),
                ],
              ),
            ),

            // Main content
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Student info row
                  Row(
                    children: [
                      // Enhanced avatar with border
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppTheme.primaryColor.withValues(alpha: 0.2),
                            width: 2,
                          ),
                        ),
                        child: CircleAvatar(
                          radius: 20,
                          backgroundImage:
                              avatarUrl != null && avatarUrl.isNotEmpty
                              ? NetworkImage(avatarUrl)
                              : null,
                          backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
                          child: avatarUrl == null || avatarUrl.isEmpty
                              ? Text(
                                  studentName[0].toUpperCase(),
                                  style: GoogleFonts.outfit(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.primaryColor,
                                  ),
                                )
                              : null,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              studentName,
                              style: GoogleFonts.outfit(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textColor,
                                letterSpacing: 0.2,
                              ),
                            ),
                            if (currentStage != null) ...[
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: currentStage['color'].withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: currentStage['color'].withValues(alpha: 0.3),
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      currentStage['icon'],
                                      size: 11,
                                      color: currentStage['color'],
                                    ),
                                    const SizedBox(width: 5),
                                    Text(
                                      currentStage['label'],
                                      style: GoogleFonts.outfit(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        color: currentStage['color'],
                                        letterSpacing: 0.3,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  // Roadmap with background
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: PlacementRoadmapWidget(
                        application: application,
                        height: 100,
                        compact: false,
                      ),
                    ),
                  ),
                  // Package display
                  if (application.status == 'selected' && offer != null) ...[
                    const SizedBox(height: 14),
                    _buildPackageDisplay(offer),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Get current stage information
  Map<String, dynamic>? _getCurrentStageInfo() {
    final rounds = application.rounds;

    // If no rounds, return status-based stage
    if (rounds == null || rounds.isEmpty) {
      switch (application.status) {
        case 'applied':
          return {
            'label': 'Application Submitted',
            'icon': Icons.send_rounded,
            'color': Colors.blue,
          };
        case 'shortlisted':
          return {
            'label': 'Shortlisted',
            'icon': Icons.check_circle_outline,
            'color': Colors.orange,
          };
        case 'in_progress':
          return {
            'label': 'Under Review',
            'icon': Icons.hourglass_empty_rounded,
            'color': Colors.purple,
          };
        case 'selected':
          return {
            'label': 'Offer Extended',
            'icon': Icons.celebration_rounded,
            'color': Colors.green,
          };
        case 'rejected':
          return {
            'label': 'Not Selected',
            'icon': Icons.cancel_outlined,
            'color': Colors.red,
          };
      }
      return null;
    }

    // Find current round based on currentRound index
    final currentRoundIndex = application.currentRound;
    if (currentRoundIndex >= 0 && currentRoundIndex < rounds.length) {
      final round = rounds[currentRoundIndex];
      return {
        'label': round.title,
        'icon': _getRoundIcon(round.roundType),
        'color': Colors.purple,
      };
    }

    // All rounds completed
    if (application.status == 'selected') {
      return {
        'label': 'Offer Extended',
        'icon': Icons.celebration_rounded,
        'color': Colors.green,
      };
    }

    return null;
  }

  IconData _getRoundIcon(String roundType) {
    switch (roundType.toLowerCase()) {
      case 'technical':
        return Icons.code_rounded;
      case 'aptitude':
        return Icons.psychology_rounded;
      case 'hr':
      case 'behavioral':
        return Icons.people_rounded;
      case 'coding':
        return Icons.terminal_rounded;
      default:
        return Icons.play_circle_outline;
    }
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    String label;

    switch (status) {
      case 'applied':
        color = Colors.blue;
        label = 'APPLIED';
        break;
      case 'shortlisted':
        color = Colors.orange;
        label = 'SHORTLISTED';
        break;
      case 'in_progress':
        color = Colors.purple;
        label = 'IN PROGRESS';
        break;
      case 'selected':
        color = Colors.green;
        label = 'SELECTED';
        break;
      case 'rejected':
        color = Colors.red;
        label = 'REJECTED';
        break;
      default:
        color = Colors.grey;
        label = status.toUpperCase();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color, width: 1.2),
      ),
      child: Text(
        label,
        style: GoogleFonts.outfit(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: color,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildPackageDisplay(Offer offer) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.green.shade400, Colors.green.shade600],
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.celebration, color: Colors.white, size: 32),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Offer Package',
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: 0.9),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${offer.currency} ${offer.packageAmount?.toStringAsFixed(2) ?? '0.00'} LPA',
                  style: GoogleFonts.outfit(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          if (offer.joiningDate != null)
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'Joining Date',
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatDate(offer.joiningDate!),
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

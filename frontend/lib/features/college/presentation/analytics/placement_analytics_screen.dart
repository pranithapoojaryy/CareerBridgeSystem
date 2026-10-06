import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../../core/theme/app_theme.dart';

class PlacementAnalyticsScreen extends ConsumerStatefulWidget {
  const PlacementAnalyticsScreen({super.key});

  @override
  ConsumerState<PlacementAnalyticsScreen> createState() =>
      _PlacementAnalyticsScreenState();
}

class _PlacementAnalyticsScreenState
    extends ConsumerState<PlacementAnalyticsScreen> {
  Map<String, dynamic>? _stats;
  List<Map<String, dynamic>> _recentPlacements = [];
  List<Map<String, dynamic>> _companyStats = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAnalytics();
  }

  Future<void> _loadAnalytics() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      // Get college ID
      final profile = await Supabase.instance.client
          .from('profiles')
          .select('organization_id')
          .eq('id', user.id)
          .single();

      final collegeId = profile['organization_id'];
      if (collegeId == null) {
        setState(() => _isLoading = false);
        return;
      }

      // Get all students from this college
      final students = await Supabase.instance.client
          .from('student_profiles')
          .select('user_id')
          .eq('college_id', collegeId);

      final studentIds = students.map((s) => s['user_id']).toList();
      if (studentIds.isEmpty) {
        setState(() => _isLoading = false);
        return;
      }

      // Get applications with offers
      final applications = await Supabase.instance.client
          .from('job_applications')
          .select('''
            id, status, created_at,
            jobs(title, organizations(name)),
            offers(id, offer_type, package_amount, status)
          ''')
          .inFilter('student_id', studentIds);

      // Calculate stats
      int totalApplications = applications.length;
      int totalShortlisted = applications
          .where(
            (a) =>
                a['status'] == 'shortlisted' ||
                a['status'] == 'in_progress' ||
                a['status'] == 'selected',
          )
          .length;
      int totalSelected = applications
          .where((a) => a['status'] == 'selected')
          .length;
      int totalOffers = applications.where((a) => a['offers'] != null).length;

      // Calculate average package
      double totalPackage = 0;
      int packageCount = 0;
      for (var app in applications) {
        if (app['offers'] != null && app['offers']['package_amount'] != null) {
          totalPackage += (app['offers']['package_amount'] as num).toDouble();
          packageCount++;
        }
      }
      double avgPackage = packageCount > 0 ? totalPackage / packageCount : 0;

      // Group by company
      Map<String, int> companyPlacements = {};
      for (var app in applications) {
        if (app['status'] == 'selected') {
          final companyName =
              app['jobs']?['organizations']?['name'] ?? 'Unknown';
          companyPlacements[companyName] =
              (companyPlacements[companyName] ?? 0) + 1;
        }
      }

      // Convert to list and sort
      final companyStatsList = companyPlacements.entries
          .map((e) => {'name': e.key, 'count': e.value})
          .toList();
      companyStatsList.sort(
        (a, b) => (b['count'] as int).compareTo(a['count'] as int),
      );

      // Get recent placements
      final recentPlacements = applications
          .where((a) => a['status'] == 'selected')
          .take(10)
          .toList();

      setState(() {
        _stats = {
          'totalApplications': totalApplications,
          'totalShortlisted': totalShortlisted,
          'totalSelected': totalSelected,
          'totalOffers': totalOffers,
          'avgPackage': avgPackage,
          'placementRate': totalApplications > 0
              ? (totalSelected / studentIds.length * 100)
              : 0,
        };
        _companyStats = companyStatsList;
        _recentPlacements = recentPlacements;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading analytics: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadAnalytics,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Placement Analytics',
                      style: GoogleFonts.outfit(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Track placement progress and statistics',
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 32),
                    _buildStatsGrid(),
                    const SizedBox(height: 32),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: _buildPlacementChart()),
                        const SizedBox(width: 24),
                        Expanded(child: _buildCompanyBreakdown()),
                      ],
                    ),
                    const SizedBox(height: 32),
                    _buildRecentPlacements(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildStatsGrid() {
    final stats = [
      {
        'label': 'Total Applications',
        'value': _stats?['totalApplications']?.toString() ?? '0',
        'icon': Icons.assignment,
        'color': Colors.blue,
      },
      {
        'label': 'Shortlisted',
        'value': _stats?['totalShortlisted']?.toString() ?? '0',
        'icon': Icons.star,
        'color': Colors.orange,
      },
      {
        'label': 'Placed Students',
        'value': _stats?['totalSelected']?.toString() ?? '0',
        'icon': Icons.check_circle,
        'color': Colors.green,
      },
      {
        'label': 'Avg. Package',
        'value': '₹${(_stats?['avgPackage'] ?? 0).toStringAsFixed(1)} LPA',
        'icon': Icons.currency_rupee,
        'color': Colors.purple,
      },
      {
        'label': 'Placement Rate',
        'value': '${(_stats?['placementRate'] ?? 0).toStringAsFixed(1)}%',
        'icon': Icons.trending_up,
        'color': Colors.teal,
      },
      {
        'label': 'Active Offers',
        'value': _stats?['totalOffers']?.toString() ?? '0',
        'icon': Icons.local_offer,
        'color': Colors.pink,
      },
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 2.2,
        crossAxisSpacing: 20,
        mainAxisSpacing: 20,
      ),
      itemCount: stats.length,
      itemBuilder: (context, index) {
        final stat = stats[index];
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 20),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: (stat['color'] as Color).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  stat['icon'] as IconData,
                  color: stat['color'] as Color,
                  size: 28,
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      stat['value'] as String,
                      style: GoogleFonts.outfit(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      stat['label'] as String,
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        color: Colors.grey[600],
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

  Widget _buildPlacementChart() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 20),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Hiring Funnel',
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 250,
            child: PieChart(
              PieChartData(
                centerSpaceRadius: 60,
                sectionsSpace: 4,
                sections: [
                  PieChartSectionData(
                    value: (_stats?['totalApplications'] ?? 0).toDouble(),
                    color: Colors.blue,
                    title: 'Applied',
                    titleStyle: GoogleFonts.outfit(
                      fontSize: 12,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                    radius: 60,
                  ),
                  PieChartSectionData(
                    value: (_stats?['totalShortlisted'] ?? 0).toDouble(),
                    color: Colors.orange,
                    title: 'Shortlisted',
                    titleStyle: GoogleFonts.outfit(
                      fontSize: 12,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                    radius: 60,
                  ),
                  PieChartSectionData(
                    value: (_stats?['totalSelected'] ?? 0).toDouble(),
                    color: Colors.green,
                    title: 'Placed',
                    titleStyle: GoogleFonts.outfit(
                      fontSize: 12,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                    radius: 60,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompanyBreakdown() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 20),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Top Recruiting Companies',
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          if (_companyStats.isEmpty)
            Center(
              child: Text(
                'No placement data yet',
                style: GoogleFonts.outfit(color: Colors.grey[500]),
              ),
            )
          else
            ...(_companyStats.take(5).map((company) {
              final maxCount = _companyStats.first['count'] as int;
              final count = company['count'] as int;
              final percentage = count / maxCount;

              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          company['name'] as String,
                          style: GoogleFonts.outfit(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          '$count placements',
                          style: GoogleFonts.outfit(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: percentage,
                        minHeight: 8,
                        backgroundColor: Colors.grey[200],
                        valueColor: AlwaysStoppedAnimation(
                          AppTheme.primaryColor,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList()),
        ],
      ),
    );
  }

  Widget _buildRecentPlacements() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 20),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recent Placements',
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton(
                onPressed: () {
                  // TODO: Navigate to full list
                },
                child: const Text('View All'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_recentPlacements.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text(
                  'No placements recorded yet',
                  style: GoogleFonts.outfit(color: Colors.grey[500]),
                ),
              ),
            )
          else
            DataTable(
              columns: [
                DataColumn(
                  label: Text(
                    'Student',
                    style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'Company',
                    style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'Position',
                    style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'Package',
                    style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
              rows: _recentPlacements.map((placement) {
                final offer = placement['offers'];
                return DataRow(
                  cells: [
                    DataCell(
                      Text('Student'),
                    ), // Would need to join with profiles
                    DataCell(
                      Text(
                        placement['jobs']?['organizations']?['name'] ?? 'N/A',
                      ),
                    ),
                    DataCell(Text(placement['jobs']?['title'] ?? 'N/A')),
                    DataCell(
                      Text(
                        offer != null && offer['package_amount'] != null
                            ? '₹${offer['package_amount']} LPA'
                            : 'N/A',
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
        ],
      ),
    );
  }
}

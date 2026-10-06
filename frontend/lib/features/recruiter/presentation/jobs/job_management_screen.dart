import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'job_posting_screen.dart';

class JobManagementScreen extends ConsumerStatefulWidget {
  final VoidCallback? onBackPressed;

  const JobManagementScreen({super.key, this.onBackPressed});

  @override
  ConsumerState<JobManagementScreen> createState() =>
      _JobManagementScreenState();
}

class _JobManagementScreenState extends ConsumerState<JobManagementScreen> {
  List<Map<String, dynamic>> _jobs = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadJobs();
  }

  Future<void> _loadJobs() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      final response = await Supabase.instance.client
          .from('jobs')
          .select('*')
          .eq('posted_by', user.id)
          .order('created_at', ascending: false);

      if (mounted) {
        setState(() {
          _jobs = List<Map<String, dynamic>>.from(response);
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading jobs: $e');
      if (mounted) setState(() => _isLoading = false);
    }
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
        // Grid View of Jobs
        Expanded(
          flex: 3,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: 24),
                if (_jobs.isEmpty)
                  _buildEmptyState()
                else
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 400,
                          mainAxisExtent: 320,
                          crossAxisSpacing: 24,
                          mainAxisSpacing: 24,
                        ),
                    itemCount: _jobs.length,
                    itemBuilder: (context, index) {
                      return _buildJobGridTile(_jobs[index]);
                    },
                  ),
              ],
            ),
          ),
        ),

        // Right Sidebar Analytics
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
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 24),
          if (_jobs.isEmpty)
            _buildEmptyState()
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _jobs.length,
              itemBuilder: (context, index) {
                return _buildJobCard(
                  _jobs[index],
                ); // Keep original card for mobile
              },
            ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
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
              'Job Postings',
              style: GoogleFonts.outfit(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        FilledButton.icon(
          onPressed: () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const JobPostingScreen()),
            );
            if (result == true) {
              _loadJobs();
            }
          },
          icon: const Icon(Icons.add),
          label: const Text('Post New Job'),
          style: FilledButton.styleFrom(
            backgroundColor: Colors.orange,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        children: [
          const SizedBox(height: 64),
          Icon(Icons.work_outline, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No jobs posted yet',
            style: GoogleFonts.outfit(fontSize: 18, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildJobGridTile(Map<String, dynamic> job) {
    final status = job['status'] ?? 'draft';
    final isClosed = status == 'closed';
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
                    job['title'] ?? 'Untitled',
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 16),

                  // Form-like Fields
                  _buildGridField('Location', job['location'] ?? 'Remote'),
                  const SizedBox(height: 8),
                  _buildGridField('Type', job['job_type'] ?? 'Full-time'),
                  const SizedBox(height: 8),
                  _buildGridField(
                    'Posted On',
                    DateFormat('MMM d, yyyy').format(date),
                  ),

                  const Spacer(),
                ],
              ),
            ),
          ),

          // Footer Actions
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (!isClosed)
                  TextButton(
                    onPressed: () => _closeJob(job['id']),
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(50, 30),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      'Close',
                      style: GoogleFonts.outfit(
                        color: Colors.orange,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                const Spacer(),
                IconButton(
                  icon: const Icon(
                    Icons.delete_outline,
                    size: 20,
                    color: Colors.red,
                  ),
                  onPressed: () => _confirmDelete(job['id']),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGridField(String label, String value) {
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

  Widget _buildAnalyticsSidebar() {
    final totalJobs = _jobs.length;
    final activeJobs = _jobs.where((j) => j['status'] == 'open').length;
    final closedJobs = _jobs.where((j) => j['status'] == 'closed').length;
    final fullTime = _jobs.where((j) => j['job_type'] == 'Full-time').length;

    // Calculate simple trends (mocking "this week" vs "total" for visual)
    final thisWeekStart = DateTime.now().subtract(const Duration(days: 7));
    final newJobsThisWeek = _jobs
        .where((j) => DateTime.parse(j['created_at']).isAfter(thisWeekStart))
        .length;

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text(
          'Performance Overview',
          style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 24),

        _buildAnalyticsCard(
          title: 'Total Active Jobs',
          value: activeJobs.toString(),
          trend: '+$newJobsThisWeek new this week',
          icon: Icons.check_circle_outline,
          color: Colors.green,
        ),
        const SizedBox(height: 16),
        _buildAnalyticsCard(
          title: 'Total Posted',
          value: totalJobs.toString(),
          trend: 'Lifetime total',
          icon: Icons.work_outline,
          color: Colors.blue,
        ),
        const SizedBox(height: 16),
        _buildAnalyticsCard(
          title: 'Closed / Filled',
          value: closedJobs.toString(),
          trend:
              '${((closedJobs / (totalJobs == 0 ? 1 : totalJobs)) * 100).toStringAsFixed(0)}% closure rate',
          icon: Icons.archive_outlined,
          color: Colors.orange,
        ),

        const SizedBox(height: 32),
        Text(
          'Job Types Distribution',
          style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        _buildDistributionBar('Full-time', fullTime, totalJobs, Colors.purple),
        const SizedBox(height: 12),
        _buildDistributionBar(
          'Part-time',
          _jobs.where((j) => j['job_type'] == 'Part-time').length,
          totalJobs,
          Colors.teal,
        ),
        const SizedBox(height: 12),
        _buildDistributionBar(
          'Internship',
          _jobs.where((j) => j['job_type'] == 'Internship').length,
          totalJobs,
          Colors.amber,
        ),
        const SizedBox(height: 12),
        _buildDistributionBar(
          'Contract',
          _jobs.where((j) => j['job_type'] == 'Contract').length,
          totalJobs,
          Colors.redAccent,
        ),
      ],
    );
  }

  Widget _buildAnalyticsCard({
    required String title,
    required String value,
    required String trend,
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
                  height: 1.0,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                trend,
                style: GoogleFonts.outfit(fontSize: 11, color: color),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDistributionBar(
    String label,
    int count,
    int total,
    Color color,
  ) {
    if (count == 0 && total > 0)
      return const SizedBox.shrink(); // Hide if empty
    final percentage = total == 0 ? 0.0 : count / total;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: GoogleFonts.outfit(
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              '$count',
              style: GoogleFonts.outfit(
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: percentage,
            backgroundColor: Colors.grey[100],
            color: color,
            minHeight: 6,
          ),
        ),
      ],
    );
  }

  Widget _buildJobCard(Map<String, dynamic> job) {
    final status = job['status'] ?? 'draft';
    final statusColor = status == 'open'
        ? Colors.green
        : (status == 'closed' ? Colors.red : Colors.grey);
    final isClosed = status == 'closed';

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
                child: Text(
                  job['title'] ?? 'Untitled Job',
                  style: GoogleFonts.outfit(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
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
          const SizedBox(height: 12),
          Text(
            job['description'] ?? '',
            style: GoogleFonts.outfit(fontSize: 14, color: Colors.grey[600]),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 4),
              Text(
                job['location'] ?? 'Not specified',
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(width: 24),
              Icon(Icons.work, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 4),
              Text(
                job['job_type'] ?? 'Full-time',
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              const Spacer(),
              if (!isClosed)
                TextButton.icon(
                  onPressed: () => _closeJob(job['id']),
                  icon: const Icon(Icons.close, size: 16),
                  label: const Text('Close'),
                  style: TextButton.styleFrom(foregroundColor: Colors.orange),
                ),
              const SizedBox(width: 8),
              TextButton.icon(
                onPressed: () => _confirmDelete(job['id']),
                icon: const Icon(Icons.delete_outline, size: 16),
                label: const Text('Delete'),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _closeJob(String jobId) async {
    try {
      await Supabase.instance.client
          .from('jobs')
          .update({'status': 'closed'})
          .eq('id', jobId);
      _loadJobs();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Job closed successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error closing job: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _confirmDelete(String jobId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Job Posting?'),
        content: const Text(
          'This will permanently delete this job. Can\'t be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true) _deleteJob(jobId);
  }

  Future<void> _deleteJob(String jobId) async {
    try {
      await Supabase.instance.client.from('jobs').delete().eq('id', jobId);
      _loadJobs();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Job deleted'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
    }
  }
}

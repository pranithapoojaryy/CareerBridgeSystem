import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/college_providers.dart';
import 'assessment_questions_screen.dart';
import 'create_assessment_screen.dart';

class AssessmentDetailsScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic> assessment;

  const AssessmentDetailsScreen({super.key, required this.assessment});

  @override
  ConsumerState<AssessmentDetailsScreen> createState() =>
      _AssessmentDetailsScreenState();
}

class _AssessmentDetailsScreenState
    extends ConsumerState<AssessmentDetailsScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _attempts = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchAttempts();
  }

  Future<void> _fetchAttempts() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final attempts = await ref
          .read(collegeRepositoryProvider)
          .getAssessmentAttempts(widget.assessment['id']);

      setState(() {
        _attempts = attempts;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.assessment['title'] ?? 'Assessment Details';
    final totalAttempts = _attempts.length;
    final avgScore = _attempts.isEmpty
        ? 0.0
        : _attempts
                  .map((a) => (a['score'] as num).toDouble())
                  .reduce((a, b) => a + b) /
              totalAttempts;
    final passedCount = _attempts
        .where((a) => (a['status'] == 'passed'))
        .length;
    final passRate = totalAttempts == 0
        ? 0.0
        : (passedCount / totalAttempts) * 100;

    return Container(
      height: MediaQuery.of(context).size.height * 0.95,
      decoration: const BoxDecoration(
        color: Color(0xFFF9FAFC),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(32),
          topRight: Radius.circular(32),
        ),
      ),
      child: Column(
        children: [
          // Premium Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            decoration: const BoxDecoration(
              color: Color(0xFF1A1F36),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(32),
                topRight: Radius.circular(32),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    title.toUpperCase(),
                    style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 1.2,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, color: Colors.white),
                  color: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  onSelected: (value) {
                    if (value == 'view_questions') {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AssessmentQuestionsScreen(
                            assessment: widget.assessment,
                          ),
                        ),
                      );
                    } else if (value == 'edit') {
                      // Close details modal first, then open edit modal
                      Navigator.pop(context);
                      // This needs to be handled by the parent or re-opened
                      // ideally pass a callback or use a navigator key, but for now:
                      // We will let the user navigate back to edit.
                      // OR we can push the edit modal on top.
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (_) => CreateAssessmentScreen(
                          assessment: widget.assessment,
                        ),
                      );
                    } else if (value == 'delete') {
                      _confirmDelete();
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'view_questions',
                      child: Row(
                        children: [
                          const Icon(
                            Icons.quiz_outlined,
                            size: 20,
                            color: Color(0xFF1A1F36),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'View Questions',
                            style: GoogleFonts.outfit(
                              color: const Color(0xFF1A1F36),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          const Icon(
                            Icons.edit_outlined,
                            size: 20,
                            color: Color(0xFF1A1F36),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Edit Assessment',
                            style: GoogleFonts.outfit(
                              color: const Color(0xFF1A1F36),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          const Icon(
                            Icons.delete_outline,
                            color: Colors.red,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Delete',
                            style: GoogleFonts.outfit(
                              color: Colors.red,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(
                    Icons.close_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
              ],
            ),
          ),

          // Content
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                ? Center(
                    child: Text(
                      'Error loading details: $_error',
                      style: GoogleFonts.outfit(color: Colors.red),
                    ),
                  )
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildStatsOverview(totalAttempts, avgScore, passRate),
                        const SizedBox(height: 32),
                        Text(
                          'STUDENT ATTEMPTS',
                          style: GoogleFonts.outfit(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF1A1F36),
                            letterSpacing: 1.1,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildAttemptsTable(),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsOverview(
    int totalAttempts,
    double avgScore,
    double passRate,
  ) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'Total Attempts',
            totalAttempts.toString(),
            Icons.people_alt_outlined,
            Colors.blue,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            'Average Score',
            '${avgScore.toStringAsFixed(1)}%',
            Icons.analytics_outlined,
            Colors.purple,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            'Pass Rate',
            '${passRate.toStringAsFixed(0)}%',
            Icons.check_circle_outline,
            Colors.green,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
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
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: GoogleFonts.outfit(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppTheme.textColor,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildAttemptsTable() {
    if (_attempts.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Text(
            'No attempts yet.',
            style: GoogleFonts.outfit(color: Colors.grey),
          ),
        ),
      );
    }

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Table(
        columnWidths: const {
          0: FlexColumnWidth(2), // Student Name
          1: FlexColumnWidth(1), // Score
          2: FlexColumnWidth(1), // Status
          3: FlexColumnWidth(1.5), // Date
        },
        defaultVerticalAlignment: TableCellVerticalAlignment.middle,
        children: [
          _buildTableHeader(),
          ..._attempts.map((attempt) => _buildTableRow(attempt)),
        ],
      ),
    );
  }

  TableRow _buildTableHeader() {
    return TableRow(
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
      ),
      children: [
        _buildHeaderCell('Student'),
        _buildHeaderCell('Score'),
        _buildHeaderCell('Status'),
        _buildHeaderCell('Date'),
      ],
    );
  }

  Widget _buildHeaderCell(String text) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Text(
        text,
        style: GoogleFonts.outfit(
          fontWeight: FontWeight.bold,
          color: Colors.grey[700],
          fontSize: 13,
        ),
      ),
    );
  }

  TableRow _buildTableRow(Map<String, dynamic> attempt) {
    final profile = attempt['profiles'] ?? {};
    final name = profile['full_name'] ?? 'Unknown';
    final email = profile['email'] ?? '';
    final score = attempt['score'] ?? 0;
    final status = attempt['status'] ?? 'pending';
    final date = DateTime.parse(attempt['created_at']);
    final formattedDate = DateFormat('MMM d, h:mm a').format(date);

    return TableRow(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFEEEEEE))),
      ),
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              if (email.isNotEmpty)
                Text(
                  email,
                  style: GoogleFonts.outfit(color: Colors.grey, fontSize: 10),
                  overflow: TextOverflow.ellipsis,
                ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(12),
          child: Text(
            '$score%',
            style: GoogleFonts.outfit(
              fontWeight: FontWeight.bold,
              color: _getScoreColor(score),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _getStatusColor(status).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              status.toString().toUpperCase(),
              style: GoogleFonts.outfit(
                color: _getStatusColor(status),
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(12),
          child: Text(
            formattedDate,
            style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey[600]),
          ),
        ),
      ],
    );
  }

  Color _getScoreColor(num score) {
    if (score >= 80) return Colors.green;
    if (score >= 60) return Colors.orange;
    return Colors.red;
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'passed':
        return Colors.green;
      case 'failed':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Assessment'),
        content: Text(
          'Are you sure you want to delete "${widget.assessment['title']}"? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              final navigator = Navigator.of(context);
              navigator.pop(); // Close dialog

              try {
                await ref
                    .read(collegeRepositoryProvider)
                    .deleteAssessment(widget.assessment['id']);

                if (mounted) {
                  messenger.showSnackBar(
                    const SnackBar(content: Text('Assessment deleted')),
                  );
                  navigator.pop('deleted'); // Close details screen
                }
              } catch (e) {
                if (mounted) {
                  messenger.showSnackBar(
                    SnackBar(content: Text('Error deleting assessment: $e')),
                  );
                }
              }
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../student/data/learning_repository.dart';
import '../../../student/domain/learning_course.dart';

/// Screen to display enrolled students for a specific course
class CourseEnrollmentsScreen extends ConsumerStatefulWidget {
  final LearningCourse course;

  const CourseEnrollmentsScreen({Key? key, required this.course})
    : super(key: key);

  @override
  ConsumerState<CourseEnrollmentsScreen> createState() =>
      _CourseEnrollmentsScreenState();
}

class _CourseEnrollmentsScreenState
    extends ConsumerState<CourseEnrollmentsScreen> {
  List<Map<String, dynamic>> _enrollments = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadEnrollments();
  }

  Future<void> _loadEnrollments() async {
    setState(() => _isLoading = true);
    try {
      final repo = ref.read(learningRepositoryProvider);
      final enrollments = await repo.getCourseEnrollments(widget.course.id);
      if (mounted) {
        setState(() {
          _enrollments = enrollments;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading enrollments: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Enrolled Students', style: GoogleFonts.outfit(fontSize: 18)),
            Text(
              widget.course.title,
              style: GoogleFonts.outfit(
                fontSize: 13,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadEnrollments,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _enrollments.isEmpty
          ? _buildEmptyState()
          : _buildEnrollmentsList(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people_outline, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No students enrolled yet',
            style: GoogleFonts.outfit(fontSize: 18, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildEnrollmentsList() {
    return Column(
      children: [
        // Summary Card
        Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue.shade400, Colors.blue.shade600],
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildSummaryItem(
                'Total Students',
                _enrollments.length.toString(),
                Icons.people,
              ),
              _buildSummaryItem(
                'Avg Progress',
                '${_calculateAverageProgress().toStringAsFixed(1)}%',
                Icons.trending_up,
              ),
              _buildSummaryItem(
                'Completed',
                _enrollments
                    .where((e) => e['is_completed'] == true)
                    .length
                    .toString(),
                Icons.check_circle,
              ),
            ],
          ),
        ),

        // Students List
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _enrollments.length,
            itemBuilder: (context, index) {
              final enrollment = _enrollments[index];
              return _buildEnrollmentCard(enrollment);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 32),
        const SizedBox(height: 8),
        Text(
          value,
          style: GoogleFonts.outfit(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 12,
            color: Colors.white.withValues(alpha: 0.9),
          ),
        ),
      ],
    );
  }

  Widget _buildEnrollmentCard(Map<String, dynamic> enrollment) {
    final enrolledDate = DateTime.tryParse(enrollment['enrolled_date'] ?? '');
    final progress =
        (enrollment['progress_percent'] as num?)?.toDouble() ?? 0.0;
    final isCompleted = enrollment['is_completed'] == true;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showEnrollmentDetails(enrollment),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Student Avatar
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: Colors.blue.shade100,
                    child: Text(
                      (enrollment['student_name'] ?? 'U')[0].toUpperCase(),
                      style: GoogleFonts.outfit(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),

                  // Student Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          enrollment['student_name'] ?? 'Unknown',
                          style: GoogleFonts.outfit(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          enrollment['student_email'] ?? '',
                          style: GoogleFonts.outfit(
                            fontSize: 13,
                            color: Colors.grey[600],
                          ),
                        ),
                        if (enrollment['student_college'] != null) ...[
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Icon(
                                Icons.school,
                                size: 14,
                                color: Colors.grey[600],
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  enrollment['student_college'],
                                  style: GoogleFonts.outfit(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),

                  // Status Badge
                  if (isCompleted)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.shade100,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.check_circle,
                            size: 16,
                            color: Colors.green.shade700,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Completed',
                            style: GoogleFonts.outfit(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.green.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),

              const SizedBox(height: 16),

              // Progress Bar
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Progress',
                        style: GoogleFonts.outfit(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        '${progress.toStringAsFixed(1)}%',
                        style: GoogleFonts.outfit(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.blue.shade700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: progress / 100,
                    backgroundColor: Colors.grey.shade200,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      progress >= 100
                          ? Colors.green
                          : progress >= 50
                          ? Colors.blue
                          : Colors.orange,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Details Row
              Wrap(
                spacing: 16,
                runSpacing: 8,
                children: [
                  if (enrollment['student_mobile'] != null)
                    _buildDetailChip(Icons.phone, enrollment['student_mobile']),
                  if (enrollment['usn'] != null)
                    _buildDetailChip(Icons.badge, 'USN: ${enrollment['usn']}'),
                  if (enrollment['department'] != null)
                    _buildDetailChip(Icons.apartment, enrollment['department']),
                  if (enrolledDate != null)
                    _buildDetailChip(
                      Icons.calendar_today,
                      'Enrolled: ${DateFormat('dd MMM yyyy').format(enrolledDate)}',
                    ),
                  if (enrollment['assessments_done'] != null &&
                      enrollment['assessments_done'] > 0)
                    _buildDetailChip(
                      Icons.assignment_turned_in,
                      'Assessments: ${enrollment['assessments_done']}',
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailChip(IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: Colors.grey[600]),
        const SizedBox(width: 4),
        Text(
          label,
          style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey[700]),
        ),
      ],
    );
  }

  double _calculateAverageProgress() {
    if (_enrollments.isEmpty) return 0.0;
    final total = _enrollments.fold<double>(
      0.0,
      (sum, e) => sum + ((e['progress_percent'] as num?)?.toDouble() ?? 0.0),
    );
    return total / _enrollments.length;
  }

  void _showEnrollmentDetails(Map<String, dynamic> enrollment) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          enrollment['student_name'] ?? 'Student Details',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Email', enrollment['student_email']),
              _buildDetailRow(
                'Mobile',
                enrollment['student_mobile'] ?? 'Not provided',
              ),
              _buildDetailRow(
                'College',
                enrollment['student_college'] ?? 'Not specified',
              ),
              _buildDetailRow('USN', enrollment['usn'] ?? 'Not provided'),
              _buildDetailRow(
                'Department',
                enrollment['department'] ?? 'Not specified',
              ),
              _buildDetailRow(
                'Semester',
                enrollment['semester']?.toString() ?? 'N/A',
              ),
              _buildDetailRow('CGPA', enrollment['cgpa']?.toString() ?? 'N/A'),
              const Divider(height: 24),
              _buildDetailRow(
                'Progress',
                '${enrollment['progress_percent'] ?? 0}%',
              ),
              _buildDetailRow(
                'Assessments',
                enrollment['assessments_done']?.toString() ?? '0',
              ),
              _buildDetailRow(
                'Avg Score',
                enrollment['avg_score']?.toStringAsFixed(1) ?? 'N/A',
              ),
              _buildDetailRow(
                'Current Section',
                enrollment['current_section_name'] ?? 'Not started',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value ?? 'N/A',
              style: GoogleFonts.outfit(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

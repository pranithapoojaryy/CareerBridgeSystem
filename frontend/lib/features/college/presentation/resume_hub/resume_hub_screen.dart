import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../data/college_providers.dart';
import '../../../resume/data/resume_providers.dart';

class ResumeHubScreen extends ConsumerStatefulWidget {
  const ResumeHubScreen({super.key});

  @override
  ConsumerState<ResumeHubScreen> createState() => _ResumeHubScreenState();
}

class _ResumeHubScreenState extends ConsumerState<ResumeHubScreen> {
  String _searchQuery = '';
  final _feedbackController = TextEditingController();

  @override
  void dispose() {
    _feedbackController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final collegeId = ref.watch(currentCollegeProvider).value?['id'];
    final studentsAsync = ref.watch(studentsProvider(collegeId));

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 24),
          _buildStatsBar(studentsAsync),
          const SizedBox(height: 24),
          _buildSearchField(),
          const SizedBox(height: 20),
          Expanded(
            child: studentsAsync.when(
              data: (students) {
                var filtered = students.where((s) {
                  final profiles =
                      s['student_profiles'] as Map<String, dynamic>?;
                  return profiles != null && profiles['resume_url'] != null;
                }).toList();

                if (_searchQuery.isNotEmpty) {
                  filtered = filtered.where((s) {
                    final name = s['full_name']?.toString().toLowerCase() ?? '';
                    final profiles =
                        s['student_profiles'] as Map<String, dynamic>?;
                    final usn =
                        profiles?['usn']?.toString().toLowerCase() ?? '';
                    return name.contains(_searchQuery.toLowerCase()) ||
                        usn.contains(_searchQuery.toLowerCase());
                  }).toList();
                }

                if (filtered.isEmpty) return _buildEmptyState();

                return GridView.builder(
                  padding: const EdgeInsets.only(bottom: 24),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 5,
                    childAspectRatio:
                        1.25, // Adjusted slightly to prevent vertical overflow/zero-size issues
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) =>
                      _buildResumeCard(filtered[index], index),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(child: Text('Error: $err')),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppTheme.primaryColor,
                AppTheme.primaryColor.withValues(alpha: 0.8),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryColor.withValues(alpha: 0.2),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Icon(
            Icons.description_rounded,
            color: Colors.white,
            size: 24,
          ),
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Resume Hub',
              style: GoogleFonts.outfit(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A1C1E),
                letterSpacing: -0.5,
              ),
            ),
            Text(
              'Consolidated repository of student credentials',
              style: GoogleFonts.outfit(fontSize: 13, color: Colors.grey[600]),
            ),
          ],
        ),
      ],
    ).animate().fadeIn(duration: 400.ms).slideX(begin: -0.05);
  }

  Widget _buildStatsBar(AsyncValue<List<Map<String, dynamic>>> studentsAsync) {
    return studentsAsync
        .maybeWhen(
          data: (students) {
            final totalWithResumes = students
                .where(
                  (s) => (s['student_profiles'] as Map?)?['resume_url'] != null,
                )
                .length;
            final totalStudents = students.length;

            return Row(
              children: [
                _buildStatItem(
                  'Total Students',
                  '$totalStudents',
                  Icons.people_outline,
                  Colors.blue,
                ),
                const SizedBox(width: 12),
                _buildStatItem(
                  'Resumes Available',
                  '$totalWithResumes',
                  Icons.assignment_turned_in_outlined,
                  Colors.green,
                ),
                const SizedBox(width: 12),
                _buildStatItem(
                  'Pending Review',
                  'N/A',
                  Icons.pending_actions_rounded,
                  Colors.orange,
                ),
              ],
            );
          },
          orElse: () => const SizedBox.shrink(),
        )
        .animate()
        .fadeIn(delay: 200.ms);
  }

  Widget _buildStatItem(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.1)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 16),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1C1E),
                  ),
                ),
                Text(
                  label,
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    color: Colors.grey[500],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchField() {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        onChanged: (value) => setState(() => _searchQuery = value),
        style: GoogleFonts.outfit(fontSize: 14),
        textAlignVertical: TextAlignVertical.center,
        decoration: InputDecoration(
          hintText: 'Search by student name or USN...',
          hintStyle: GoogleFonts.outfit(color: Colors.grey[400], fontSize: 13),
          prefixIcon: Icon(
            Icons.search_rounded,
            color: AppTheme.primaryColor,
            size: 20,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
          isDense: true,
        ),
      ),
    ).animate().fadeIn(delay: 300.ms);
  }

  Widget _buildResumeCard(Map<String, dynamic> student, int index) {
    final profiles = student['student_profiles'] as Map<String, dynamic>;
    final resumeUrl = profiles['resume_url'] as String;
    final name = student['full_name'] ?? 'Unknown';
    final usn = profiles['usn'] ?? 'N/A';
    final dept = (student['department'] as Map?)?['name'] ?? 'N/A';
    final cgpa = profiles['cgpa']?.toString() ?? 'N/A';

    return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Column(
              children: [
                // Top Section with Gradient Accent
                Container(
                  height: 3,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.primaryColor,
                        AppTheme.primaryColor.withValues(alpha: 0.5),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Name and USN Row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    name,
                                    style: GoogleFonts.outfit(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                      color: Color(0xFF1A1C1E),
                                      height: 1.2,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    usn,
                                    style: GoogleFonts.outfit(
                                      color: Colors.grey[500],
                                      fontSize: 10,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),

                        // Details Row (Dept & CGPA)
                        Row(
                          children: [
                            Expanded(
                              child: _buildIconLabel(
                                Icons.business_rounded,
                                dept,
                                Colors.blue,
                                isFlexible:
                                    true, // Allow dept to flex and truncate
                              ),
                            ),
                            const SizedBox(width: 8),
                            // CGPA is fixed, not flexible
                            _buildIconLabel(
                              Icons.star_rounded,
                              '$cgpa',
                              Colors.amber,
                              isFlexible: false,
                            ),
                          ],
                        ),

                        const Spacer(),

                        // Action Buttons
                        Row(
                          children: [
                            Expanded(
                              child: _CardButton(
                                onTap: () => _viewResume(resumeUrl),
                                icon: Icons.visibility_rounded,
                                label: 'View',
                                color: AppTheme.primaryColor,
                                isPrimary: true,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: _CardButton(
                                onTap: () =>
                                    _showFeedbackDialog(student['id'], name),
                                icon: Icons.chat_bubble_outline_rounded,
                                label: 'Review',
                                color: Colors.grey[600]!,
                                isPrimary: false,
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
        )
        .animate(delay: (index * 30).ms)
        .fadeIn(duration: 300.ms)
        .scale(begin: const Offset(0.95, 0.95));
  }

  // Updated to support flexibility control
  Widget _buildIconLabel(
    IconData icon,
    String label,
    Color color, {
    bool isFlexible = false,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color.withValues(alpha: 0.7), size: 12),
        const SizedBox(width: 6),
        if (isFlexible)
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.outfit(
                fontSize: 11,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          )
        else
          Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: 11,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.description_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No resumes found',
            style: GoogleFonts.outfit(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try adjusting your search or filters',
            style: GoogleFonts.outfit(fontSize: 14, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Future<void> _viewResume(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  Future<void> _showFeedbackDialog(String studentId, String studentName) async {
    _feedbackController.clear();
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Review for $studentName',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Share your constructive feedback to help the student polish their professional profile.',
              style: GoogleFonts.outfit(fontSize: 14, color: Colors.grey[600]),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _feedbackController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Enter feedback...',
                filled: true,
                fillColor: Colors.grey[50],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Dismiss',
              style: GoogleFonts.outfit(color: Colors.grey),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              if (_feedbackController.text.trim().isEmpty) return;
              Navigator.pop(context);
              await _submitFeedback(studentId, _feedbackController.text.trim());
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(
              'Submit Review',
              style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _submitFeedback(String studentId, String content) async {
    try {
      await ref.read(resumeRepositoryProvider).addFeedback(studentId, content);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Feedback submitted successfully!'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }
}

class _CardButton extends StatelessWidget {
  final VoidCallback onTap;
  final IconData icon;
  final String label;
  final Color color;
  final bool isPrimary;

  const _CardButton({
    required this.onTap,
    required this.icon,
    required this.label,
    required this.color,
    required this.isPrimary,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isPrimary ? color.withValues(alpha: 0.08) : Colors.transparent,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: isPrimary
                ? null
                : Border.all(color: Colors.grey.withValues(alpha: 0.2)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 14, color: isPrimary ? color : Colors.grey[700]),
              const SizedBox(width: 6),
              Text(
                label,
                style: GoogleFonts.outfit(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: isPrimary ? color : Colors.grey[700],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

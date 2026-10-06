import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class ResumeScreeningScreen extends ConsumerStatefulWidget {
  final VoidCallback? onBackPressed;

  const ResumeScreeningScreen({super.key, this.onBackPressed});

  @override
  ConsumerState<ResumeScreeningScreen> createState() =>
      _ResumeScreeningScreenState();
}

class _ResumeScreeningScreenState extends ConsumerState<ResumeScreeningScreen> {
  List<Map<String, dynamic>> _applications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPendingApplications();
  }

  Future<void> _loadPendingApplications() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      // Get recruiter's jobs
      final jobsResponse = await Supabase.instance.client
          .from('jobs')
          .select('id')
          .eq('posted_by', user.id);

      if (jobsResponse.isEmpty) {
        setState(() => _isLoading = false);
        return;
      }

      final jobIds = jobsResponse.map((j) => j['id']).toList();

      // Get PENDING applications only
      final response = await Supabase.instance.client
          .from('job_applications')
          .select(
            '*, jobs(title), profiles(full_name, email, profile_photo_url)',
          )
          .inFilter('job_id', jobIds)
          .eq('status', 'pending')
          .order('applied_at', ascending: false);

      setState(() {
        _applications = List<Map<String, dynamic>>.from(response);
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading pending applications: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updateStatus(String applicationId, String newStatus) async {
    try {
      await Supabase.instance.client
          .from('job_applications')
          .update({'status': newStatus})
          .eq('id', applicationId);

      setState(() {
        _applications.removeWhere((app) => app['id'] == applicationId);
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Application marked as $newStatus'),
            backgroundColor: newStatus == 'shortlisted'
                ? Colors.green
                : Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating status: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _openResume(String? url) async {
    if (url == null || url.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('No resume attached')));
      return;
    }

    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Could not open resume')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
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
                        'Resume Screening',
                        style: GoogleFonts.outfit(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.blue.shade200),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.auto_awesome,
                              size: 16,
                              color: Colors.blue,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'AI Enabled',
                              style: GoogleFonts.outfit(
                                fontSize: 13,
                                color: Colors.blue.shade700,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Review and process pending applications with AI assistance',
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 24),
                  if (_applications.isEmpty)
                    Center(
                      child: Column(
                        children: [
                          const SizedBox(height: 64),
                          Icon(
                            Icons.check_circle_outline,
                            size: 64,
                            color: Colors.green.shade200,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'All caught up!',
                            style: GoogleFonts.outfit(
                              fontSize: 18,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'No pending applications to review',
                            style: GoogleFonts.outfit(
                              fontSize: 14,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _applications.length,
                      itemBuilder: (context, index) {
                        return _buildScreeningCard(_applications[index]);
                      },
                    ),
                ],
              ),
            ),
    );
  }

  Widget _buildScreeningCard(Map<String, dynamic> application) {
    final candidateName =
        application['profiles']?['full_name'] ?? 'Unknown Candidate';
    final jobTitle = application['jobs']?['title'] ?? 'Unknown Job';
    final resumeUrl = application['resume_url'];
    final coverLetter = application['cover_letter'];

    // Simulate AI Score (Deterministic based on name length to keep it consistent-ish)
    final aiScore = 70 + (candidateName.length * 2) % 25;

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
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
          // Header
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: Colors.blue.shade100,
                  backgroundImage:
                      application['profiles']?['profile_photo_url'] != null
                      ? NetworkImage(
                          application['profiles']!['profile_photo_url'],
                        )
                      : null,
                  child: application['profiles']?['profile_photo_url'] == null
                      ? Text(
                          candidateName[0].toUpperCase(),
                          style: GoogleFonts.outfit(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade700,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 16),
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
                      Text(
                        'Applying for $jobTitle',
                        style: GoogleFonts.outfit(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: aiScore > 85
                        ? Colors.green.shade50
                        : Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: aiScore > 85
                          ? Colors.green.shade200
                          : Colors.orange.shade200,
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        '$aiScore%',
                        style: GoogleFonts.outfit(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: aiScore > 85
                              ? Colors.green.shade700
                              : Colors.orange.shade700,
                        ),
                      ),
                      Text(
                        'Match Score',
                        style: GoogleFonts.outfit(
                          fontSize: 10,
                          color: aiScore > 85
                              ? Colors.green.shade600
                              : Colors.orange.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Content
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'COVER LETTER',
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[500],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        coverLetter ?? 'No cover letter provided.',
                        style: GoogleFonts.outfit(
                          fontSize: 14,
                          color: Colors.grey[800],
                          height: 1.5,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 24),
                Expanded(
                  flex: 2,
                  child: InkWell(
                    onTap: () => _openResume(resumeUrl),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.picture_as_pdf,
                            color: Colors.red.shade400,
                            size: 32,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'View Resume',
                            style: GoogleFonts.outfit(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Actions
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () =>
                        _updateStatus(application['id'], 'rejected'),
                    icon: const Icon(Icons.close),
                    label: const Text('Reject'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () =>
                        _updateStatus(application['id'], 'shortlisted'),
                    icon: const Icon(Icons.check),
                    label: const Text('Shortlist'),
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

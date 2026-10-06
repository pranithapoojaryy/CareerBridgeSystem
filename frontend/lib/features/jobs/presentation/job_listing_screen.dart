import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/theme/app_theme.dart';
import 'application_timeline_screen.dart';
import '../../resume/data/resume_providers.dart';
import '../../resume/data/resume_data_service.dart';
import '../data/job_repository.dart';
import '../domain/job_model.dart';
import '../domain/services/resume_matching_service.dart';
import 'widgets/video_screening_dialog.dart';

class JobListingScreen extends ConsumerStatefulWidget {
  const JobListingScreen({super.key});

  @override
  ConsumerState<JobListingScreen> createState() => _JobListingScreenState();
}

class _JobListingScreenState extends ConsumerState<JobListingScreen> {
  String _sortBy = 'newest'; // 'newest' or 'applied'
  Map<String, dynamic> _applications = {}; // map jobId -> application data
  // Removed unused _isLoadingApplied
  String? _selectedCompany; // filter by company name

  // AI Matching State
  final Map<String, Map<String, dynamic>> _matchScores = {};
  bool _isAnalyzing = false;

  @override
  void initState() {
    super.initState();
    _loadAppliedJobs();
  }

  Future<void> _loadAppliedJobs() async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) return;

      final response = await Supabase.instance.client
          .from('job_applications')
          .select('id, job_id, status, current_round')
          .eq('student_id', userId);

      if (mounted) {
        setState(() {
          _applications = {
            for (var item in response)
              if (item['job_id'] != null) item['job_id'].toString(): item,
          };
        });
      }
    } catch (e) {
      debugPrint('Error loading applied jobs: $e');
    }
  }

  Future<void> _analyzeJobMatch(Job job) async {
    final resumeUrlAsync = ref.read(resumeUrlProvider);

    // Check if resume exists
    final resumeUrl = resumeUrlAsync.asData?.value;
    if (resumeUrl == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please upload a resume first to analyze match.'),
        ),
      );
      return;
    }

    setState(() => _isAnalyzing = true);

    try {
      // 1. Extract Text
      final resumeText = await ResumeMatchingService().extractTextFromPdf(
        resumeUrl,
      );
      if (resumeText == null || resumeText.isEmpty) {
        throw Exception(
          'Could not read resume text. Please ensure it is a valid PDF.',
        );
      }

      // 2. Calculate Match
      // Debug print to verify content (visible in run output)
      debugPrint(
        'Analyzing Job: ${job.title}, Requirements: ${job.requirements?.length ?? 0} chars',
      );

      final result = await ResumeMatchingService().calculateMatchWithAI(
        resumeText: resumeText,
        jobTitle: job.title,
        jobDescription: job.description,
        jobRequirements: job.requirements,
      );

      if (mounted) {
        setState(() {
          _matchScores[job.id] = result;
          _isAnalyzing = false;
        });

        // Show Result Dialog
        _showMatchResultDialog(job, result);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isAnalyzing = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Verification Failed: $e')));
      }
    }
  }

  void _showMatchResultDialog(Job job, Map<String, dynamic> result) {
    final score = result['score'] as int;
    final matched = List<String>.from(result['matched'] ?? []);
    final missing = List<String>.from(result['missing'] ?? []);

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
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 5,
                    ),
                  ],
                ),
                child: Icon(Icons.auto_awesome, color: AppTheme.primaryColor),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'AI Match Analysis',
                  style: TextStyle(fontSize: 18),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 20),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Analysis for "${job.title}"',
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.black87,
                ),
              ),
              Text(
                'Based on recruiter requirements',
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic,
                ),
              ),
              const SizedBox(height: 24),

              // Score Indicator
              Center(
                child: Column(
                  children: [
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: 100,
                          height: 100,
                          child: CircularProgressIndicator(
                            value: score / 100,
                            strokeWidth: 10,
                            color: scoreColor,
                            backgroundColor: scoreColor.withValues(alpha: 0.1),
                            strokeCap: StrokeCap.round,
                          ),
                        ),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '$score%',
                              style: GoogleFonts.outfit(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: scoreColor,
                              ),
                            ),
                            Text(
                              'Match',
                              style: GoogleFonts.outfit(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: scoreColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: scoreColor.withValues(alpha: 0.3)),
                      ),
                      child: Text(
                        score >= 70
                            ? 'Excellent Fit!'
                            : (score >= 40 ? 'Potential Fit' : 'Low Match'),
                        style: GoogleFonts.outfit(
                          fontWeight: FontWeight.bold,
                          color: scoreColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Keywords
              _buildKeywordSection(
                '✅ Skills Found in Resume',
                matched,
                Colors.green,
                Icons.check_circle_outline,
              ),
              const SizedBox(height: 20),
              _buildKeywordSection(
                '⚠️ Missing Requirements',
                missing,
                Colors.red,
                Icons.warning_amber_rounded,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildKeywordSection(
    String title,
    List<String> keywords,
    Color color,
    IconData icon,
  ) {
    if (keywords.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 8),
            Text(
              title,
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.w600,
                color: Colors.black87,
                fontSize: 14,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: keywords.take(15).map((k) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: color.withValues(alpha: 0.2)),
              ),
              child: Text(
                k,
                style: GoogleFonts.outfit(
                  color: Color.lerp(
                    color,
                    Colors.black,
                    0.2,
                  ), // Darken for text
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            );
          }).toList(),
        ),
        if (keywords.length > 15)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Text(
              '+ ${keywords.length - 15} more',
              style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final jobsAsync = ref.watch(allJobsProvider);
    final resumeUrlAsync = ref.watch(resumeUrlProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Available Jobs',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        actions: _buildResumeActions(resumeUrlAsync),
      ),
      body: jobsAsync.when(
        data: (jobs) {
          // 1. Filter jobs based on Sidebar Selection
          List<Job> filteredJobs = _selectedCompany == null
              ? jobs
              : jobs
                    .where(
                      (j) =>
                          (j.organization?['name'] ?? 'Unknown') ==
                          _selectedCompany,
                    )
                    .toList();

          // 2. Apply Sorting
          List<Job> displayJobs = List.from(filteredJobs);
          if (_sortBy == 'applied') {
            displayJobs = displayJobs
                .where((j) => _applications.containsKey(j.id))
                .toList();
          } else {
            // Default sort by date (newest first)
            // jobs from provider are already sorted by created_at desc
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Main Content (Job List)
              Expanded(
                flex: 3,
                child: Column(
                  children: [
                    const Divider(height: 1),
                    // Sorting chips
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      color: Colors.white,
                      child: Row(
                        children: [
                          Text(
                            'Sort by:',
                            style: GoogleFonts.outfit(
                              fontWeight: FontWeight.w500,
                              color: Colors.grey[700],
                            ),
                          ),
                          const SizedBox(width: 12),
                          _buildSortChip('Newest', 'newest', Icons.access_time),
                          const SizedBox(width: 8),
                          _buildSortChip(
                            'Applied',
                            'applied',
                            Icons.check_circle_outline,
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    // Jobs list
                    Expanded(
                      child: displayJobs.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.work_off_outlined,
                                    size: 64,
                                    color: Colors.grey[300],
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'No jobs found matching your criteria.',
                                    style: GoogleFonts.outfit(
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : LayoutBuilder(
                              builder: (context, constraints) {
                                if (constraints.maxWidth > 900) {
                                  return RefreshIndicator(
                                    onRefresh: () async {
                                      ref.invalidate(allJobsProvider);
                                      await _loadAppliedJobs();
                                    },
                                    child: GridView.builder(
                                      padding: const EdgeInsets.all(
                                        32,
                                      ), // Same as recruiter
                                      gridDelegate:
                                          const SliverGridDelegateWithMaxCrossAxisExtent(
                                            maxCrossAxisExtent:
                                                400, // Same as recruiter
                                            mainAxisExtent:
                                                320, // Same as recruiter
                                            crossAxisSpacing:
                                                24, // Same as recruiter
                                            mainAxisSpacing:
                                                24, // Same as recruiter
                                          ),
                                      itemCount: displayJobs.length,
                                      itemBuilder: (context, index) =>
                                          _buildJobCard(displayJobs[index]),
                                    ),
                                  );
                                } else {
                                  return RefreshIndicator(
                                    onRefresh: () async {
                                      ref.invalidate(allJobsProvider);
                                      await _loadAppliedJobs();
                                    },
                                    child: ListView.separated(
                                      padding: const EdgeInsets.all(16),
                                      itemCount: displayJobs.length,
                                      separatorBuilder: (context, index) =>
                                          const SizedBox(height: 16),
                                      itemBuilder: (context, index) =>
                                          _buildJobCard(displayJobs[index]),
                                    ),
                                  );
                                }
                              },
                            ),
                    ),
                  ],
                ),
              ),
              // Right Sidebar
              _buildCompanySidebar(jobs),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }

  List<Widget> _buildResumeActions(AsyncValue<String?> resumeUrlAsync) {
    return [
      resumeUrlAsync.when(
        data: (url) {
          if (url != null) {
            return IconButton(
              onPressed: () {
                // View Resume logic (open URL)
                // For now just show snackbar or could launch url
                // using url_launcher logic similar to ResumeHub
                // or just reuse _handleUploadResume to update it?
                // Let's open it.
                // We need to import url_launcher or use a helper.
                // Since I don't want to add imports if I can avoid it yet,
                // or I can just let them Update it.
                // The user said "NOT VISIBLE HERE".
                // Let's show a "Check" icon and "Upload" icon?
                // Or better: Show a View icon.
                _viewResume(url);
              },
              icon: const Icon(Icons.description, color: Colors.green),
              tooltip: 'View My Resume',
            );
          }
          return IconButton(
            onPressed: _handleUploadResume,
            icon: const Icon(Icons.upload_file),
            tooltip: 'Upload Resume',
          );
        },
        loading: () => const SizedBox(
          width: 24,
          height: 24,
          child: Padding(
            padding: EdgeInsets.all(8.0),
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
        error: (_, __) => IconButton(
          onPressed: _handleUploadResume,
          icon: const Icon(Icons.upload_file),
          tooltip: 'Upload Resume',
        ),
      ),
    ];
  }

  Future<void> _viewResume(String url) async {
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    } else {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Could not open resume.')));
      }
    }
  }

  Future<void> _handleUploadResume() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        withData: true,
      );

      if (result != null) {
        final file = result.files.single;
        final userId = Supabase.instance.client.auth.currentUser?.id;
        if (userId == null) return;

        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Uploading resume...')));
        }

        String storagePath = 'resumes/$userId/resume.pdf';

        if (kIsWeb) {
          if (file.bytes != null) {
            await Supabase.instance.client.storage
                .from('resumes')
                .uploadBinary(
                  storagePath,
                  file.bytes!,
                  fileOptions: const FileOptions(upsert: true),
                );
          }
        } else {
          if (file.path != null) {
            await Supabase.instance.client.storage
                .from('resumes')
                .upload(
                  storagePath,
                  File(file.path!),
                  fileOptions: const FileOptions(upsert: true),
                );
          }
        }

        // Get Public URL
        final publicUrl = Supabase.instance.client.storage
            .from('resumes')
            .getPublicUrl(storagePath);

        // Update profile
        await Supabase.instance.client
            .from('profiles')
            .update({'resume_url': publicUrl})
            .eq('id', userId);

        // Refresh provider
        ref.invalidate(resumeUrlProvider);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Resume uploaded successfully!'),
              action: SnackBarAction(
                label: 'AI SCAN',
                onPressed: () => _handleAIScanResume(publicUrl),
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error uploading resume: $e')));
      }
    }
  }

  Future<void> _handleAIScanResume(String url) async {
    try {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('AI is scanning your resume...')),
        );
      }

      final ResumeDataService dataService = ref.read(resumeDataServiceProvider);
      final extractedData = await dataService.parseResumeFromPdf(url);

      if (extractedData != null) {
        if (mounted) {
          final confirmed = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('AI Analysis Complete'),
              content: const Text(
                'AI has extracted your details, skills, and projects. Would you like to update your CareerBridge profile with this information?',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Maybe Later'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Update Profile'),
                ),
              ],
            ),
          );

          if (confirmed == true) {
            await dataService.persistExtractedData(extractedData);
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Profile updated successfully!')),
              );
            }
          }
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('AI could not scan this resume.')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('AI Scan Error: $e')));
      }
    }
  }

  Widget _buildSortChip(String label, String value, IconData icon) {
    final isSelected = _sortBy == value;
    return InkWell(
      onTap: () => setState(() => _sortBy = value),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryColor : Colors.grey[100],
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppTheme.primaryColor : Colors.grey[300]!,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? Colors.white : Colors.grey[600],
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: GoogleFonts.outfit(
                color: isSelected ? Colors.white : Colors.grey[800],
                fontWeight: FontWeight.w500,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildJobCard(Job job) {
    final application = _applications[job.id];
    final hasApplied = application != null;
    final status = application?['status'] as String?;
    final round = application?['current_round'] as int?;

    Color statusColor = Colors.grey;
    String statusText = 'OPEN';

    if (hasApplied) {
      if (status == 'in_progress') {
        statusText = 'ROUND $round';
        statusColor = Colors.orange;
      } else if (status == 'selected') {
        statusText = 'SELECTED';
        statusColor = Colors.green;
      } else if (status == 'rejected') {
        statusText = 'REJECTED';
        statusColor = Colors.red;
      } else if (status == 'shortlisted') {
        statusText = 'SHORTLISTED';
        statusColor = Colors.amber;
      } else {
        statusText = 'APPLIED';
        statusColor = Colors.blue;
      }
    }

    final matchData = _matchScores[job.id];
    final matchScore = matchData?['score'] as int?;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header (Logo + Status)
                // Header (Logo + Status)
                Padding(
                  padding: const EdgeInsets.fromLTRB(10, 6, 10, 2),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade100),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: job.organization?['logo_url'] != null
                              ? Image.network(
                                  job.organization!['logo_url'],
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) =>
                                      const Icon(Icons.business, size: 20),
                                )
                              : const Icon(Icons.business, size: 20),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              job.organization?['name'] ?? 'Unknown',
                              style: GoogleFonts.outfit(
                                color: Colors.grey[600],
                                fontSize: 15,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      if (matchScore != null)
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: _buildMatchChip(score: matchScore),
                        ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: (hasApplied ? statusColor : Colors.grey[100]!)
                              .withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color:
                                (hasApplied ? statusColor : Colors.grey[400]!)
                                    .withValues(alpha: 0.2),
                          ),
                        ),
                        child: Text(
                          statusText,
                          style: GoogleFonts.outfit(
                            color: hasApplied ? statusColor : Colors.grey[600],
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Title & Description Section
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        job.title,
                        style: GoogleFonts.outfit(
                          fontWeight: FontWeight.bold,
                          fontSize: 22,
                          height: 1.2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 5),
                      Text(
                        job.description,
                        style: GoogleFonts.outfit(
                          fontSize: 16,
                          color: Colors.grey[600],
                          height: 1.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 6),

                // Detail Rows (Vertical Stack)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Column(
                    children: [
                      _buildClayDetailRow(
                        'Location:',
                        job.location ?? 'Remote',
                      ),
                      const SizedBox(height: 4),
                      _buildClayDetailRow('Type:', job.jobType ?? 'Full-time'),
                      const SizedBox(height: 4),
                      _buildClayDetailRow(
                        'Posted:',
                        DateFormat('MMM d, yyyy').format(job.createdAt),
                      ),
                    ],
                  ),
                ),

                const Spacer(),

                // Footer Actions
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    border: Border(
                      top: BorderSide(color: Colors.grey.shade100),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () => matchData != null
                              ? _showMatchResultDialog(job, matchData)
                              : _analyzeJobMatch(job),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            minimumSize: Size.zero,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                _isAnalyzing && matchData == null
                                    ? Icons.sync
                                    : (matchScore != null
                                          ? Icons.insights
                                          : Icons.auto_awesome),
                                size: 14,
                                color: Colors.cyan[700],
                              ),
                              const SizedBox(width: 4),
                              Text(
                                matchScore != null ? 'Insights' : 'Analyze',
                                style: GoogleFonts.outfit(
                                  fontSize: 15,
                                  color: Colors.cyan[700],
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          onPressed: () {
                            if (hasApplied) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      ApplicationTimelineScreen(
                                        applicationId: application!['id'],
                                      ),
                                ),
                              );
                            } else {
                              _applyForJob(job);
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: hasApplied
                                ? Colors.white
                                : AppTheme.primaryColor,
                            foregroundColor: hasApplied
                                ? AppTheme.primaryColor
                                : Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6),
                              side: hasApplied
                                  ? BorderSide(
                                      color: AppTheme.primaryColor.withValues(alpha: 0.3),
                                    )
                                  : BorderSide.none,
                            ),
                          ),
                          child: Text(
                            hasApplied ? 'Status' : 'Apply Now',
                            style: GoogleFonts.outfit(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClayDetailRow(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Row(
        children: [
          Text(
            label,
            style: GoogleFonts.outfit(color: Colors.grey[500], fontSize: 14),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.outfit(
                color: Colors.black87,
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
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
          const Icon(Icons.auto_awesome, size: 14, color: Colors.green),
          const SizedBox(width: 4),
          Text(
            '$score% Match',
            style: GoogleFonts.outfit(
              color: color,
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _applyForJob(Job job) async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) return;

      List<Map<String, dynamic>>? videoResponses;

      // Check for screening questions
      if (job.screeningQuestions != null && job.screeningQuestions!.isNotEmpty) {
        final responses = await showDialog<List<Map<String, dynamic>>>(
          context: context,
          barrierDismissible: false,
          builder: (context) => VideoScreeningDialog(
            questions: job.screeningQuestions!,
            jobTitle: job.title,
          ),
        );

        if (responses == null) {
          // User cancelled the screening dialog
          return;
        }
        videoResponses = responses;
      }

      // Show applying indicator
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Submitting your application...')));
      }

      await ref.read(jobRepositoryProvider).applyForJob(
        job.id,
        userId,
        videoResponses: videoResponses,
      );

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Applied successfully!')));
        _loadAppliedJobs();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error applying: $e')));
      }
    }
  }

  Widget _buildCompanySidebar(List<Job> jobs) {
    final Map<String, int> companyCounts = {};
    for (var job in jobs) {
      final companyName = job.organization?['name'] ?? 'Unknown Company';
      companyCounts[companyName] = (companyCounts[companyName] ?? 0) + 1;
    }
    final sortedCompanies = companyCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Container(
      width: 280,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(left: BorderSide(color: Colors.grey[200]!)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // PROMOTIONAL BANNER
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppTheme.primaryColor, const Color(0xFF6C63FF)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.auto_awesome,
                      color: Colors.white,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'AI Resume Insights',
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Unlock your potential! See how well your skills match with these jobs.',
                  style: GoogleFonts.outfit(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Filter by Company',
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView(
              children: [
                _buildCompanyFilterTile(
                  label: 'All Companies',
                  count: jobs.length,
                  isSelected: _selectedCompany == null,
                  onTap: () => setState(() => _selectedCompany = null),
                ),
                ...sortedCompanies.map((entry) {
                  return _buildCompanyFilterTile(
                    label: entry.key,
                    count: entry.value,
                    isSelected: _selectedCompany == entry.key,
                    onTap: () => setState(() => _selectedCompany = entry.key),
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompanyFilterTile({
    required String label,
    required int count,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(
        Icons.business,
        color: isSelected ? AppTheme.primaryColor : Colors.grey,
        size: 20,
      ),
      title: Text(
        label,
        style: GoogleFonts.outfit(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected ? AppTheme.primaryColor : Colors.black87,
        ),
      ),
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primaryColor.withValues(alpha: 0.1)
              : Colors.grey[100],
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          count.toString(),
          style: TextStyle(
            color: isSelected ? AppTheme.primaryColor : Colors.grey[600],
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      selected: isSelected,
      onTap: onTap,
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/logger_service.dart';
import 'package:uuid/uuid.dart';

class JobPostingScreen extends ConsumerStatefulWidget {
  const JobPostingScreen({super.key});

  @override
  ConsumerState<JobPostingScreen> createState() => _JobPostingScreenState();
}

class _JobPostingScreenState extends ConsumerState<JobPostingScreen> {
  final _formKey = GlobalKey<FormState>();

  // Basic Info
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _requirementsController = TextEditingController();
  final _locationController = TextEditingController();
  final _salaryController = TextEditingController();
  String _jobType = 'Full-time';

  // Video Interview Config
  bool _enableVideoInterview = false;
  final List<TextEditingController> _questionControllers = [];
  final List<String> _questionTypes = []; // 'video' or 'text'

  // Hiring Rounds Configuration
  List<Map<String, dynamic>> _hiringRounds = [
    {
      'round_type': 'resume_screening',
      'title': 'Resume Screening',
      'submission_type': 'none',
      'instructions': 'Initial resume and profile review',
      'is_mandatory': true,
    },
  ];

  final List<Map<String, dynamic>> _availableRoundTypes = [
    {
      'type': 'resume_screening',
      'label': 'Resume Screening',
      'icon': Icons.description,
    },
    {
      'type': 'video_introduction',
      'label': 'Video Introduction',
      'icon': Icons.videocam,
    },
    {'type': 'technical', 'label': 'Technical Round', 'icon': Icons.code},
    {'type': 'hr', 'label': 'HR Interview', 'icon': Icons.people},
    {'type': 'coding', 'label': 'Coding Challenge', 'icon': Icons.terminal},
    {'type': 'quiz', 'label': 'Quiz/MCQ', 'icon': Icons.quiz},
    {
      'type': 'final_selection',
      'label': 'Final Selection',
      'icon': Icons.check_circle,
    },
    {'type': 'custom', 'label': 'Custom Round', 'icon': Icons.extension},
  ];

  bool _isLoading = false;
  bool _postToFeed = true;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _requirementsController.dispose();
    _locationController.dispose();
    _salaryController.dispose();
    for (var c in _questionControllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _addQuestion() {
    setState(() {
      _questionControllers.add(TextEditingController());
      _questionTypes.add('video'); // Default to video
    });
  }

  void _removeQuestion(int index) {
    setState(() {
      final controller = _questionControllers[index];
      _questionControllers.removeAt(index);
      _questionTypes.removeAt(index);
      controller.dispose();
    });
  }

  Future<void> _postJob() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) throw Exception('User not logged in');

      // Get recruiter's organization (optional logic, defaults to null if not found)
      final profile = await Supabase.instance.client
          .from('profiles')
          .select('organization_id')
          .eq('id', user.id)
          .maybeSingle();

      if (profile == null) throw Exception('Profile not found');
      final orgId = profile['organization_id'];

      // Prepare screening questions
      List<Map<String, dynamic>> questions = [];
      if (_enableVideoInterview) {
        for (int i = 0; i < _questionControllers.length; i++) {
          final text = _questionControllers[i].text.trim();
          if (text.isNotEmpty) {
            questions.add({
              'question': text,
              'type': _questionTypes[i],
            });
          }
        }
      }

      final jobData = {
        'posted_by': user.id,
        'organization_id': orgId,
        'recruiter_id': user.id,
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'requirements': _requirementsController.text.trim(),
        'location': _locationController.text.trim(),
        'salary_range': _salaryController.text.trim(),
        'job_type': _jobType,
        'status': 'open',
        'screening_questions': questions,
        'created_at': DateTime.now().toIso8601String(),
      };

      // Insert job and get the ID
      final jobResponse = await Supabase.instance.client
          .from('jobs')
          .insert(jobData)
          .select('id')
          .single();

      final jobId = jobResponse['id'];

      // Insert hiring rounds
      if (_hiringRounds.isNotEmpty && jobId != null) {
        for (int i = 0; i < _hiringRounds.length; i++) {
          final round = _hiringRounds[i];
          await Supabase.instance.client.from('job_rounds').insert({
            'job_id': jobId,
            'round_number': i + 1,
            'round_type': round['round_type'],
            'title': round['title'],
            'instructions': round['instructions'] ?? '',
            'submission_type': round['submission_type'],
            'evaluation_criteria': round['evaluation_criteria'],
            'is_mandatory': round['is_mandatory'] ?? true,
          });
        }
      }

      if (mounted) {
        // Auto-post to feed if enabled
        if (_postToFeed) {
          try {
            // Fetch company name for the post
            final orgResponse = await Supabase.instance.client
                .from('organizations')
                .select('name')
                .eq('id', orgId)
                .maybeSingle();

            final companyName = orgResponse?['name'] ?? 'Our Company';

            await Supabase.instance.client.from('posts').insert({
              'author_id': user.id,
              'content':
                  'We are hiring! 🚀\n\n'
                  'Job Title: ${_titleController.text.trim()}\n'
                  'Location: ${_locationController.text.trim()}\n'
                  'Type: $_jobType\n\n'
                  'Check out the latest opening at $companyName and apply now!',
              'post_type': 'job_opening',
              'media_type': 'none',
              'hashtags': ['hiring', 'jobs', 'careers', _jobType.toLowerCase()],
            });
          } catch (e) {
            debugPrint('Error auto-posting to feed: $e');
          }
        }

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Job posted with hiring rounds!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      LoggerService.error('Error posting job', e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error posting job: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          'Post New Job',
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: Colors.black,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            _buildSectionHeader('Basic Details'),
            _buildTextField(
              'Job Title',
              _titleController,
              'e.g. Senior Flutter Developer',
            ),
            const SizedBox(height: 16),
            _buildTextField(
              'Location',
              _locationController,
              'e.g. Remote, Bangalore',
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    'Salary Range',
                    _salaryController,
                    'e.g. ₹10L - ₹15L',
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Job Type',
                        style: GoogleFonts.outfit(fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        value: _jobType,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        items:
                            ['Full-time', 'Part-time', 'Internship', 'Contract']
                                .map(
                                  (t) => DropdownMenuItem(
                                    value: t,
                                    child: Text(t, style: GoogleFonts.outfit()),
                                  ),
                                )
                                .toList(),
                        onChanged: (v) => setState(() => _jobType = v!),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 32),
            _buildSectionHeader('Description & Requirements'),
            _buildTextField(
              'Job Description',
              _descriptionController,
              'Describe the role and responsibilities...',
              maxLines: 5,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              'Conditions / Requirements',
              _requirementsController,
              '- Must have 3+ years experience\n- Bachelor\'s degree or equivalent...',
              maxLines: 5,
            ),

            const SizedBox(height: 32),
            _buildSectionHeader('Video Screening', icon: Icons.videocam),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.blue.shade50.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.blue.shade100),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      'Enable Video Interview',
                      style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      'Candidates must answer recorded questions',
                      style: GoogleFonts.outfit(color: Colors.grey[600]),
                    ),
                    value: _enableVideoInterview,
                    onChanged: (val) => setState(() {
                      _enableVideoInterview = val;
                      if (val && _questionControllers.isEmpty) _addQuestion();
                    }),
                  ),

                  if (_enableVideoInterview) ...[
                    const Divider(),
                    const SizedBox(height: 8),
                    ...List.generate(_questionControllers.length, (index) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: _buildTextField(
                                    'Question ${index + 1}',
                                    _questionControllers[index],
                                    'e.g. Tell us about a challenging project...',
                                    isDense: true,
                                  ),
                                ),
                                if (_questionControllers.length > 1)
                                  IconButton(
                                    icon: const Icon(
                                      Icons.delete_outline,
                                      color: Colors.red,
                                    ),
                                    onPressed: () => _removeQuestion(index),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Text(
                                  'Response Type:',
                                  style: GoogleFonts.outfit(
                                    fontSize: 13,
                                    color: Colors.grey[600],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                SegmentedButton<String>(
                                  segments: const [
                                    ButtonSegment(
                                      value: 'text',
                                      label: Text('Text'),
                                      icon: Icon(Icons.short_text, size: 16),
                                    ),
                                    ButtonSegment(
                                      value: 'video',
                                      label: Text('Video'),
                                      icon: Icon(Icons.videocam, size: 16),
                                    ),
                                  ],
                                  selected: {_questionTypes[index]},
                                  onSelectionChanged: (Set<String> newSelection) {
                                    setState(() {
                                      _questionTypes[index] = newSelection.first;
                                    });
                                  },
                                  style: SegmentedButton.styleFrom(
                                    visualDensity: VisualDensity.compact,
                                    selectedBackgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                                    selectedForegroundColor: AppTheme.primaryColor,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    }),
                    TextButton.icon(
                      onPressed: _addQuestion,
                      icon: const Icon(Icons.add),
                      label: const Text('Add Another Question'),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 32),
            _buildSectionHeader('Hiring Rounds', icon: Icons.timeline),
            _buildHiringRoundsSection(),

            const SizedBox(height: 32),
            _buildSectionHeader('Community Engagement', icon: Icons.share),
            CheckboxListTile(
              title: Text(
                'Share to Company Feed',
                style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                'Automatically post this job opening to the community feed to reach more candidates.',
                style: GoogleFonts.outfit(
                  color: Colors.grey[600],
                  fontSize: 13,
                ),
              ),
              value: _postToFeed,
              onChanged: (val) => setState(() => _postToFeed = val ?? true),
              activeColor: AppTheme.primaryColor,
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
            ),

            const SizedBox(height: 40),
            FilledButton(
              onPressed: _isLoading ? null : _postJob,
              style: FilledButton.styleFrom(
                backgroundColor: Colors.orange,
                minimumSize: const Size(double.infinity, 56),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : Text(
                      'Post Job',
                      style: GoogleFonts.outfit(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, {IconData? icon}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, size: 20, color: Colors.blue.shade700),
            const SizedBox(width: 8),
          ],
          Text(
            title,
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller,
    String hint, {
    int maxLines = 1,
    bool isDense = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!isDense) ...[
          Text(label, style: GoogleFonts.outfit(fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
        ],
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          validator: (val) => val == null || val.isEmpty ? 'Required' : null,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.outfit(color: Colors.grey[400]),
            filled: true,
            fillColor: Colors.white,
            contentPadding: isDense
                ? const EdgeInsets.symmetric(horizontal: 16, vertical: 12)
                : const EdgeInsets.all(16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHiringRoundsSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.purple.shade50.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.purple.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Configure the interview rounds for this job',
            style: GoogleFonts.outfit(color: Colors.grey[600]),
          ),
          const SizedBox(height: 16),

          // Rounds list
          ReorderableListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _hiringRounds.length,
            onReorder: (oldIndex, newIndex) {
              setState(() {
                if (newIndex > oldIndex) newIndex--;
                final item = _hiringRounds.removeAt(oldIndex);
                _hiringRounds.insert(newIndex, item);
              });
            },
            itemBuilder: (context, index) {
              final round = _hiringRounds[index];
              final roundType = _availableRoundTypes.firstWhere(
                (r) => r['type'] == round['round_type'],
                orElse: () => _availableRoundTypes.last,
              );

              return Container(
                key: ValueKey('round_$index'),
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        roundType['icon'] as IconData,
                        color: AppTheme.primaryColor,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Round ${index + 1}: ${round['title']}',
                            style: GoogleFonts.outfit(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Row(
                            children: [
                              Text(
                                roundType['label'] as String,
                                style: GoogleFonts.outfit(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.grey[100],
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  _getSubmissionTypeLabel(
                                    round['submission_type'],
                                  ),
                                  style: GoogleFonts.outfit(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey[700],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, size: 20),
                      onPressed: () => _editRound(index),
                    ),
                    if (_hiringRounds.length > 1)
                      IconButton(
                        icon: const Icon(
                          Icons.delete_outline,
                          size: 20,
                          color: Colors.red,
                        ),
                        onPressed: () {
                          setState(() => _hiringRounds.removeAt(index));
                        },
                      ),
                    const Icon(Icons.drag_handle, color: Colors.grey),
                  ],
                ),
              );
            },
          ),

          // Add Round Button
          TextButton.icon(
            onPressed: _addRound,
            icon: const Icon(Icons.add),
            label: const Text('Add Interview Round'),
          ),
        ],
      ),
    );
  }

  void _editRound(int index) {
    final round = _hiringRounds[index];
    String title = round['title'];
    String instructions = round['instructions'] ?? '';
    String submissionType = round['submission_type'];
    bool isMandatory = round['is_mandatory'] ?? true;
    final titleController = TextEditingController(text: title);
    final instructionsController = TextEditingController(text: instructions);

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Edit Round'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(labelText: 'Round Title'),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: submissionType,
                    decoration: const InputDecoration(
                      labelText: 'Submission Type',
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'none',
                        child: Text('No Submission (Meeting/Screening)'),
                      ),
                      DropdownMenuItem(
                        value: 'video',
                        child: Text('Video Recording'),
                      ),
                      DropdownMenuItem(
                        value: 'text',
                        child: Text('Text Response'),
                      ),
                      DropdownMenuItem(
                        value: 'file',
                        child: Text('File Upload'),
                      ),
                      DropdownMenuItem(
                        value: 'coding',
                        child: Text('Coding Challenge'),
                      ),
                      DropdownMenuItem(value: 'quiz', child: Text('Quiz/MCQ')),
                    ],
                    onChanged: (v) {
                      if (v != null) {
                        setDialogState(() => submissionType = v);
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  if (submissionType == 'quiz') ...[
                    OutlinedButton.icon(
                      onPressed: () async {
                        await _openQuizConfig(index);
                      },
                      icon: const Icon(Icons.quiz),
                      label: const Text('Configure Quiz Questions'),
                    ),
                    const SizedBox(height: 16),
                  ],
                  TextField(
                    controller: instructionsController,
                    decoration: const InputDecoration(
                      labelText: 'Instructions',
                    ),
                    maxLines: 3,
                  ),
                  CheckboxListTile(
                    title: const Text('Mandatory Round'),
                    value: isMandatory,
                    onChanged: (v) => setDialogState(() => isMandatory = v!),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () {
                  setState(() {
                    _hiringRounds[index] = {
                      ...round,
                      'title': titleController.text,
                      'submission_type': submissionType,
                      'instructions': instructionsController.text,
                      'is_mandatory': isMandatory,
                    };
                  });
                  LoggerService.debug('Job round created: $round');
                  Navigator.pop(context);
                },
                child: const Text('Save'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _openQuizConfig(int index) async {
    final round = _hiringRounds[index];
    final criteria =
        round['evaluation_criteria'] as Map<String, dynamic>? ?? {};
    final currentQuestions = criteria['quiz_questions'] as List<dynamic>? ?? [];

    final parsedQuestions = currentQuestions
        .map((q) => Map<String, dynamic>.from(q))
        .toList();

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            QuizConfigDialog(initialQuestions: parsedQuestions),
      ),
    );

    if (result != null && result is List<Map<String, dynamic>>) {
      setState(() {
        final newCriteria = Map<String, dynamic>.from(criteria);
        newCriteria['quiz_questions'] = result;
        round['evaluation_criteria'] = newCriteria;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Saved ${result.length} questions'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  void _addRound() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.6,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                'Select Round Type',
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _availableRoundTypes.length,
                itemBuilder: (context, index) {
                  final type = _availableRoundTypes[index];
                  return ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        type['icon'] as IconData,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                    title: Text(
                      type['label'] as String,
                      style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
                    ),
                    onTap: () {
                      setState(() {
                        _hiringRounds.add({
                          'round_type': type['type'],
                          'title': type['label'],
                          'submission_type':
                              type['type'] == 'video_introduction'
                              ? 'video'
                              : type['type'] == 'coding'
                              ? 'coding'
                              : type['type'] == 'quiz'
                              ? 'quiz'
                              : 'none',
                          'instructions': '',
                          'is_mandatory': true,
                        });
                      });
                      Navigator.pop(context);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getSubmissionTypeLabel(String? type) {
    switch (type) {
      case 'video':
        return 'Video';
      case 'text':
        return 'Text';
      case 'file':
        return 'File';
      case 'coding':
        return 'Coding';
      case 'quiz':
        return 'Quiz';
      case 'none':
      default:
        return 'Meeting/Screening';
    }
  }
}

class QuizConfigDialog extends StatefulWidget {
  final List<Map<String, dynamic>> initialQuestions;

  const QuizConfigDialog({super.key, required this.initialQuestions});

  @override
  State<QuizConfigDialog> createState() => _QuizConfigDialogState();
}

class _QuizConfigDialogState extends State<QuizConfigDialog> {
  late List<Map<String, dynamic>> _questions;

  @override
  void initState() {
    super.initState();
    // Deep copy to avoid mutating parent state directly
    _questions = widget.initialQuestions.map((q) {
      final map = Map<String, dynamic>.from(q);
      if (map['id'] == null) {
        map['id'] = const Uuid().v4();
      }
      return map;
    }).toList();
  }

  void _addQuestion() {
    setState(() {
      _questions.add({
        'id': const Uuid().v4(),
        'question': '',
        'options': ['', '', '', ''],
        'correct_option': 0, // 0-3 index
      });
    });
  }

  void _removeQuestion(int index) {
    setState(() {
      _questions.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Configure Quiz (${_questions.length} Questions)',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, _questions),
            child: const Text('Save'),
          ),
        ],
      ),
      body: _questions.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.quiz_outlined, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text(
                    'No questions added yet',
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: _addQuestion,
                    icon: const Icon(Icons.add),
                    label: const Text('Add First Question'),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _questions.length + 1,
              itemBuilder: (context, index) {
                if (index == _questions.length) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 16, bottom: 32),
                    child: OutlinedButton.icon(
                      onPressed: _addQuestion,
                      icon: const Icon(Icons.add),
                      label: const Text('Add Another Question'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.all(16),
                      ),
                    ),
                  );
                }

                final question = _questions[index];
                return Card(
                  key: ValueKey(question['id']),
                  margin: const EdgeInsets.only(bottom: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: Colors.grey.shade200),
                  ),
                  elevation: 0,
                  child: ExpansionTile(
                    initiallyExpanded: question['question'].toString().isEmpty,
                    title: Text(
                      question['question'].toString().isEmpty
                          ? 'New Question ${index + 1}'
                          : 'Q${index + 1}: ${question['question']}',
                      style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      onPressed: () => _removeQuestion(index),
                    ),
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            TextFormField(
                              key: ValueKey('${question['id']}_qtext'),
                              initialValue: question['question'],
                              decoration: const InputDecoration(
                                labelText: 'Question Text',
                                border: OutlineInputBorder(),
                                alignLabelWithHint: true,
                              ),
                              maxLines: 2,
                              onChanged: (val) {
                                question['question'] = val;
                                // Force rebuild to update title? No need for perf
                              },
                            ),
                            const SizedBox(height: 16),
                            const Text('Options:'),
                            const SizedBox(height: 8),
                            ...List.generate(4, (optIndex) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Row(
                                  children: [
                                    Radio<int>(
                                      value: optIndex,
                                      groupValue: question['correct_option'],
                                      onChanged: (val) {
                                        setState(() {
                                          question['correct_option'] = val;
                                        });
                                      },
                                    ),
                                    Expanded(
                                      child: TextFormField(
                                        key: ValueKey(
                                          '${question['id']}_opt_$optIndex',
                                        ),
                                        initialValue:
                                            question['options'][optIndex],
                                        decoration: InputDecoration(
                                          isDense: true,
                                          contentPadding: const EdgeInsets.all(
                                            12,
                                          ),
                                          hintText: 'Option ${optIndex + 1}',
                                          border: const OutlineInputBorder(),
                                        ),
                                        onChanged: (val) {
                                          question['options'][optIndex] = val;
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }),
                            Text(
                              'Select the radio button next to the correct answer.',
                              style: GoogleFonts.outfit(
                                fontSize: 12,
                                color: Colors.grey[600],
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}

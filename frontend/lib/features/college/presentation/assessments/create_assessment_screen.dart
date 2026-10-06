import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/college_providers.dart';

class CreateAssessmentScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic>? assessment;

  const CreateAssessmentScreen({super.key, this.assessment});

  @override
  ConsumerState<CreateAssessmentScreen> createState() =>
      _CreateAssessmentScreenState();
}

class _CreateAssessmentScreenState
    extends ConsumerState<CreateAssessmentScreen> {
  int _currentStep = 0;
  bool _isSubmitting = false;

  // Form Controllers
  late final TextEditingController _titleController;
  late final TextEditingController _descController;
  late final TextEditingController _durationController;
  late final TextEditingController _passingScoreController;

  String _selectedDifficulty = 'medium';
  String? _selectedModuleId;
  String _targetAudience = 'batch'; // 'batch', 'department', 'all'
  String? _selectedBatch;
  String? _selectedDepartment;

  // Questions State
  List<Map<String, dynamic>> _questions = [];

  // Dropdown Data
  List<Map<String, dynamic>> _modules = [];
  List<Map<String, dynamic>> _batches = [];
  List<Map<String, dynamic>> _departments = [];

  bool get _isEditMode =>
      widget.assessment != null && widget.assessment!['id'] != null;
  String? _assignmentId;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _fetchDropdownData();
    if (_isEditMode) {
      _fetchAssignmentDetails();
    }
  }

  Future<void> _fetchAssignmentDetails() async {
    try {
      final assignment = await ref
          .read(collegeRepositoryProvider)
          .getAssignment(widget.assessment!['id']);

      if (assignment != null && mounted) {
        setState(() {
          _assignmentId = assignment['id'];
          // Map backend assignment types to UI logic
          final type = assignment['assignment_type'];
          if (type == 'batch') {
            _targetAudience = 'batch';
            _selectedBatch = assignment['assigned_to_batch'];
          } else if (type == 'department') {
            _targetAudience = 'department';
            _selectedDepartment = assignment['assigned_to_department'];
          } else {
            _targetAudience = 'all';
          }
        });
      }
    } catch (e) {
      print('Error fetching assignment details: $e');
    }
  }

  void _initializeControllers() {
    final a = widget.assessment;
    _titleController = TextEditingController(text: a?['title'] ?? '');
    _descController = TextEditingController(text: a?['description'] ?? '');
    _durationController = TextEditingController(
      text:
          a?['duration_minutes']?.toString() ??
          a?['duration']?.toString() ??
          '30',
    );
    _passingScoreController = TextEditingController(
      text:
          a?['passing_score']?.toString() ??
          a?['passingScore']?.toString() ??
          '50',
    );

    if (a != null) {
      _selectedDifficulty = a['difficulty'] ?? 'medium';
      _selectedModuleId =
          a['module_id']; // Ensure this is passed if possible, else user re-selects
    }
  }

  Future<void> _fetchDropdownData() async {
    try {
      final client = Supabase.instance.client;

      // Fetch Modules
      final modulesRes = await client
          .from('aptitude_modules')
          .select('id, name')
          .eq('is_active', true);

      // Fetch Departments (All for now, ideally filtered by org)
      final deptsRes = await client
          .from('college_departments')
          .select('id, name');

      // Fetch Batches (All for now)
      final batchesRes = await client
          .from('college_batches')
          .select('id, name');

      if (mounted) {
        setState(() {
          _modules = List<Map<String, dynamic>>.from(modulesRes);
          _departments = List<Map<String, dynamic>>.from(deptsRes);
          _batches = List<Map<String, dynamic>>.from(batchesRes);

          // If editing and module ID matches nothing (or null), try to match by name or keep null
          if (_isEditMode && _selectedModuleId == null && _modules.isNotEmpty) {
            // Optional: logic to auto-select if missing
          }
        });
      }
    } catch (e) {
      print('Error fetching dropdowns: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
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
                Text(
                  _isEditMode ? 'EDIT ASSESSMENT' : 'CREATE ASSESSMENT',
                  style: GoogleFonts.outfit(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 1.2,
                  ),
                ),
                const Spacer(),
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

          // Stepper Content
          Expanded(
            child: Material(
              color: Colors.transparent,
              child: Theme(
                data: Theme.of(context).copyWith(
                  colorScheme: const ColorScheme.light(
                    primary: Color(0xFF5A6ACF),
                    onSurface: Color(0xFF1A1F36),
                  ),
                  canvasColor: Colors.white,
                ),
                child: Stepper(
                  type: StepperType.horizontal,
                  currentStep: _currentStep,
                  onStepContinue: _nextStep,
                  onStepCancel: _prevStep,
                  elevation: 0,
                  controlsBuilder: (context, details) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 32, bottom: 24),
                      child: Row(
                        children: [
                          if (_currentStep < 2)
                            Expanded(
                              child: FilledButton(
                                onPressed: details.onStepContinue,
                                style: FilledButton.styleFrom(
                                  backgroundColor: const Color(0xFF1A1F36),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                                child: Text(
                                  'Next Step',
                                  style: GoogleFonts.outfit(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            )
                          else
                            Expanded(
                              child: FilledButton.icon(
                                onPressed: _isSubmitting
                                    ? null
                                    : (_isEditMode
                                          ? _updateAssessment
                                          : _submitAssessment),
                                icon: _isSubmitting
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : Icon(
                                        _isEditMode
                                            ? Icons.save_rounded
                                            : Icons.check_circle_rounded,
                                        size: 20,
                                      ),
                                label: Text(
                                  _isEditMode
                                      ? 'UPDATE ASSESSMENT'
                                      : 'PUBLISH ASSESSMENT',
                                  style: GoogleFonts.outfit(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    letterSpacing: 1,
                                  ),
                                ),
                                style: FilledButton.styleFrom(
                                  backgroundColor: const Color(0xFF43E97B),
                                  foregroundColor: const Color(0xFF1A1F36),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                              ),
                            ),
                          const SizedBox(width: 16),
                          if (_currentStep > 0)
                            Expanded(
                              child: OutlinedButton(
                                onPressed: details.onStepCancel,
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                  side: BorderSide(
                                    color: const Color(
                                      0xFF1A1F36,
                                    ).withValues(alpha: 0.2),
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                                child: Text(
                                  'Back',
                                  style: GoogleFonts.outfit(
                                    color: const Color(0xFF697386),
                                    fontWeight: FontWeight.w600,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                  steps: [
                    Step(
                      title: Text(
                        'Details',
                        style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
                      ),
                      content: _buildDetailsStep(),
                      isActive: _currentStep >= 0,
                      state: _currentStep > 0
                          ? StepState.complete
                          : StepState.editing,
                    ),
                    Step(
                      title: const Text('Assignment'),
                      content: _buildAssignmentStep(),
                      isActive: _currentStep >= 1,
                      state: _currentStep > 1
                          ? StepState.complete
                          : StepState.editing,
                    ),
                    Step(
                      title: Text(_isEditMode ? 'Review' : 'Questions'),
                      content: _isEditMode
                          ? _buildReviewStep()
                          : _buildQuestionsStep(),
                      isActive: _currentStep >= 2,
                      state: _currentStep > 2
                          ? StepState.complete
                          : StepState.editing,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _titleController,
          decoration: const InputDecoration(
            labelText: 'Assessment Title',
            border: OutlineInputBorder(),
            hintText: 'e.g., Mid-Term Aptitude Test',
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _descController,
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: 'Description',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                value: _selectedModuleId,
                items: _modules
                    .map(
                      (m) => DropdownMenuItem(
                        value: m['id'] as String,
                        child: Text(m['name']),
                      ),
                    )
                    .toList(),
                onChanged: (val) => setState(() => _selectedModuleId = val),
                decoration: const InputDecoration(
                  labelText: 'Topic / Module',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: DropdownButtonFormField<String>(
                value: _selectedDifficulty,
                items: ['easy', 'medium', 'hard']
                    .map(
                      (d) => DropdownMenuItem(
                        value: d,
                        child: Text(d.toUpperCase()),
                      ),
                    )
                    .toList(),
                onChanged: (val) => setState(() => _selectedDifficulty = val!),
                decoration: const InputDecoration(
                  labelText: 'Difficulty',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _durationController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Duration (Minutes)',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextField(
                controller: _passingScoreController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Passing Score (%)',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAssignmentStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Who should take this test?',
          style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          children: [
            ChoiceChip(
              label: const Text('Specific Batch'),
              selected: _targetAudience == 'batch',
              onSelected: (val) => setState(() => _targetAudience = 'batch'),
            ),
            ChoiceChip(
              label: const Text('Specific Department'),
              selected: _targetAudience == 'department',
              onSelected: (val) =>
                  setState(() => _targetAudience = 'department'),
            ),
            ChoiceChip(
              label: const Text('All Students'),
              selected: _targetAudience == 'all',
              onSelected: (val) => setState(() => _targetAudience = 'all'),
            ),
          ],
        ),
        const SizedBox(height: 24),
        if (_targetAudience == 'batch')
          DropdownButtonFormField<String>(
            value: _selectedBatch,
            items: _batches
                .map(
                  (b) => DropdownMenuItem(
                    value: b['id'] as String,
                    child: Text(b['name']),
                  ),
                )
                .toList(),
            onChanged: (val) => setState(() => _selectedBatch = val),
            decoration: const InputDecoration(
              labelText: 'Select Batch',
              border: OutlineInputBorder(),
            ),
          ),
        if (_targetAudience == 'department')
          DropdownButtonFormField<String>(
            value: _selectedDepartment,
            items: _departments
                .map(
                  (d) => DropdownMenuItem(
                    value: d['id'] as String,
                    child: Text(d['name']),
                  ),
                )
                .toList(),
            onChanged: (val) => setState(() => _selectedDepartment = val),
            decoration: const InputDecoration(
              labelText: 'Select Department',
              border: OutlineInputBorder(),
            ),
          ),
      ],
    );
  }

  Widget _buildReviewStep() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.blue.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          const Icon(Icons.info_outline, color: Colors.blue, size: 48),
          const SizedBox(height: 16),
          Text(
            'Managing Questions',
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'To manage questions for this assessment, please save your changes first and then use the "View Questions" option from the assessment menu.',
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(color: Colors.grey[700]),
          ),
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 16),
          Text(
            'Ready to update details?',
            style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionsStep() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Questions (${_questions.length})',
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            OutlinedButton.icon(
              onPressed: _showAddQuestionDialog,
              icon: const Icon(Icons.add),
              label: const Text('Add Question'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (_questions.isEmpty)
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(child: Text('No questions added yet.')),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _questions.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final q = _questions[index];
              return Card(
                elevation: 0,
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  side: BorderSide(color: Colors.grey[200]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ListTile(
                  title: Text(
                    q['question_text'],
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  leading: CircleAvatar(child: Text('${index + 1}')),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    onPressed: () => setState(() => _questions.removeAt(index)),
                  ),
                ),
              );
            },
          ),
      ],
    );
  }

  void _nextStep() {
    // Validate current step
    if (_currentStep == 0) {
      if (_titleController.text.isEmpty || _selectedModuleId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please fill all required fields')),
        );
        return;
      }
    }
    if (_currentStep < 2) {
      setState(() => _currentStep++);
    }
  }

  void _prevStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    }
  }

  void _showAddQuestionDialog() {
    // Simplified add dialog
    final qTextController = TextEditingController();
    final opt1Controller = TextEditingController();
    final opt2Controller = TextEditingController();
    final opt3Controller = TextEditingController();
    final opt4Controller = TextEditingController();
    int rightAns = 0;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Add Question'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: qTextController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Question Text',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                _buildOptionField(
                  0,
                  opt1Controller,
                  rightAns,
                  (val) => setDialogState(() => rightAns = val),
                ),
                _buildOptionField(
                  1,
                  opt2Controller,
                  rightAns,
                  (val) => setDialogState(() => rightAns = val),
                ),
                _buildOptionField(
                  2,
                  opt3Controller,
                  rightAns,
                  (val) => setDialogState(() => rightAns = val),
                ),
                _buildOptionField(
                  3,
                  opt4Controller,
                  rightAns,
                  (val) => setDialogState(() => rightAns = val),
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
                if (qTextController.text.isNotEmpty) {
                  setState(() {
                    _questions.add({
                      'question_text': qTextController.text,
                      'options': [
                        opt1Controller.text,
                        opt2Controller.text,
                        opt3Controller.text,
                        opt4Controller.text,
                      ],
                      'correct_answer': rightAns,
                      'difficulty': 'medium', // default
                    });
                  });
                  Navigator.pop(context);
                }
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionField(
    int index,
    TextEditingController controller,
    int groupVal,
    Function(int) onChanged,
  ) {
    return RadioListTile<int>(
      value: index,
      groupValue: groupVal,
      onChanged: (val) => onChanged(val!),
      title: TextField(
        controller: controller,
        decoration: InputDecoration(hintText: 'Option ${index + 1}'),
      ),
    );
  }

  Future<void> _updateAssessment() async {
    setState(() => _isSubmitting = true);
    try {
      final testId = widget.assessment!['id'];

      // 1. Update Test Details
      final testData = {
        'title': _titleController.text,
        'description': _descController.text,
        'duration_minutes': int.tryParse(_durationController.text) ?? 30,
        'module_id': _selectedModuleId,
        'difficulty': _selectedDifficulty,
        'passing_score': int.tryParse(_passingScoreController.text) ?? 50,
      };

      await ref
          .read(collegeRepositoryProvider)
          .updateAssessment(testId, testData);

      // 2. Update Assignment Details
      if (_assignmentId != null) {
        String assignmentType;
        if (_targetAudience == 'all') {
          assignmentType = 'all_students';
        } else if (_targetAudience == 'department') {
          assignmentType = 'department';
        } else {
          assignmentType = 'batch';
        }

        final assignmentData = {
          'assignment_type': assignmentType,
          'assigned_to_batch': _targetAudience == 'batch'
              ? _selectedBatch
              : null,
          'assigned_to_department': _targetAudience == 'department'
              ? _selectedDepartment
              : null,
        };

        await ref
            .read(collegeRepositoryProvider)
            .updateAssignment(_assignmentId!, assignmentData);
      }

      if (mounted) {
        final scaffoldMessenger = ScaffoldMessenger.of(context);
        final navigator = Navigator.of(context);
        scaffoldMessenger.showSnackBar(
          const SnackBar(content: Text('Assessment Updated Successfully!')),
        );
        navigator.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error updating: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _submitAssessment() async {
    // [Keep existing implementation]
    if (_questions.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please add at least one question')),
        );
      }
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        throw Exception('User not logged in');
      }
      final orgData = await ref
          .read(collegeRepositoryProvider)
          .getOrganizationByUserId(user.id);

      if (orgData == null) {
        throw Exception('Organization not found');
      }

      final testData = {
        'title': _titleController.text,
        'description': _descController.text,
        'test_type': 'assignment', // College created tests are assignments
        'duration_minutes': int.tryParse(_durationController.text) ?? 30,
        'module_id': _selectedModuleId,
        'organization_id': orgData['id'],
        'difficulty': _selectedDifficulty,
        'passing_score': int.tryParse(_passingScoreController.text) ?? 50,
        'instructions': 'Answer all questions within the time limit.',
      };

      String assignmentType;
      if (_targetAudience == 'all') {
        assignmentType = 'all_students';
      } else if (_targetAudience == 'department') {
        assignmentType = 'department';
      } else {
        assignmentType = 'batch';
      }

      final assignmentData = {
        'assignment_type': assignmentType,
        'assigned_by_role': 'college_admin',
        'deadline': DateTime.now()
            .add(const Duration(days: 7))
            .toIso8601String(),
        'is_mandatory': true,
        // Add batch/dept fields if needed
        'assigned_to_batch': _targetAudience == 'batch' ? _selectedBatch : null,
        'assigned_to_department': _targetAudience == 'department'
            ? _selectedDepartment
            : null,
      };

      await Supabase.instance.client.rpc(
        'create_full_aptitude_test',
        params: {
          'p_test_data': testData,
          'p_questions_data': _questions,
          'p_assignment_data': assignmentData,
        },
      );

      if (mounted) {
        final scaffoldMessenger = ScaffoldMessenger.of(context);
        final navigator = Navigator.of(context);
        scaffoldMessenger.showSnackBar(
          const SnackBar(content: Text('Assessment Created Successfully!')),
        );
        navigator.pop(); // Close screen
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error creating assessment: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }
}

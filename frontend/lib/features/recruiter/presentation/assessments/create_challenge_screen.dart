import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CreateChallengeScreen extends StatefulWidget {
  const CreateChallengeScreen({super.key});

  @override
  State<CreateChallengeScreen> createState() => _CreateChallengeScreenState();
}

class _CreateChallengeScreenState extends State<CreateChallengeScreen> {
  int _currentStep = 0;
  bool _isSubmitting = false;

  // Form Controllers
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _durationController = TextEditingController(text: '60');
  final _passingScoreController = TextEditingController(text: '75');
  final _jobRoleController = TextEditingController();

  String _selectedDifficulty = 'hard';
  String? _selectedModuleId;

  // Questions State
  List<Map<String, dynamic>> _questions = [];

  // Dropdown Data
  List<Map<String, dynamic>> _modules = [];

  @override
  void initState() {
    super.initState();
    _fetchDropdownData();
  }

  Future<void> _fetchDropdownData() async {
    try {
      final modulesRes = await Supabase.instance.client
          .from('aptitude_modules')
          .select('id, name')
          .eq('is_active', true);

      if (mounted) {
        setState(() {
          _modules = List<Map<String, dynamic>>.from(modulesRes);
        });
      }
    } catch (e) {
      print('Error fetching dropdowns: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.maybePop(context),
        ),
        title: Text(
          'Create Technical Challenge',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: Stepper(
        type: StepperType.horizontal,
        currentStep: _currentStep,
        onStepContinue: _nextStep,
        onStepCancel: _prevStep,
        elevation: 0,
        controlsBuilder: (context, details) {
          return Padding(
            padding: const EdgeInsets.only(top: 24),
            child: Row(
              children: [
                if (_currentStep < 2)
                  FilledButton(
                    onPressed: details.onStepContinue,
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.black87,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                    child: const Text('Next Step'),
                  )
                else
                  FilledButton.icon(
                    onPressed: _isSubmitting ? null : _submitChallenge,
                    icon: _isSubmitting
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Icon(Icons.rocket_launch, size: 18),
                    label: const Text('Launch Challenge'),
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.black87,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                  ),
                const SizedBox(width: 12),
                if (_currentStep > 0)
                  TextButton(
                    onPressed: details.onStepCancel,
                    child: Text(
                      'Back',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ),
              ],
            ),
          );
        },
        steps: [
          Step(
            title: const Text('Basics'),
            content: _buildDetailsStep(),
            isActive: _currentStep >= 0,
            state: _currentStep > 0 ? StepState.complete : StepState.editing,
          ),
          Step(
            title: const Text('Configuration'),
            content: _buildConfigStep(),
            isActive: _currentStep >= 1,
            state: _currentStep > 1 ? StepState.complete : StepState.editing,
          ),
          Step(
            title: const Text('Questions'),
            content: _buildQuestionsStep(),
            isActive: _currentStep >= 2,
            state: _currentStep > 2 ? StepState.complete : StepState.editing,
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
            labelText: 'Challenge Title',
            hintText: 'e.g., Senior React Developer Assessment',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _jobRoleController,
          decoration: const InputDecoration(
            labelText: 'Target Job Role',
            hintText: 'e.g., Frontend Engineer',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _descController,
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: 'Description / Instructions',
            hintText: 'Provide context for the candidates...',
            border: OutlineInputBorder(),
          ),
        ),
      ],
    );
  }

  Widget _buildConfigStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButtonFormField<String>(
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
            labelText: 'Primary Skill Category',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                value: _selectedDifficulty,
                items: ['medium', 'hard', 'expert']
                    .map(
                      (d) => DropdownMenuItem(
                        value: d,
                        child: Text(d.toUpperCase()),
                      ),
                    )
                    .toList(),
                onChanged: (val) => setState(() => _selectedDifficulty = val!),
                decoration: const InputDecoration(
                  labelText: 'Difficulty Level',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextField(
                controller: _durationController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Duration (Min)',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _passingScoreController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Passing Score (%)',
            helperText: 'Minimum score to be considered for interview',
            border: OutlineInputBorder(),
          ),
        ),
      ],
    );
  }

  Widget _buildQuestionsStep() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Challenge Questions (${_questions.length})',
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            OutlinedButton.icon(
              onPressed: _showAddQuestionDialog,
              icon: const Icon(Icons.add),
              label: const Text('Add Question'),
              style: OutlinedButton.styleFrom(foregroundColor: Colors.black87),
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
              color: Colors.grey[50],
            ),
            child: Center(
              child: Column(
                children: [
                  Icon(Icons.quiz_outlined, size: 48, color: Colors.grey[400]),
                  const SizedBox(height: 8),
                  const Text('No questions added yet.'),
                  Text(
                    'Add custom questions to test specific skills.',
                    style: TextStyle(color: Colors.grey[500], fontSize: 12),
                  ),
                ],
              ),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _questions.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final q = _questions[index];
              return ListTile(
                shape: RoundedRectangleBorder(
                  side: BorderSide(color: Colors.grey[200]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                title: Text(
                  q['question_text'],
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                leading: CircleAvatar(
                  backgroundColor: Colors.black87,
                  foregroundColor: Colors.white,
                  child: Text('${index + 1}'),
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.close, color: Colors.grey),
                  onPressed: () => setState(() => _questions.removeAt(index)),
                ),
              );
            },
          ),
      ],
    );
  }

  void _nextStep() {
    if (_currentStep == 0) {
      if (_titleController.text.isEmpty || _jobRoleController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please fill all required fields')),
        );
        return;
      }
    } else if (_currentStep == 1) {
      if (_selectedModuleId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a skill category')),
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
          title: const Text('Add Challenge Question'),
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
                      'correct_answer': rightAns, // 0-indexed
                      'difficulty': _selectedDifficulty,
                    });
                  });
                  Navigator.pop(context);
                }
              },
              style: FilledButton.styleFrom(backgroundColor: Colors.black87),
              child: const Text('Add Question'),
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
      activeColor: Colors.black87,
      title: TextField(
        controller: controller,
        decoration: InputDecoration(
          hintText: 'Option ${index + 1}',
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 0,
            vertical: 8,
          ),
          border: InputBorder.none,
        ),
      ),
    );
  }

  Future<void> _submitChallenge() async {
    if (_questions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one question')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) throw Exception('User not logged in');

      // Recruiters might not have organization_id in same way, but let's assume 'recruiters' table has company_id
      final recruiterData = await Supabase.instance.client
          .from('recruiters')
          .select('company_id')
          .eq('id', user.id)
          .single();

      final testData = {
        'title': _titleController.text,
        'description':
            '${_descController.text}\nJob Role: ${_jobRoleController.text}',
        'test_type': 'challenge',
        'duration_minutes': int.tryParse(_durationController.text) ?? 60,
        'module_id': _selectedModuleId,
        'organization_id':
            recruiterData['company_id'], // Using company_id as organization_id
        'difficulty': _selectedDifficulty,
        'passing_score': int.tryParse(_passingScoreController.text) ?? 75,
        'instructions':
            'Complete this technical challenge to proceed to the next round.',
      };

      final assignmentData = {
        'assignment_type':
            'public_link', // Challenges are open via link by default for now
        'assigned_by_role': 'recruiter',
        'deadline': DateTime.now()
            .add(const Duration(days: 30))
            .toIso8601String(),
        'is_mandatory': true,
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Challenge Created Successfully!')),
        );
        Navigator.pop(context); // Close screen
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error creating challenge: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }
}

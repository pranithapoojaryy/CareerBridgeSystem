import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../student/data/learning_repository.dart';
import '../../../student/domain/learning_course.dart';
import '../../../student/domain/assessment.dart';
import 'question_editor_screen.dart';

class AssessmentBuilderScreen extends ConsumerStatefulWidget {
  final CourseSection section;
  final AssessmentType assessmentType;
  final Function(Assessment) onSave;
  final Assessment? existingAssessment;

  const AssessmentBuilderScreen({
    super.key,
    required this.section,
    required this.assessmentType,
    required this.onSave,
    this.existingAssessment,
  });

  @override
  ConsumerState<AssessmentBuilderScreen> createState() =>
      _AssessmentBuilderScreenState();
}

class _AssessmentBuilderScreenState
    extends ConsumerState<AssessmentBuilderScreen> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _passingCriteriaController = TextEditingController();
  final _weightageController = TextEditingController();
  final _attemptsController = TextEditingController();

  bool _isAutoEvaluated = true;
  bool _isSaving = false;
  List<AssessmentQuestion> _questions = [];
  int _currentStep = 0;

  @override
  void initState() {
    super.initState();
    if (widget.existingAssessment != null) {
      _initFromExisting();
    } else {
      _passingCriteriaController.text = '60';
      _weightageController.text = '10';
      _attemptsController.text = '3';
    }
  }

  void _initFromExisting() {
    final assessment = widget.existingAssessment!;
    _titleController.text = assessment.title;
    _descriptionController.text = assessment.description;
    _passingCriteriaController.text = assessment.passingCriteria.toString();
    _weightageController.text = assessment.weightage.toString();
    _attemptsController.text = assessment.attemptsAllowed.toString();
    _isAutoEvaluated = assessment.isAutoEvaluated;
    _questions = List.from(assessment.questions);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      appBar: AppBar(
        title: Text(
          widget.existingAssessment != null
              ? 'Edit Assessment'
              : 'Create Assessment',
          style: GoogleFonts.outfit(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: LinearProgressIndicator(
            value: (_currentStep + 1) / 3,
            backgroundColor: Colors.grey[100],
            valueColor: const AlwaysStoppedAnimation<Color>(
              AppTheme.primaryColor,
            ),
          ),
        ),
      ),
      body: Stepper(
        type: StepperType.horizontal,
        currentStep: _currentStep,
        onStepContinue: _nextStep,
        onStepCancel: _prevStep,
        elevation: 0,
        controlsBuilder: (context, details) {
          return Padding(
            padding: const EdgeInsets.only(top: 32),
            child: Row(
              children: [
                Expanded(
                  child: FilledButton(
                    onPressed: _isSaving ? null : details.onStepContinue,
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      backgroundColor: AppTheme.primaryColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isSaving
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : Text(
                            _currentStep == 2 ? 'Save Assessment' : 'Continue',
                            style: GoogleFonts.outfit(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                  ),
                ),
                if (_currentStep > 0) ...[
                  const SizedBox(width: 16),
                  OutlinedButton(
                    onPressed: details.onStepCancel,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        vertical: 18,
                        horizontal: 24,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Back',
                      style: GoogleFonts.outfit(color: Colors.grey.shade700),
                    ),
                  ),
                ],
              ],
            ),
          );
        },
        steps: [
          Step(
            title: const Text('Details'),
            content: _buildDetailsStep(),
            isActive: _currentStep >= 0,
            state: _currentStep > 0 ? StepState.complete : StepState.editing,
          ),
          Step(
            title: const Text('Questions'),
            content: _buildQuestionsStep(),
            isActive: _currentStep >= 1,
            state: _currentStep > 1 ? StepState.complete : StepState.editing,
          ),
          Step(
            title: const Text('Review'),
            content: _buildReviewStep(),
            isActive: _currentStep >= 2,
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsStep() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionCard(
            title: 'Assessment Information',
            icon: Icons.assignment_outlined,
            children: [
              TextField(
                controller: _titleController,
                decoration: _inputDecoration(
                  label: 'Assessment Title *',
                  hint: 'e.g., Module 1 Quiz',
                  icon: Icons.title,
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _descriptionController,
                maxLines: 3,
                decoration: _inputDecoration(
                  label: 'Description',
                  hint: 'What will students be evaluated on?',
                  icon: Icons.description_outlined,
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          _buildSectionCard(
            title: 'Assessment Settings',
            icon: Icons.settings_outlined,
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _passingCriteriaController,
                      keyboardType: TextInputType.number,
                      decoration: _inputDecoration(
                        label: 'Passing % *',
                        hint: '60',
                        icon: Icons.percent,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextField(
                      controller: _weightageController,
                      keyboardType: TextInputType.number,
                      decoration: _inputDecoration(
                        label: 'Weightage %',
                        hint: '10',
                        icon: Icons.balance,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _attemptsController,
                keyboardType: TextInputType.number,
                decoration: _inputDecoration(
                  label: 'Attempts Allowed',
                  hint: '3',
                  icon: Icons.refresh,
                ),
              ),
              const SizedBox(height: 20),
              SwitchListTile(
                title: Text('Auto-Evaluate', style: GoogleFonts.outfit()),
                subtitle: Text(
                  'Automatically grade MCQ and True/False questions',
                  style: GoogleFonts.outfit(fontSize: 12),
                ),
                value: _isAutoEvaluated,
                onChanged: (v) => setState(() => _isAutoEvaluated = v),
                activeColor: AppTheme.primaryColor,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionsStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_questions.isEmpty)
          Container(
            padding: const EdgeInsets.all(40),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Center(
              child: Column(
                children: [
                  Icon(
                    Icons.quiz_outlined,
                    size: 64,
                    color: Colors.grey.shade300,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No Questions Yet',
                    style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Add questions to build your assessment',
                    style: GoogleFonts.outfit(
                      color: Colors.grey.shade600,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: _addQuestion,
                    icon: const Icon(Icons.add),
                    label: const Text('Add First Question'),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          Column(
            children: [
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _questions.length,
                itemBuilder: (context, index) =>
                    _buildQuestionCard(_questions[index], index),
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: _addQuestion,
                icon: const Icon(Icons.add),
                label: const Text('Add Another Question'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    vertical: 16,
                    horizontal: 24,
                  ),
                ),
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildQuestionCard(AssessmentQuestion question, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          leading: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '${index + 1}',
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor,
                ),
              ),
            ),
          ),
          title: Text(
            question.questionText,
            style: GoogleFonts.outfit(fontWeight: FontWeight.w500),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Row(
              children: [
                _buildQuestionTypeBadge(question.type),
                const SizedBox(width: 8),
                Text(
                  '${question.points} points',
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.edit_outlined, size: 18),
                onPressed: () => _editQuestion(index),
              ),
              IconButton(
                icon: const Icon(
                  Icons.delete_outline,
                  size: 18,
                  color: Colors.red,
                ),
                onPressed: () => _deleteQuestion(index),
              ),
              const Icon(Icons.expand_more),
            ],
          ),
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (question.type == QuestionType.multipleChoice) ...[
                    Text(
                      'Options:',
                      style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    ...question.options.asMap().entries.map((entry) {
                      final optIndex = entry.key;
                      final option = entry.value;
                      final isCorrect = question.correctAnswers.contains(
                        optIndex,
                      );
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          children: [
                            Icon(
                              isCorrect
                                  ? Icons.check_circle
                                  : Icons.radio_button_unchecked,
                              size: 16,
                              color: isCorrect ? Colors.green : Colors.grey,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                option,
                                style: GoogleFonts.outfit(
                                  fontSize: 13,
                                  fontWeight: isCorrect
                                      ? FontWeight.w600
                                      : FontWeight.normal,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ] else if (question.correctAnswer != null) ...[
                    Text(
                      'Correct Answer:',
                      style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      question.correctAnswer!,
                      style: GoogleFonts.outfit(fontSize: 13),
                    ),
                  ],
                  if (question.explanation != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.lightbulb_outline,
                                size: 16,
                                color: Colors.blue.shade700,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Explanation',
                                style: GoogleFonts.outfit(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue.shade700,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            question.explanation!,
                            style: GoogleFonts.outfit(fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestionTypeBadge(QuestionType type) {
    String label;
    Color color;

    switch (type) {
      case QuestionType.multipleChoice:
        label = 'MCQ';
        color = const Color(0xFF3B82F6);
        break;
      case QuestionType.trueFalse:
        label = 'T/F';
        color = const Color(0xFF10B981);
        break;
      case QuestionType.shortAnswer:
        label = 'Short Answer';
        color = const Color(0xFF8B5CF6);
        break;
      case QuestionType.essay:
        label = 'Essay';
        color = const Color(0xFFF59E0B);
        break;
      case QuestionType.code:
        label = 'Code';
        color = const Color(0xFFEF4444);
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: GoogleFonts.outfit(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Widget _buildReviewStep() {
    final totalPoints = _questions.fold(0, (sum, q) => sum + q.points);

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Ready to Publish?',
            style: GoogleFonts.outfit(
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Review your assessment before publishing',
            style: GoogleFonts.outfit(color: Colors.grey.shade600),
          ),
          const SizedBox(height: 24),

          _buildSectionCard(
            title: 'Assessment Details',
            icon: Icons.info_outline,
            children: [
              _buildReviewRow('Title', _titleController.text),
              _buildReviewRow('Type', widget.assessmentType.toString()),
              _buildReviewRow('Total Questions', '${_questions.length}'),
              _buildReviewRow('Total Points', '$totalPoints'),
              _buildReviewRow(
                'Passing Criteria',
                '${_passingCriteriaController.text}%',
              ),
              _buildReviewRow('Weightage', '${_weightageController.text}%'),
              _buildReviewRow('Attempts Allowed', _attemptsController.text),
              _buildReviewRow(
                'Auto-Evaluated',
                _isAutoEvaluated ? 'Yes' : 'No',
              ),
            ],
          ),

          const SizedBox(height: 20),

          if (_questions.isNotEmpty)
            _buildSectionCard(
              title: 'Questions Breakdown',
              icon: Icons.analytics_outlined,
              children: [
                _buildReviewRow(
                  'MCQ',
                  '${_questions.where((q) => q.type == QuestionType.multipleChoice).length}',
                ),
                _buildReviewRow(
                  'True/False',
                  '${_questions.where((q) => q.type == QuestionType.trueFalse).length}',
                ),
                _buildReviewRow(
                  'Short Answer',
                  '${_questions.where((q) => q.type == QuestionType.shortAnswer).length}',
                ),
                _buildReviewRow(
                  'Essay',
                  '${_questions.where((q) => q.type == QuestionType.essay).length}',
                ),
                _buildReviewRow(
                  'Code',
                  '${_questions.where((q) => q.type == QuestionType.code).length}',
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: AppTheme.primaryColor, size: 22),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ...children,
        ],
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String label,
    String? hint,
    IconData? icon,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: icon != null ? Icon(icon, size: 20) : null,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppTheme.primaryColor, width: 2),
      ),
      filled: true,
      fillColor: Colors.grey.shade50,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }

  Widget _buildReviewRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.outfit(
              color: Colors.grey.shade600,
              fontSize: 14,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.outfit(
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  void _addQuestion() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => QuestionEditorScreen(
          onSave: (question) {
            setState(() => _questions.add(question));
          },
        ),
      ),
    );
  }

  void _editQuestion(int index) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => QuestionEditorScreen(
          existingQuestion: _questions[index],
          onSave: (question) {
            setState(() => _questions[index] = question);
          },
        ),
      ),
    );
  }

  void _deleteQuestion(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Delete Question?',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              setState(() => _questions.removeAt(index));
              Navigator.pop(context);
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _nextStep() {
    if (_currentStep < 2) {
      // Validation
      if (_currentStep == 0) {
        if (_titleController.text.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please enter assessment title')),
          );
          return;
        }
      } else if (_currentStep == 1) {
        if (_questions.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please add at least one question')),
          );
          return;
        }
      }
      setState(() => _currentStep++);
    } else {
      _saveAssessment();
    }
  }

  void _prevStep() {
    if (_currentStep > 0) setState(() => _currentStep--);
  }

  Future<void> _saveAssessment() async {
    setState(() => _isSaving = true);
    try {
      final assessment = Assessment(
        id:
            widget.existingAssessment?.id ??
            DateTime.now().millisecondsSinceEpoch.toString(),
        sectionId: widget.section.id,
        title: _titleController.text,
        description: _descriptionController.text,
        type: widget.assessmentType,
        passingCriteria:
            double.tryParse(_passingCriteriaController.text) ?? 60.0,
        weightage: double.tryParse(_weightageController.text) ?? 10.0,
        attemptsAllowed: int.tryParse(_attemptsController.text) ?? 3,
        isAutoEvaluated: _isAutoEvaluated,
        questions: _questions,
        createdAt: DateTime.now(),
      );

      // Validate that section_id is a valid UUID
      final uuidPattern = RegExp(
        r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
        caseSensitive: false,
      );

      if (!uuidPattern.hasMatch(widget.section.id)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Cannot save assessment: The module must be saved first. Please click "Save Changes" on the previous screen.',
            ),
            backgroundColor: Colors.orange,
            action: SnackBarAction(
              label: 'OK',
              onPressed: () {},
              textColor: Colors.white,
            ),
          ),
        );
        setState(() => _isSaving = false);
        return;
      }

      // Save to database and get the real assessment ID
      final assessmentId = await ref
          .read(learningRepositoryProvider)
          .createAssessment(assessment);

      // Call callback with updated assessment
      widget.onSave(assessment.copyWith(id: assessmentId));

      // Show success and go back
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Assessment created successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating assessment: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _passingCriteriaController.dispose();
    _weightageController.dispose();
    _attemptsController.dispose();
    super.dispose();
  }
}

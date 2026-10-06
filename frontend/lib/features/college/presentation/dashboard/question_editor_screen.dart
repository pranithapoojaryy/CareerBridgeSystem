import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../student/domain/assessment.dart';
import 'dart:io';

class QuestionEditorScreen extends StatefulWidget {
  final Function(AssessmentQuestion) onSave;
  final AssessmentQuestion? existingQuestion;

  const QuestionEditorScreen({
    super.key,
    required this.onSave,
    this.existingQuestion,
  });

  @override
  State<QuestionEditorScreen> createState() => _QuestionEditorScreenState();
}

class _QuestionEditorScreenState extends State<QuestionEditorScreen> {
  final _questionController = TextEditingController();
  final _explanationController = TextEditingController();
  final _pointsController = TextEditingController();
  final _correctAnswerController = TextEditingController();

  QuestionType _selectedType = QuestionType.multipleChoice;
  List<String> _options = ['', '', '', ''];
  List<int> _correctAnswers = [];
  String? _imagePath;
  String? _codeStub;

  @override
  void initState() {
    super.initState();
    _pointsController.text = '1';

    if (widget.existingQuestion != null) {
      _initFromExisting();
    }
  }

  void _initFromExisting() {
    final q = widget.existingQuestion!;
    _questionController.text = q.questionText;
    _selectedType = q.type;
    _pointsController.text = q.points.toString();
    _explanationController.text = q.explanation ?? '';

    if (q.type == QuestionType.multipleChoice) {
      _options = List.from(q.options);
      _correctAnswers = List.from(q.correctAnswers);
    } else if (q.correctAnswer != null) {
      _correctAnswerController.text = q.correctAnswer!;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      appBar: AppBar(
        title: Text(
          widget.existingQuestion != null ? 'Edit Question' : 'New Question',
          style: GoogleFonts.outfit(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: FilledButton(
              onPressed: _saveQuestion,
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
              ),
              child: const Text('Save'),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionCard(
              title: 'Question Type',
              icon: Icons.category_outlined,
              children: [
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _buildTypeChip(
                      QuestionType.multipleChoice,
                      'Multiple Choice',
                      Icons.checklist,
                    ),
                    _buildTypeChip(
                      QuestionType.trueFalse,
                      'True/False',
                      Icons.toggle_on,
                    ),
                    _buildTypeChip(
                      QuestionType.shortAnswer,
                      'Short Answer',
                      Icons.short_text,
                    ),
                    _buildTypeChip(
                      QuestionType.essay,
                      'Essay',
                      Icons.article_outlined,
                    ),
                    _buildTypeChip(QuestionType.code, 'Code', Icons.code),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 20),

            _buildSectionCard(
              title: 'Question Details',
              icon: Icons.question_answer_outlined,
              children: [
                TextField(
                  controller: _questionController,
                  maxLines: 3,
                  decoration: _inputDecoration(
                    label: 'Question Text *',
                    hint: 'Enter your question here',
                  ),
                ),
                const SizedBox(height: 16),

                // Image Upload
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Question Image (Optional)',
                            style: GoogleFonts.outfit(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          OutlinedButton.icon(
                            onPressed: _pickImage,
                            icon: const Icon(Icons.image, size: 18),
                            label: const Text('Upload Image'),
                          ),
                        ],
                      ),
                      if (_imagePath != null) ...[
                        const SizedBox(height: 12),
                        Container(
                          height: 150,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            image: DecorationImage(
                              image: FileImage(File(_imagePath!)),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextButton.icon(
                          onPressed: () => setState(() => _imagePath = null),
                          icon: const Icon(Icons.delete, size: 16),
                          label: const Text('Remove Image'),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.red,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 16),
                TextField(
                  controller: _pointsController,
                  keyboardType: TextInputType.number,
                  decoration: _inputDecoration(
                    label: 'Points',
                    hint: '1',
                    icon: Icons.star_outline,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Type-specific fields
            if (_selectedType == QuestionType.multipleChoice)
              _buildMCQSection(),
            if (_selectedType == QuestionType.trueFalse)
              _buildTrueFalseSection(),
            if (_selectedType == QuestionType.shortAnswer)
              _buildShortAnswerSection(),
            if (_selectedType == QuestionType.essay) _buildEssaySection(),
            if (_selectedType == QuestionType.code) _buildCodeSection(),

            const SizedBox(height: 20),

            _buildSectionCard(
              title: 'Explanation (Optional)',
              icon: Icons.lightbulb_outline,
              children: [
                TextField(
                  controller: _explanationController,
                  maxLines: 3,
                  decoration: _inputDecoration(
                    label: 'Explanation',
                    hint: 'Explain the correct answer for students',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeChip(QuestionType type, String label, IconData icon) {
    final isSelected = _selectedType == type;
    return FilterChip(
      selected: isSelected,
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [Icon(icon, size: 18), const SizedBox(width: 8), Text(label)],
      ),
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _selectedType = type;
            // Reset type-specific data
            if (type == QuestionType.multipleChoice) {
              _options = ['', '', '', ''];
              _correctAnswers = [];
            } else {
              _correctAnswerController.clear();
            }
          });
        }
      },
      selectedColor: AppTheme.primaryColor.withValues(alpha: 0.2),
      checkmarkColor: AppTheme.primaryColor,
    );
  }

  Widget _buildMCQSection() {
    return _buildSectionCard(
      title: 'Answer Options',
      icon: Icons.list_alt,
      children: [
        ..._options.asMap().entries.map((entry) {
          final index = entry.key;
          final option = entry.value;
          final isCorrect = _correctAnswers.contains(index);

          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                Checkbox(
                  value: isCorrect,
                  onChanged: (checked) {
                    setState(() {
                      if (checked == true) {
                        _correctAnswers.add(index);
                      } else {
                        _correctAnswers.remove(index);
                      }
                    });
                  },
                  activeColor: AppTheme.primaryColor,
                ),
                Expanded(
                  child: TextField(
                    controller: TextEditingController(text: option)
                      ..selection = TextSelection.collapsed(
                        offset: option.length,
                      ),
                    onChanged: (value) => _options[index] = value,
                    decoration: InputDecoration(
                      labelText: 'Option ${String.fromCharCode(65 + index)}',
                      border: const OutlineInputBorder(),
                      suffixIcon: index >= 4
                          ? IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => setState(() {
                                _options.removeAt(index);
                                _correctAnswers = _correctAnswers
                                    .where((i) => i != index)
                                    .map((i) => i > index ? i - 1 : i)
                                    .toList();
                              }),
                            )
                          : null,
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
        OutlinedButton.icon(
          onPressed: () => setState(() => _options.add('')),
          icon: const Icon(Icons.add),
          label: const Text('Add Option'),
        ),
        const SizedBox(height: 12),
        if (_correctAnswers.isEmpty)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orange.shade200),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.warning_amber,
                  color: Colors.orange.shade700,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Please select at least one correct answer',
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      color: Colors.orange.shade900,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildTrueFalseSection() {
    return _buildSectionCard(
      title: 'Correct Answer',
      icon: Icons.check_circle_outline,
      children: [
        RadioListTile<String>(
          title: const Text('True'),
          value: 'true',
          groupValue: _correctAnswerController.text.toLowerCase(),
          onChanged: (value) =>
              setState(() => _correctAnswerController.text = value!),
          activeColor: AppTheme.primaryColor,
        ),
        RadioListTile<String>(
          title: const Text('False'),
          value: 'false',
          groupValue: _correctAnswerController.text.toLowerCase(),
          onChanged: (value) =>
              setState(() => _correctAnswerController.text = value!),
          activeColor: AppTheme.primaryColor,
        ),
      ],
    );
  }

  Widget _buildShortAnswerSection() {
    return _buildSectionCard(
      title: 'Expected Answer',
      icon: Icons.edit_note,
      children: [
        TextField(
          controller: _correctAnswerController,
          decoration: _inputDecoration(
            label: 'Correct Answer',
            hint: 'Enter the expected answer',
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Matching will be case-insensitive and trim whitespace',
          style: GoogleFonts.outfit(fontSize: 11, color: Colors.grey.shade600),
        ),
      ],
    );
  }

  Widget _buildEssaySection() {
    return _buildSectionCard(
      title: 'Essay Question',
      icon: Icons.article_outlined,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Colors.blue.shade700,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Manual Grading Required',
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Essay questions require manual evaluation by faculty. Students will submit their answers, and you can provide feedback and grades.',
                style: GoogleFonts.outfit(fontSize: 12),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCodeSection() {
    return _buildSectionCard(
      title: 'Code Question',
      icon: Icons.code,
      children: [
        TextField(
          maxLines: 5,
          decoration: _inputDecoration(
            label: 'Code Stub (Optional)',
            hint: '// Starter code for students\nfunction solution() {\n  \n}',
          ),
          onChanged: (value) => _codeStub = value,
          style: GoogleFonts.jetBrainsMono(fontSize: 13),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _correctAnswerController,
          maxLines: 3,
          decoration: _inputDecoration(
            label: 'GitHub Repository URL (Optional)',
            hint: 'https://github.com/username/repo',
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.purple.shade50,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.code, color: Colors.purple.shade700, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Code Submission',
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.bold,
                      color: Colors.purple.shade700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Students can submit code via text editor or GitHub repository link. Manual evaluation required.',
                style: GoogleFonts.outfit(fontSize: 12),
              ),
            ],
          ),
        ),
      ],
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

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      setState(() => _imagePath = image.path);
    }
  }

  void _saveQuestion() {
    // Validation
    if (_questionController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter question text')),
      );
      return;
    }

    if (_selectedType == QuestionType.multipleChoice &&
        _correctAnswers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one correct answer'),
        ),
      );
      return;
    }

    if (_selectedType == QuestionType.trueFalse &&
        _correctAnswerController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select correct answer')),
      );
      return;
    }

    final question = AssessmentQuestion(
      id:
          widget.existingQuestion?.id ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      questionText: _questionController.text,
      type: _selectedType,
      options: _selectedType == QuestionType.multipleChoice ? _options : [],
      correctAnswers: _correctAnswers,
      correctAnswer:
          _selectedType != QuestionType.multipleChoice &&
              _selectedType != QuestionType.essay
          ? _correctAnswerController.text
          : null,
      points: int.tryParse(_pointsController.text) ?? 1,
      explanation: _explanationController.text.isNotEmpty
          ? _explanationController.text
          : null,
    );

    widget.onSave(question);
    Navigator.pop(context);
  }

  @override
  void dispose() {
    _questionController.dispose();
    _explanationController.dispose();
    _pointsController.dispose();
    _correctAnswerController.dispose();
    super.dispose();
  }
}

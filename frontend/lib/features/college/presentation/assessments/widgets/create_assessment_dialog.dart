import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../core/theme/app_theme.dart';

class CreateAssessmentDialog extends StatefulWidget {
  final Function(Map<String, dynamic>) onAssessmentCreated;
  
  const CreateAssessmentDialog({
    super.key,
    required this.onAssessmentCreated,
  });

  @override
  State<CreateAssessmentDialog> createState() => _CreateAssessmentDialogState();
}

class _CreateAssessmentDialogState extends State<CreateAssessmentDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _skillController = TextEditingController();
  final _durationController = TextEditingController();
  final _totalQuestionsController = TextEditingController();
  final _passingScoreController = TextEditingController();
  final _instructionsController = TextEditingController();
  
  String _selectedCategory = 'programming';
  String _selectedDifficulty = 'intermediate';
  bool _isActive = true;
  bool _allowRetakes = false;
  bool _showResults = true;
  bool _randomizeQuestions = true;

  @override
  void dispose() {
    _titleController.dispose();
    _skillController.dispose();
    _durationController.dispose();
    _totalQuestionsController.dispose();
    _passingScoreController.dispose();
    _instructionsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 700,
        height: 800,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Create New Assessment',
                  style: GoogleFonts.outfit(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textColor,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Form
            Expanded(
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Assessment Title
                      TextFormField(
                        controller: _titleController,
                        decoration: const InputDecoration(
                          labelText: 'Assessment Title',
                          hintText: 'Enter assessment title',
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter assessment title';
                          }
                          return null;
                        },
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Category and Skill
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Category',
                                  style: GoogleFonts.outfit(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.textColor,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[100],
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton<String>(
                                      value: _selectedCategory,
                                      isExpanded: true,
                                      items: [
                                        {'value': 'programming', 'label': '💻 Programming'},
                                        {'value': 'aptitude', 'label': '🧮 Aptitude'},
                                        {'value': 'domain', 'label': '📚 Domain Knowledge'},
                                        {'value': 'soft_skills', 'label': '🗣️ Soft Skills'},
                                      ].map((item) {
                                        return DropdownMenuItem<String>(
                                          value: item['value'],
                                          child: Text(item['label']!),
                                        );
                                      }).toList(),
                                      onChanged: (value) {
                                        setState(() => _selectedCategory = value!);
                                      },
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: _skillController,
                              decoration: const InputDecoration(
                                labelText: 'Skill/Subject',
                                hintText: 'e.g., Python, Java, DSA',
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter skill/subject';
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Difficulty
                      Text(
                        'Difficulty Level',
                        style: GoogleFonts.outfit(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          _buildDifficultyChip('beginner', 'Beginner', Colors.green),
                          const SizedBox(width: 12),
                          _buildDifficultyChip('intermediate', 'Intermediate', Colors.orange),
                          const SizedBox(width: 12),
                          _buildDifficultyChip('advanced', 'Advanced', Colors.red),
                        ],
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Duration and Questions
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _durationController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Duration (minutes)',
                                hintText: '60',
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter duration';
                                }
                                if (int.tryParse(value) == null) {
                                  return 'Please enter a valid number';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: _totalQuestionsController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Total Questions',
                                hintText: '30',
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter total questions';
                                }
                                if (int.tryParse(value) == null) {
                                  return 'Please enter a valid number';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: _passingScoreController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Passing Score (%)',
                                hintText: '70',
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter passing score';
                                }
                                final score = int.tryParse(value);
                                if (score == null || score < 0 || score > 100) {
                                  return 'Please enter a valid percentage (0-100)';
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Instructions
                      TextFormField(
                        controller: _instructionsController,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'Instructions',
                          hintText: 'Enter assessment instructions for students',
                        ),
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Settings
                      Text(
                        'Assessment Settings',
                        style: GoogleFonts.outfit(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textColor,
                        ),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      CheckboxListTile(
                        title: const Text('Active Assessment'),
                        subtitle: const Text('Students can take this assessment'),
                        value: _isActive,
                        onChanged: (value) {
                          setState(() => _isActive = value!);
                        },
                        controlAffinity: ListTileControlAffinity.leading,
                      ),
                      
                      CheckboxListTile(
                        title: const Text('Allow Retakes'),
                        subtitle: const Text('Students can retake this assessment'),
                        value: _allowRetakes,
                        onChanged: (value) {
                          setState(() => _allowRetakes = value!);
                        },
                        controlAffinity: ListTileControlAffinity.leading,
                      ),
                      
                      CheckboxListTile(
                        title: const Text('Show Results'),
                        subtitle: const Text('Show results immediately after completion'),
                        value: _showResults,
                        onChanged: (value) {
                          setState(() => _showResults = value!);
                        },
                        controlAffinity: ListTileControlAffinity.leading,
                      ),
                      
                      CheckboxListTile(
                        title: const Text('Randomize Questions'),
                        subtitle: const Text('Questions appear in random order'),
                        value: _randomizeQuestions,
                        onChanged: (value) {
                          setState(() => _randomizeQuestions = value!);
                        },
                        controlAffinity: ListTileControlAffinity.leading,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Action Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 16),
                OutlinedButton(
                  onPressed: _saveDraft,
                  child: const Text('Save as Draft'),
                ),
                const SizedBox(width: 16),
                FilledButton(
                  onPressed: _createAssessment,
                  child: const Text('Create Assessment'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDifficultyChip(String value, String label, Color color) {
    final isSelected = _selectedDifficulty == value;
    
    return InkWell(
      onTap: () => setState(() => _selectedDifficulty = value),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.1) : Colors.grey[100],
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? color : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isSelected ? color : Colors.grey[600],
          ),
        ),
      ),
    );
  }

  void _saveDraft() {
    if (_formKey.currentState!.validate()) {
      final assessmentData = _getAssessmentData();
      assessmentData['status'] = 'draft';
      
      print('Saving draft: $assessmentData');
      
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${_titleController.text} saved as draft')),
      );
    }
  }

  void _createAssessment() {
    if (_formKey.currentState!.validate()) {
      final assessmentData = {
        'title': _titleController.text,
        'category': _selectedCategory,
        'skill': _skillController.text,
        'difficulty': _selectedDifficulty,
        'duration_minutes': int.parse(_durationController.text),
        'total_questions': int.parse(_totalQuestionsController.text),
        'passing_score': int.parse(_passingScoreController.text),
        'instructions': _instructionsController.text,
        'is_active': _isActive,
        'allow_retakes': _allowRetakes,
        'show_results': _showResults,
        'randomize_questions': _randomizeQuestions,
      };

      widget.onAssessmentCreated(assessmentData);
      Navigator.pop(context);
    }
  }

  Map<String, dynamic> _getAssessmentData() {
    return {
      'title': _titleController.text,
      'category': _selectedCategory,
      'skill': _skillController.text,
      'difficulty': _selectedDifficulty,
      'duration': int.parse(_durationController.text),
      'totalQuestions': int.parse(_totalQuestionsController.text),
      'passingScore': int.parse(_passingScoreController.text),
      'instructions': _instructionsController.text,
      'isActive': _isActive,
      'allowRetakes': _allowRetakes,
      'showResults': _showResults,
      'randomizeQuestions': _randomizeQuestions,
    };
  }
}
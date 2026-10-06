import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/college_providers.dart';

class AssessmentQuestionsScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic> assessment;

  const AssessmentQuestionsScreen({super.key, required this.assessment});

  @override
  ConsumerState<AssessmentQuestionsScreen> createState() =>
      _AssessmentQuestionsScreenState();
}

class _AssessmentQuestionsScreenState
    extends ConsumerState<AssessmentQuestionsScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _questions = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchQuestions();
  }

  Future<void> _fetchQuestions() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      // Assuming 'test_id' is available in the assessment map, fallback to 'id' if not.
      // Based on typical join, it might be nested, but for created assessments 'id' might be the test_id
      // OR there's a specific 'test_id' field if it's an assignment.
      // For College Assessments table, 'id' IS the test_id usually (or mapped to it).
      // Let's assume assessment['id'] is the proper ID for aptitude_questions.test_id
      final testId = widget.assessment['test_id'] ?? widget.assessment['id'];

      final questions = await ref
          .read(collegeRepositoryProvider)
          .getQuestions(testId);

      setState(() {
        _questions = questions;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          'Questions - ${widget.assessment['title']}',
          style: GoogleFonts.outfit(color: AppTheme.textColor, fontSize: 18),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(child: Text('Error: $_error'))
          : _questions.isEmpty
          ? Center(
              child: Text(
                'No questions found for this assessment.',
                style: GoogleFonts.outfit(color: Colors.grey),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(24),
              itemCount: _questions.length,
              separatorBuilder: (_, __) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                return _buildQuestionCard(_questions[index], index + 1);
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addNewQuestion,
        backgroundColor: AppTheme.primaryColor,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildQuestionCard(Map<String, dynamic> question, int index) {
    // Normalize options to Map for UI
    Map<String, dynamic> optionsMap = {};
    if (question['options'] is List) {
      final list = question['options'] as List;
      if (list.isNotEmpty) optionsMap['a'] = list[0];
      if (list.length > 1) optionsMap['b'] = list[1];
      if (list.length > 2) optionsMap['c'] = list[2];
      if (list.length > 3) optionsMap['d'] = list[3];
    } else if (question['options'] is Map) {
      optionsMap = Map<String, dynamic>.from(question['options']);
    }

    // Normalize correct option to 'a'...'d'
    String correctOption = 'a';
    if (question['correct_answer'] != null) {
      final idx = question['correct_answer'] as int;
      if (idx >= 0 && idx < 4) {
        correctOption = ['a', 'b', 'c', 'd'][idx];
      }
    } else if (question['correct_option'] != null) {
      correctOption = question['correct_option'].toString();
    }

    return Container(
      padding: const EdgeInsets.all(20),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Question $index',
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.edit_outlined, size: 20),
                onPressed: () => _editQuestion(question),
                tooltip: 'Edit Question',
              ),
              IconButton(
                icon: const Icon(
                  Icons.delete_outline,
                  size: 20,
                  color: Colors.red,
                ),
                onPressed: () => _confirmDeleteQuestion(question),
                tooltip: 'Delete Question',
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            question['question_text'] ?? 'No text',
            style: GoogleFonts.outfit(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: AppTheme.textColor,
            ),
          ),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 8),
          ...optionsMap.entries.map((entry) {
            final isCorrect = entry.key == correctOption;
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isCorrect
                    ? Colors.green.withValues(alpha: 0.1)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
                border: isCorrect
                    ? Border.all(color: Colors.green.withValues(alpha: 0.5))
                    : null,
              ),
              child: Row(
                children: [
                  Text(
                    '${entry.key.toUpperCase()})',
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.bold,
                      color: isCorrect ? Colors.green : Colors.grey[700],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      entry.value.toString(),
                      style: GoogleFonts.outfit(
                        color: isCorrect ? Colors.green[900] : Colors.grey[800],
                      ),
                    ),
                  ),
                  if (isCorrect)
                    const Icon(
                      Icons.check_circle,
                      color: Colors.green,
                      size: 18,
                    ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  void _editQuestion(Map<String, dynamic> question) {
    showDialog(
      context: context,
      builder: (context) => _EditQuestionDialog(
        question: question,
        onSave: (updatedData) async {
          final messenger = ScaffoldMessenger.of(context);
          final navigator = Navigator.of(context);
          try {
            // Adapt UI data (Map/String) to Schema data (List/Int)
            final newOptionsMap =
                updatedData['options'] as Map<String, dynamic>;
            final newOptionsList = [
              newOptionsMap['a'] ?? '',
              newOptionsMap['b'] ?? '',
              newOptionsMap['c'] ?? '',
              newOptionsMap['d'] ?? '',
            ];
            final correctKey = updatedData['correct_option'] as String;
            final correctIdx = ['a', 'b', 'c', 'd'].indexOf(correctKey);

            final schemaData = {
              'question_text': updatedData['question_text'],
              'options': newOptionsList,
              'correct_answer': correctIdx != -1 ? correctIdx : 0,
            };

            await ref
                .read(collegeRepositoryProvider)
                .updateQuestion(question['id'], schemaData);

            if (mounted) {
              navigator.pop();
              messenger.showSnackBar(
                const SnackBar(content: Text('Question updated successfully')),
              );
              _fetchQuestions(); // Refresh list
            }
          } catch (e) {
            if (mounted) {
              messenger.showSnackBar(
                SnackBar(content: Text('Failed to update: $e')),
              );
            }
          }
        },
      ),
    );
  }

  void _addNewQuestion() {
    final newQuestion = {
      'question_text': '',
      'options': {'a': '', 'b': '', 'c': '', 'd': ''},
      'correct_option': 'a',
    };

    showDialog(
      context: context,
      builder: (context) => _EditQuestionDialog(
        question: newQuestion,
        onSave: (data) async {
          final messenger = ScaffoldMessenger.of(context);
          final navigator = Navigator.of(context);
          try {
            final testId =
                widget.assessment['test_id'] ?? widget.assessment['id'];
            final userId = Supabase.instance.client.auth.currentUser!.id;

            // Adapt UI data (Map/String) to Schema data (List/Int)
            final newOptionsMap = data['options'] as Map<String, dynamic>;
            final newOptionsList = [
              newOptionsMap['a'] ?? '',
              newOptionsMap['b'] ?? '',
              newOptionsMap['c'] ?? '',
              newOptionsMap['d'] ?? '',
            ];
            final correctKey = data['correct_option'] as String;
            final correctIdx = ['a', 'b', 'c', 'd'].indexOf(correctKey);

            final questionData = {
              'question_text': data['question_text'],
              'options': newOptionsList,
              'correct_answer': correctIdx != -1 ? correctIdx : 0,
              'module_id': widget.assessment['module_id'], // Required by schema
              'tags': ['test_id:$testId'], // Link to test via tags
              'created_by': userId,
              'difficulty': widget.assessment['difficulty'] ?? 'medium',
              'is_active': true,
            };

            await ref
                .read(collegeRepositoryProvider)
                .createQuestion(questionData);

            if (mounted) {
              navigator.pop();
              messenger.showSnackBar(
                const SnackBar(content: Text('Question added successfully')),
              );
              _fetchQuestions();
            }
          } catch (e) {
            if (mounted) {
              messenger.showSnackBar(
                SnackBar(content: Text('Failed to add: $e')),
              );
            }
          }
        },
      ),
    );
  }

  void _confirmDeleteQuestion(Map<String, dynamic> question) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Question'),
        content: const Text(
          'Are you sure you want to delete this question? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              final navigator = Navigator.of(context);
              navigator.pop(); // Close dialog

              try {
                await ref
                    .read(collegeRepositoryProvider)
                    .deleteQuestion(question['id']);

                if (mounted) {
                  messenger.showSnackBar(
                    const SnackBar(
                      content: Text('Question deleted successfully'),
                    ),
                  );
                  _fetchQuestions();
                }
              } catch (e) {
                if (mounted) {
                  messenger.showSnackBar(
                    SnackBar(content: Text('Failed to delete: $e')),
                  );
                }
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class _EditQuestionDialog extends StatefulWidget {
  final Map<String, dynamic> question;
  final Function(Map<String, dynamic>) onSave;

  const _EditQuestionDialog({required this.question, required this.onSave});

  @override
  State<_EditQuestionDialog> createState() => _EditQuestionDialogState();
}

class _EditQuestionDialogState extends State<_EditQuestionDialog> {
  late TextEditingController _questionController;
  late TextEditingController _optionAController;
  late TextEditingController _optionBController;
  late TextEditingController _optionCController;
  late TextEditingController _optionDController;
  String _correctOption = 'a';

  @override
  void initState() {
    super.initState();
    _questionController = TextEditingController(
      text: widget.question['question_text'],
    );

    // Normalize options/correct answer for editing
    Map<String, dynamic> optionsMap = {};
    if (widget.question['options'] is List) {
      final list = widget.question['options'] as List;
      if (list.isNotEmpty) optionsMap['a'] = list[0];
      if (list.length > 1) optionsMap['b'] = list[1];
      if (list.length > 2) optionsMap['c'] = list[2];
      if (list.length > 3) optionsMap['d'] = list[3];
    } else if (widget.question['options'] is Map) {
      optionsMap = Map<String, dynamic>.from(widget.question['options']);
    } else {
      optionsMap = {'a': '', 'b': '', 'c': '', 'd': ''};
    }

    String initialCorrect = 'a';
    if (widget.question['correct_answer'] != null) {
      final idx = widget.question['correct_answer'] as int;
      if (idx >= 0 && idx < 4) initialCorrect = ['a', 'b', 'c', 'd'][idx];
    } else if (widget.question['correct_option'] != null) {
      initialCorrect = widget.question['correct_option'].toString();
    }

    _optionAController = TextEditingController(text: optionsMap['a'] ?? '');
    _optionBController = TextEditingController(text: optionsMap['b'] ?? '');
    _optionCController = TextEditingController(text: optionsMap['c'] ?? '');
    _optionDController = TextEditingController(text: optionsMap['d'] ?? '');
    _correctOption = initialCorrect;
  }

  @override
  void dispose() {
    _questionController.dispose();
    _optionAController.dispose();
    _optionBController.dispose();
    _optionCController.dispose();
    _optionDController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Question'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _questionController,
              decoration: const InputDecoration(
                labelText: 'Question Text',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            const Text(
              'Options',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            _buildOptionField('a', _optionAController),
            const SizedBox(height: 8),
            _buildOptionField('b', _optionBController),
            const SizedBox(height: 8),
            _buildOptionField('c', _optionCController),
            const SizedBox(height: 8),
            _buildOptionField('d', _optionDController),
            const SizedBox(height: 16),
            const Text(
              'Correct Answer',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            DropdownButton<String>(
              value: _correctOption,
              isExpanded: true,
              items: ['a', 'b', 'c', 'd'].map((opt) {
                return DropdownMenuItem(
                  value: opt,
                  child: Text('Option ${opt.toUpperCase()}'),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null) setState(() => _correctOption = val);
              },
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
            final updatedData = {
              'question_text': _questionController.text,
              'options': {
                'a': _optionAController.text,
                'b': _optionBController.text,
                'c': _optionCController.text,
                'd': _optionDController.text,
              },
              'correct_option': _correctOption,
            };
            widget.onSave(updatedData);
          },
          child: const Text('Save'),
        ),
      ],
    );
  }

  Widget _buildOptionField(String key, TextEditingController controller) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: 'Option ${key.toUpperCase()}',
        isDense: true,
        border: const OutlineInputBorder(),
      ),
    );
  }
}

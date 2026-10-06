import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:uuid/uuid.dart';

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

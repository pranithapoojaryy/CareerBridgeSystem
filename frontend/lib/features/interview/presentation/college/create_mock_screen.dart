import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'mock_interview_providers.dart';
import '../interview_providers.dart'; // For fetching all questions
import '../../domain/interview_models.dart';
import 'widgets/add_question_sheet.dart';

class CreateMockScreen extends ConsumerStatefulWidget {
  const CreateMockScreen({super.key});

  @override
  ConsumerState<CreateMockScreen> createState() => _CreateMockScreenState();
}

class _CreateMockScreenState extends ConsumerState<CreateMockScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _timeCtrl = TextEditingController(text: "30");

  // Selected Questions
  List<InterviewQuestion> _selectedQuestions = [];
  bool _isLoading = false;

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedQuestions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select at least one question")),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await ref
          .read(mockRepositoryProvider)
          .createMock(
            title: _titleCtrl.text,
            description: _descCtrl.text,
            timeLimit: int.tryParse(_timeCtrl.text) ?? 30,
            questionIds: _selectedQuestions.map((q) => q.id).toList(),
          );
      if (mounted) Navigator.pop(context); // Success
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _openQuestionPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => _QuestionPickerSheet(
        alreadySelectedIds: _selectedQuestions.map((q) => q.id).toSet(),
        onSelected: (questions) {
          setState(() {
            _selectedQuestions.addAll(questions);
          });
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text(
          "Create New Mock",
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _save,
            child: Text(
              "Save",
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Basic Info
              Text(
                "Basic Information",
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _titleCtrl,
                decoration: const InputDecoration(
                  labelText: "Mock Title",
                  border: OutlineInputBorder(),
                ),
                validator: (v) => v!.isEmpty ? "Required" : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descCtrl,
                decoration: const InputDecoration(
                  labelText: "Description",
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _timeCtrl,
                decoration: const InputDecoration(
                  labelText: "Time Limit (Minutes)",
                  border: OutlineInputBorder(),
                  suffixText: "min",
                ),
                keyboardType: TextInputType.number,
                validator: (v) => v!.isEmpty ? "Required" : null,
              ),

              const SizedBox(height: 32),

              // 2. Questions
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Questions (${_selectedQuestions.length})",
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: _openQuestionPicker,
                    icon: const Icon(Icons.add),
                    label: const Text("Add Questions"),
                  ),
                ],
              ),
              const Divider(),

              if (_selectedQuestions.isEmpty)
                Container(
                  padding: const EdgeInsets.all(32),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    "No questions added yet.\nClick 'Add Questions' to browse the bank.",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey),
                  ),
                )
              else
                ReorderableListView(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  onReorder: (oldIndex, newIndex) {
                    setState(() {
                      if (oldIndex < newIndex) newIndex -= 1;
                      final item = _selectedQuestions.removeAt(oldIndex);
                      _selectedQuestions.insert(newIndex, item);
                    });
                  },
                  children: [
                    for (int i = 0; i < _selectedQuestions.length; i++)
                      ListTile(
                        key: ValueKey(_selectedQuestions[i].id),
                        leading: CircleAvatar(
                          child: Text("${i + 1}"),
                          backgroundColor: Colors.blue.shade100,
                          radius: 14,
                        ),
                        title: Text(
                          _selectedQuestions[i].questionText,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          "${_selectedQuestions[i].difficulty} • ${_selectedQuestions[i].questionType}",
                        ),
                        trailing: IconButton(
                          icon: const Icon(
                            Icons.remove_circle_outline,
                            color: Colors.red,
                          ),
                          onPressed: () =>
                              setState(() => _selectedQuestions.removeAt(i)),
                        ),
                      ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuestionPickerSheet extends ConsumerStatefulWidget {
  final Set<String> alreadySelectedIds;
  final Function(List<InterviewQuestion>) onSelected;

  const _QuestionPickerSheet({
    required this.alreadySelectedIds,
    required this.onSelected,
  });

  @override
  ConsumerState<_QuestionPickerSheet> createState() =>
      _QuestionPickerSheetState();
}

class _QuestionPickerSheetState extends ConsumerState<_QuestionPickerSheet> {
  // We need to fetch ALL questions.
  // IMPORTANT: The provider `interviewQuestionsProvider` takes a CategoryID.
  // Ideally, we need a "Fetch All Questions" provider or iterate categories.
  // For simplicity, let's fetch categories then let user filter by them.

  String? _selectedCategoryFilter;
  List<InterviewQuestion> _tempSelected = [];

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(interviewCategoriesProvider);

    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Select Questions",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                Row(
                  children: [
                    // Add New Question Button
                    TextButton.icon(
                      icon: const Icon(Icons.add),
                      label: const Text("New"),
                      onPressed: () {
                        if (_selectedCategoryFilter == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Select a category filter first!"),
                            ),
                          );
                          return;
                        }
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          builder: (_) => AddQuestionSheet(
                            categoryId: _selectedCategoryFilter!,
                          ),
                        ).then((val) {
                          if (val == true) {
                            // Refresh questions list
                            ref.invalidate(
                              interviewQuestionsProvider(
                                _selectedCategoryFilter!,
                              ),
                            );
                          }
                        });
                      },
                    ),
                    const SizedBox(width: 8),
                    TextButton(
                      onPressed: () {
                        widget.onSelected(_tempSelected);
                        Navigator.pop(context);
                      },
                      child: Text("Done (${_tempSelected.length})"),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Filter
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: categoriesAsync.when(
              data: (cats) => DropdownButton<String>(
                isExpanded: true,
                hint: const Text("Filter by Category"),
                value: _selectedCategoryFilter,
                items: [
                  const DropdownMenuItem(
                    value: null,
                    child: Text("All Categories"),
                  ),
                  ...cats.map(
                    (c) => DropdownMenuItem(value: c.id, child: Text(c.name)),
                  ),
                ],
                onChanged: (v) => setState(() => _selectedCategoryFilter = v),
              ),
              loading: () => const LinearProgressIndicator(),
              error: (_, __) => const SizedBox(),
            ),
          ),

          // List
          Expanded(
            child: _selectedCategoryFilter == null
                ? const Center(
                    child: Text(
                      "Please select a category to browse questions.",
                    ),
                  )
                : Consumer(
                    builder: (context, ref, _) {
                      final qsAsync = ref.watch(
                        interviewQuestionsProvider(_selectedCategoryFilter!),
                      );
                      return qsAsync.when(
                        data: (questions) {
                          // Filter out already selected in parent
                          final available = questions
                              .where(
                                (q) =>
                                    !widget.alreadySelectedIds.contains(q.id),
                              )
                              .toList();

                          return ListView.builder(
                            itemCount: available.length,
                            itemBuilder: (ctx, idx) {
                              final q = available[idx];
                              final isSelected = _tempSelected.contains(q);
                              return CheckboxListTile(
                                value: isSelected,
                                title: Text(q.questionText),
                                subtitle: Text(q.difficulty),
                                onChanged: (val) {
                                  setState(() {
                                    if (val == true) {
                                      _tempSelected.add(q);
                                    } else {
                                      _tempSelected.remove(q);
                                    }
                                  });
                                },
                              );
                            },
                          );
                        },
                        loading: () =>
                            const Center(child: CircularProgressIndicator()),
                        error: (e, s) => Center(child: Text("Error: $e")),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

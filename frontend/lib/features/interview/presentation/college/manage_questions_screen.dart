import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/interview_models.dart';
import '../interview_providers.dart';
import 'widgets/add_question_sheet.dart';

class ManageQuestionsScreen extends ConsumerStatefulWidget {
  final String? initialCategoryId;
  const ManageQuestionsScreen({super.key, this.initialCategoryId});

  @override
  ConsumerState<ManageQuestionsScreen> createState() =>
      _ManageQuestionsScreenState();
}

class _ManageQuestionsScreenState extends ConsumerState<ManageQuestionsScreen> {
  String? _selectedCategoryId;

  @override
  void initState() {
    super.initState();
    _selectedCategoryId = widget.initialCategoryId;
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(interviewCategoriesProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFC),
      body: Stack(
        children: [
          Column(
            children: [
              // 1. Top Section: Filters & Context
              Container(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(32),
                    bottomRight: Radius.circular(32),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Color(0x0A1A1F36),
                      blurRadius: 20,
                      offset: Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Select Practice Set",
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF5A6ACF),
                        letterSpacing: 1.1,
                      ),
                    ),
                    const SizedBox(height: 12),
                    categoriesAsync.when(
                      data: (categories) {
                        if (categories.isEmpty) return const SizedBox.shrink();
                        if (_selectedCategoryId == null &&
                            categories.isNotEmpty) {
                          Future.microtask(() {
                            if (mounted) {
                              setState(
                                () => _selectedCategoryId = categories.first.id,
                              );
                            }
                          });
                        }
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF4F7FA),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFE3E8EE)),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _selectedCategoryId,
                              isExpanded: true,
                              icon: const Icon(
                                Icons.keyboard_arrow_down_rounded,
                                color: Color(0xFF1A1F36),
                              ),
                              style: GoogleFonts.outfit(
                                color: const Color(0xFF1A1F36),
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                              items: categories
                                  .map(
                                    (c) => DropdownMenuItem(
                                      value: c.id,
                                      child: Text(c.name),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (val) {
                                setState(() => _selectedCategoryId = val);
                              },
                            ),
                          ),
                        );
                      },
                      loading: () => const LinearProgressIndicator(
                        backgroundColor: Color(0xFFF4F7FA),
                        color: Color(0xFF5A6ACF),
                      ),
                      error: (e, s) => const SizedBox.shrink(),
                    ),
                  ],
                ),
              ),

              // 2. Questions List
              Expanded(
                child: _selectedCategoryId == null
                    ? _buildNoCategorySelected()
                    : Consumer(
                        builder: (context, ref, child) {
                          final questionsAsync = ref.watch(
                            interviewQuestionsProvider(_selectedCategoryId!),
                          );
                          return questionsAsync.when(
                            data: (questions) {
                              if (questions.isEmpty) return _buildEmptyState();

                              final easyCount = questions
                                  .where((q) => q.difficulty == 'Easy')
                                  .length;
                              final hardCount = questions
                                  .where((q) => q.difficulty == 'Hard')
                                  .length;
                              final medCount =
                                  questions.length - easyCount - hardCount;

                              return ListView(
                                padding: const EdgeInsets.all(24),
                                children: [
                                  Row(
                                    children: [
                                      _buildStatChip(
                                        label: 'Total',
                                        count: questions.length,
                                        color: const Color(0xFF5A6ACF),
                                      ),
                                      const SizedBox(width: 8),
                                      _buildStatChip(
                                        label: 'Easy',
                                        count: easyCount,
                                        color: const Color(0xFF2AF598),
                                      ),
                                      const SizedBox(width: 8),
                                      _buildStatChip(
                                        label: 'Med',
                                        count: medCount,
                                        color: const Color(0xFFFFB038),
                                      ),
                                      const SizedBox(width: 8),
                                      _buildStatChip(
                                        label: 'Hard',
                                        count: hardCount,
                                        color: const Color(0xFFE04F5F),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 24),
                                  ...questions
                                      .map((q) => _buildQuestionCard(q))
                                      .toList(),
                                  const SizedBox(height: 80),
                                ],
                              );
                            },
                            loading: () => const Center(
                              child: CircularProgressIndicator(
                                color: Color(0xFF5A6ACF),
                              ),
                            ),
                            error: (e, s) => Center(
                              child: Text(
                                'Error: $e',
                                style: GoogleFonts.outfit(),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
          if (_selectedCategoryId != null)
            Positioned(
              bottom: 24,
              right: 24,
              child: FloatingActionButton.extended(
                onPressed: () => _showAddQuestionSheet(context),
                backgroundColor: const Color(0xFF1A1F36),
                icon: const Icon(Icons.add_rounded, color: Colors.white),
                label: Text(
                  "ADD QUESTION",
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.1,
                    color: Colors.white,
                  ),
                ),
                elevation: 4,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildNoCategorySelected() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: const Icon(
              Icons.category_outlined,
              size: 48,
              color: Color(0xFF5A6ACF),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            "Select a Practice Set",
            style: GoogleFonts.outfit(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1A1F36),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Select a category above to manage questions.",
            style: GoogleFonts.outfit(color: const Color(0xFF697386)),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: const Icon(
              Icons.library_add_outlined,
              size: 48,
              color: Color(0xFF5A6ACF),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            "No Questions Found",
            style: GoogleFonts.outfit(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1A1F36),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Add questions to build your practice bank.",
            style: GoogleFonts.outfit(color: const Color(0xFF697386)),
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip({
    required String label,
    required int count,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: GoogleFonts.outfit(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              count.toString(),
              style: GoogleFonts.outfit(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 10,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionCard(InterviewQuestion q) {
    Color diffColor = const Color(0xFFFFB038); // Medium
    if (q.difficulty == 'Easy') diffColor = const Color(0xFF2AF598);
    if (q.difficulty == 'Hard') diffColor = const Color(0xFFE04F5F);

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 10, 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: diffColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: diffColor.withValues(alpha: 0.2)),
                  ),
                  child: Text(
                    q.difficulty.toUpperCase(),
                    style: GoogleFonts.outfit(
                      color: diffColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 10,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0F2F5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        q.questionType == 'coding'
                            ? Icons.code_rounded
                            : Icons.videocam_rounded,
                        size: 14,
                        color: const Color(0xFF5A6ACF),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        q.questionType.toUpperCase(),
                        style: GoogleFonts.outfit(
                          color: const Color(0xFF5A6ACF),
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(
                    Icons.delete_outline_rounded,
                    size: 22,
                    color: Color(0xFFE04F5F),
                  ),
                  onPressed: () => _confirmDelete(q),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  q.questionText,
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1A1F36),
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 16),
                if (q.expectedKeywords != null &&
                    q.expectedKeywords!.isNotEmpty)
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: q.expectedKeywords!
                        .map(
                          (k) => Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF0F2F5),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.tag_rounded,
                                  size: 12,
                                  color: Color(0xFF697386),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  k,
                                  style: GoogleFonts.outfit(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: const Color(0xFF697386),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                        .toList(),
                  )
                else
                  Text(
                    "No evaluation keywords defined.",
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      fontStyle: FontStyle.italic,
                      color: const Color(0xFFAFB5CF),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(InterviewQuestion q) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          "Delete Question?",
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        content: Text(
          "This question will be permanently removed from the practice set.",
          style: GoogleFonts.outfit(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              "CANCEL",
              style: GoogleFonts.outfit(
                color: const Color(0xFF697386),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await Supabase.instance.client
                  .from('interview_questions')
                  .delete()
                  .eq('id', q.id);
              ref.invalidate(interviewQuestionsProvider(_selectedCategoryId!));
            },
            child: Text(
              "DELETE",
              style: GoogleFonts.outfit(
                color: const Color(0xFFE04F5F),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddQuestionSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddQuestionSheet(categoryId: _selectedCategoryId!),
    ).then((val) {
      if (val == true) {
        ref.invalidate(interviewQuestionsProvider(_selectedCategoryId!));
      }
    });
  }
}

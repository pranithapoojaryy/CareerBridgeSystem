import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'interview_providers.dart';
import '../domain/interview_models.dart';
import 'video_practice_screen.dart';
import 'coding_practice_screen.dart';
import 'widgets/shared_widgets.dart';
import 'widgets/practice_tips_widget.dart';

class QuestionBankScreen extends ConsumerStatefulWidget {
  const QuestionBankScreen({super.key});

  @override
  ConsumerState<QuestionBankScreen> createState() => _QuestionBankScreenState();
}

class _QuestionBankScreenState extends ConsumerState<QuestionBankScreen>
    with SingleTickerProviderStateMixin {
  TabController? _tabController;
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(interviewCategoriesProvider);
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width >= 1024;
    final isTablet = size.width >= 600 && size.width < 1024;
    final isMobile = size.width < 600;

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: categoriesAsync.when(
        data: (rawCategories) {
          if (rawCategories.isEmpty) {
            return const EmptyState(
              title: 'No Categories Available',
              message: 'Practice categories will appear here',
              icon: Icons.category_outlined,
            );
          }

          final uniqueCategories = <String, InterviewCategory>{};
          for (var c in rawCategories) {
            String key = c.name;
            if (key == 'Technical (Java)') key = 'Technical';
            if (!uniqueCategories.containsKey(key)) {
              uniqueCategories[key] = c;
            }
          }

          final categories = uniqueCategories.values.toList();

          if (_tabController == null ||
              _tabController!.length != categories.length) {
            _tabController = TabController(
              length: categories.length,
              vsync: this,
            );
          }

          return Column(
            children: [
              _buildHeader(categories, isDesktop, isTablet, isMobile),
              Expanded(
                child: isDesktop
                    ? Row(
                        children: [
                          // Main content area
                          Expanded(
                            flex: 7,
                            child: TabBarView(
                              controller: _tabController,
                              children: categories
                                  .map(
                                    (c) => _QuestionList(
                                      category: c,
                                      searchQuery: _searchQuery,
                                    ),
                                  )
                                  .toList(),
                            ),
                          ),
                          // Sidebar
                          Container(
                            width: 320,
                            margin: const EdgeInsets.only(
                              top: 16,
                              right: 16,
                              bottom: 16,
                            ),
                            child: const PracticeTipsWidget(),
                          ),
                        ],
                      )
                    : TabBarView(
                        controller: _tabController,
                        children: categories
                            .map(
                              (c) => _QuestionList(
                                category: c,
                                searchQuery: _searchQuery,
                              ),
                            )
                            .toList(),
                      ),
              ),
            ],
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation(Color(0xFF8B5CF6)),
          ),
        ),
        error: (e, s) => EmptyState(
          title: 'Error Loading Categories',
          message: e.toString(),
          icon: Icons.error_outline,
        ),
      ),
    );
  }

  Widget _buildHeader(
    List<InterviewCategory> categories,
    bool isDesktop,
    bool isTablet,
    bool isMobile,
  ) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF8B5CF6), Color(0xFF6D28D9)],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF8B5CF6).withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Top Bar with Back Button and Title
            Padding(
              padding: EdgeInsets.all(isMobile ? 16 : 20),
              child: Row(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: IconButton(
                      icon: const Icon(
                        Icons.arrow_back_ios_new,
                        color: Colors.white,
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Practice Questions',
                          style: GoogleFonts.poppins(
                            fontSize: isMobile ? 20 : 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          'Choose a category to start practicing',
                          style: GoogleFonts.poppins(
                            fontSize: isMobile ? 12 : 14,
                            color: Colors.white.withValues(alpha: 0.9),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Search Bar
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: isMobile ? 16 : 20,
                vertical: 8,
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: TextField(
                  onChanged: (value) {
                    setState(() => _searchQuery = value.toLowerCase());
                  },
                  decoration: InputDecoration(
                    hintText: 'Search questions...',
                    hintStyle: GoogleFonts.poppins(
                      color: const Color(0xFF9CA3AF),
                      fontSize: 14,
                    ),
                    prefixIcon: const Icon(
                      Icons.search,
                      color: Color(0xFF8B5CF6),
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                  ),
                  style: GoogleFonts.poppins(fontSize: 14),
                ),
              ),
            ),

            // Category Tabs
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: TabBar(
                controller: _tabController,
                isScrollable: true,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white.withValues(alpha: 0.6),
                labelStyle: GoogleFonts.poppins(
                  fontSize: isMobile ? 13 : 14,
                  fontWeight: FontWeight.w600,
                ),
                unselectedLabelStyle: GoogleFonts.poppins(
                  fontSize: isMobile ? 13 : 14,
                ),
                indicator: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                indicatorPadding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                tabs: categories.map((c) {
                  String label = c.name;
                  if (label == 'Technical (Java)') label = 'Technical';
                  return Tab(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(_getCategoryIcon(label), size: 18),
                          const SizedBox(width: 8),
                          Text(label),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'technical':
        return Icons.code;
      case 'hr interview':
        return Icons.people;
      case 'behavioral':
        return Icons.psychology;
      case 'group discussion':
        return Icons.groups;
      default:
        return Icons.quiz;
    }
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }
}

class _QuestionList extends ConsumerWidget {
  final InterviewCategory category;
  final String searchQuery;

  const _QuestionList({required this.category, required this.searchQuery});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final questionsAsync = ref.watch(interviewQuestionsProvider(category.id));
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width >= 1024;
    final isTablet = size.width >= 600 && size.width < 1024;
    final isMobile = size.width < 600;

    return questionsAsync.when(
      data: (questions) {
        if (questions.isEmpty) {
          return const EmptyState(
            title: 'No Questions Yet',
            message: 'Questions will appear here once added',
            icon: Icons.quiz_outlined,
          );
        }

        // Filter questions based on search
        final filteredQuestions = searchQuery.isEmpty
            ? questions
            : questions
                  .where(
                    (q) =>
                        q.questionText.toLowerCase().contains(searchQuery) ||
                        q.difficulty.toLowerCase().contains(searchQuery) ||
                        q.questionType.toLowerCase().contains(searchQuery),
                  )
                  .toList();

        if (filteredQuestions.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.search_off, size: 64, color: Colors.grey.shade300),
                const SizedBox(height: 16),
                Text(
                  'No questions found',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          );
        }

        // Grid for desktop, List for mobile/tablet
        if (isDesktop) {
          return GridView.builder(
            padding: const EdgeInsets.all(24),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 20,
              mainAxisSpacing: 20,
              childAspectRatio: 3,
            ),
            itemCount: filteredQuestions.length,
            itemBuilder: (context, index) {
              return _buildQuestionCard(
                context,
                filteredQuestions[index],
                index,
                isDesktop: true,
              );
            },
          );
        } else {
          return ListView.builder(
            padding: EdgeInsets.all(isMobile ? 16 : 20),
            itemCount: filteredQuestions.length,
            itemBuilder: (context, index) {
              return _buildQuestionCard(
                context,
                filteredQuestions[index],
                index,
                isDesktop: false,
              );
            },
          );
        }
      },
      loading: () => const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation(Color(0xFF8B5CF6)),
        ),
      ),
      error: (e, s) => EmptyState(
        title: 'Error Loading Questions',
        message: e.toString(),
        icon: Icons.error_outline,
      ),
    );
  }

  Widget _buildQuestionCard(
    BuildContext context,
    InterviewQuestion question,
    int index, {
    required bool isDesktop,
  }) {
    final colors = [
      const Color(0xFF8B5CF6),
      const Color(0xFF3B82F6),
      const Color(0xFF10B981),
      const Color(0xFFF59E0B),
    ];
    final color = colors[index % colors.length];

    final difficultyColor = question.difficulty == 'easy'
        ? const Color(0xFF10B981)
        : question.difficulty == 'medium'
        ? const Color(0xFFF59E0B)
        : const Color(0xFFEF4444);

    return Card(
      margin: EdgeInsets.only(bottom: isDesktop ? 0 : 16),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: color.withValues(alpha: 0.2), width: 2),
      ),
      child: InkWell(
        onTap: () {
          if (question.questionType == 'coding') {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => CodingPracticeScreen(question: question),
              ),
            );
          } else {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => VideoPracticeScreen(
                  question: question,
                  categoryName: category.name,
                ),
              ),
            );
          }
        },
        borderRadius: BorderRadius.circular(20),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [color.withValues(alpha: 0.05), Colors.white],
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          padding: EdgeInsets.all(isDesktop ? 20 : 16),
          child: Row(
            children: [
              // Number Badge
              Container(
                width: isDesktop ? 64 : 56,
                height: isDesktop ? 64 : 56,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [color, color.withValues(alpha: 0.7)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    '${index + 1}',
                    style: GoogleFonts.poppins(
                      fontSize: isDesktop ? 24 : 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),

              // Question Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Tags Row
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _buildTag(
                          label: question.difficulty.toUpperCase(),
                          color: difficultyColor,
                          icon: Icons.flag,
                        ),
                        _buildTag(
                          label: question.questionType == 'coding'
                              ? 'CODING'
                              : 'VIDEO',
                          color: color,
                          icon: question.questionType == 'coding'
                              ? Icons.code
                              : Icons.videocam,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Question Text
                    Text(
                      question.questionText,
                      style: GoogleFonts.poppins(
                        fontSize: isDesktop ? 15 : 14,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF1F2937),
                        height: 1.4,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 12),

              // Arrow Icon
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.arrow_forward_ios, size: 16, color: color),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTag({
    required String label,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: color,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/college_providers.dart';
import 'widgets/assessment_card.dart';
import 'widgets/assessment_stats_panel.dart';
import 'create_assessment_screen.dart';
import 'assessment_questions_screen.dart';
import 'assessment_details_screen.dart';
import 'question_bank_screen.dart';

class SkillAssessmentsScreen extends ConsumerStatefulWidget {
  const SkillAssessmentsScreen({super.key});

  @override
  ConsumerState<SkillAssessmentsScreen> createState() =>
      _SkillAssessmentsScreenState();
}

class _SkillAssessmentsScreenState extends ConsumerState<SkillAssessmentsScreen> {

  bool _isLoading = true;
  List<Map<String, dynamic>> _allAssessments = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchAssessments();
  }

  Future<void> _fetchAssessments() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final repository = ref.read(collegeRepositoryProvider);
      // Fetch ALL assessments once
      final assessments = await repository.getAssessments(isActive: true);

      if (mounted) {
        setState(() {
          _allAssessments = assessments;
          _isLoading = false;
        });
      }
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
      body: Column(
        children: [
          // Header Section
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Skill Assessments',
                          style: GoogleFonts.outfit(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Create, manage and track skill validation tests',
                          style: GoogleFonts.outfit(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        OutlinedButton.icon(
                          onPressed: () => _showQuestionBankDialog(),
                          icon: const Icon(Icons.quiz_rounded),
                          label: const Text('Question Bank'),
                        ),
                        const SizedBox(width: 16),
                        FilledButton.icon(
                          onPressed: () => _showCreateAssessmentDialog(),
                          icon: const Icon(Icons.add_rounded),
                          label: const Text('Create Assessment'),
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Stats Panel
                const AssessmentStatsPanel(),

                const SizedBox(height: 24),
              ],
            ),
          ),

          // Content Area
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 64,
                          color: Colors.red[300],
                        ),
                        const SizedBox(height: 16),
                        Text('Error loading assessments: $_error'),
                        const SizedBox(height: 16),
                        FilledButton(
                          onPressed: _fetchAssessments,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  )
                : _buildAssessmentsGrid(),
          ),
        ],
      ),
    );
  }

  Widget _buildAssessmentsGrid() {
    if (_allAssessments.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.assignment_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No assessments found',
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Create your first assessment to get started',
              style: GoogleFonts.outfit(fontSize: 14, color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(24),
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 24,
          mainAxisSpacing: 24,
          childAspectRatio: 1.3,
        ),
        itemCount: _allAssessments.length,
        itemBuilder: (context, index) {
          final assessment = _allAssessments[index];
          return AssessmentCard(
            assessment: assessment,
            onTap: () => _viewAssessmentDetails(assessment),
            onViewQuestions: () => _viewAssessmentQuestions(assessment),
            onEdit: () => _editAssessment(assessment),
            onDelete: () => _deleteAssessment(assessment),
          );
        },
      ),
    );
  }

  Future<void> _showCreateAssessmentDialog() async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const CreateAssessmentScreen(),
    );
    // Refresh list and stats
    if (mounted) {
      await _fetchAssessments(); // Refresh local list
      ref.invalidate(assessmentStatsProvider); // Refresh stats panel
    }
  }

  Future<void> _showQuestionBankDialog() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const QuestionBankScreen()),
    );
    // Refresh list in case changes were made in Question Bank
    await _fetchAssessments();
    ref.invalidate(assessmentStatsProvider);
  }

  void _viewAssessmentDetails(Map<String, dynamic> assessment) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AssessmentDetailsScreen(assessment: assessment),
    );
    if (mounted) {
      await _fetchAssessments();
      ref.invalidate(assessmentStatsProvider);
    }
  }

  void _viewAssessmentQuestions(Map<String, dynamic> assessment) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AssessmentQuestionsScreen(assessment: assessment),
      ),
    );
  }

  void _editAssessment(Map<String, dynamic> assessment) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CreateAssessmentScreen(assessment: assessment),
    );
    if (mounted) {
      await _fetchAssessments();
      ref.invalidate(assessmentStatsProvider);
    }
  }

  void _deleteAssessment(Map<String, dynamic> assessment) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Assessment'),
        content: Text(
          'Are you sure you want to delete "${assessment['title']}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              final scaffoldMessenger = ScaffoldMessenger.of(context);
              Navigator.pop(context);

              // Optimistically remove from list
              final previousList = List<Map<String, dynamic>>.from(
                _allAssessments,
              );
              setState(() {
                _allAssessments.removeWhere((a) => a['id'] == assessment['id']);
              });

              try {
                await ref
                    .read(collegeRepositoryProvider)
                    .deleteAssessment(assessment['id']);

                if (mounted) {
                  scaffoldMessenger.showSnackBar(
                    SnackBar(content: Text('${assessment['title']} deleted')),
                  );
                  // Refresh from server to be sure, but UI is already updated
                  await _fetchAssessments();
                  ref.invalidate(assessmentStatsProvider);
                }
              } catch (e) {
                // Revert optimistic update on error
                if (mounted) {
                  setState(() {
                    _allAssessments = previousList;
                  });
                  scaffoldMessenger.showSnackBar(
                    SnackBar(content: Text('Error deleting assessment: $e')),
                  );
                }
              }
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../data/college_providers.dart';
import '../../../../features/aptitude/domain/test_assignment.dart';
import 'create_assessment_screen.dart';
import 'assessment_questions_screen.dart';

class QuestionBankScreen extends ConsumerStatefulWidget {
  const QuestionBankScreen({super.key});

  @override
  ConsumerState<QuestionBankScreen> createState() => _QuestionBankScreenState();
}

class _QuestionBankScreenState extends ConsumerState<QuestionBankScreen> {
  bool _isLoading = true;
  List<TestAssignment> _assessments = [];

  @override
  void initState() {
    super.initState();
    _fetchAssessments();
  }

  Future<void> _fetchAssessments() async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) return;

      // Fetch ALL assignments created by this user/org (simplified for now)
      // In a real scenario, we might want to fetch from 'aptitude_tests' directly
      // but 'test_assignments' gives us the deployment status.
      // Let's fetch 'aptitude_tests' created by this user.

      final response = await Supabase.instance.client
          .from('aptitude_tests')
          .select()
          .eq('created_by', userId)
          .order('created_at', ascending: false);

      setState(() {
        _assessments = (response as List)
            .map(
              (e) => TestAssignment.fromJson({
                'id': 'placeholder',
                'test_id': e['id'],
                'test_title': e['title'],
                'test_description': e['description'],
                'duration_minutes': e['duration_minutes'],
                'total_questions': e['total_questions'],
                'created_at': e['created_at'],
                'is_active': e['is_active'],
                // Dummy values for required fields not present in aptitude_tests
                'assigned_by': 'self',
                'assigned_by_role': 'college_admin',
                'organization_id': 'self',
                'assignment_type': 'draft',
                'start_date': DateTime.now().toIso8601String(),
              }),
            )
            .toList();
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading assessments: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Padding(
        padding: const EdgeInsets.all(32),
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
                      'Assessment Bank',
                      style: GoogleFonts.outfit(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    Text(
                      'Manage and create aptitude tests for your students',
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                FilledButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const CreateAssessmentScreen(),
                      ),
                    ).then((_) => _fetchAssessments()); // Refresh on return
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Create Assessment'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 16,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else if (_assessments.isEmpty)
              _buildEmptyState()
            else
              Expanded(
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    childAspectRatio: 1.5,
                    crossAxisSpacing: 24,
                    mainAxisSpacing: 24,
                  ),
                  itemCount: _assessments.length,
                  itemBuilder: (context, index) {
                    return _buildAssessmentCard(_assessments[index]);
                  },
                ),
              ),
          ],
        ),
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
              color: Colors.grey[100],
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.quiz_outlined, size: 48, color: Colors.grey[400]),
          ),
          const SizedBox(height: 16),
          Text(
            'No Assessments Created Yet',
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Create your first aptitude test to assess student skills.',
            style: GoogleFonts.outfit(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildAssessmentCard(TestAssignment test) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: AppTheme.clayDecoration.copyWith(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Active',
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, size: 20),
                onSelected: (value) {
                  // Reconstruct map for navigation since screens expect Map<String, dynamic>
                  // This is a bit of a hack since QuestionBank uses TestAssignment objects
                  final assessmentMap = {
                    'id': test.testId,
                    'title': test.testTitle,
                    'description': test.testDescription,
                    'duration_minutes': test.durationMinutes,
                    'passing_score':
                        0, // Fallback as getter might be missing in TestAssignment model
                    'is_active': test.isActive,
                  };

                  if (value == 'view_questions') {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AssessmentQuestionsScreen(
                          assessment: assessmentMap,
                        ),
                      ),
                    );
                  } else if (value == 'edit') {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            CreateAssessmentScreen(assessment: assessmentMap),
                      ),
                    ).then((_) => _fetchAssessments());
                  } else if (value == 'delete') {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Delete Assessment'),
                        content: Text(
                          'Are you sure you want to delete "${test.testTitle}"?',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Cancel'),
                          ),
                          FilledButton(
                            onPressed: () async {
                              final scaffoldMessenger = ScaffoldMessenger.of(
                                context,
                              );
                              Navigator.pop(context);

                              // Optimistically remove
                              final previousList = List<TestAssignment>.from(
                                _assessments,
                              );
                              setState(() {
                                _assessments.removeWhere(
                                  (a) => a.testId == test.testId,
                                );
                              });

                              try {
                                await ref
                                    .read(collegeRepositoryProvider)
                                    .deleteAssessment(test.testId);
                                if (mounted) {
                                  scaffoldMessenger.showSnackBar(
                                    const SnackBar(
                                      content: Text('Assessment deleted'),
                                    ),
                                  );
                                  // No need to fetch if successful, but can do silently
                                  _fetchAssessments();
                                }
                              } catch (e) {
                                // Revert
                                if (mounted) {
                                  setState(() {
                                    _assessments = previousList;
                                  });
                                  scaffoldMessenger.showSnackBar(
                                    SnackBar(content: Text('Error: $e')),
                                  );
                                }
                              }
                            },
                            style: FilledButton.styleFrom(
                              backgroundColor: Colors.red,
                            ),
                            child: const Text('Delete'),
                          ),
                        ],
                      ),
                    );
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'view_questions',
                    child: Row(
                      children: [
                        Icon(Icons.quiz_outlined, size: 20),
                        SizedBox(width: 8),
                        Text('View Questions'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit_outlined, size: 20),
                        SizedBox(width: 8),
                        Text('Edit'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete_outline, color: Colors.red, size: 20),
                        SizedBox(width: 8),
                        Text('Delete', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            test.testTitle ?? 'Untitled',
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.textColor,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          Text(
            test.testDescription ?? 'No description provided',
            style: GoogleFonts.outfit(fontSize: 14, color: Colors.grey[600]),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const Spacer(),
          Row(
            children: [
              Icon(Icons.timer_outlined, size: 16, color: Colors.grey[500]),
              const SizedBox(width: 4),
              Text(
                '${test.durationMinutes ?? 0} mins',
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(width: 16),
              Icon(
                Icons.format_list_numbered,
                size: 16,
                color: Colors.grey[500],
              ),
              const SizedBox(width: 4),
              Text(
                '${test.totalQuestions ?? 0} Qs',
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

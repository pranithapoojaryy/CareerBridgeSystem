import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../features/aptitude/domain/test_assignment.dart'; // Reusing domain model
import 'create_challenge_screen.dart';

class RecruiterAssessmentsScreen extends StatefulWidget {
  const RecruiterAssessmentsScreen({super.key});

  @override
  State<RecruiterAssessmentsScreen> createState() =>
      _RecruiterAssessmentsScreenState();
}

class _RecruiterAssessmentsScreenState
    extends State<RecruiterAssessmentsScreen> {
  bool _isLoading = true;
  List<TestAssignment> _challenges = [];

  @override
  void initState() {
    super.initState();
    _fetchChallenges();
  }

  Future<void> _fetchChallenges() async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) return;

      // Fetch aptitude tests created by this recruiter
      final response = await Supabase.instance.client
          .from('aptitude_tests')
          .select()
          .eq('created_by', userId)
          .order('created_at', ascending: false);

      if (mounted) {
        setState(() {
          _challenges = (response as List)
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
                }),
              )
              .toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading challenges: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
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
                    'Technical Challenges',
                    style: GoogleFonts.outfit(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  Text(
                    'Create and manage assessment challenges for candidates',
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
                      builder: (_) => const CreateChallengeScreen(),
                    ),
                  ).then((_) => _fetchChallenges());
                },
                icon: const Icon(Icons.add),
                label: const Text('Create Challenge'),
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.black87,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          if (_isLoading)
            const Center(child: CircularProgressIndicator())
          else if (_challenges.isEmpty)
            _buildEmptyState()
          else
            Expanded(
              child: ListView.separated(
                itemCount: _challenges.length,
                separatorBuilder: (_, __) => const SizedBox(height: 16),
                itemBuilder: (context, index) {
                  return _buildChallengeCard(_challenges[index]);
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.code_off, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            'No Challenges Created',
            style: GoogleFonts.outfit(fontSize: 18, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            'Create your first technical challenge to screen candidates.',
            style: GoogleFonts.outfit(color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildChallengeCard(TestAssignment test) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.code, color: Colors.orange),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  test.testTitle ?? 'Untitled Challenge',
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  test.testDescription ?? '',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.outfit(
                    color: Colors.grey[600],
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                children: [
                  Icon(Icons.timer_outlined, size: 14, color: Colors.grey[500]),
                  const SizedBox(width: 4),
                  Text(
                    '${test.durationMinutes}m',
                    style: GoogleFonts.outfit(
                      color: Colors.grey[600],
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Icon(Icons.list_alt, size: 14, color: Colors.grey[500]),
                  const SizedBox(width: 4),
                  Text(
                    '${test.totalQuestions}Q',
                    style: GoogleFonts.outfit(
                      color: Colors.grey[600],
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Active',
                style: GoogleFonts.outfit(
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

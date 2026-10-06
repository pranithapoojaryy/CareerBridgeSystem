import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/test_assignment.dart';
import '../controllers/aptitude_controller.dart';
import '../utils/aptitude_utils.dart';

class AssignmentsListScreen extends ConsumerWidget {
  const AssignmentsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final assignmentsAsync = ref.watch(myAssignmentsProvider);

    return Scaffold(
      backgroundColor: Colors.grey[50], // Consistent background
      appBar: AppBar(
        title: Text(
          'My Assignments',
          style: GoogleFonts.outfit(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: assignmentsAsync.when(
        data: (assignments) {
          if (assignments.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.assignment_outlined,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No assignments yet',
                    style: GoogleFonts.outfit(
                      fontSize: 18,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            );
          }

          // Sort: Pending first, then by deadline
          final sortedAssignments = List<TestAssignment>.from(assignments);
          sortedAssignments.sort((a, b) {
            if (a.isCompleted && !b.isCompleted) return 1;
            if (!a.isCompleted && b.isCompleted) return -1;
            if (a.deadline != null && b.deadline != null) {
              return a.deadline!.compareTo(b.deadline!);
            }
            return 0;
          });

          return ListView.separated(
            padding: const EdgeInsets.all(24),
            itemCount: sortedAssignments.length,
            separatorBuilder: (_, __) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              final assignment = sortedAssignments[index];
              return _buildAssignmentCard(context, ref, assignment)
                  .animate()
                  .fadeIn(delay: (index * 50).ms)
                  .slideY(begin: 0.1, end: 0);
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }

  Widget _buildAssignmentCard(
    BuildContext context,
    WidgetRef ref,
    TestAssignment assignment,
  ) {
    final isExpired = assignment.isExpired;
    final isCompleted = assignment.isCompleted;

    return Container(
      decoration: AppTheme.clayDecoration.copyWith(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: isExpired
            ? Border.all(color: Colors.grey[300]!)
            : Border.all(color: Colors.transparent),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Badge
              if (isCompleted)
                _buildBadge('Completed', Colors.green)
              else if (isExpired)
                _buildBadge('Expired', Colors.grey)
              else if (assignment.isMandatory)
                _buildBadge('Mandatory', Colors.orange)
              else
                _buildBadge('Assigned', Colors.blue),

              // Deadline
              if (assignment.deadline != null)
                Text(
                  'Due ${assignment.deadline!.day}/${assignment.deadline!.month}',
                  style: GoogleFonts.outfit(
                    color: isExpired ? Colors.grey : Colors.red,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            assignment.testTitle ?? 'Untitled Assignment',
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isExpired ? Colors.grey[600] : AppTheme.textColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Assigned by: ${assignment.assignedByRole}', // Could map to cleaner text
            style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey[500]),
          ),
          const SizedBox(height: 16),
          // Action Button
          SizedBox(
            width: double.infinity,
            child: isCompleted
                ? OutlinedButton(
                    onPressed: () {
                      // Navigate to results (todo)
                    },
                    child: const Text('View Results'),
                  )
                : ElevatedButton(
                    onPressed: isExpired
                        ? null
                        : () {
                            startAssignmentTest(
                              context,
                              ref,
                              assignment.id,
                              assignment.testId,
                            );
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          AppTheme.primaryColor, // Replaced primary
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Start Test'),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: GoogleFonts.outfit(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

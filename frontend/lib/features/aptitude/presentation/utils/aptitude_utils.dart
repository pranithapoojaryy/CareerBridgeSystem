import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../screens/test_taking_screen.dart';
import '../../data/aptitude_repository.dart';
import '../../domain/test_attempt.dart';
import '../controllers/aptitude_controller.dart'; // Needed for aptitudeRepositoryProvider

// Helper function to start an assignment test
Future<void> startAssignmentTest(
  BuildContext context,
  WidgetRef ref,
  String assignmentId,
  String testId,
) async {
  try {
    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    // Call repository to start test
    final result = await ref
        .read(aptitudeRepositoryProvider)
        .startTest(testId: testId, testType: 'assignment');

    if (context.mounted) {
      Navigator.pop(context); // Dismiss loading dialog

      final attempt = result['attempt'] as TestAttempt;
      final settings = result['settings'] as Map<String, dynamic>;

      // Navigate to test taking screen
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) =>
              TestTakingScreen(attempt: attempt, settings: settings),
        ),
      );
    }
  } catch (e) {
    if (context.mounted) {
      Navigator.pop(context); // Dismiss loading dialog
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to start test: $e')));
    }
  }
}

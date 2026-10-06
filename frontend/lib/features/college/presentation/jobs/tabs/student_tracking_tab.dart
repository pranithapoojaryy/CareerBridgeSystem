import 'package:flutter/material.dart';
import '../../placement/student_placement_tracking_screen.dart';

/// Student Tracking Tab - Wraps the existing student placement tracking screen
class StudentTrackingTab extends StatelessWidget {
  const StudentTrackingTab({super.key});

  @override
  Widget build(BuildContext context) {
    // Reuse the existing StudentPlacementTrackingScreen content
    // but without the Scaffold (since we're inside a tab)
    return const StudentPlacementTrackingScreen(embedded: true);
  }
}

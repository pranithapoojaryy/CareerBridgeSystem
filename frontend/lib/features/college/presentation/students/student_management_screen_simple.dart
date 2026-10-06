import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'widgets/invite_students_dialog.dart';

// Simple mock data provider
final studentsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  // Mock data for demonstration
  return [
    {
      'id': '1',
      'full_name': 'Arjun Sharma',
      'email': 'arjun.sharma@college.edu',
      'usn': 'CS21001',
      'department': 'Computer Science',
      'batch': '2021-2025',
      'cgpa': 8.5,
      'placement_status': 'placed',
      'company': 'Google',
    },
    {
      'id': '2',
      'full_name': 'Priya Patel',
      'email': 'priya.patel@college.edu',
      'usn': 'CS21002',
      'department': 'Computer Science',
      'batch': '2021-2025',
      'cgpa': 9.2,
      'placement_status': 'interviewing',
      'company': null,
    },
    {
      'id': '3',
      'full_name': 'Rahul Kumar',
      'email': 'rahul.kumar@college.edu',
      'usn': 'CS21003',
      'department': 'Computer Science',
      'batch': '2021-2025',
      'cgpa': 7.8,
      'placement_status': 'seeking',
      'company': null,
    },
  ];
});

class StudentManagementScreen extends ConsumerWidget {
  const StudentManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final studentsAsync = ref.watch(studentsProvider);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          'Student Management',
          style: GoogleFonts.outfit(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: FilledButton.icon(
              onPressed: () => _showInviteStudentsDialog(context),
              icon: const Icon(Icons.person_add_rounded),
              label: const Text('Invite Students'),
            ),
          ),
        ],
      ),
      body: studentsAsync.when(
        data: (students) => _buildStudentsList(students),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text('Error: $error'),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => ref.invalidate(studentsProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStudentsList(List<Map<String, dynamic>> students) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Stats Cards
          Row(
            children: [
              _buildStatCard('Total Students', students.length.toString(), Colors.blue),
              const SizedBox(width: 16),
              _buildStatCard(
                'Placed', 
                students.where((s) => s['placement_status'] == 'placed').length.toString(), 
                Colors.green
              ),
              const SizedBox(width: 16),
              _buildStatCard(
                'Seeking', 
                students.where((s) => s['placement_status'] == 'seeking').length.toString(), 
                Colors.orange
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          // Students List
          Text(
            'Students',
            style: GoogleFonts.outfit(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          Expanded(
            child: ListView.builder(
              itemCount: students.length,
              itemBuilder: (context, index) {
                final student = students[index];
                return _buildStudentCard(student);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
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
            Text(
              title,
              style: GoogleFonts.outfit(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: GoogleFonts.outfit(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStudentCard(Map<String, dynamic> student) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Avatar
          CircleAvatar(
            radius: 24,
            backgroundColor: Colors.blue[100],
            child: Text(
              student['full_name'][0].toUpperCase(),
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.blue[700],
              ),
            ),
          ),
          const SizedBox(width: 16),
          
          // Student Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  student['full_name'],
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${student['usn']} • ${student['department']}',
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  student['email'],
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          ),
          
          // Status & CGPA
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getStatusColor(student['placement_status']),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  student['placement_status'].toString().toUpperCase(),
                  style: GoogleFonts.outfit(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'CGPA: ${student['cgpa']}',
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                ),
              ),
              if (student['company'] != null) ...[
                const SizedBox(height: 4),
                Text(
                  student['company'],
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    color: Colors.green[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'placed':
        return Colors.green;
      case 'interviewing':
        return Colors.blue;
      case 'seeking':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  void _showInviteStudentsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const InviteStudentsDialog(),
    );
  }
}

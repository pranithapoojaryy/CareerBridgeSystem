import 'package:supabase_flutter/supabase_flutter.dart';

class StudentRepository {
  final SupabaseClient _supabase;

  StudentRepository(this._supabase);

  // Fetch students for a specific college
  Future<List<Map<String, dynamic>>> fetchStudents(String collegeId) async {
    try {
      // TODO: Replace with actual RPC or select query when data is linked
      // final response = await _supabase
      //     .from('student_profiles')
      //     .select('*, profiles(full_name, email)')
      //     .eq('college_id', collegeId);

      // For now, return Mock Data to unblock UI development
      await Future.delayed(
        const Duration(milliseconds: 800),
      ); // Simulate network
      return _generateMockStudents();
    } catch (e) {
      throw Exception('Failed to fetch students: $e');
    }
  }

  Future<void> verifyStudent(String studentId) async {
    // TODO: Implement actual update
    // await _supabase.from('student_profiles').update({'is_verified': true}).eq('id', studentId);
  }

  Future<void> rejectStudent(String studentId) async {
    // TODO: Implement actual update
    // await _supabase.from('student_profiles').update({'college_id': null}).eq('id', studentId);
  }

  List<Map<String, dynamic>> _generateMockStudents() {
    return [
      {
        'id': '1',
        'full_name': 'Aarav Patel',
        'email': 'aarav.p@example.com',
        'department': 'Computer Science',
        'batch': '2024',
        'cgpa': 9.2,
        'status': 'verified',
        'skills': ['Flutter', 'Node.js', 'Python'],
      },
      {
        'id': '2',
        'full_name': 'Sneha Reddy',
        'email': 'sneha.r@example.com',
        'department': 'Information Science',
        'batch': '2024',
        'cgpa': 8.5,
        'status': 'pending',
        'skills': ['Java', 'SQL', 'React'],
      },
      {
        'id': '3',
        'full_name': 'Rohan Sharma',
        'email': 'rohan.s@example.com',
        'department': 'Electronics',
        'batch': '2025',
        'cgpa': 7.8,
        'status': 'pending',
        'skills': ['Embedded C', 'IoT'],
      },
      {
        'id': '4',
        'full_name': 'Meera Iyer',
        'email': 'meera.i@example.com',
        'department': 'Computer Science',
        'batch': '2024',
        'cgpa': 9.5,
        'status': 'verified',
        'skills': ['AI/ML', 'Python', 'TensorFlow'],
      },
      {
        'id': '5',
        'full_name': 'Karthik N',
        'email': 'karthik.n@example.com',
        'department': 'Mechanical',
        'batch': '2024',
        'cgpa': 8.1,
        'status': 'verified',
        'skills': ['AutoCAD', 'SolidWorks'],
      },
    ];
  }
}

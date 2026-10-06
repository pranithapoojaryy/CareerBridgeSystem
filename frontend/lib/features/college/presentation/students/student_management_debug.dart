import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../data/college_repository.dart';
import '../../../../../core/utils/logger_service.dart';

class StudentManagementDebug extends ConsumerStatefulWidget {
  const StudentManagementDebug({super.key});

  @override
  ConsumerState<StudentManagementDebug> createState() =>
      _StudentManagementDebugState();
}

class _StudentManagementDebugState extends ConsumerState<StudentManagementDebug> {
  List<Map<String, dynamic>> _students = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadStudents();
  }

  Future<void> _loadStudents() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        setState(() {
          _error = 'No authenticated user';
          _isLoading = false;
        });
        return;
      }

      // Get college info first
      final repository = CollegeRepository(Supabase.instance.client);
      final college = await repository.getOrganizationByUserId(user.id);
      
      if (college == null) {
        setState(() {
          _error = 'No college found for user';
          _isLoading = false;
        });
        return;
      }

      LoggerService.debug('College ID: ${college['id']}');

      // Get students directly
      final students = await repository.getStudents(collegeId: college['id']);
      
      LoggerService.debug('Found ${students.length} students');
      
      setState(() {
        _students = students;
        _isLoading = false;
      });
    } catch (e) {
      LoggerService.error('Error loading students', e);
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Student Management Debug'),
        actions: [
          IconButton(
            onPressed: _loadStudents,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Debug Information',
              style: GoogleFonts.outfit(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            if (_isLoading)
              const Center(
                child: Column(
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Loading students...'),
                  ],
                ),
              )
            else if (_error != null)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Error:',
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.bold,
                        color: Colors.red[700],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(_error!),
                  ],
                ),
              )
            else
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.green[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.green[200]!),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Success!',
                            style: GoogleFonts.outfit(
                              fontWeight: FontWeight.bold,
                              color: Colors.green[700],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text('Found ${_students.length} students'),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    Text(
                      'Students:',
                      style: GoogleFonts.outfit(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    Expanded(
                      child: _students.isEmpty
                          ? const Center(
                              child: Text('No students found'),
                            )
                          : ListView.builder(
                              itemCount: _students.length,
                              itemBuilder: (context, index) {
                                final student = _students[index];
                                return Card(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  child: ListTile(
                                    leading: CircleAvatar(
                                      child: Text(
                                        (student['full_name'] ?? 'U')[0].toUpperCase(),
                                      ),
                                    ),
                                    title: Text(student['full_name'] ?? 'Unknown'),
                                    subtitle: Text(student['email'] ?? 'No email'),
                                    trailing: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          'ID: ${student['id'].toString().substring(0, 8)}...',
                                          style: const TextStyle(fontSize: 12),
                                        ),
                                        Text(
                                          'Org: ${student['organization_id'].toString().substring(0, 8)}...',
                                          style: const TextStyle(fontSize: 12),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
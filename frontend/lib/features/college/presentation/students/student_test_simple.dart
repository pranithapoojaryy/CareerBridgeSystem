import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/college_providers.dart';

class StudentTestSimple extends ConsumerWidget {
  const StudentTestSimple({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final collegeAsync = ref.watch(currentCollegeProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Simple Student Test'),
        actions: [
          IconButton(
            onPressed: () {
              ref.invalidate(studentsProvider);
              ref.invalidate(currentCollegeProvider);
            },
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: collegeAsync.when(
          data: (college) {
            if (college == null) {
              return const Center(
                child: Text('No college found'),
              );
            }
            
            final studentsAsync = ref.watch(studentsProvider(college['id']));
            
            return studentsAsync.when(
              data: (students) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'SUCCESS: Found ${students.length} students',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: ListView.builder(
                        itemCount: students.length,
                        itemBuilder: (context, index) {
                          final student = students[index];
                          return Card(
                            child: ListTile(
                              title: Text(student['full_name'] ?? 'Unknown'),
                              subtitle: Text(student['email'] ?? 'No email'),
                              trailing: Text('ID: ${student['id'].toString().substring(0, 8)}...'),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
              loading: () => const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Loading...'),
                  ],
                ),
              ),
              error: (error, stack) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error, color: Colors.red, size: 48),
                    const SizedBox(height: 16),
                    Text('Error: $error'),
                  ],
                ),
              ),
            );
          },
          loading: () => const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Loading college...'),
              ],
            ),
          ),
          error: (error, stack) => Center(
            child: Text('College error: $error'),
          ),
        ),
      ),
    );
  }
}
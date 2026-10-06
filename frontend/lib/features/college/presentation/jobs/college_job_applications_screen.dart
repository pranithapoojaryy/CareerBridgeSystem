import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:timeago/timeago.dart' as timeago;

class CollegeJobApplicationsScreen extends ConsumerStatefulWidget {
  const CollegeJobApplicationsScreen({super.key});

  @override
  ConsumerState<CollegeJobApplicationsScreen> createState() =>
      _CollegeJobApplicationsScreenState();
}

class _CollegeJobApplicationsScreenState
    extends ConsumerState<CollegeJobApplicationsScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _applications = [];

  @override
  void initState() {
    super.initState();
    _fetchApplications();
  }

  Future<void> _fetchApplications() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      // 1. Get College Admin's Organization ID
      final profile = await Supabase.instance.client
          .from('profiles')
          .select('organization_id')
          .eq('id', user.id)
          .single();

      final orgId = profile['organization_id'];

      // 2. Fetch applications for students in this organization
      // Using the RLS policy or direct query if we have permissions
      // Since RLS was tricky, let's try a direct query with filters that mimics the logic

      final response = await Supabase.instance.client
          .from('job_applications')
          .select('''
            *,
            job:jobs(title, organization:organizations(name, logo_url)),
            student:profiles!inner(full_name, avatar_url, organization_id)
          ''')
          .eq('student.organization_id', orgId)
          .order('applied_at', ascending: false);

      setState(() {
        _applications = List<Map<String, dynamic>>.from(response);
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Student Placements',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _applications.isEmpty
          ? Center(
              child: Text(
                'No applications found yet.',
                style: GoogleFonts.outfit(),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: _applications.length,
              separatorBuilder: (context, index) => const Divider(),
              itemBuilder: (context, index) {
                final app = _applications[index];
                final job = app['job'];
                final student = app['student'];

                return ListTile(
                  leading: CircleAvatar(
                    backgroundImage: student['avatar_url'] != null
                        ? NetworkImage(student['avatar_url'])
                        : null,
                    child: student['avatar_url'] == null
                        ? Text(student['full_name'][0])
                        : null,
                  ),
                  title: Text(
                    student['full_name'],
                    style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Applied for ${job['title']} at ${job['organization']['name']}',
                      ),
                      Text(
                        timeago.format(DateTime.parse(app['applied_at'])),
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                  trailing: _buildStatusChip(app['status']),
                );
              },
            ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color color = Colors.grey;
    if (status == 'hired') color = Colors.green;
    if (status == 'rejected') color = Colors.red;
    if (status == 'shortlisted') color = Colors.orange;

    return Chip(
      label: Text(
        status.toUpperCase(),
        style: GoogleFonts.outfit(
          fontSize: 10,
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
      backgroundColor: color,
      padding: EdgeInsets.zero,
    );
  }
}

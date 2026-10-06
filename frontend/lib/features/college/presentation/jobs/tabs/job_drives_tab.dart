import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../widgets/job_drive_card.dart';

/// Job Drives Tab - Shows active placement drives/job postings
class JobDrivesTab extends ConsumerStatefulWidget {
  const JobDrivesTab({super.key});

  @override
  ConsumerState<JobDrivesTab> createState() => _JobDrivesTabState();
}

class _JobDrivesTabState extends ConsumerState<JobDrivesTab> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _jobs = [];
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchJobs();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchJobs() async {
    try {
      // Fetch all open jobs posted by companies
      final jobsResponse = await Supabase.instance.client
          .from('jobs')
          .select('''
            *,
            organization:organizations(name, logo_url),
            applications:job_applications(count)
          ''')
          .eq('status', 'open')
          .order('created_at', ascending: false);

      setState(() {
        _jobs = List<Map<String, dynamic>>.from(jobsResponse);
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading jobs: $e')));
      }
    }
  }

  List<Map<String, dynamic>> get _filteredJobs {
    if (_searchQuery.isEmpty) return _jobs;

    return _jobs.where((job) {
      final title = job['title']?.toString().toLowerCase() ?? '';
      final company =
          job['organization']?['name']?.toString().toLowerCase() ?? '';
      final location = job['location']?.toString().toLowerCase() ?? '';
      final query = _searchQuery.toLowerCase();
      return title.contains(query) ||
          company.contains(query) ||
          location.contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        // Search Bar Section
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          color: Colors.white,
          child: TextField(
            controller: _searchController,
            onChanged: (value) => setState(() => _searchQuery = value),
            decoration: InputDecoration(
              hintText: 'Search job drives by title, company, or location...',
              hintStyle: GoogleFonts.outfit(
                color: Colors.grey[400],
                fontSize: 14,
              ),
              prefixIcon: const Icon(
                Icons.search,
                color: Colors.grey,
                size: 20,
              ),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _searchQuery = '');
                      },
                    )
                  : null,
              filled: true,
              fillColor: Colors.grey[50],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[200]!),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[200]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.orange, width: 1.5),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 16,
              ),
            ),
          ),
        ),

        // Jobs List/Grid View
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final jobs = _filteredJobs;

              if (jobs.isEmpty) {
                return _buildEmptyState();
              }

              if (constraints.maxWidth > 900) {
                return GridView.builder(
                  padding: const EdgeInsets.all(24),
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 400,
                    mainAxisExtent: 280,
                    crossAxisSpacing: 24,
                    mainAxisSpacing: 24,
                  ),
                  itemCount: jobs.length,
                  itemBuilder: (context, index) {
                    return JobDriveCard(job: jobs[index]);
                  },
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(24),
                itemCount: jobs.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 24),
                    child: SizedBox(
                      height: 280,
                      child: JobDriveCard(job: jobs[index]),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.work_off_rounded, size: 64, color: Colors.grey[200]),
          const SizedBox(height: 16),
          Text(
            _searchQuery.isEmpty
                ? 'No job drives available yet'
                : 'No matching jobs found',
            style: GoogleFonts.outfit(
              fontSize: 16,
              color: Colors.grey[400],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

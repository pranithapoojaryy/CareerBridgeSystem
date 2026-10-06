import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../networking/presentation/screens/network_profile_view.dart';

class StudentSearchScreen extends ConsumerStatefulWidget {
  final VoidCallback? onBackPressed;
  const StudentSearchScreen({super.key, this.onBackPressed});

  @override
  ConsumerState<StudentSearchScreen> createState() =>
      _StudentSearchScreenState();
}

class _StudentSearchScreenState extends ConsumerState<StudentSearchScreen> {
  final _searchController = TextEditingController();
  List<Map<String, dynamic>> _students = [];
  bool _isLoading = false;
  String _searchQuery = '';
  String _selectedCollege = 'All Colleges';
  List<String> _colleges = ['All Colleges'];

  @override
  void initState() {
    super.initState();
    _loadInitialStudents();
  }

  Future<void> _loadInitialStudents() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      // Initially load some students (limit raised to 100 for better stats)
      final response = await Supabase.instance.client
          .from('profiles')
          .select(
            'id, full_name, email, role, profile_photo_url, organization_id, organizations(name, logo_url)',
          )
          .eq('role', 'student')
          .limit(100);

      final studentsList = List<Map<String, dynamic>>.from(response);

      // Extract unique colleges
      final Set<String> collegeNames = {'All Colleges'};
      for (var s in studentsList) {
        final org = s['organizations'];
        if (org != null) {
          final name = org['name'] as String?;
          if (name != null && name.isNotEmpty) collegeNames.add(name);
        }
      }

      if (mounted) {
        setState(() {
          _students = studentsList;
          _colleges = collegeNames.toList()..sort();
          _colleges.remove('All Colleges');
          _colleges.insert(0, 'All Colleges');
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading initial students: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _performSearch(String query) async {
    setState(() {
      _isLoading = true;
      _searchQuery = query;
    });

    if (query.isEmpty) {
      _loadInitialStudents();
      return;
    }

    try {
      final response = await Supabase.instance.client.rpc(
        'search_profiles',
        params: {'search_query': query},
      );

      final allResults = List<Map<String, dynamic>>.from(response);

      // Filter for active students only
      var studentResults = allResults.where((user) {
        return user['role'] == 'student';
      }).toList();

      // Hydrate organization data if missing
      if (studentResults.isNotEmpty &&
          studentResults.first['organizations'] == null) {
        final ids = studentResults.map((e) => e['id']).toList();
        if (ids.isNotEmpty) {
          final orgData = await Supabase.instance.client
              .from('profiles')
              .select('id, organizations(name, logo_url)')
              .inFilter('id', ids);

          final orgMap = {
            for (var item in orgData) item['id']: item['organizations'],
          };

          for (var student in studentResults) {
            student['organizations'] = orgMap[student['id']];
          }
        }
      }

      if (mounted) {
        setState(() {
          _students = studentResults;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error searching students: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _getStudentCollegeName(Map<String, dynamic> student) {
    if (student['organizations'] != null) {
      return student['organizations']['name'] ?? '';
    }
    return student['college_name'] ?? '';
  }

  String? _getStudentCollegeLogo(Map<String, dynamic> student) {
    if (student['organizations'] != null) {
      return student['organizations']['logo_url'];
    }
    return null;
  }

  List<Map<String, dynamic>> _getFilteredStudents() {
    if (_selectedCollege == 'All Colleges') {
      return _students;
    }
    return _students
        .where((s) => _getStudentCollegeName(s) == _selectedCollege)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth > 900) {
                  return _buildDesktopLayout();
                }
                return _buildMobileLayout();
              },
            ),
    );
  }

  Widget _buildDesktopLayout() {
    final filteredStudents = _getFilteredStudents();
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Main Search Area
        Expanded(
          flex: 3,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(filteredStudents.length),
                const SizedBox(height: 24),
                _buildSearchAndFilter(),
                const SizedBox(height: 24),
                _buildStudentsGrid(filteredStudents),
              ],
            ),
          ),
        ),

        // Analytics Sidebar
        Container(
          width: 350,
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(left: BorderSide(color: Colors.grey.shade200)),
          ),
          child: _buildAnalyticsSidebar(),
        ),
      ],
    );
  }

  Widget _buildMobileLayout() {
    final filteredStudents = _getFilteredStudents();
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(filteredStudents.length),
          const SizedBox(height: 24),
          _buildSearchAndFilter(),
          const SizedBox(height: 24),
          _buildStudentsGrid(filteredStudents),
        ],
      ),
    );
  }

  Widget _buildHeader(int count) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () {
            if (widget.onBackPressed != null) {
              widget.onBackPressed!();
            } else {
              Navigator.maybePop(context);
            }
          },
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Search Candidates',
                style: GoogleFonts.outfit(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                'Find top talent from colleges',
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  color: Colors.grey[600],
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            '$count Candidates',
            style: GoogleFonts.outfit(
              fontWeight: FontWeight.w600,
              color: AppTheme.primaryColor,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchAndFilter() {
    final bool isMobileWidth = MediaQuery.of(context).size.width < 600;

    if (isMobileWidth) {
      return Column(
        children: [
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search by name or email...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        _performSearch('');
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 16,
              ),
            ),
            onChanged: (value) {
              _performSearch(value);
            },
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _colleges.contains(_selectedCollege)
                    ? _selectedCollege
                    : 'All Colleges',
                isExpanded: true,
                hint: const Text('Filter by College'),
                icon: const Icon(Icons.school, color: Colors.grey),
                items: _colleges.map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(
                      value,
                      style: GoogleFonts.outfit(fontSize: 14),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }).toList(),
                onChanged: (newValue) {
                  if (newValue != null) {
                    setState(() => _selectedCollege = newValue);
                  }
                },
              ),
            ),
          ),
        ],
      );
    }

    return Row(
      children: [
        Expanded(
          flex: 2,
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search by name or email...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        _performSearch('');
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 16,
              ),
            ),
            onChanged: (value) {
              _performSearch(value);
            },
          ),
        ),
        const SizedBox(width: 16),
        // College Dropdown
        Expanded(
          flex: 1,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _colleges.contains(_selectedCollege)
                    ? _selectedCollege
                    : 'All Colleges',
                isExpanded: true,
                hint: const Text('Filter by College'),
                icon: const Icon(Icons.school, color: Colors.grey),
                items: _colleges.map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(
                      value,
                      style: GoogleFonts.outfit(fontSize: 14),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }).toList(),
                onChanged: (newValue) {
                  if (newValue != null) {
                    setState(() => _selectedCollege = newValue);
                  }
                },
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStudentsGrid(List<Map<String, dynamic>> students) {
    if (students.isEmpty) {
      return Center(
        child: Column(
          children: [
            const SizedBox(height: 64),
            Icon(
              Icons.person_search_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No candidates found',
              style: GoogleFonts.outfit(
                fontSize: 18,
                color: Colors.grey[600],
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 250,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio:
            0.50, // Reduced to 0.50 for ultra-safe vertical clearance on all mobile widths
      ),
      itemCount: students.length,
      itemBuilder: (context, index) {
        return _buildStudentCard(students[index]);
      },
    );
  }

  Widget _buildStudentCard(Map<String, dynamic> student) {
    final String fullName = student['full_name'] ?? 'Unknown';
    final String? avatarUrl =
        student['profile_photo_url'] ?? student['avatar_url'];
    final String email = student['email'] ?? '';
    final String userId = student['id'] ?? student['user_id'];

    final collegeName = _getStudentCollegeName(student);
    final collegeLogo = _getStudentCollegeLogo(student);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Stack(
            children: [
              CircleAvatar(
                radius: 36,
                backgroundImage: avatarUrl != null
                    ? NetworkImage(avatarUrl)
                    : null,
                backgroundColor: Colors.blue.shade100,
                child: avatarUrl == null
                    ? Text(
                        fullName.isNotEmpty ? fullName[0].toUpperCase() : '?',
                        style: GoogleFonts.outfit(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade700,
                        ),
                      )
                    : null,
              ),
              if (collegeLogo != null && collegeLogo.isNotEmpty)
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: CircleAvatar(
                      radius: 12,
                      backgroundImage: NetworkImage(collegeLogo),
                      backgroundColor: Colors.white,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            fullName,
            style: GoogleFonts.outfit(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          if (collegeName.isNotEmpty)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (collegeLogo == null || collegeLogo.isEmpty) ...[
                  Icon(Icons.school, size: 12, color: Colors.grey[700]),
                  const SizedBox(width: 4),
                ],
                Flexible(
                  child: Text(
                    collegeName,
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      color: Colors.grey[700],
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),

          const SizedBox(height: 4),
          Text(
            email.isNotEmpty ? email : 'Student',
            style: GoogleFonts.outfit(fontSize: 11, color: Colors.grey[500]),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const Spacer(),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => NetworkProfileView(
                    userId: userId,
                    userName: fullName,
                    userAvatar: avatarUrl,
                    userRole: 'student',
                  ),
                ),
              );
            },
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              minimumSize: const Size(double.infinity, 36),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: EdgeInsets.zero,
            ),
            child: const Text(
              'View Profile',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyticsSidebar() {
    Map<String, int> collegeCounts = {};
    Map<String, String?> collegeLogos = {};

    // Calculate stats based on loaded students
    for (var s in _students) {
      final college = _getStudentCollegeName(s);
      if (college.isNotEmpty) {
        collegeCounts[college] = (collegeCounts[college] ?? 0) + 1;
        if (!collegeLogos.containsKey(college)) {
          collegeLogos[college] = _getStudentCollegeLogo(s);
        }
      }
    }

    var sortedColleges = collegeCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final totalStudents = _students.length;

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text(
          'Talent Insights',
          style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          'Student distribution by college',
          style: GoogleFonts.outfit(fontSize: 13, color: Colors.grey[500]),
        ),
        const SizedBox(height: 32),

        // Total Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade100),
            boxShadow: [
              BoxShadow(
                color: Colors.orange.withValues(alpha: 0.05),
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
                child: const Icon(
                  Icons.people_alt,
                  color: Colors.orange,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$totalStudents',
                    style: GoogleFonts.outfit(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Visible Candidates',
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 32),
        Text(
          'Top Colleges',
          style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),

        if (sortedColleges.isEmpty)
          Text(
            'No data available',
            style: GoogleFonts.outfit(color: Colors.grey),
          )
        else
          ...sortedColleges
              .map(
                (entry) => _buildCollegeStatRow(
                  entry.key,
                  entry.value,
                  totalStudents,
                  collegeLogos[entry.key],
                ),
              )
              .toList(),
      ],
    );
  }

  Widget _buildCollegeStatRow(
    String name,
    int count,
    int total,
    String? logoUrl,
  ) {
    double percentage = total > 0 ? count / total : 0;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                  image: logoUrl != null && logoUrl.isNotEmpty
                      ? DecorationImage(
                          image: NetworkImage(logoUrl),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: logoUrl == null || logoUrl.isEmpty
                    ? Center(
                        child: Text(
                          name.characters.first.toUpperCase(),
                          style: GoogleFonts.outfit(
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[600],
                          ),
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '$count candidates',
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${(percentage * 100).toStringAsFixed(0)}%',
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: percentage,
              backgroundColor: Colors.grey[100],
              color: Colors.blueAccent,
              minHeight: 4,
            ),
          ),
        ],
      ),
    );
  }
}

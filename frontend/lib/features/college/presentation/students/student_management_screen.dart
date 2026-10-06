import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../../core/theme/app_theme.dart';
import '../../../networking/presentation/screens/network_profile_view.dart';
import '../../../networking/presentation/screens/chat_screen.dart';
import 'widgets/student_card.dart';
import 'widgets/student_stats_panel.dart';
import 'widgets/bulk_actions_panel.dart';
import 'widgets/student_filters_panel.dart';
import 'widgets/bulk_message_dialog.dart';
import '../../data/college_providers.dart';
import '../../data/student_export_service.dart';
import '../verification/certificate_verification_screen.dart';
import 'package:printing/printing.dart';

class StudentManagementScreen extends ConsumerStatefulWidget {
  const StudentManagementScreen({super.key});

  @override
  ConsumerState<StudentManagementScreen> createState() =>
      _StudentManagementScreenState();
}

class _StudentManagementScreenState
    extends ConsumerState<StudentManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();

  // Enhanced state management
  String _searchQuery = '';
  String _selectedDepartment = 'All';
  String _selectedBatch = 'All';
  String _selectedPlacementStatus = 'All';
  String _sortBy = 'name';
  bool _sortAscending = true;
  final List<String> _selectedStudents = [];
  bool _showFilters = false;
  final StudentExportService _exportService = StudentExportService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
      });
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Column(
        children: [
          // Header Section
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Student Management',
                          style: GoogleFonts.outfit(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Manage student profiles, track progress & monitor placements',
                          style: GoogleFonts.outfit(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        OutlinedButton.icon(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) =>
                                    const CertificateVerificationScreen(),
                              ),
                            );
                          },
                          icon: const Icon(Icons.verified_user_outlined),
                          label: const Text('Verify Certificates'),
                        ),
                        const SizedBox(width: 16),
                        OutlinedButton.icon(
                          onPressed: () => _exportStudentData(),
                          icon: const Icon(Icons.download_rounded),
                          label: const Text('Export Data'),
                        ),
                        const SizedBox(width: 16),
                        OutlinedButton.icon(
                          onPressed: () {
                            // Force refresh the providers
                            ref.invalidate(studentsProvider);
                            ref.invalidate(studentStatsProvider);
                            ref.invalidate(currentCollegeProvider);
                          },
                          icon: const Icon(Icons.refresh_rounded),
                          label: const Text('Refresh'),
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Stats Panel
                const StudentStatsPanel(),

                const SizedBox(height: 24),

                // Search and Filter Bar
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Search by name, USN, email, or skills...',
                          prefixIcon: const Icon(Icons.search_rounded),
                          suffixIcon: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (_searchQuery.isNotEmpty)
                                IconButton(
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() => _searchQuery = '');
                                  },
                                  icon: const Icon(Icons.clear_rounded),
                                ),
                              IconButton(
                                onPressed: () => setState(
                                  () => _showFilters = !_showFilters,
                                ),
                                icon: Icon(
                                  _showFilters
                                      ? Icons.filter_list_off
                                      : Icons.filter_list,
                                  color: _showFilters
                                      ? AppTheme.primaryColor
                                      : null,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _sortBy,
                          items:
                              [
                                {'value': 'name', 'label': 'Sort by Name'},
                                {'value': 'cgpa', 'label': 'Sort by CGPA'},
                                {
                                  'value': 'completion',
                                  'label': 'Sort by Profile Completion',
                                },
                                {
                                  'value': 'last_active',
                                  'label': 'Sort by Last Active',
                                },
                              ].map((item) {
                                return DropdownMenuItem(
                                  value: item['value'],
                                  child: Text(item['label']!),
                                );
                              }).toList(),
                          onChanged: (value) {
                            setState(() => _sortBy = value!);
                          },
                        ),
                      ),
                    ),
                  ],
                ),

                // Filters Panel (Collapsible)
                if (_showFilters) ...[
                  const SizedBox(height: 16),
                  StudentFiltersPanel(
                    selectedDepartment: _selectedDepartment,
                    selectedBatch: _selectedBatch,
                    selectedPlacementStatus: _selectedPlacementStatus,
                    onDepartmentChanged: (value) =>
                        setState(() => _selectedDepartment = value),
                    onBatchChanged: (value) =>
                        setState(() => _selectedBatch = value),
                    onPlacementStatusChanged: (value) =>
                        setState(() => _selectedPlacementStatus = value),
                    onClearFilters: () => setState(() {
                      _selectedDepartment = 'All';
                      _selectedBatch = 'All';
                      _selectedPlacementStatus = 'All';
                    }),
                  ),
                ],
              ],
            ),
          ),

          // Bulk Actions Panel (when students are selected)
          if (_selectedStudents.isNotEmpty)
            BulkActionsPanel(
              selectedCount: _selectedStudents.length,
              onSendMessage: () => _sendBulkMessage(),
              onExportSelected: () => _exportSelectedStudents(),
              onAssignTest: () => _assignBulkTest(),
              onClearSelection: () => setState(() => _selectedStudents.clear()),
            ),

          // Tab Bar
          Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              labelColor: AppTheme.primaryColor,
              unselectedLabelColor: Colors.grey[600],
              indicatorColor: AppTheme.primaryColor,
              labelStyle: GoogleFonts.outfit(fontWeight: FontWeight.w600),
              isScrollable: true,
              tabs: const [
                Tab(text: 'All Students'),
                Tab(text: 'Pending Verification'),
                Tab(text: 'Active Students'),
                Tab(text: 'Placed Students'),
                Tab(text: 'Need Attention'),
              ],
            ),
          ),

          // Content Area
          Expanded(
            child: Consumer(
              builder: (context, ref, child) {
                // Get college first
                final collegeAsync = ref.watch(currentCollegeProvider);

                return collegeAsync.when(
                  data: (college) {
                    if (college == null) {
                      return const Center(
                        child: Text('No college found for current user'),
                      );
                    }

                    final studentsAsync = ref.watch(
                      studentsProvider(college['id']),
                    );

                    return studentsAsync.when(
                      data: (students) {
                        if (students.isEmpty) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.people_outline_rounded,
                                  size: 64,
                                  color: Colors.grey[400],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No students found',
                                  style: GoogleFonts.outfit(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Students will appear here once they register for your college.',
                                  style: GoogleFonts.outfit(
                                    fontSize: 14,
                                    color: Colors.grey[500],
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          );
                        }

                        final filteredStudents = _filterAndSortStudents(
                          students,
                        );

                        return TabBarView(
                          controller: _tabController,
                          children: [
                            _buildStudentGrid(filteredStudents, 'all'),
                            _buildStudentGrid(filteredStudents, 'pending'),
                            _buildStudentGrid(filteredStudents, 'verified'),
                            _buildStudentGrid(filteredStudents, 'placed'),
                            _buildStudentGrid(filteredStudents, 'attention'),
                          ],
                        );
                      },
                      loading: () {
                        return const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CircularProgressIndicator(),
                              SizedBox(height: 16),
                              Text('Loading students...'),
                            ],
                          ),
                        );
                      },
                      error: (err, stack) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.error_outline,
                                size: 64,
                                color: Colors.red[300],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Error loading students',
                                style: GoogleFonts.outfit(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.red[600],
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Please check your connection and try again.',
                                style: GoogleFonts.outfit(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                              const SizedBox(height: 16),
                              FilledButton.icon(
                                onPressed: () {
                                  // Refresh the data
                                  ref.invalidate(studentsProvider);
                                },
                                icon: const Icon(Icons.refresh_rounded),
                                label: const Text('Retry'),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                  loading: () {
                    return const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 16),
                          Text('Loading college information...'),
                        ],
                      ),
                    );
                  },
                  error: (err, stack) {
                    return Center(child: Text('Error loading college: $err'));
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> _filterAndSortStudents(
    List<Map<String, dynamic>> students,
  ) {
    var filtered = students.where((student) {
      // Extract nested data safely
      final studentProfile = student['student_profiles'] is List
          ? (student['student_profiles'] as List).isNotEmpty
                ? (student['student_profiles'] as List)[0]
                : {}
          : student['student_profiles'] ?? {};

      // Search filter
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final name = (student['full_name'] ?? '').toString().toLowerCase();
        final email = (student['email'] ?? '').toString().toLowerCase();
        final usn = (studentProfile['usn'] ?? '').toString().toLowerCase();

        if (!name.contains(query) &&
            !email.contains(query) &&
            !usn.contains(query)) {
          return false;
        }
      }

      // Placement status filter
      if (_selectedPlacementStatus != 'All') {
        final status = studentProfile['placement_status'] ?? 'seeking';
        if (status != _selectedPlacementStatus) {
          return false;
        }
      }

      return true;
    }).toList();

    // Sort students
    filtered.sort((a, b) {
      int comparison = 0;

      final aProfile = a['student_profiles'] is List
          ? (a['student_profiles'] as List).isNotEmpty
                ? (a['student_profiles'] as List)[0]
                : {}
          : a['student_profiles'] ?? {};
      final bProfile = b['student_profiles'] is List
          ? (b['student_profiles'] as List).isNotEmpty
                ? (b['student_profiles'] as List)[0]
                : {}
          : b['student_profiles'] ?? {};

      switch (_sortBy) {
        case 'name':
          comparison = (a['full_name'] ?? '').compareTo(b['full_name'] ?? '');
          break;
        case 'cgpa':
          final aCgpa = (aProfile['cgpa'] ?? 0.0) as num;
          final bCgpa = (bProfile['cgpa'] ?? 0.0) as num;
          comparison = aCgpa.compareTo(bCgpa);
          break;
        case 'completion':
          final aCompletion = (a['profile_completion'] ?? 0) as int;
          final bCompletion = (b['profile_completion'] ?? 0) as int;
          comparison = aCompletion.compareTo(bCompletion);
          break;
        case 'last_active':
          final aActive =
              DateTime.tryParse(a['updated_at'] ?? '') ?? DateTime.now();
          final bActive =
              DateTime.tryParse(b['updated_at'] ?? '') ?? DateTime.now();
          comparison = aActive.compareTo(bActive);
          break;
      }

      return _sortAscending ? comparison : -comparison;
    });

    return filtered;
  }

  Future<void> _verifyStudent(Map<String, dynamic> student) async {
    try {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Verify Student'),
          content: Text(
            'Are you sure you want to mark ${student['full_name']} as verified?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Verify'),
            ),
          ],
        ),
      );

      if (confirm == true) {
        await ref.read(collegeRepositoryProvider).verifyStudent(student['id']);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Student verified successfully')),
          );
          // Refresh lists
          ref.invalidate(studentsProvider);
          ref.invalidate(studentStatsProvider);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error verifying student: $e')));
      }
    }
  }

  Future<void> _deleteStudent(Map<String, dynamic> student) async {
    try {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(
            'Delete Student',
            style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
          ),
          content: Text(
            'Are you sure you want to remove ${student['full_name']} from the system? This action will permanently delete all associated data.',
            style: GoogleFonts.outfit(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Delete'),
            ),
          ],
        ),
      );

      if (confirm == true) {
        await ref
            .read(studentsNotifierProvider.notifier)
            .deleteStudent(student['id']);
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Student deleted')));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error deleting student: $e')));
      }
    }
  }

  Widget _buildStudentGrid(
    List<Map<String, dynamic>> allStudents,
    String filterStatus,
  ) {
    // Filter by tab status
    final filtered = allStudents.where((student) {
      final studentProfile = student['student_profiles'] is List
          ? (student['student_profiles'] as List).isNotEmpty
                ? (student['student_profiles'] as List)[0]
                : {}
          : student['student_profiles'] ?? {};

      switch (filterStatus) {
        case 'all':
          return true;
        case 'pending':
          return (student['is_verified'] ?? false) == false;
        case 'verified':
          return (student['is_verified'] ?? false) == true &&
              (studentProfile['placement_status'] ?? 'seeking') != 'placed';
        case 'placed':
          return (studentProfile['placement_status'] ?? 'seeking') == 'placed';
        case 'attention':
          return (student['profile_completion'] ?? 0) < 70;
        default:
          return true;
      }
    }).toList();

    if (filtered.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.people_outline_rounded,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No students found',
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _getEmptyStateMessage(filterStatus),
              style: GoogleFonts.outfit(fontSize: 14, color: Colors.grey[500]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(24),
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 24,
          mainAxisSpacing: 24,
          childAspectRatio: 1.05, // Adjusted from 0.85 for smaller cards
        ),
        itemCount: filtered.length,
        itemBuilder: (context, index) {
          final student = filtered[index];
          final isSelected = _selectedStudents.contains(student['id']);
          final isVerified = student['is_verified'] ?? false;

          return StudentCard(
            student: student,
            isSelected: isSelected,
            onTap: () => _viewStudentDetails(student),
            onSelect: (selected) {
              setState(() {
                if (selected) {
                  _selectedStudents.add(student['id']);
                } else {
                  _selectedStudents.remove(student['id']);
                }
              });
            },
            onMessage: () => _messageStudent(student),
            onVerify: !isVerified ? () => _verifyStudent(student) : null,
            onDelete: () => _deleteStudent(student),
          );
        },
      ),
    );
  }

  String _getEmptyStateMessage(String filterStatus) {
    switch (filterStatus) {
      case 'pending':
        return 'No students pending verification.\nAll students have been processed.';
      case 'verified':
        return 'No active students found.\nInvite students to get started.';
      case 'placed':
        return 'No students have been placed yet.\nStart organizing placement drives.';
      case 'attention':
        return 'Great! All students are on track.\nNo immediate attention required.';
      default:
        return 'No students found matching your criteria.\nTry adjusting your filters.';
    }
  }

  Future<void> _exportStudentData() async {
    final college = ref.read(currentCollegeProvider).value;
    final collegeName = college?['name'] ?? 'College';
    final collegeId = college?['id'] ?? '';

    if (collegeId.isEmpty) return;

    try {
      // Show loading indicator
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Generating PDF Report...')));

      // Get all students for this college (filtered by current search/tab if possible,
      // but simpler to just fetch all for the general export)
      final allStudents = ref.read(studentsProvider(collegeId)).value ?? [];

      if (allStudents.isEmpty) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('No students to export')));
        return;
      }

      final pdfBytes = await _exportService.generateStudentReport(
        students: allStudents,
        collegeName: collegeName,
        reportTitle: 'Complete Student Directory',
      );

      await Printing.sharePdf(
        bytes: pdfBytes,
        filename: '${collegeName.replaceAll(' ', '_')}_Students.pdf',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error generating PDF: $e')));
      }
    }
  }

  void _sendBulkMessage() {
    showDialog(
      context: context,
      builder: (context) => BulkMessageDialog(
        studentIds: _selectedStudents,
        studentCount: _selectedStudents.length,
      ),
    );
  }

  Future<void> _exportSelectedStudents() async {
    final college = ref.read(currentCollegeProvider).value;
    final collegeName = college?['name'] ?? 'College';
    final collegeId = college?['id'] ?? '';

    if (_selectedStudents.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('No students selected')));
      return;
    }

    try {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Exporting ${_selectedStudents.length} selected students...',
          ),
        ),
      );

      final allStudents = ref.read(studentsProvider(collegeId)).value ?? [];
      final selectedData = allStudents
          .where((s) => _selectedStudents.contains(s['id']))
          .toList();

      final pdfBytes = await _exportService.generateStudentReport(
        students: selectedData,
        collegeName: collegeName,
        reportTitle: 'Selected Students Report',
      );

      await Printing.sharePdf(
        bytes: pdfBytes,
        filename: 'Selected_Students_Export.pdf',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error exporting students: $e')));
      }
    }
  }

  void _assignBulkTest() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Assigning test to ${_selectedStudents.length} students'),
      ),
    );
  }

  void _viewStudentDetails(Map<String, dynamic> student) {
    try {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => NetworkProfileView(
            userId: student['id'],
            userName: student['full_name'] ?? 'Student',
            userAvatar: student['profile_photo_url'],
            userRole: 'student',
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error opening profile: $e')));
      }
    }
  }

  void _messageStudent(Map<String, dynamic> student) {
    showDialog(
      context: context,
      builder: (context) => SimpleDialog(
        title: Text(
          'Message ${student['full_name']}',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        children: [
          SimpleDialogOption(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              // Open App Chat
              try {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => ChatScreen(
                      targetUserId: student['id'],
                      targetUserName: student['full_name'] ?? 'Student',
                      targetUserAvatar: student['profile_photo_url'],
                    ),
                  ),
                );
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error opening chat: $e')),
                  );
                }
              }
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.chat_bubble_outline,
                      color: AppTheme.primaryColor,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text('In-App Chat', style: GoogleFonts.outfit(fontSize: 16)),
                ],
              ),
            ),
          ),
          SimpleDialogOption(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              _openWhatsApp(student);
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.message_outlined,
                      color: Colors.green,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text('WhatsApp', style: GoogleFonts.outfit(fontSize: 16)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openWhatsApp(Map<String, dynamic> student) async {
    final phone = student['phone'] as String?;
    if (phone == null || phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No phone number available for this student'),
        ),
      );
      return;
    }

    // Basic cleaning of phone number
    var cleanPhone = phone.replaceAll(RegExp(r'\D'), '');
    if (!cleanPhone.startsWith('91') && cleanPhone.length == 10) {
      cleanPhone = '91$cleanPhone'; // Default to India code if missing
    }

    final message = Uri.encodeComponent(
      'Hello ${student['full_name']}, regarding your placement opportunities...',
    );

    final url = Uri.parse('https://wa.me/$cleanPhone?text=$message');

    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not launch WhatsApp')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error launching WhatsApp: $e')));
      }
    }
  }

  // _assignTestToStudent function removed as requested and no longer used
}

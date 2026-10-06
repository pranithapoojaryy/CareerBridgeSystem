import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';

class RoleSelectionScreen extends StatefulWidget {
  const RoleSelectionScreen({super.key});

  @override
  State<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends State<RoleSelectionScreen> {
  String? _selectedRole;

  final List<Map<String, dynamic>> _roles = [
    {
      'id': 'student',
      'title': 'Student',
      'subtitle': 'Find your dream job and build your career',
      'icon': Icons.school_rounded,
      'color': Colors.blue,
      'features': [
        'Create professional resume',
        'Apply to job opportunities',
        'Track application status',
        'Skill assessments',
        'Career guidance',
      ],
    },
    {
      'id': 'college',
      'title': 'College/University',
      'subtitle': 'Manage placements and student career development',
      'icon': Icons.account_balance_rounded,
      'color': Colors.green,
      'features': [
        'Manage student database',
        'Coordinate with recruiters',
        'Track placement statistics',
        'Organize campus drives',
        'Student progress monitoring',
      ],
    },
    {
      'id': 'recruiter',
      'title': 'Recruiter/HR',
      'subtitle': 'Discover and hire top talent efficiently',
      'icon': Icons.business_center_rounded,
      'color': Colors.orange,
      'features': [
        'Post job opportunities',
        'Search candidate database',
        'Schedule interviews',
        'Manage hiring pipeline',
        'Campus recruitment',
      ],
    },
  ];

  void _selectRole(String roleId) {
    setState(() {
      _selectedRole = roleId;
    });
  }

  void _continue() {
    if (_selectedRole == null) return;

    switch (_selectedRole) {
      case 'student':
        Navigator.pushNamed(context, '/student-register');
        break;
      case 'college':
        Navigator.pushNamed(context, '/college-register');
        break;
      case 'recruiter':
        Navigator.pushNamed(context, '/recruiter-register');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: AppTheme.gradientBackground,
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Row(
                      children: [
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.arrow_back_rounded),
                          color: AppTheme.primaryColor,
                        ),
                        const Spacer(),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Choose Your Role',
                      style: GoogleFonts.outfit(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryColor,
                      ),
                    ).animate().fadeIn(delay: 200.ms).slideY(begin: -0.2, end: 0),
                    const SizedBox(height: 8),
                    Text(
                      'Select how you want to use CareerBridge',
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                    ).animate().fadeIn(delay: 400.ms).slideY(begin: -0.2, end: 0),
                  ],
                ),
              ),

              // Role Cards
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  itemCount: _roles.length,
                  itemBuilder: (context, index) {
                    final role = _roles[index];
                    final isSelected = _selectedRole == role['id'];
                    
                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => _selectRole(role['id']),
                          borderRadius: BorderRadius.circular(20),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isSelected 
                                    ? role['color'] 
                                    : Colors.grey.withValues(alpha: 0.2),
                                width: isSelected ? 2 : 1,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: isSelected 
                                      ? role['color'].withValues(alpha: 0.2)
                                      : Colors.black.withValues(alpha: 0.05),
                                  blurRadius: isSelected ? 15 : 10,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: role['color'].withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Icon(
                                        role['icon'],
                                        color: role['color'],
                                        size: 28,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            role['title'],
                                            style: GoogleFonts.outfit(
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.black87,
                                            ),
                                          ),
                                          Text(
                                            role['subtitle'],
                                            style: GoogleFonts.outfit(
                                              fontSize: 14,
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (isSelected)
                                      Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: BoxDecoration(
                                          color: role['color'],
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.check_rounded,
                                          color: Colors.white,
                                          size: 16,
                                        ),
                                      ),
                                  ],
                                ),
                                if (isSelected) ...[
                                  const SizedBox(height: 16),
                                  Text(
                                    'Key Features:',
                                    style: GoogleFonts.outfit(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  ...role['features'].map<Widget>((feature) {
                                    return Padding(
                                      padding: const EdgeInsets.only(bottom: 4),
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.check_circle_rounded,
                                            color: role['color'],
                                            size: 16,
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              feature,
                                              style: GoogleFonts.outfit(
                                                fontSize: 13,
                                                color: Colors.grey[700],
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }).toList(),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),
                    ).animate(delay: Duration(milliseconds: 200 * index))
                     .fadeIn(duration: 600.ms)
                     .slideX(begin: 0.2, end: 0);
                  },
                ),
              ),

              // Continue Button
              Padding(
                padding: const EdgeInsets.all(24),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _selectedRole != null ? _continue : null,
                    style: FilledButton.styleFrom(
                      backgroundColor: _selectedRole != null 
                          ? _roles.firstWhere((r) => r['id'] == _selectedRole)['color']
                          : Colors.grey,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Continue',
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
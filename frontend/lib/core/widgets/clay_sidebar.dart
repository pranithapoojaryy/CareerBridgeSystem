import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

class ClaySidebar extends StatefulWidget {
  final int selectedIndex;
  final Function(int) onItemSelected;
  final bool isCollapsed;
  final VoidCallback onToggleCollapse;

  const ClaySidebar({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
    required this.isCollapsed,
    required this.onToggleCollapse,
  });

  @override
  State<ClaySidebar> createState() => _ClaySidebarState();
}

class _ClaySidebarState extends State<ClaySidebar> {
  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: widget.isCollapsed ? 120 : 400,
      height: double.infinity,
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(4, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          // Logo Area
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 300),
            crossFadeState: widget.isCollapsed
                ? CrossFadeState.showFirst
                : CrossFadeState.showSecond,
            firstChild: Column(
              children: [
                const SizedBox(height: 12),
                InkWell(
                  onTap: widget.onToggleCollapse,
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.keyboard_double_arrow_right_rounded,
                      color: Colors.grey,
                      size: 24,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: 48,
                  height: 48,
                  child: Image.asset(
                    'assets/images/logo.png',
                    fit: BoxFit.contain,
                  ),
                ),
              ],
            ),
            secondChild: Container(
              padding: EdgeInsets.zero, // Removed all padding
              width: 400,
              child: Column(
                children: [
                  const SizedBox(height: 8),
                  // Toggle Button aligned to right
                  Align(
                    alignment: Alignment.centerRight,
                    child: Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: IconButton(
                        onPressed: widget.onToggleCollapse,
                        visualDensity: VisualDensity.compact,
                        icon: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.keyboard_double_arrow_left_rounded,
                            color: Colors.grey,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Massive Logo
                  SizedBox(
                    width: 120,
                    child: Image.asset(
                      'assets/images/logo.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                  // No vertical spacing here
                  Text(
                    'CareerBridge',
                    style: GoogleFonts.outfit(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryColor,
                      height: 0.9,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  Text(
                    'Student Portal',
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[500],
                      height: 1.0,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),

          // Navigation Items
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _buildSectionHeader('Profile Zone'),
                _buildNavItem(0, 'Dashboard', Icons.dashboard_rounded),
                _buildNavItem(1, 'My Profile', Icons.person_rounded),
                _buildNavItem(2, 'Resume Builder', Icons.description_rounded),

                const SizedBox(height: 24),
                _buildSectionHeader('Career Tools'),
                _buildNavItem(3, 'Mock Tests', Icons.quiz_rounded),
                _buildNavItem(4, 'Skill Courses', Icons.school_rounded),
                _buildNavItem(5, 'Job Listings', Icons.work_rounded),
                _buildNavItem(6, 'Achievements', Icons.emoji_events_rounded),

                const SizedBox(height: 24),
                _buildSectionHeader('Practice & Testing'),
                _buildNavItem(7, 'Mock Interview', Icons.mic_rounded),
                _buildNavItem(8, 'Placement Tests', Icons.assignment_rounded),
                _buildNavItem(9, 'Progress Reports', Icons.bar_chart_rounded),

                const SizedBox(height: 24),
                _buildSectionHeader('Community'),
                _buildNavItem(10, 'Messaging', Icons.chat_bubble_rounded),
                _buildNavItem(11, 'Events', Icons.event_rounded),
              ],
            ),
          ),

          // System / Logout
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                _buildNavItem(12, 'Settings', Icons.settings_rounded),
                const SizedBox(height: 8),
                _buildNavItem(
                  13,
                  'Logout',
                  Icons.logout_rounded,
                  isDestructive: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, bottom: 8),
      child: Text(
        title.toUpperCase(),
        style: GoogleFonts.outfit(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: Colors.grey[400],
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildNavItem(
    int index,
    String title,
    IconData icon, {
    bool isDestructive = false,
  }) {
    final isSelected = widget.selectedIndex == index;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => widget.onItemSelected(index),
          borderRadius: BorderRadius.circular(16),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppTheme.primaryColor.withValues(alpha: 0.1)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 22,
                  color: isDestructive
                      ? Colors.red[400]
                      : isSelected
                      ? AppTheme.primaryColor
                      : Colors.grey[500],
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: isDestructive
                        ? Colors.red[400]
                        : isSelected
                        ? AppTheme.primaryColor
                        : Colors.grey[600],
                  ),
                ),
                if (isSelected) ...[
                  const Spacer(),
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: AppTheme.primaryColor,
                      shape: BoxShape.circle,
                    ),
                  ).animate().scale(),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

import 'package:google_fonts/google_fonts.dart';
import '../../../../../core/theme/app_theme.dart';
import 'package:flutter_animate/flutter_animate.dart';

class CollegeSidebar extends StatefulWidget {
  final int selectedIndex;
  final Function(int) onItemSelected;
  final bool isCollapsed;
  final VoidCallback onToggleCollapse;

  const CollegeSidebar({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
    required this.isCollapsed,
    required this.onToggleCollapse,
  });

  @override
  State<CollegeSidebar> createState() => _CollegeSidebarState();
}

class _CollegeSidebarState extends State<CollegeSidebar> {
  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: widget.isCollapsed ? 80 : 280, // Slimmer Sidebar
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
              width: 280,
              child: Column(
                children: [
                  const SizedBox(height: 8), // Minimal top spacing
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
                      height: 0.9, // Tighter line height
                    ),
                    textAlign: TextAlign.center,
                  ),
                  Text(
                    'College Portal',
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
                _buildSectionHeader('Core Management'),
                _buildNavItem(0, 'Dashboard', Icons.dashboard_rounded),
                _buildNavItem(2, 'Students', Icons.people_alt_rounded),

                const SizedBox(height: 24),
                _buildSectionHeader('Placement Operations'),
                _buildNavItem(3, 'Placement Drives', Icons.work_rounded),
                _buildNavItem(4, 'Resume Hub', Icons.description_rounded),
                _buildNavItem(5, 'Skill Assessments', Icons.assignment_rounded),
                _buildNavItem(
                  6,
                  'Interview Management',
                  Icons.admin_panel_settings_rounded,
                ),

                const SizedBox(height: 24),
                _buildSectionHeader('Skill Development'),
                // _buildNavItem(7, 'Learning Paths', Icons.school_rounded), // REMOVED
                // _buildNavItem(8, 'Skill Validation', Icons.verified_rounded), // REMOVED

                // _buildNavItem(9, 'Mock Tests', Icons.timer_rounded), // REMOVED
                _buildNavItem(
                  9,
                  'Certifications',
                  Icons.workspace_premium_rounded,
                ),

                const SizedBox(height: 24),
                _buildSectionHeader('Events & Engagement'),
                _buildNavItem(10, 'Events Manager', Icons.event_rounded),

                // _buildNavItem(12, 'Alumni Connect', Icons.connect_without_contact_rounded), // REMOVED
                // _buildNavItem(13, 'Mentorship', Icons.psychology_rounded), // REMOVED
                const SizedBox(height: 24),
                _buildSectionHeader('Communication'),
                _buildNavItem(14, 'Campus Feed', Icons.feed_rounded),
                _buildNavItem(15, 'My Network', Icons.network_locked_rounded),

                // _buildNavItem(16, 'Notifications', Icons.notifications_rounded), // REMOVED

                // _buildNavItem(19, 'Skill Analytics', Icons.trending_up_rounded), // REMOVED
                // _buildNavItem(20, 'NAAC Reports', Icons.folder_shared_rounded), // REMOVED
                const SizedBox(height: 24),
                _buildSectionHeader('Content Management'),
                _buildNavItem(21, 'Question Bank', Icons.quiz_rounded),
                _buildNavItem(
                  22,
                  'Learning Content',
                  Icons.library_books_rounded,
                ),

                const SizedBox(height: 24),
                _buildSectionHeader('AI Assistant'),
                _buildNavItem(
                  99,
                  'Ask CareerBridge AI (Beta)',
                  Icons.auto_awesome_rounded,
                ),
                const SizedBox(height: 24),
                _buildSectionHeader('System & Settings'),
                _buildNavItem(25, 'College Settings', Icons.settings_rounded),
                // _buildNavItem(24, 'Documents', Icons.folder_open_rounded), // REMOVED
              ],
            ),
          ),

          // Collapse Toggle & System
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // Toggle Button Removed from bottom
                const SizedBox(height: 8),
                _buildNavItem(
                  26,
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
    if (widget.isCollapsed) return const SizedBox.shrink();
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
      child: _HoverNavItem(
        isSelected: isSelected,
        isDestructive: isDestructive,
        isCollapsed: widget.isCollapsed,
        icon: icon,
        title: title,
        onTap: () => widget.onItemSelected(index),
      ),
    );
  }
}

// Hover-aware navigation item with smooth animations
class _HoverNavItem extends StatefulWidget {
  final bool isSelected;
  final bool isDestructive;
  final bool isCollapsed;
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _HoverNavItem({
    required this.isSelected,
    required this.isDestructive,
    required this.isCollapsed,
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  State<_HoverNavItem> createState() => _HoverNavItemState();
}

class _HoverNavItemState extends State<_HoverNavItem> {
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      child: AnimatedScale(
        scale: _isHovering && !widget.isSelected ? 1.02 : 1.0,
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOut,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: BorderRadius.circular(20),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: EdgeInsets.symmetric(
                horizontal: widget.isCollapsed ? 0 : 16,
                vertical: 12,
              ),
              decoration: BoxDecoration(
                gradient: widget.isSelected
                    ? LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppTheme.primaryColor.withValues(alpha: 0.15),
                          AppTheme.primaryColor.withValues(alpha: 0.08),
                        ],
                      )
                    : null,
                color: !widget.isSelected && _isHovering
                    ? Colors.grey.withValues(alpha: 0.05)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
                boxShadow: widget.isSelected
                    ? [
                        BoxShadow(
                          color: AppTheme.primaryColor.withValues(alpha: 0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              child: widget.isCollapsed
                  ? Center(
                      child: Icon(
                        widget.icon,
                        size: 24,
                        color: widget.isDestructive
                            ? Colors.red[400]
                            : (widget.title.contains("CareerBridge AI")
                                  ? AppTheme.primaryColor
                                  : (widget.isSelected
                                        ? AppTheme.primaryColor
                                        : Colors.grey[500])),
                      ),
                    )
                  : Row(
                      children: [
                        Icon(
                          widget.icon,
                          size: 22,
                          color: widget.isDestructive
                              ? Colors.red[400]
                              : (widget.title.contains("CareerBridge AI")
                                    ? AppTheme.primaryColor
                                    : (widget.isSelected
                                          ? AppTheme.primaryColor
                                          : Colors.grey[500])),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            widget.title,
                            style: GoogleFonts.outfit(
                              fontSize: 14,
                              fontWeight: widget.isSelected
                                  ? FontWeight.w600
                                  : FontWeight.w500,
                              color: widget.isDestructive
                                  ? Colors.red[400]
                                  : (widget.title.contains("CareerBridge AI")
                                        ? AppTheme.primaryColor
                                        : (widget.isSelected
                                              ? AppTheme.primaryColor
                                              : Colors.grey[600])),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (widget.title.contains("CareerBridge AI") &&
                            !widget.isSelected)
                          Icon(
                                Icons.bolt_rounded,
                                size: 14,
                                color: AppTheme.primaryColor.withValues(alpha: 0.5),
                              )
                              .animate(onPlay: (c) => c.repeat())
                              .fade(duration: 1000.ms)
                              .then()
                              .fade(duration: 1000.ms),
                        if (widget.isSelected) ...[
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: AppTheme.primaryColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

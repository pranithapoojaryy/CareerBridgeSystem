import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';

class RecruiterSidebar extends StatefulWidget {
  final int selectedIndex;
  final Function(int) onItemSelected;
  final bool isCollapsed;
  final VoidCallback onToggleCollapse;
  final bool isMobile;

  const RecruiterSidebar({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
    required this.isCollapsed,
    required this.onToggleCollapse,
    this.isMobile = false,
  });

  @override
  State<RecruiterSidebar> createState() => _RecruiterSidebarState();
}

class _RecruiterSidebarState extends State<RecruiterSidebar>
    with TickerProviderStateMixin {
  int? _hoveredIndex;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: widget.isCollapsed ? 120 : 400,
      height: double.infinity,
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white, Colors.orange.shade50.withValues(alpha: 0.3)],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withValues(alpha: 0.08),
            blurRadius: 30,
            offset: const Offset(4, 0),
            spreadRadius: 0,
          ),
        ],
        borderRadius: const BorderRadius.only(
          topRight: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Column(
        children: [
          _buildLogoArea(),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _buildSectionHeader('Dashboard', 0),
                _buildNavItem(0, 'Home', Icons.dashboard_rounded),

                const SizedBox(height: 24),
                _buildSectionHeader('Recruitment', 1),
                _buildNavItem(1, 'Job Postings', Icons.work_rounded),
                _buildNavItem(2, 'Applications', Icons.assignment_rounded),
                _buildNavItem(3, 'Students', Icons.people_rounded),

                // _buildNavItem(4, 'Resume Screening', Icons.document_scanner_rounded),
                const SizedBox(height: 24),
                _buildSectionHeader('Learning', 2),
                _buildNavItem(5, 'Learning Content', Icons.school_rounded),

                const SizedBox(height: 24),
                _buildSectionHeader('Connect', 3),
                _buildNavItem(6, 'Network', Icons.network_locked_rounded),

                const SizedBox(height: 24),
                _buildSectionHeader('Account', 4),
                _buildNavItem(7, 'Profile', Icons.person_rounded),

                const SizedBox(height: 24),
                _buildSectionHeader('AI Assistant', 5),
                _buildNavItem(
                  99,
                  'Ask CareerBridge AI (Beta)',
                  Icons.auto_awesome_rounded,
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: _buildNavItem(
              8,
              'Logout',
              Icons.logout_rounded,
              isDestructive: true,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogoArea() {
    return AnimatedCrossFade(
      duration: const Duration(milliseconds: 300),
      crossFadeState: widget.isCollapsed
          ? CrossFadeState.showFirst
          : CrossFadeState.showSecond,
      firstChild: Column(
        children: [
          const SizedBox(height: 12),
          if (!widget.isMobile)
            InkWell(
              onTap: widget.onToggleCollapse,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.grey.shade100, Colors.grey.shade50],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.keyboard_double_arrow_right_rounded,
                  color: Colors.grey.shade600,
                  size: 24,
                ),
              ),
            ),
          const SizedBox(height: 8),
          SizedBox(
            width: 48,
            height: 48,
            child: Image.asset('assets/images/logo.png', fit: BoxFit.contain),
          ),
        ],
      ),
      secondChild: Container(
        padding: EdgeInsets.zero,
        width: 400,
        child: Column(
          children: [
            const SizedBox(height: 8),
            if (!widget.isMobile)
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
                        gradient: LinearGradient(
                          colors: [Colors.grey.shade100, Colors.grey.shade50],
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.keyboard_double_arrow_left_rounded,
                        color: Colors.grey.shade600,
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ),
            SizedBox(
              width: 120,
              child: Image.asset('assets/images/logo.png', fit: BoxFit.contain),
            ),
            ShaderMask(
              shaderCallback: (bounds) => const LinearGradient(
                colors: [Colors.orange, Colors.deepOrange],
              ).createShader(bounds),
              child: Text(
                'CareerBridge',
                style: GoogleFonts.outfit(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  height: 0.9,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            Text(
              'Recruiter Portal',
              style: GoogleFonts.outfit(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade500,
                height: 1.0,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, int sectionIndex) {
    if (widget.isCollapsed) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(left: 16, bottom: 8),
      child: Text(
        title.toUpperCase(),
        style: GoogleFonts.outfit(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: Colors.grey.shade600,
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
    final isHovered = _hoveredIndex == index;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: MouseRegion(
        onEnter: (_) => setState(() => _hoveredIndex = index),
        onExit: (_) => setState(() => _hoveredIndex = null),
        child: Material(
          color: Colors.transparent,
          elevation: isHovered ? 4 : 0,
          borderRadius: BorderRadius.circular(16),
          shadowColor: isDestructive
              ? Colors.red.withValues(alpha: 0.2)
              : Colors.orange.withValues(alpha: 0.2),
          child: InkWell(
            onTap: () => widget.onItemSelected(index),
            borderRadius: BorderRadius.circular(24),
            splashColor: isDestructive
                ? Colors.red.withValues(alpha: 0.1)
                : Colors.orange.withValues(alpha: 0.1),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              padding: EdgeInsets.symmetric(
                horizontal: widget.isCollapsed ? 0 : 16,
                vertical: 14,
              ),
              decoration: BoxDecoration(
                color: isSelected
                    ? (isDestructive ? Colors.red.shade400 : Colors.orange)
                    : null,
                gradient: !isSelected && isHovered
                    ? LinearGradient(
                        colors: [Colors.grey.shade100, Colors.grey.shade50],
                      )
                    : null,
                borderRadius: BorderRadius.circular(24),
                border: isSelected
                    ? null
                    : Border.all(
                        color: isHovered
                            ? Colors.orange.withValues(alpha: 0.2)
                            : Colors.transparent,
                        width: 1,
                      ),
              ),
              child: widget.isCollapsed
                  ? Center(
                      child: Icon(
                        icon,
                        size: 24,
                        color: isSelected
                            ? Colors.white
                            : isDestructive
                            ? Colors.red.shade400
                            : Colors.grey.shade600,
                      ),
                    )
                  : Row(
                      children: [
                        Icon(
                          icon,
                          size: 22,
                          color: isSelected
                              ? Colors.white
                              : isDestructive
                              ? Colors.red.shade400
                              : Colors.grey.shade600,
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Text(
                            title,
                            style: GoogleFonts.outfit(
                              fontSize: 14,
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.w500,
                              color: isSelected
                                  ? Colors.white
                                  : isDestructive
                                  ? Colors.red.shade400
                                  : (index == 99
                                        ? Colors.orange
                                        : Colors.grey.shade700),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (index == 99 && !isSelected)
                          Icon(
                                Icons.bolt_rounded,
                                size: 14,
                                color: Colors.orange.shade300,
                              )
                              .animate(onPlay: (c) => c.repeat())
                              .fade(duration: 1000.ms)
                              .then()
                              .fade(duration: 1000.ms),
                        if (isSelected)
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.8),
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

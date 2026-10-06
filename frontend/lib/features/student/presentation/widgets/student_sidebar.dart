import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_theme.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../notifications/presentation/providers/notification_provider.dart';

class StudentSidebar extends ConsumerStatefulWidget {
  final int selectedIndex;
  final Function(int) onItemSelected;
  final bool isCollapsed;
  final VoidCallback onToggleCollapse;
  final bool isMobile;
  final VoidCallback? onNotificationTap;

  const StudentSidebar({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
    required this.isCollapsed,
    required this.onToggleCollapse,
    this.isMobile = false,
    this.onNotificationTap,
  });

  @override
  ConsumerState<StudentSidebar> createState() => _StudentSidebarState();
}

class _StudentSidebarState extends ConsumerState<StudentSidebar>
    with TickerProviderStateMixin {
  int? _hoveredIndex;
  late AnimationController _pulseController;
  late AnimationController _shimmerController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _shimmerController.dispose();
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
          colors: [Colors.white, Colors.blue.shade50.withValues(alpha: 0.3)],
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withValues(alpha: 0.08),
            blurRadius: 30,
            offset: const Offset(4, 0),
            spreadRadius: 0,
          ),
          BoxShadow(
            color: Colors.blue.shade100.withValues(alpha: 0.05),
            blurRadius: 60,
            offset: const Offset(8, 0),
          ),
        ],
        borderRadius: const BorderRadius.only(
          topRight: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Column(
        children: [
          // Logo Area with animations
          _buildLogoArea(),

          // Navigation Items
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _buildSectionHeader('Dashboard', 0),
                _buildNavItem(0, 'Home', Icons.dashboard_rounded),
                _buildNavItem(
                  1,
                  'Notifications',
                  Icons.notifications_rounded,
                  showBadge: true,
                ),
                _buildNavItem(2, 'My Profile', Icons.person_rounded),
                _buildNavItem(3, 'My Projects', Icons.work_outline_rounded),

                const SizedBox(height: 24),
                _buildSectionHeader('Career Tools', 3),
                _buildNavItem(4, 'Resume Builder', Icons.description_rounded),
                _buildNavItem(5, 'Job Applications', Icons.work_rounded),
                _buildNavItem(6, 'Interview Prep', Icons.video_call_rounded),

                const SizedBox(height: 24),
                _buildSectionHeader('Learning & Growth', 7),
                _buildNavItem(7, 'Learning Paths', Icons.school_rounded),
                _buildNavItem(
                  8,
                  'Certifications',
                  Icons.workspace_premium_rounded,
                ),
                _buildNavItem(
                  9,
                  'Practice Arena',
                  Icons.sports_esports_rounded,
                ),
                _buildNavItem(10, 'Aptitude Tests', Icons.quiz_rounded),

                const SizedBox(height: 24),
                _buildSectionHeader('Events & Opportunities', 11),
                _buildNavItem(11, 'Events', Icons.event_rounded),

                const SizedBox(height: 24),
                _buildSectionHeader('Connect', 12),
                _buildNavItem(12, 'My Network', Icons.network_locked_rounded),

                const SizedBox(height: 24),
                _buildSectionHeader('Progress & Analytics', 13),
                _buildNavItem(13, 'My Analytics', Icons.bar_chart_rounded),

                const SizedBox(height: 24),
                _buildSectionHeader('AI Assistant', 12),
                _buildNavItem(
                  99,
                  'Ask CareerBridge AI (Beta)',
                  Icons.auto_awesome_rounded,
                ),
              ],
            ),
          ),

          // Logout with special styling
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: _buildNavItem(
              14,
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
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.keyboard_double_arrow_right_rounded,
                  color: Colors.grey.shade600,
                  size: 24,
                ),
              ),
            ),
          const SizedBox(height: 8),
          AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              return Transform.scale(
                scale: 1.0 + (_pulseController.value * 0.05),
                child: SizedBox(
                  width: 48,
                  height: 48,
                  child: Image.asset(
                    'assets/images/logo.png',
                    fit: BoxFit.contain,
                  ),
                ),
              );
            },
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
            AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) {
                return Transform.scale(
                  scale: 1.0 + (_pulseController.value * 0.03),
                  child: SizedBox(
                    width: 120,
                    child: Image.asset(
                      'assets/images/logo.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                );
              },
            ),
            ShaderMask(
              shaderCallback: (bounds) => LinearGradient(
                colors: [AppTheme.primaryColor, AppTheme.primaryColor],
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
              'Student Portal',
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

    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 300 + (sectionIndex * 50)),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(-20 * (1 - value), 0),
            child: Padding(
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
            ),
          ),
        );
      },
    );
  }

  Widget _buildNavItem(
    int index,
    String title,
    IconData icon, {
    bool isDestructive = false,
    bool showBadge = false,
  }) {
    final isSelected = widget.selectedIndex == index;
    final isHovered = _hoveredIndex == index;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: MouseRegion(
        onEnter: (_) => setState(() => _hoveredIndex = index),
        onExit: (_) => setState(() => _hoveredIndex = null),
        child: TweenAnimationBuilder<double>(
          duration: const Duration(milliseconds: 200),
          tween: Tween(begin: 1.0, end: isHovered ? 1.02 : 1.0),
          curve: Curves.easeOut,
          builder: (context, scale, child) {
            return Transform.scale(
              scale: scale,
              child: Material(
                color: Colors.transparent,
                elevation: isHovered ? 4 : 0,
                borderRadius: BorderRadius.circular(16),
                shadowColor: isDestructive
                    ? Colors.red.withValues(alpha: 0.2)
                    : AppTheme.primaryColor.withValues(alpha: 0.2),
                child: InkWell(
                  onTap: () => widget.onItemSelected(index),
                  borderRadius: BorderRadius.circular(24),
                  splashColor: isDestructive
                      ? Colors.red.withValues(alpha: 0.1)
                      : AppTheme.primaryColor.withValues(alpha: 0.1),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    padding: EdgeInsets.symmetric(
                      horizontal: widget.isCollapsed ? 0 : 16,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? (isDestructive
                                ? Colors.red.shade400
                                : AppTheme.primaryColor)
                          : null,
                      gradient: !isSelected && isHovered
                          ? LinearGradient(
                              colors: [
                                Colors.grey.shade100,
                                Colors.grey.shade50,
                              ],
                            )
                          : null,
                      borderRadius: BorderRadius.circular(24),
                      border: isSelected
                          ? null
                          : Border.all(
                              color: isHovered
                                  ? AppTheme.primaryColor.withValues(alpha: 0.2)
                                  : Colors.transparent,
                              width: 1,
                            ),
                    ),
                    child: Stack(
                      children: [
                        if (isSelected)
                          Positioned(
                            left: 0,
                            top: 0,
                            bottom: 0,
                            child: AnimatedBuilder(
                              animation: _pulseController,
                              builder: (context, child) {
                                return Container(
                                  width: 4,
                                  decoration: BoxDecoration(
                                    color: AppTheme.primaryColor.withValues(
                                      alpha: 0.8 + (_pulseController.value * 0.2),
                                    ),
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                );
                              },
                            ),
                          ),
                        widget.isCollapsed
                            ? Center(
                                child: TweenAnimationBuilder<double>(
                                  duration: const Duration(milliseconds: 200),
                                  tween: Tween(
                                    begin: 0.0,
                                    end: isHovered ? -5.0 : 0.0,
                                  ),
                                  builder: (context, rotation, child) {
                                    return Transform.rotate(
                                      angle: rotation * (3.14159 / 180),
                                      child: Stack(
                                        clipBehavior: Clip.none,
                                        children: [
                                          Icon(
                                            icon,
                                            size: 24,
                                            color: isSelected
                                                ? Colors.white
                                                : isDestructive
                                                ? Colors.red.shade400
                                                : Colors.grey.shade600,
                                          ),
                                          if (showBadge)
                                            Positioned(
                                              right: -2,
                                              top: -2,
                                              child: Consumer(
                                                builder: (context, ref, _) {
                                                  final unreadCount = ref.watch(
                                                    unreadNotificationCountProvider,
                                                  );
                                                  if (unreadCount == 0)
                                                    return const SizedBox.shrink();
                                                  return Container(
                                                    width: 10,
                                                    height: 10,
                                                    decoration: BoxDecoration(
                                                      color: Colors.blue,
                                                      shape: BoxShape.circle,
                                                      border: Border.all(
                                                        color: isSelected
                                                            ? AppTheme
                                                                  .primaryColor
                                                            : Colors.white,
                                                        width: 1.5,
                                                      ),
                                                    ),
                                                  );
                                                },
                                              ),
                                            ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              )
                            : Row(
                                children: [
                                  TweenAnimationBuilder<double>(
                                    duration: const Duration(milliseconds: 200),
                                    tween: Tween(
                                      begin: 0.0,
                                      end: isHovered ? -5.0 : 0.0,
                                    ),
                                    builder: (context, rotation, child) {
                                      return Transform.rotate(
                                        angle: rotation * (3.14159 / 180),
                                        child: Stack(
                                          clipBehavior: Clip.none,
                                          children: [
                                            Icon(
                                              icon,
                                              size: 24,
                                              color: isSelected
                                                  ? Colors.white
                                                  : isDestructive
                                                  ? Colors.red.shade400
                                                  : Colors.grey.shade600,
                                            ),
                                            if (showBadge)
                                              Positioned(
                                                right: -2,
                                                top: -2,
                                                child: Consumer(
                                                  builder: (context, ref, _) {
                                                    final unreadCount = ref.watch(
                                                      unreadNotificationCountProvider,
                                                    );
                                                    if (unreadCount == 0)
                                                      return const SizedBox.shrink();
                                                    return Container(
                                                      width: 10,
                                                      height: 10,
                                                      decoration: BoxDecoration(
                                                        color: Colors.blue,
                                                        shape: BoxShape.circle,
                                                        border: Border.all(
                                                          color: isSelected
                                                              ? AppTheme
                                                                    .primaryColor
                                                              : Colors.white,
                                                          width: 1.5,
                                                        ),
                                                      ),
                                                    );
                                                  },
                                                ),
                                              ),
                                          ],
                                        ),
                                      );
                                    },
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
                                                  ? AppTheme.primaryColor
                                                  : Colors.grey.shade700),
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  if (index == 99 && !isSelected)
                                    Icon(
                                          Icons.bolt_rounded,
                                          size: 14,
                                          color: AppTheme.primaryColor
                                              .withValues(alpha: 0.5),
                                        )
                                        .animate(onPlay: (c) => c.repeat())
                                        .fade(duration: 1000.ms)
                                        .then()
                                        .fade(duration: 1000.ms),
                                  if (isSelected)
                                    AnimatedBuilder(
                                      animation: _pulseController,
                                      builder: (context, child) {
                                        return Container(
                                          width: 8,
                                          height: 8,
                                          decoration: BoxDecoration(
                                            color: Colors.white.withValues(
                                              alpha: 0.7 +
                                                  (_pulseController.value *
                                                      0.3),
                                            ),
                                            shape: BoxShape.circle,
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.white.withValues(
                                                  alpha: 0.5,
                                                ),
                                                blurRadius:
                                                    4 +
                                                    (_pulseController.value *
                                                        4),
                                                spreadRadius:
                                                    _pulseController.value * 2,
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                    ),
                                ],
                              ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

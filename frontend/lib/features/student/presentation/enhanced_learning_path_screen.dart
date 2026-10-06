import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';
import '../data/learning_repository.dart';
import '../domain/learning_course.dart';

class EnhancedLearningPathScreen extends ConsumerStatefulWidget {
  final LearningCourse course;
  const EnhancedLearningPathScreen({super.key, required this.course});

  @override
  ConsumerState<EnhancedLearningPathScreen> createState() =>
      _EnhancedLearningPathScreenState();
}

class _EnhancedLearningPathScreenState
    extends ConsumerState<EnhancedLearningPathScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isEnrolling = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    final myLearning = ref.watch(myLearningProvider);
    final isEnrolled =
        widget.course.isEnrolled ||
        myLearning.asData?.value.any((c) => c.id == widget.course.id) == true;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: CustomScrollView(
        slivers: [
          _buildAppBar(context, isEnrolled),
          SliverToBoxAdapter(child: _buildHeader()),
          SliverToBoxAdapter(child: _buildMetadataCards()),
          SliverToBoxAdapter(child: _buildTabBar()),
          SliverFillRemaining(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildOverviewTab(),
                _buildCurriculumTab(isEnrolled),
                _buildSkillsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar(BuildContext context, bool isEnrolled) {
    return SliverAppBar(
      expandedHeight: 250,
      pinned: true,
      backgroundColor: AppTheme.primaryColor,
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.primaryColor,
                    AppTheme.primaryColor.withValues(alpha: 0.7),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
            if (widget.course.thumbnailAsset.isNotEmpty)
              Opacity(
                opacity: 0.2,
                child: Image.network(
                  widget.course.thumbnailAsset,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const SizedBox(),
                ),
              ),
            Positioned(
              bottom: 20,
              left: 20,
              right: 20,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.5)),
                    ),
                    child: Text(
                      widget.course.category,
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.course.title,
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      shadows: [Shadow(color: Colors.black26, blurRadius: 4)],
                    ),
                    maxLines: 2,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
                child: Icon(
                  Icons.school,
                  color: AppTheme.primaryColor,
                  size: 28,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.course.providerName,
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (widget.course.targetRole != null)
                      Text(
                        '🎯 ${widget.course.targetRole}',
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetadataCards() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildInfoCard(
                  '⏱️',
                  '${widget.course.estimatedDurationWeeks ?? 8} Weeks',
                  'Duration',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildInfoCard('🎓', widget.course.difficulty, 'Level'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildInfoCard(
                  '📊',
                  widget.course.placementRelevance ?? 'High',
                  'Placement',
                  color: _getPlacementColor(widget.course.placementRelevance),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildInfoCard(
                  '💎',
                  '${widget.course.skillPoints} Points',
                  'Skill Score',
                ),
              ),
            ],
          ),
          if (widget.course.price > 0) ...[
            const SizedBox(height: 12),
            _buildPriceCard(),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoCard(
    String emoji,
    String value,
    String label, {
    Color? color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color?.withValues(alpha: 0.1) ?? Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color?.withValues(alpha: 0.3) ?? Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 24)),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.outfit(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            label,
            style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryColor.withValues(alpha: 0.1),
            Colors.purple.withValues(alpha: 0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Course Fee',
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  color: Colors.grey[700],
                ),
              ),
              Text(
                '₹${widget.course.price.toStringAsFixed(0)}',
                style: GoogleFonts.outfit(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor,
                ),
              ),
            ],
          ),
          Icon(Icons.verified, color: Colors.green[600], size: 32),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: AppTheme.primaryColor,
          borderRadius: BorderRadius.circular(12),
        ),
        labelColor: Colors.white,
        unselectedLabelColor: Colors.grey[600],
        labelStyle: GoogleFonts.outfit(
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
        tabs: const [
          Tab(text: '📋 Overview'),
          Tab(text: '📚 Curriculum'),
          Tab(text: '🎯 Skills'),
        ],
      ),
    );
  }

  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionCard(
            title: '📝 About This Path',
            child: Text(
              widget.course.description,
              style: GoogleFonts.outfit(
                fontSize: 14,
                color: Colors.grey[700],
                height: 1.5,
              ),
            ),
          ),
          if (widget.course.prerequisites != null) ...[
            const SizedBox(height: 16),
            _buildSectionCard(
              title: '⚠️ Prerequisites',
              color: Colors.orange[50],
              child: Text(
                widget.course.prerequisites!,
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  color: Colors.grey[700],
                  height: 1.5,
                ),
              ),
            ),
          ],
          if (widget.course.learningOutcomes != null) ...[
            const SizedBox(height: 16),
            _buildSectionCard(
              title: '✅ Learning Outcomes',
              color: Colors.green[50],
              child: Text(
                widget.course.learningOutcomes!,
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  color: Colors.grey[700],
                  height: 1.5,
                ),
              ),
            ),
          ],
          if (widget.course.itMetadata != null)
            _buildITMetadata(widget.course.itMetadata!),
          if (widget.course.managementMetadata != null)
            _buildManagementMetadata(widget.course.managementMetadata!),
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required Widget child,
    Color? color,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color ?? Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.outfit(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _buildITMetadata(ITCourseMetadata meta) {
    return Column(
      children: [
        const SizedBox(height: 16),
        _buildSectionCard(
          title: '💻 Technical Requirements',
          color: Colors.blue[50],
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (meta.programmingLanguages.isNotEmpty) ...[
                _buildMetaRow('Languages', meta.programmingLanguages),
                const SizedBox(height: 8),
              ],
              if (meta.toolsFrameworks.isNotEmpty) ...[
                _buildMetaRow('Tools & Frameworks', meta.toolsFrameworks),
                const SizedBox(height: 8),
              ],
              if (meta.codePracticeRequired)
                _buildBadge('💻 Code Practice Required', Colors.blue),
              if (meta.githubSubmissionRequired)
                _buildBadge('🔗 GitHub Submission', Colors.purple),
              if (meta.labSessionsRequired)
                _buildBadge('🧪 Lab Sessions', Colors.teal),
              if (meta.miniProjectsCount > 0)
                _buildBadge(
                  '🚀 ${meta.miniProjectsCount} Mini Projects',
                  Colors.orange,
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildManagementMetadata(ManagementCourseMetadata meta) {
    return Column(
      children: [
        const SizedBox(height: 16),
        _buildSectionCard(
          title: '📊 Management Focus',
          color: Colors.purple[50],
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (meta.caseStudiesRequired)
                _buildBadge('📚 Case Studies', Colors.indigo),
              if (meta.presentationRequired)
                _buildBadge('🎤 Presentations', Colors.pink),
              if (meta.groupActivityRequired)
                _buildBadge('👥 Group Activities', Colors.cyan),
              if (meta.rolePlayRequired)
                _buildBadge('🎭 Role Play', Colors.deepPurple),
              if (meta.reportSubmissionRequired)
                _buildBadge('📝 Reports', Colors.brown),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMetaRow(String label, List<String> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 4),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: items
              .map(
                (item) => Chip(
                  label: Text(item, style: GoogleFonts.outfit(fontSize: 11)),
                  padding: EdgeInsets.zero,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  backgroundColor: Colors.white,
                ),
              )
              .toList(),
        ),
      ],
    );
  }

  Widget _buildBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      margin: const EdgeInsets.only(top: 4, right: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        text,
        style: GoogleFonts.outfit(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Widget _buildCurriculumTab(bool isEnrolled) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: widget.course.sections.length,
      itemBuilder: (context, index) {
        final section = widget.course.sections[index];
        final isLocked = !isEnrolled && index > 0;
        return _buildWeekCard(section, index + 1, isLocked);
      },
    );
  }

  Widget _buildWeekCard(CourseSection section, int weekNumber, bool isLocked) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isLocked
              ? Colors.grey[300]!
              : AppTheme.primaryColor.withValues(alpha: 0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ExpansionTile(
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: isLocked
                ? Colors.grey[100]
                : AppTheme.primaryColor.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: isLocked
                ? Icon(Icons.lock, color: Colors.grey[400])
                : Text(
                    '$weekNumber',
                    style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryColor,
                    ),
                  ),
          ),
        ),
        title: Text(
          section.title,
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Text(
          '${section.lectures.length} learning units • ${section.estimatedHours?.toStringAsFixed(0) ?? '2'} hours',
          style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey[600]),
        ),
        children: section.lectures
            .map(
              (lecture) => ListTile(
                dense: true,
                leading: Icon(
                  _getLectureIcon(lecture.type),
                  size: 20,
                  color: AppTheme.primaryColor,
                ),
                title: Text(
                  lecture.title,
                  style: GoogleFonts.outfit(fontSize: 13),
                ),
                subtitle: Text(
                  '${lecture.durationMinutes} min',
                  style: GoogleFonts.outfit(fontSize: 11),
                ),
                trailing: lecture.isMandatory
                    ? const Icon(Icons.stars, size: 16, color: Colors.amber)
                    : null,
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _buildSkillsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionCard(
            title: '🎯 Skills You\'ll Gain',
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: widget.course.skillsGained
                  .map(
                    (skill) => Chip(
                      label: Text(
                        skill,
                        style: GoogleFonts.outfit(fontSize: 13),
                      ),
                      backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
                      avatar: const Icon(
                        Icons.check_circle,
                        size: 18,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }

  Color _getPlacementColor(String? relevance) {
    switch (relevance) {
      case 'High':
        return Colors.green;
      case 'Medium':
        return Colors.orange;
      case 'Low':
        return Colors.red;
      default:
        return Colors.blue;
    }
  }

  IconData _getLectureIcon(String type) {
    switch (type.toLowerCase()) {
      case 'video':
        return Icons.play_circle_outline;
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'quiz':
        return Icons.quiz;
      default:
        return Icons.article;
    }
  }
}

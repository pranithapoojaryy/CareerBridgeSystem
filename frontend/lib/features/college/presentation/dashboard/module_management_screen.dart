import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../student/data/learning_repository.dart';
import '../../../student/domain/learning_course.dart';
import '../../../student/domain/assessment.dart';
import 'assessment_builder_screen.dart';
import 'certificate_template_screen.dart';

class ModuleManagementScreen extends ConsumerStatefulWidget {
  final LearningCourse course;

  const ModuleManagementScreen({super.key, required this.course});

  @override
  ConsumerState<ModuleManagementScreen> createState() =>
      _ModuleManagementScreenState();
}

class _ModuleManagementScreenState
    extends ConsumerState<ModuleManagementScreen> {
  late List<CourseSection> _sections;

  @override
  void initState() {
    super.initState();
    _sections = List.from(widget.course.sections);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      appBar: AppBar(
        title: Text(
          'Manage Modules',
          style: GoogleFonts.outfit(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          // Certificate Template Preview Button
          Tooltip(
            message: 'View Certificate Template',
            child: IconButton(
              icon: const Icon(
                Icons.workspace_premium,
                color: Color(0xFFEAB308),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CertificateTemplatePreviewScreen(
                      courseTitle: widget.course.title,
                      providerName: widget.course.providerName,
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addModule,
        backgroundColor: AppTheme.primaryColor,
        icon: const Icon(Icons.add),
        label: const Text('Add Module'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Course Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      gradient: LinearGradient(
                        colors: [
                          Color(
                            (widget.course.title.hashCode * 0xFFFFFF).toInt(),
                          ).withValues(alpha: 0.7),
                          Color(
                            ((widget.course.title.hashCode + 1) * 0xFFFFFF)
                                .toInt(),
                          ).withValues(alpha: 0.5),
                        ],
                      ),
                    ),
                    child: const Icon(
                      Icons.school,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.course.title,
                          style: GoogleFonts.outfit(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${_sections.length} Modules • ${_sections.fold(0, (sum, s) => sum + s.lectures.length)} Lectures',
                          style: GoogleFonts.outfit(
                            fontSize: 13,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  FilledButton.icon(
                    onPressed: _saveChanges,
                    icon: const Icon(Icons.save, size: 18),
                    label: const Text('Save Changes'),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Modules List
            Expanded(
              child: _sections.isEmpty
                  ? _buildEmptyState()
                  : Column(
                      children: [
                        Expanded(
                          child: ReorderableListView.builder(
                            buildDefaultDragHandles: false,
                            onReorder: (oldIndex, newIndex) {
                              setState(() {
                                if (newIndex > oldIndex) newIndex--;
                                final item = _sections.removeAt(oldIndex);
                                _sections.insert(newIndex, item);
                              });
                            },
                            itemCount: _sections.length,
                            itemBuilder: (context, index) {
                              return _buildModuleCard(_sections[index], index);
                            },
                          ),
                        ),

                        // Final Exam Section
                        Container(
                          margin: const EdgeInsets.only(top: 24),
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppTheme.primaryColor.withValues(alpha: 0.1),
                                AppTheme.secondaryColor.withValues(alpha: 0.1),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: AppTheme.primaryColor.withValues(alpha: 0.3),
                              width: 2,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: AppTheme.primaryColor,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Icon(
                                      Icons.military_tech,
                                      color: Colors.white,
                                      size: 28,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Final Exam / Assessment',
                                          style: GoogleFonts.outfit(
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Unlocks after all modules completed • Auto-generates certificate',
                                          style: GoogleFonts.outfit(
                                            fontSize: 12,
                                            color: Colors.grey.shade600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  FilledButton.icon(
                                    onPressed: () => _createFinalExam(),
                                    icon: const Icon(Icons.add, size: 18),
                                    label: const Text('Create Final Exam'),
                                    style: FilledButton.styleFrom(
                                      backgroundColor: AppTheme.primaryColor,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 20,
                                        vertical: 16,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.info_outline,
                                      size: 20,
                                      color: AppTheme.primaryColor,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        'Final exam must have "Final Exam" or "Final Assessment" in the title to trigger automatic certificate generation',
                                        style: GoogleFonts.outfit(fontSize: 12),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.view_module_outlined,
              size: 64,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No Modules Yet',
            style: GoogleFonts.outfit(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add your first module to structure this course',
            style: GoogleFonts.outfit(color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _buildModuleCard(CourseSection section, int index) {
    return Container(
      key: ValueKey(section.id),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          key: PageStorageKey(section.id),
          leading: ReorderableDragStartListener(
            index: index,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(
                  '${index + 1}',
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ),
          title: Text(
            section.title,
            style: GoogleFonts.outfit(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              '${section.lectures.length} lectures',
              style: GoogleFonts.outfit(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
          ),
          trailing: PopupMenuButton(
            icon: const Icon(Icons.more_vert),
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'edit', child: Text('Edit Module')),
              const PopupMenuItem(
                value: 'add_lecture',
                child: Text('Add Lecture'),
              ),
              const PopupMenuItem(
                value: 'add_assessment',
                child: Text('Add Assessment'),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Text('Delete', style: TextStyle(color: Colors.red)),
              ),
            ],
            onSelected: (value) =>
                _handleModuleAction(value.toString(), section, index),
          ),
          children: [
            ...section.lectures.asMap().entries.map((entry) {
              final lectureIndex = entry.key;
              final lecture = entry.value;
              return _buildLectureItem(lecture, section, lectureIndex);
            }),
            // Add lecture button
            ListTile(
              leading: Icon(
                Icons.add_circle_outline,
                color: AppTheme.primaryColor,
              ),
              title: Text(
                'Add Lecture or Assessment',
                style: GoogleFonts.outfit(
                  color: AppTheme.primaryColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
              onTap: () => _showAddContentMenu(section),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLectureItem(
    CourseLecture lecture,
    CourseSection section,
    int index,
  ) {
    IconData icon;
    Color color;

    switch (lecture.type.toLowerCase()) {
      case 'video':
        icon = Icons.play_circle_outline;
        color = const Color(0xFFEF4444);
        break;
      case 'pdf':
      case 'article':
        icon = Icons.description_outlined;
        color = const Color(0xFF8B5CF6);
        break;
      case 'quiz':
      case 'assignment':
        icon = Icons.assignment_outlined;
        color = const Color(0xFF10B981);
        break;
      default:
        icon = Icons.circle;
        color = Colors.grey;
    }

    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 20, color: color),
      ),
      title: Text(lecture.title, style: GoogleFonts.outfit(fontSize: 14)),
      subtitle: Text(
        '${lecture.durationMinutes} mins • ${lecture.type}',
        style: GoogleFonts.outfit(fontSize: 11, color: Colors.grey.shade600),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.edit_outlined, size: 18),
            onPressed: () => _editLecture(section, lecture, index),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
            onPressed: () => _deleteLecture(section, index),
          ),
        ],
      ),
    );
  }

  void _handleModuleAction(String action, CourseSection section, int index) {
    switch (action) {
      case 'edit':
        _editModule(section, index);
        break;
      case 'add_lecture':
        _addLecture(section);
        break;
      case 'add_assessment':
        _showAssessmentBuilder(section);
        break;
      case 'delete':
        _deleteModule(index);
        break;
    }
  }

  void _showAddContentMenu(CourseSection section) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Add Content',
              style: GoogleFonts.outfit(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(
                Icons.play_circle_outline,
                color: Color(0xFFEF4444),
              ),
              title: const Text('Video Lecture'),
              onTap: () {
                Navigator.pop(context);
                _addLecture(section, type: 'video');
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.description_outlined,
                color: Color(0xFF8B5CF6),
              ),
              title: const Text('PDF/Article'),
              onTap: () {
                Navigator.pop(context);
                _addLecture(section, type: 'pdf');
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.quiz_outlined,
                color: Color(0xFF10B981),
              ),
              title: const Text('Quiz/Assessment'),
              onTap: () {
                Navigator.pop(context);
                _showAssessmentBuilder(section);
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.assignment_outlined,
                color: Color(0xFFF59E0B),
              ),
              title: const Text('Assignment'),
              onTap: () {
                Navigator.pop(context);
                _showAssessmentBuilder(
                  section,
                  type: AssessmentType.assignment,
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _addModule() {
    showDialog(
      context: context,
      builder: (context) {
        final controller = TextEditingController(
          text: 'Module ${_sections.length + 1}: ',
        );
        return AlertDialog(
          title: Text(
            'New Module',
            style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
          ),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              labelText: 'Module Title',
              hintText: 'e.g., Introduction to Programming',
              border: OutlineInputBorder(),
            ),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                if (controller.text.isNotEmpty) {
                  setState(() {
                    _sections.add(
                      CourseSection(
                        id: DateTime.now().millisecondsSinceEpoch.toString(),
                        title: controller.text,
                        lectures: [],
                      ),
                    );
                  });
                  Navigator.pop(context);
                }
              },
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
              ),
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  void _editModule(CourseSection section, int index) {
    showDialog(
      context: context,
      builder: (context) {
        final controller = TextEditingController(text: section.title);
        return AlertDialog(
          title: Text(
            'Edit Module',
            style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
          ),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              labelText: 'Module Title',
              border: OutlineInputBorder(),
            ),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                if (controller.text.isNotEmpty) {
                  setState(() {
                    _sections[index] = CourseSection(
                      id: section.id,
                      title: controller.text,
                      lectures: section.lectures,
                    );
                  });
                  Navigator.pop(context);
                }
              },
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
              ),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  void _deleteModule(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Delete Module?',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'This will delete all lectures and assessments in this module.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              setState(() => _sections.removeAt(index));
              Navigator.pop(context);
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _addLecture(CourseSection section, {String type = 'video'}) {
    showDialog(
      context: context,
      builder: (context) {
        final titleCtrl = TextEditingController();
        final durCtrl = TextEditingController();
        final urlCtrl = TextEditingController();
        final descCtrl = TextEditingController();
        String selectedType = type;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(
                'Add Learning Unit',
                style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
              ),
              content: SingleChildScrollView(
                child: SizedBox(
                  width: 500,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: titleCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Title *',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: selectedType,
                        items: const [
                          DropdownMenuItem(
                            value: 'video',
                            child: Text('Video'),
                          ),
                          DropdownMenuItem(
                            value: 'pdf',
                            child: Text('PDF/Article'),
                          ),
                          DropdownMenuItem(value: 'quiz', child: Text('Quiz')),
                          DropdownMenuItem(
                            value: 'assignment',
                            child: Text('Assignment'),
                          ),
                        ],
                        onChanged: (v) =>
                            setDialogState(() => selectedType = v!),
                        decoration: const InputDecoration(
                          labelText: 'Type',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: durCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Duration (mins)',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 16),
                      if (selectedType == 'video' || selectedType == 'pdf')
                        TextField(
                          controller: urlCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Content URL',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      if (selectedType == 'quiz' ||
                          selectedType == 'assignment')
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.blue.shade100),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.info_outline,
                                color: Colors.blue.shade700,
                                size: 20,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Assessment content is managed via the Assessment Builder.',
                                  style: GoogleFonts.outfit(
                                    fontSize: 13,
                                    color: Colors.blue.shade700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: descCtrl,
                        maxLines: 2,
                        decoration: const InputDecoration(
                          labelText: 'Description (Optional)',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () {
                    if (titleCtrl.text.isNotEmpty) {
                      setState(() {
                        final sectionIndex = _sections.indexOf(section);
                        _sections[sectionIndex].lectures.add(
                          CourseLecture(
                            id: DateTime.now().millisecondsSinceEpoch
                                .toString(),
                            title: titleCtrl.text,
                            type: selectedType,
                            durationMinutes: int.tryParse(durCtrl.text) ?? 10,
                            contentUrl: urlCtrl.text.isNotEmpty
                                ? urlCtrl.text
                                : '',
                            description: descCtrl.text.isNotEmpty
                                ? descCtrl.text
                                : null,
                          ),
                        );
                      });
                      Navigator.pop(context);
                    }
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                  ),
                  child: const Text('Add'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _editLecture(
    CourseSection section,
    CourseLecture lecture,
    int lectureIndex,
  ) {
    showDialog(
      context: context,
      builder: (context) {
        final titleCtrl = TextEditingController(text: lecture.title);
        final durCtrl = TextEditingController(
          text: lecture.durationMinutes.toString(),
        );
        final urlCtrl = TextEditingController(text: lecture.contentUrl);
        final descCtrl = TextEditingController(text: lecture.description ?? '');
        String selectedType = lecture.type;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(
                'Edit Learning Unit',
                style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
              ),
              content: SingleChildScrollView(
                child: SizedBox(
                  width: 500,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: titleCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Title *',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: selectedType,
                        items: const [
                          DropdownMenuItem(
                            value: 'video',
                            child: Text('Video'),
                          ),
                          DropdownMenuItem(
                            value: 'pdf',
                            child: Text('PDF/Article'),
                          ),
                          DropdownMenuItem(value: 'quiz', child: Text('Quiz')),
                          DropdownMenuItem(
                            value: 'assignment',
                            child: Text('Assignment'),
                          ),
                        ],
                        onChanged: (v) =>
                            setDialogState(() => selectedType = v!),
                        decoration: const InputDecoration(
                          labelText: 'Type',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: durCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Duration (mins)',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 16),
                      if (selectedType == 'video' || selectedType == 'pdf')
                        TextField(
                          controller: urlCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Content URL',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      if (selectedType == 'quiz' ||
                          selectedType == 'assignment')
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.blue.shade100),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.info_outline,
                                color: Colors.blue.shade700,
                                size: 20,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Assessment content is managed via the Assessment Builder.',
                                  style: GoogleFonts.outfit(
                                    fontSize: 13,
                                    color: Colors.blue.shade700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: descCtrl,
                        maxLines: 2,
                        decoration: const InputDecoration(
                          labelText: 'Description',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () {
                    if (titleCtrl.text.isNotEmpty) {
                      setState(() {
                        final sectionIndex = _sections.indexOf(section);
                        _sections[sectionIndex].lectures[lectureIndex] =
                            CourseLecture(
                              id: lecture.id,
                              title: titleCtrl.text,
                              type: selectedType,
                              durationMinutes: int.tryParse(durCtrl.text) ?? 10,
                              contentUrl: urlCtrl.text.isNotEmpty
                                  ? urlCtrl.text
                                  : '',
                              description: descCtrl.text.isNotEmpty
                                  ? descCtrl.text
                                  : null,
                            );
                      });
                      Navigator.pop(context);
                    }
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                  ),
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _deleteLecture(CourseSection section, int lectureIndex) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Delete Lecture?',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              setState(() {
                final sectionIndex = _sections.indexOf(section);
                _sections[sectionIndex].lectures.removeAt(lectureIndex);
              });
              Navigator.pop(context);
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showAssessmentBuilder(
    CourseSection section, {
    AssessmentType type = AssessmentType.quiz,
  }) {
    // Navigate to full assessment builder screen
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AssessmentBuilderScreen(
          section: section,
          assessmentType: type,
          onSave: (assessment) {
            // Save assessment and add to module
            _saveAssessment(section, assessment);
          },
        ),
      ),
    );
  }

  void _saveAssessment(CourseSection section, Assessment assessment) {
    setState(() {
      final sectionIndex = _sections.indexWhere((s) => s.id == section.id);

      // Calculate total points from questions
      final totalPoints = assessment.questions.fold(
        0,
        (sum, q) => sum + q.points,
      );

      // Create a lecture entry for this assessment
      // We store the assessment.id in contentUrl to reliably link them
      final assessmentLecture = CourseLecture(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: assessment.title,
        type: assessment.type == AssessmentType.quiz ? 'quiz' : 'assignment',
        durationMinutes: 0,
        contentUrl: assessment.id, // Store Assessment ID here!
        description:
            'Total Points: $totalPoints | Passing: ${assessment.passingCriteria}%',
      );

      if (sectionIndex != -1) {
        // Add to existing section
        _sections[sectionIndex].lectures.add(assessmentLecture);
      } else {
        // Create new section (for final exam)
        _sections.add(
          CourseSection(
            id: section.id,
            title: section.title,
            lectures: [assessmentLecture],
          ),
        );
      }
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Assessment "${assessment.title}" added successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _saveChanges() async {
    try {
      // Update course with new sections
      final updatedCourse = widget.course.copyWith(sections: _sections);
      await ref.read(learningRepositoryProvider).updateCourse(updatedCourse);

      // Refresh data from DB to get real UUIDs
      final freshCourse = await ref
          .read(learningRepositoryProvider)
          .getCourseById(widget.course.id);

      if (mounted) {
        setState(() {
          _sections = freshCourse.sections;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Changes saved successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _createFinalExam() async {
    try {
      // First, create a "Final Assessment" section in the database
      final repo = ref.read(learningRepositoryProvider);

      // Check if a "Final Assessment" section already exists
      CourseSection? finalSection;
      for (var section in _sections) {
        if (section.title == 'Final Assessment') {
          finalSection = section;
          break;
        }
      }

      // If it doesn't exist, create it
      if (finalSection == null) {
        // Add to local state first
        finalSection = CourseSection(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          title: 'Final Assessment',
          lectures: [],
        );

        setState(() {
          _sections.add(finalSection!);
        });

        // Save the updated course with the new section to database
        final updatedCourse = widget.course.copyWith(sections: _sections);
        await repo.updateCourse(updatedCourse);

        // Refresh the course to get the real UUID from database
        final freshCourse = await repo.getCourseById(widget.course.id);

        // Find the Final Assessment section with real ID
        for (var section in freshCourse.sections) {
          if (section.title == 'Final Assessment') {
            finalSection = section;
            break;
          }
        }

        // Update local state with fresh data
        setState(() {
          _sections = freshCourse.sections;
        });
      }

      // Now navigate to assessment builder with the real section
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AssessmentBuilderScreen(
              section: finalSection!,
              assessmentType: AssessmentType.quiz,
              onSave: (assessment) {
                // Verify it has "final" in the title
                if (!assessment.title.toLowerCase().contains('final')) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Warning: Assessment title should contain "Final Exam" or "Final Assessment" for auto-certificate generation',
                      ),
                      backgroundColor: Colors.orange,
                      duration: Duration(seconds: 4),
                    ),
                  );
                }
                Navigator.pop(context);
              },
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating Final Assessment section: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../student/data/learning_repository.dart';
import '../../../student/domain/learning_course.dart';

class EnhancedPathWizard extends ConsumerStatefulWidget {
  final LearningCourse? courseToEdit;
  const EnhancedPathWizard({super.key, this.courseToEdit});

  @override
  ConsumerState<EnhancedPathWizard> createState() => _EnhancedPathWizardState();
}

class _EnhancedPathWizardState extends ConsumerState<EnhancedPathWizard> {
  int _currentStep = 0;
  bool _isLoading = false;

  // Basic Info
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _codeController = TextEditingController();
  final _prereqController = TextEditingController();
  final _targetRoleController = TextEditingController();
  final _outcomesController = TextEditingController();
  final _priceController = TextEditingController();
  final _durationController = TextEditingController();

  String _selectedCategory = 'Technology';
  String _selectedDifficulty = 'Beginner';
  String _selectedPlacementRelevance = 'High';
  String _selectedDomainType = 'IT';
  List<String> _skillsGained = [];
  List<String> _tags = [];

  // IT/Management Metadata
  List<String> _programmingLanguages = [];
  List<String> _toolsFrameworks = [];
  bool _codePracticeRequired = false;
  int _miniProjectsCount = 0;
  bool _githubRequired = false;
  String? _systemDesignLevel;
  bool _labSessionsRequired = false;

  bool _caseStudiesRequired = false;
  bool _presentationRequired = false;
  bool _groupActivityRequired = false;
  String? _commSkillWeight;
  List<String> _industryExamples = [];

  // Curriculum
  List<CourseSection> _sections = [];

  final List<String> categories = [
    'Technology',
    'Business',
    'Design',
    'Finance',
    'Soft Skills',
  ];
  final List<String> difficulties = ['Beginner', 'Intermediate', 'Advanced'];
  final List<String> placementRelevance = ['High', 'Medium', 'Low'];
  final List<String> domainTypes = ['IT', 'Management', 'General'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: _buildAppBar(),
      body: _buildBody(),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      title: Text(
        widget.courseToEdit == null
            ? '✨ Create Learning Path'
            : '📝 Edit Learning Path',
        style: GoogleFonts.outfit(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 20,
        ),
      ),
      backgroundColor: AppTheme.primaryColor,
      elevation: 0,
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: Container(
          color: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: Row(
            children: List.generate(3, (index) {
              final steps = ['📋 Metadata', '📚 Curriculum', '🎯 Domain Info'];
              final isActive = index == _currentStep;
              final isCompleted = index < _currentStep;

              return Expanded(
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          vertical: 8,
                          horizontal: 12,
                        ),
                        decoration: BoxDecoration(
                          color: isActive
                              ? AppTheme.primaryColor
                              : isCompleted
                              ? Colors.green[50]
                              : Colors.grey[100],
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isActive
                                ? AppTheme.primaryColor
                                : isCompleted
                                ? Colors.green
                                : Colors.grey[300]!,
                            width: 2,
                          ),
                        ),
                        child: Text(
                          steps[index],
                          textAlign: TextAlign.center,
                          style: GoogleFonts.outfit(
                            color: isActive ? Colors.white : Colors.black87,
                            fontWeight: isActive
                                ? FontWeight.bold
                                : FontWeight.w500,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                    if (index < 2)
                      Container(
                        width: 20,
                        height: 2,
                        color: isCompleted ? Colors.green : Colors.grey[300],
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                      ),
                  ],
                ),
              );
            }),
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: _buildCurrentStep(),
      ),
    );
  }

  Widget _buildCurrentStep() {
    switch (_currentStep) {
      case 0:
        return _buildMetadataStep();
      case 1:
        return _buildCurriculumStep();
      case 2:
        return _buildDomainInfoStep();
      default:
        return const SizedBox();
    }
  }

  // Step 1: Metadata
  Widget _buildMetadataStep() {
    return Column(
      key: const ValueKey(0),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionCard(
          title: '📝 Basic Information',
          children: [
            _buildTextField(
              'Path Title',
              _titleController,
              'e.g., Java Backend Development',
            ),
            const SizedBox(height: 16),
            _buildTextField(
              'Curriculum Code',
              _codeController,
              'e.g., JR-2024-JAVA',
              maxLines: 1,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              'Description',
              _descController,
              'What will students learn?',
              maxLines: 4,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              'Target Role',
              _targetRoleController,
              'e.g., Backend Developer, Full Stack Engineer',
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildDropdown(
                    'Category',
                    _selectedCategory,
                    categories,
                    (val) {
                      setState(() => _selectedCategory = val!);
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildDropdown(
                    'Difficulty',
                    _selectedDifficulty,
                    difficulties,
                    (val) {
                      setState(() => _selectedDifficulty = val!);
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 24),
        _buildSectionCard(
          title: '🎯 Curriculum Planning',
          children: [
            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    'Duration (Weeks)',
                    _durationController,
                    '8',
                    isNumber: true,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildDropdown(
                    'Placement Relevance',
                    _selectedPlacementRelevance,
                    placementRelevance,
                    (val) {
                      setState(() => _selectedPlacementRelevance = val!);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildTextField(
              'Prerequisites',
              _prereqController,
              'What should students know before?',
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              'Learning Outcomes',
              _outcomesController,
              'What will they achieve?',
              maxLines: 3,
            ),
          ],
        ),
        const SizedBox(height: 24),
        _buildSectionCard(
          title: '💰 Pricing & Skills',
          children: [
            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    'Price (₹)',
                    _priceController,
                    '0',
                    isNumber: true,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildDropdown(
                    'Domain Type',
                    _selectedDomainType,
                    domainTypes,
                    (val) {
                      setState(() => _selectedDomainType = val!);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildChipInput(
              'Skills Gained',
              _skillsGained,
              'Java, SQL, Spring Boot...',
            ),
            const SizedBox(height: 16),
            _buildChipInput(
              'Tags',
              _tags,
              'Programming, Backend, Enterprise...',
            ),
          ],
        ),
      ],
    );
  }

  // Step 2: Curriculum
  Widget _buildCurriculumStep() {
    return Column(
      key: const ValueKey(1),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionCard(
          title: '📚 Weeks / Modules',
          trailing: IconButton(
            onPressed: _addSection,
            icon: const Icon(
              Icons.add_circle,
              color: AppTheme.primaryColor,
              size: 28,
            ),
            tooltip: 'Add Week',
          ),
          children: [
            if (_sections.isEmpty)
              Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.book_outlined,
                        size: 48,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'No modules yet',
                        style: GoogleFonts.outfit(
                          color: Colors.grey[600],
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton.icon(
                        onPressed: _addSection,
                        icon: const Icon(Icons.add),
                        label: const Text('Add First Week'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ..._sections.asMap().entries.map(
              (entry) => _buildSectionTile(entry.key),
            ),
          ],
        ),
      ],
    );
  }

  // Step 3: Domain-specific
  Widget _buildDomainInfoStep() {
    return Column(
      key: const ValueKey(2),
      children: [
        if (_selectedDomainType == 'IT') _buildITFields(),
        if (_selectedDomainType == 'Management') _buildManagementFields(),
        if (_selectedDomainType == 'General')
          Container(
            padding: const EdgeInsets.all(48),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue[50]!, Colors.purple[50]!],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Icon(Icons.check_circle, size: 64, color: Colors.green[600]),
                const SizedBox(height: 16),
                Text(
                  'All Set!',
                  style: GoogleFonts.outfit(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'General curriculum doesn\'t require domain-specific fields.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildITFields() {
    return _buildSectionCard(
      title: '💻 IT-Specific Requirements',
      children: [
        _buildChipInput(
          'Programming Languages',
          _programmingLanguages,
          'Java, Python, JavaScript...',
        ),
        const SizedBox(height: 16),
        _buildChipInput(
          'Tools & Frameworks',
          _toolsFrameworks,
          'Spring Boot, React, Docker...',
        ),
        const SizedBox(height: 16),
        _buildSwitch('Code Practice Required', _codePracticeRequired, (val) {
          setState(() => _codePracticeRequired = val);
        }),
        _buildSwitch('GitHub Submission Required', _githubRequired, (val) {
          setState(() => _githubRequired = val);
        }),
        _buildSwitch('Lab Sessions Required', _labSessionsRequired, (val) {
          setState(() => _labSessionsRequired = val);
        }),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildTextField(
                'Mini Projects Count',
                TextEditingController(text: _miniProjectsCount.toString()),
                '0',
                isNumber: true,
                onChanged: (val) {
                  _miniProjectsCount = int.tryParse(val) ?? 0;
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildDropdown(
                'System Design Level',
                _systemDesignLevel,
                ['Basic', 'Intermediate', 'Advanced'],
                (val) {
                  setState(() => _systemDesignLevel = val);
                },
                allowNull: true,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildManagementFields() {
    return _buildSectionCard(
      title: '📊 Management-Specific Requirements',
      children: [
        _buildSwitch('Case Studies Required', _caseStudiesRequired, (val) {
          setState(() => _caseStudiesRequired = val);
        }),
        _buildSwitch('Presentation Required', _presentationRequired, (val) {
          setState(() => _presentationRequired = val);
        }),
        _buildSwitch('Group Activity Required', _groupActivityRequired, (val) {
          setState(() => _groupActivityRequired = val);
        }),
        const SizedBox(height: 16),
        _buildDropdown(
          'Communication Skill Weight',
          _commSkillWeight,
          ['High', 'Medium', 'Low'],
          (val) {
            setState(() => _commSkillWeight = val);
          },
          allowNull: true,
        ),
        const SizedBox(height: 16),
        _buildChipInput(
          'Industry Examples',
          _industryExamples,
          'Marketing Strategy, Product Launch...',
        ),
      ],
    );
  }

  // Helper Widgets
  Widget _buildSectionCard({
    required String title,
    Widget? trailing,
    required List<Widget> children,
  }) {
    return Container(
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
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
              if (trailing != null) trailing,
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller,
    String hint, {
    int maxLines = 1,
    bool isNumber = false,
    Function(String)? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.grey[800],
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: isNumber ? TextInputType.number : TextInputType.text,
          onChanged: onChanged,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.outfit(color: Colors.grey[400]),
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
              borderSide: const BorderSide(
                color: AppTheme.primaryColor,
                width: 2,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
          ),
          style: GoogleFonts.outfit(fontSize: 14),
        ),
      ],
    );
  }

  Widget _buildDropdown(
    String label,
    String? value,
    List<String> items,
    Function(String?) onChanged, {
    bool allowNull = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.grey[800],
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: value,
          decoration: InputDecoration(
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
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
          ),
          items: [
            if (allowNull)
              const DropdownMenuItem(value: null, child: Text('None')),
            ...items.map(
              (item) => DropdownMenuItem(value: item, child: Text(item)),
            ),
          ],
          onChanged: onChanged,
          style: GoogleFonts.outfit(fontSize: 14, color: Colors.black87),
        ),
      ],
    );
  }

  Widget _buildChipInput(String label, List<String> items, String hint) {
    final controller = TextEditingController();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.grey[800],
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ...items.map(
              (item) => Chip(
                label: Text(item, style: GoogleFonts.outfit(fontSize: 12)),
                deleteIcon: const Icon(Icons.close, size: 16),
                onDeleted: () {
                  setState(() => items.remove(item));
                },
                backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
                deleteIconColor: AppTheme.primaryColor,
              ),
            ),
            SizedBox(
              width: 200,
              child: TextField(
                controller: controller,
                decoration: InputDecoration(
                  hintText: hint,
                  hintStyle: GoogleFonts.outfit(
                    fontSize: 12,
                    color: Colors.grey[400],
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.add, size: 18),
                    onPressed: () {
                      if (controller.text.isNotEmpty) {
                        setState(() {
                          items.add(controller.text);
                          controller.clear();
                        });
                      }
                    },
                  ),
                ),
                style: GoogleFonts.outfit(fontSize: 12),
                onSubmitted: (val) {
                  if (val.isNotEmpty) {
                    setState(() {
                      items.add(val);
                      controller.clear();
                    });
                  }
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSwitch(String label, bool value, Function(bool) onChanged) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.grey[800],
          ),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeColor: AppTheme.primaryColor,
        ),
      ],
    );
  }

  Widget _buildSectionTile(int index) {
    final section = _sections[index];
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey[200]!),
      ),
      child: ExpansionTile(
        title: Text(
          'Week ${index + 1}: ${section.title}',
          style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          '${section.lectures.length} learning units',
          style: GoogleFonts.outfit(fontSize: 12),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline, color: Colors.red),
          onPressed: () => setState(() => _sections.removeAt(index)),
        ),
        children: [
          ...section.lectures.asMap().entries.map(
            (e) => ListTile(
              dense: true,
              title: Text(
                e.value.title,
                style: GoogleFonts.outfit(fontSize: 13),
              ),
              subtitle: Text(
                '${e.value.type} • ${e.value.durationMinutes} min',
                style: GoogleFonts.outfit(fontSize: 11),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          if (_currentStep > 0)
            Expanded(
              child: OutlinedButton(
                onPressed: () => setState(() => _currentStep--),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text('← Back', style: GoogleFonts.outfit(fontSize: 16)),
              ),
            ),
          if (_currentStep > 0) const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton(
              onPressed: _isLoading ? null : _handleNext,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Text(
                      _currentStep == 2 ? '✨ Publish Path' : 'Next →',
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  void _handleNext() {
    if (_currentStep < 2) {
      setState(() => _currentStep++);
    } else {
      _savePath();
    }
  }

  void _addSection() {
    // Placeholder - implement dialog to add section
    setState(() {
      _sections.add(
        CourseSection(
          id: DateTime.now().toString(),
          title: 'Week ${_sections.length + 1}',
          lectures: [],
        ),
      );
    });
  }

  Future<void> _savePath() async {
    // Implementation similar to original
    setState(() => _isLoading = true);
    // TODO: Save to repository
    await Future.delayed(const Duration(seconds: 1));
    setState(() => _isLoading = false);
    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Path published successfully!',
            style: GoogleFonts.outfit(),
          ),
          backgroundColor: Colors.green,
        ),
      );
    }
  }
}

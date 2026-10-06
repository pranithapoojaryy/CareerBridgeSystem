import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../student/data/learning_repository.dart';
import '../../../student/domain/learning_course.dart';

class PathCreationWizard extends ConsumerStatefulWidget {
  final LearningCourse? courseToEdit;
  const PathCreationWizard({super.key, this.courseToEdit});

  @override
  ConsumerState<PathCreationWizard> createState() => _PathCreationWizardState();
}

class _PathCreationWizardState extends ConsumerState<PathCreationWizard> {
  int _currentStep = 0;
  bool _isLoading = false;

  // Step 1: Basic Info & Metadata
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _priceController = TextEditingController();
  final _mentorNameController = TextEditingController();
  final _curriculumCodeController = TextEditingController();
  final _targetRoleController = TextEditingController();
  final _durationWeeksController = TextEditingController();

  String _providerName = ''; // Auto-filled from user profile
  String _selectedCategory = 'Technology';
  String _selectedDifficulty = 'Beginner';
  String _selectedPlacementRelevance = 'High';

  // Step 2: Domain Selection
  String? _domainType;

  // IT Metadata - Dynamic fields
  List<String> _programmingLanguages = [];
  List<String> _toolsFrameworks = [];
  final _languageInputController = TextEditingController();
  final _frameworkInputController = TextEditingController();
  bool _codePracticeRequired = false;
  int _miniProjectsCount = 0;
  bool _githubSubmissionRequired = false;
  String _systemDesignLevel = 'Basic';
  bool _labSessionsRequired = false;

  // Management Metadata
  bool _caseStudiesRequired = false;
  bool _presentationRequired = false;
  bool _groupActivityRequired = false;
  String _communicationSkillWeight = 'Medium';
  bool _rolePlayRequired = false;
  bool _reportSubmissionRequired = false;

  // Step 3: Learning Outcomes - Dynamic skills
  final _prerequisitesController = TextEditingController();
  final _learningOutcomesController = TextEditingController();
  List<String> _skillsGained = [];
  final _skillInputController = TextEditingController();

  // Step 4: Curriculum
  List<CourseSection> _sections = [];

  // Suggestions
  final List<String> _languageSuggestions = [
    'Java',
    'Python',
    'JavaScript',
    'TypeScript',
    'C++',
    'C#',
    'Go',
    'Rust',
    'Kotlin',
    'Swift',
  ];
  final List<String> _frameworkSuggestions = [
    'Spring Boot',
    'Django',
    'Flask',
    'React',
    'Angular',
    'Vue.js',
    'Node.js',
    'Express',
    'Next.js',
    'Laravel',
    'FastAPI',
    'Docker',
    'Kubernetes',
  ];
  final List<String> _skillSuggestions = [
    'Communication',
    'Leadership',
    'Problem Solving',
    'Critical Thinking',
    'Teamwork',
    'Time Management',
    'Adaptability',
    'Analytical Skills',
    'Project Management',
    'Presentation Skills',
    'Negotiation',
    'Decision Making',
  ];

  // Data
  final List<String> _categories = [
    'Technology',
    'Business',
    'Design',
    'Finance',
    'Soft Skills',
  ];
  final List<String> _difficulties = ['Beginner', 'Intermediate', 'Advanced'];

  @override
  void initState() {
    super.initState();
    _fetchUserProfile();
    if (widget.courseToEdit != null) {
      _initEditMode();
    }
  }

  Future<void> _fetchUserProfile() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        final profile = await Supabase.instance.client
            .from('profiles')
            .select('full_name, role, organization_id')
            .eq('id', user.id)
            .single();

        setState(() {
          // Use full_name as the primary provider name
          _providerName = profile['full_name'] ?? 'CareerBridge';

          // If we wanted to be more specific, we could fetch organization name using organization_id
          // but for now, full_name is a safe and existing field.
        });
      }
    } catch (e) {
      setState(() => _providerName = 'CareerBridge');
    }
  }

  void _initEditMode() {
    final c = widget.courseToEdit!;
    _titleController.text = c.title;
    _descController.text = c.description;
    _priceController.text = c.price.toString();
    _curriculumCodeController.text = c.curriculumCode ?? '';
    _targetRoleController.text = c.targetRole ?? '';
    _durationWeeksController.text = c.estimatedDurationWeeks?.toString() ?? '';
    _prerequisitesController.text = c.prerequisites ?? '';
    _learningOutcomesController.text = c.learningOutcomes ?? '';

    _selectedCategory = _categories.contains(c.category)
        ? c.category
        : 'Technology';
    _selectedDifficulty = _difficulties.contains(c.difficulty)
        ? c.difficulty
        : 'Beginner';
    _selectedPlacementRelevance = c.placementRelevance ?? 'High';
    _domainType = c.domainType;
    _skillsGained = List.from(c.skillsGained);
    _sections = List.from(c.sections);

    if (c.itMetadata != null) {
      _programmingLanguages = List.from(c.itMetadata!.programmingLanguages);
      _toolsFrameworks = List.from(c.itMetadata!.toolsFrameworks);
      _codePracticeRequired = c.itMetadata!.codePracticeRequired;
      _miniProjectsCount = c.itMetadata!.miniProjectsCount;
      _githubSubmissionRequired = c.itMetadata!.githubSubmissionRequired;
      _systemDesignLevel = c.itMetadata!.systemDesignLevel ?? 'Basic';
      _labSessionsRequired = c.itMetadata!.labSessionsRequired;
    }

    if (c.managementMetadata != null) {
      _caseStudiesRequired = c.managementMetadata!.caseStudiesRequired;
      _presentationRequired = c.managementMetadata!.presentationRequired;
      _groupActivityRequired = c.managementMetadata!.groupActivityRequired;
      _communicationSkillWeight =
          c.managementMetadata!.communicationSkillWeight ?? 'Medium';
      _rolePlayRequired = c.managementMetadata!.rolePlayRequired;
      _reportSubmissionRequired =
          c.managementMetadata!.reportSubmissionRequired;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.courseToEdit != null;
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      appBar: AppBar(
        title: Text(
          isEditing ? 'Edit Learning Path' : 'Create New Path',
          style: GoogleFonts.outfit(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: LinearProgressIndicator(
            value: (_currentStep + 1) / 5, // 5 steps now
            backgroundColor: Colors.grey[100],
            valueColor: const AlwaysStoppedAnimation<Color>(
              AppTheme.primaryColor,
            ),
          ),
        ),
      ),
      body: Stepper(
        type: StepperType.horizontal,
        currentStep: _currentStep,
        onStepContinue: _nextStep,
        onStepCancel: _prevStep,
        elevation: 0,
        controlsBuilder: (context, details) {
          return Padding(
            padding: const EdgeInsets.only(top: 32),
            child: Row(
              children: [
                Expanded(
                  child: FilledButton(
                    onPressed: _isLoading ? null : details.onStepContinue,
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      backgroundColor: AppTheme.primaryColor,
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
                            _currentStep == 4
                                ? (isEditing
                                      ? 'Update Course'
                                      : 'Publish Course')
                                : 'Continue',
                            style: GoogleFonts.outfit(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                  ),
                ),
                if (_currentStep > 0) ...[
                  const SizedBox(width: 16),
                  OutlinedButton(
                    onPressed: details.onStepCancel,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        vertical: 18,
                        horizontal: 24,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Back',
                      style: GoogleFonts.outfit(color: Colors.grey.shade700),
                    ),
                  ),
                ],
              ],
            ),
          );
        },
        steps: [
          Step(
            title: const Text('Basics'),
            content: _buildBasicInfoStep(),
            isActive: _currentStep >= 0,
            state: _currentStep > 0 ? StepState.complete : StepState.editing,
          ),
          Step(
            title: const Text('Domain'),
            content: _buildDomainStep(),
            isActive: _currentStep >= 1,
            state: _currentStep > 1 ? StepState.complete : StepState.editing,
          ),
          Step(
            title: const Text('Outcomes'),
            content: _buildOutcomesStep(),
            isActive: _currentStep >= 2,
            state: _currentStep > 2 ? StepState.complete : StepState.editing,
          ),
          Step(
            title: const Text('Curriculum'),
            content: _buildCurriculumStep(),
            isActive: _currentStep >= 3,
            state: _currentStep > 3 ? StepState.complete : StepState.editing,
          ),
          Step(
            title: const Text('Review'),
            content: _buildReviewStep(),
            isActive: _currentStep >= 4,
          ),
        ],
      ),
    );
  }

  // STEP 1: Enhanced Basic Info
  Widget _buildBasicInfoStep() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionCard(
            title: 'Course Information',
            icon: Icons.book_outlined,
            children: [
              TextField(
                controller: _titleController,
                decoration: _inputDecoration(
                  label: 'Course Title *',
                  hint: 'e.g., Full Stack Java Development',
                  icon: Icons.title,
                ),
              ),
              const SizedBox(height: 20),

              TextField(
                controller: _descController,
                maxLines: 4,
                decoration: _inputDecoration(
                  label: 'Description *',
                  hint: 'What will students learn?',
                  icon: Icons.description_outlined,
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          _buildSectionCard(
            title: 'Course Details',
            icon: Icons.settings_outlined,
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _curriculumCodeController,
                      decoration: _inputDecoration(
                        label: 'Curriculum Code',
                        hint: 'CS-101',
                        icon: Icons.code,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _selectedDifficulty,
                      items: _difficulties
                          .map(
                            (d) => DropdownMenuItem(value: d, child: Text(d)),
                          )
                          .toList(),
                      onChanged: (v) =>
                          setState(() => _selectedDifficulty = v!),
                      decoration: _inputDecoration(
                        label: 'Difficulty',
                        icon: Icons.signal_cellular_alt,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _selectedCategory,
                      items: _categories
                          .map(
                            (c) => DropdownMenuItem(value: c, child: Text(c)),
                          )
                          .toList(),
                      onChanged: (v) => setState(() => _selectedCategory = v!),
                      decoration: _inputDecoration(
                        label: 'Category',
                        icon: Icons.category_outlined,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextField(
                      controller: _durationWeeksController,
                      keyboardType: TextInputType.number,
                      decoration: _inputDecoration(
                        label: 'Duration (Weeks)',
                        hint: '8',
                        icon: Icons.calendar_today_outlined,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _targetRoleController,
                      decoration: _inputDecoration(
                        label: 'Target Role',
                        hint: 'Software Engineer',
                        icon: Icons.work_outline,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _selectedPlacementRelevance,
                      items: ['High', 'Medium', 'Low']
                          .map(
                            (r) => DropdownMenuItem(value: r, child: Text(r)),
                          )
                          .toList(),
                      onChanged: (v) =>
                          setState(() => _selectedPlacementRelevance = v!),
                      decoration: _inputDecoration(
                        label: 'Placement Relevance',
                        icon: Icons.trending_up,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 20),

          _buildSectionCard(
            title: 'Faculty & Pricing',
            icon: Icons.person_outline,
            children: [
              TextField(
                controller: _mentorNameController,
                decoration: _inputDecoration(
                  label: 'Mentor/Professor Name',
                  hint: 'Optional',
                  icon: Icons.school_outlined,
                ),
              ),
              const SizedBox(height: 20),

              Row(
                children: [
                  Expanded(
                    child: TextField(
                      enabled: false,
                      decoration:
                          _inputDecoration(
                            label: 'Provider',
                            icon: Icons.business_outlined,
                          ).copyWith(
                            hintText: _providerName,
                            hintStyle: const TextStyle(color: Colors.black87),
                          ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextField(
                      controller: _priceController,
                      keyboardType: TextInputType.number,
                      decoration: _inputDecoration(
                        label: 'Price (₹)',
                        hint: '0 for Free',
                        icon: Icons.currency_rupee,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // STEP 2: Domain Selection with dynamic inputs
  Widget _buildDomainStep() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionCard(
            title: 'Select Course Domain',
            icon: Icons.category,
            children: [
              ...['IT', 'Management', 'General'].map(
                (domain) => RadioListTile<String>(
                  title: Text(
                    domain,
                    style: GoogleFonts.outfit(fontWeight: FontWeight.w500),
                  ),
                  value: domain,
                  groupValue: _domainType,
                  onChanged: (v) => setState(() => _domainType = v),
                  activeColor: AppTheme.primaryColor,
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          if (_domainType == 'IT') _buildITMetadataForm(),
          if (_domainType == 'Management') _buildManagementMetadataForm(),
          if (_domainType == 'General')
            _buildSectionCard(
              title: 'General Course',
              icon: Icons.info_outline,
              children: [
                Text(
                  'General courses don\'t require domain-specific metadata.',
                  style: GoogleFonts.outfit(color: Colors.grey.shade600),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildITMetadataForm() {
    return Column(
      children: [
        _buildSectionCard(
          title: 'Programming Languages',
          icon: Icons.code,
          children: [
            TextField(
              controller: _languageInputController,
              decoration:
                  _inputDecoration(
                    label: 'Add Language',
                    hint: 'Type or select from suggestions',
                    icon: Icons.add,
                  ).copyWith(
                    suffixIcon: IconButton(
                      icon: const Icon(
                        Icons.add_circle,
                        color: AppTheme.primaryColor,
                      ),
                      onPressed: () {
                        if (_languageInputController.text.isNotEmpty) {
                          setState(() {
                            _programmingLanguages.add(
                              _languageInputController.text,
                            );
                            _languageInputController.clear();
                          });
                        }
                      },
                    ),
                  ),
              onSubmitted: (value) {
                if (value.isNotEmpty) {
                  setState(() {
                    _programmingLanguages.add(value);
                    _languageInputController.clear();
                  });
                }
              },
            ),
            const SizedBox(height: 12),
            if (_programmingLanguages.isNotEmpty)
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _programmingLanguages
                    .map(
                      (lang) => Chip(
                        label: Text(lang),
                        deleteIcon: const Icon(Icons.close, size: 18),
                        onDeleted: () =>
                            setState(() => _programmingLanguages.remove(lang)),
                        backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
                        side: BorderSide(
                          color: AppTheme.primaryColor.withValues(alpha: 0.3),
                        ),
                      ),
                    )
                    .toList(),
              ),
            const SizedBox(height: 12),
            Text(
              'Suggestions:',
              style: GoogleFonts.outfit(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: _languageSuggestions
                  .map(
                    (lang) => ActionChip(
                      label: Text(lang, style: const TextStyle(fontSize: 11)),
                      onPressed: () {
                        if (!_programmingLanguages.contains(lang)) {
                          setState(() => _programmingLanguages.add(lang));
                        }
                      },
                      backgroundColor: Colors.grey.shade100,
                    ),
                  )
                  .toList(),
            ),
          ],
        ),

        const SizedBox(height: 20),

        _buildSectionCard(
          title: 'Tools & Frameworks',
          icon: Icons.build_outlined,
          children: [
            TextField(
              controller: _frameworkInputController,
              decoration:
                  _inputDecoration(
                    label: 'Add Framework/Tool',
                    hint: 'Spring Boot, Docker, etc.',
                    icon: Icons.add,
                  ).copyWith(
                    suffixIcon: IconButton(
                      icon: const Icon(
                        Icons.add_circle,
                        color: AppTheme.primaryColor,
                      ),
                      onPressed: () {
                        if (_frameworkInputController.text.isNotEmpty) {
                          setState(() {
                            _toolsFrameworks.add(
                              _frameworkInputController.text,
                            );
                            _frameworkInputController.clear();
                          });
                        }
                      },
                    ),
                  ),
              onSubmitted: (value) {
                if (value.isNotEmpty) {
                  setState(() {
                    _toolsFrameworks.add(value);
                    _frameworkInputController.clear();
                  });
                }
              },
            ),
            const SizedBox(height: 12),
            if (_toolsFrameworks.isNotEmpty)
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _toolsFrameworks
                    .map(
                      (tool) => Chip(
                        label: Text(tool),
                        deleteIcon: const Icon(Icons.close, size: 18),
                        onDeleted: () =>
                            setState(() => _toolsFrameworks.remove(tool)),
                        backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
                        side: BorderSide(
                          color: AppTheme.primaryColor.withValues(alpha: 0.3),
                        ),
                      ),
                    )
                    .toList(),
              ),
            const SizedBox(height: 12),
            Text(
              'Suggestions:',
              style: GoogleFonts.outfit(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: _frameworkSuggestions
                  .map(
                    (fw) => ActionChip(
                      label: Text(fw, style: const TextStyle(fontSize: 11)),
                      onPressed: () {
                        if (!_toolsFrameworks.contains(fw)) {
                          setState(() => _toolsFrameworks.add(fw));
                        }
                      },
                      backgroundColor: Colors.grey.shade100,
                    ),
                  )
                  .toList(),
            ),
          ],
        ),

        const SizedBox(height: 20),

        _buildSectionCard(
          title: 'Additional Requirements',
          icon: Icons.checklist,
          children: [
            SwitchListTile(
              title: Text(
                'Code Practice Required',
                style: GoogleFonts.outfit(),
              ),
              value: _codePracticeRequired,
              onChanged: (v) => setState(() => _codePracticeRequired = v),
              activeColor: AppTheme.primaryColor,
            ),
            SwitchListTile(
              title: Text(
                'GitHub Submission Required',
                style: GoogleFonts.outfit(),
              ),
              value: _githubSubmissionRequired,
              onChanged: (v) => setState(() => _githubSubmissionRequired = v),
              activeColor: AppTheme.primaryColor,
            ),
            SwitchListTile(
              title: Text('Lab Sessions Required', style: GoogleFonts.outfit()),
              value: _labSessionsRequired,
              onChanged: (v) => setState(() => _labSessionsRequired = v),
              activeColor: AppTheme.primaryColor,
            ),
            const SizedBox(height: 12),
            TextField(
              keyboardType: TextInputType.number,
              onChanged: (v) => _miniProjectsCount = int.tryParse(v) ?? 0,
              decoration: _inputDecoration(
                label: 'Number of Mini Projects',
                hint: '2',
                icon: Icons.folder_outlined,
              ),
            ),
            const SizedBox(height: 20),
            DropdownButtonFormField<String>(
              value: _systemDesignLevel,
              items: [
                'Basic',
                'Intermediate',
                'Advanced',
              ].map((l) => DropdownMenuItem(value: l, child: Text(l))).toList(),
              onChanged: (v) => setState(() => _systemDesignLevel = v!),
              decoration: _inputDecoration(
                label: 'System Design Level',
                icon: Icons.architecture_outlined,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildManagementMetadataForm() {
    return _buildSectionCard(
      title: 'Management Course Requirements',
      icon: Icons.business_center_outlined,
      children: [
        SwitchListTile(
          title: Text('Case Studies Required', style: GoogleFonts.outfit()),
          value: _caseStudiesRequired,
          onChanged: (v) => setState(() => _caseStudiesRequired = v),
          activeColor: AppTheme.primaryColor,
        ),
        SwitchListTile(
          title: Text('Presentation Required', style: GoogleFonts.outfit()),
          value: _presentationRequired,
          onChanged: (v) => setState(() => _presentationRequired = v),
          activeColor: AppTheme.primaryColor,
        ),
        SwitchListTile(
          title: Text('Group Activity Required', style: GoogleFonts.outfit()),
          value: _groupActivityRequired,
          onChanged: (v) => setState(() => _groupActivityRequired = v),
          activeColor: AppTheme.primaryColor,
        ),
        SwitchListTile(
          title: Text('Role Play Required', style: GoogleFonts.outfit()),
          value: _rolePlayRequired,
          onChanged: (v) => setState(() => _rolePlayRequired = v),
          activeColor: AppTheme.primaryColor,
        ),
        SwitchListTile(
          title: Text(
            'Report Submission Required',
            style: GoogleFonts.outfit(),
          ),
          value: _reportSubmissionRequired,
          onChanged: (v) => setState(() => _reportSubmissionRequired = v),
          activeColor: AppTheme.primaryColor,
        ),
        const SizedBox(height: 20),
        DropdownButtonFormField<String>(
          value: _communicationSkillWeight,
          items: [
            'High',
            'Medium',
            'Low',
          ].map((w) => DropdownMenuItem(value: w, child: Text(w))).toList(),
          onChanged: (v) => setState(() => _communicationSkillWeight = v!),
          decoration: _inputDecoration(
            label: 'Communication Skill Weight',
            icon: Icons.record_voice_over,
          ),
        ),
      ],
    );
  }

  // STEP 3: Learning Outcomes with dynamic skills
  Widget _buildOutcomesStep() {
    return SingleChildScrollView(
      child: Column(
        children: [
          _buildSectionCard(
            title: 'Prerequisites',
            icon: Icons.check_circle_outline,
            children: [
              TextField(
                controller: _prerequisitesController,
                maxLines: 3,
                decoration: _inputDecoration(
                  label: 'Prerequisites',
                  hint: 'What should students know before starting?',
                  icon: Icons.list_alt,
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          _buildSectionCard(
            title: 'Learning Outcomes',
            icon: Icons.emoji_events_outlined,
            children: [
              TextField(
                controller: _learningOutcomesController,
                maxLines: 4,
                decoration: _inputDecoration(
                  label: 'Learning Outcomes',
                  hint: 'What will students achieve?',
                  icon: Icons.school_outlined,
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          _buildSectionCard(
            title: 'Skills Students Will Gain',
            icon: Icons.star_outline,
            children: [
              TextField(
                controller: _skillInputController,
                decoration:
                    _inputDecoration(
                      label: 'Add Skill',
                      hint: 'Type or select from suggestions',
                      icon: Icons.add,
                    ).copyWith(
                      suffixIcon: IconButton(
                        icon: const Icon(
                          Icons.add_circle,
                          color: AppTheme.primaryColor,
                        ),
                        onPressed: () {
                          if (_skillInputController.text.isNotEmpty) {
                            setState(() {
                              _skillsGained.add(_skillInputController.text);
                              _skillInputController.clear();
                            });
                          }
                        },
                      ),
                    ),
                onSubmitted: (value) {
                  if (value.isNotEmpty) {
                    setState(() {
                      _skillsGained.add(value);
                      _skillInputController.clear();
                    });
                  }
                },
              ),
              const SizedBox(height: 12),
              if (_skillsGained.isNotEmpty)
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _skillsGained
                      .map(
                        (skill) => Chip(
                          label: Text(skill),
                          deleteIcon: const Icon(Icons.close, size: 18),
                          onDeleted: () =>
                              setState(() => _skillsGained.remove(skill)),
                          backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
                          side: BorderSide(
                            color: AppTheme.primaryColor.withValues(alpha: 0.3),
                          ),
                        ),
                      )
                      .toList(),
                ),
              const SizedBox(height: 12),
              Text(
                'Combine domain skills with soft skills',
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  ..._programmingLanguages.map(
                    (lang) => ActionChip(
                      label: Text(lang, style: const TextStyle(fontSize: 11)),
                      onPressed: () {
                        if (!_skillsGained.contains(lang)) {
                          setState(() => _skillsGained.add(lang));
                        }
                      },
                      backgroundColor: Colors.blue.shade50,
                    ),
                  ),
                  ..._toolsFrameworks.map(
                    (tool) => ActionChip(
                      label: Text(tool, style: const TextStyle(fontSize: 11)),
                      onPressed: () {
                        if (!_skillsGained.contains(tool)) {
                          setState(() => _skillsGained.add(tool));
                        }
                      },
                      backgroundColor: Colors.green.shade50,
                    ),
                  ),
                  ..._skillSuggestions.map(
                    (skill) => ActionChip(
                      label: Text(skill, style: const TextStyle(fontSize: 11)),
                      onPressed: () {
                        if (!_skillsGained.contains(skill)) {
                          setState(() => _skillsGained.add(skill));
                        }
                      },
                      backgroundColor: Colors.orange.shade50,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // STEP 4: Curriculum Builder (same as before)
  Widget _buildCurriculumStep() {
    return Column(
      children: [
        if (_sections.isEmpty)
          _buildSectionCard(
            title: 'Build Your Curriculum',
            icon: Icons.library_books_outlined,
            children: [
              Column(
                children: [
                  Icon(Icons.menu_book, size: 64, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  Text(
                    'No modules yet',
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Break down your course into modules',
                    style: GoogleFonts.outfit(
                      color: Colors.grey.shade600,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: _addSection,
                    icon: const Icon(Icons.add),
                    label: const Text('Add First Module'),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                    ),
                  ),
                ],
              ),
            ],
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _sections.length + 1,
            itemBuilder: (context, index) {
              if (index == _sections.length) {
                return Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: OutlinedButton.icon(
                    onPressed: _addSection,
                    icon: const Icon(Icons.add),
                    label: const Text('Add Another Module'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                );
              }
              final section = _sections[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: Colors.grey.shade200),
                ),
                child: ExpansionTile(
                  key: ValueKey(section.id),
                  title: Text(
                    section.title,
                    style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    '${section.lectures.length} lectures',
                    style: GoogleFonts.outfit(fontSize: 12),
                  ),
                  children: [
                    ...section.lectures.map(
                      (l) => ListTile(
                        leading: Icon(
                          Icons.play_circle_outline,
                          color: AppTheme.primaryColor,
                        ),
                        title: Text(l.title, style: GoogleFonts.outfit()),
                        subtitle: Text('${l.durationMinutes} mins'),
                      ),
                    ),
                    ListTile(
                      leading: const Icon(
                        Icons.add,
                        color: AppTheme.primaryColor,
                      ),
                      title: Text(
                        'Add Lecture/Resource',
                        style: GoogleFonts.outfit(color: AppTheme.primaryColor),
                      ),
                      onTap: () => _addLecture(index),
                    ),
                  ],
                ),
              );
            },
          ),
      ],
    );
  }

  // STEP 5: Review
  Widget _buildReviewStep() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Ready to Publish?',
            style: GoogleFonts.outfit(
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Review your course details before publishing',
            style: GoogleFonts.outfit(color: Colors.grey.shade600),
          ),
          const SizedBox(height: 24),

          _buildSectionCard(
            title: 'Course Overview',
            icon: Icons.info_outline,
            children: [
              _buildReviewRow('Title', _titleController.text),
              _buildReviewRow('Category', _selectedCategory),
              _buildReviewRow('Difficulty', _selectedDifficulty),
              _buildReviewRow('Domain', _domainType ?? 'Not specified'),
              _buildReviewRow(
                'Duration',
                '${_durationWeeksController.text} weeks',
              ),
              _buildReviewRow('Provider', _providerName),
              if (_mentorNameController.text.isNotEmpty)
                _buildReviewRow('Mentor', _mentorNameController.text),
              _buildReviewRow(
                'Price',
                _priceController.text.isEmpty
                    ? 'Free'
                    : '₹${_priceController.text}',
              ),
            ],
          ),

          const SizedBox(height: 20),

          if (_skillsGained.isNotEmpty)
            _buildSectionCard(
              title: 'Skills (${_skillsGained.length})',
              icon: Icons.star,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _skillsGained
                      .map(
                        (s) => Chip(
                          label: Text(s),
                          backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
                        ),
                      )
                      .toList(),
                ),
              ],
            ),

          const SizedBox(height: 20),

          _buildSectionCard(
            title: 'Curriculum (${_sections.length} modules)',
            icon: Icons.menu_book,
            children: [
              ..._sections.asMap().entries.map(
                (entry) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
                        child: Text(
                          '${entry.key + 1}',
                          style: const TextStyle(
                            color: AppTheme.primaryColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              entry.value.title,
                              style: GoogleFonts.outfit(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              '${entry.value.lectures.length} lectures',
                              style: GoogleFonts.outfit(
                                fontSize: 11,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.primaryColor.withValues(alpha: 0.1),
                  AppTheme.secondaryColor.withValues(alpha: 0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: AppTheme.primaryColor),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    'This course will be available to all students on the platform immediately after publishing.',
                    style: GoogleFonts.outfit(fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Helper widgets
  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: AppTheme.primaryColor, size: 22),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ...children,
        ],
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String label,
    String? hint,
    IconData? icon,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: icon != null ? Icon(icon, size: 20) : null,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppTheme.primaryColor, width: 2),
      ),
      filled: true,
      fillColor: Colors.grey.shade50,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }

  Widget _buildReviewRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.outfit(
              color: Colors.grey.shade600,
              fontSize: 14,
            ),
          ),
          Expanded(
            child: Text(
              value.isEmpty ? '-' : value,
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
              textAlign: TextAlign.right,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  void _addSection() {
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
              hintText: 'e.g. Module 1: Introduction to Java',
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

  void _addLecture(int sectionIndex) {
    showDialog(
      context: context,
      builder: (context) {
        final titleCtrl = TextEditingController();
        final durCtrl = TextEditingController();
        final urlCtrl = TextEditingController();
        String selectedType = 'video';

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(
                'Add Learning Unit',
                style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: titleCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Title',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: selectedType,
                      items: [
                        DropdownMenuItem(
                          value: 'video',
                          child: Row(
                            children: [
                              Icon(Icons.play_circle_outline),
                              SizedBox(width: 8),
                              Text('Video'),
                            ],
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'pdf',
                          child: Row(
                            children: [
                              Icon(Icons.picture_as_pdf),
                              SizedBox(width: 8),
                              Text('PDF/Article'),
                            ],
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'quiz',
                          child: Row(
                            children: [
                              Icon(Icons.quiz_outlined),
                              SizedBox(width: 8),
                              Text('Quiz'),
                            ],
                          ),
                        ),
                      ],
                      onChanged: (v) => setDialogState(() => selectedType = v!),
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
                    TextField(
                      controller: urlCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Content URL',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
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

  void _nextStep() {
    if (_currentStep < 4) {
      setState(() => _currentStep++);
    } else {
      _savePath();
    }
  }

  void _prevStep() {
    if (_currentStep > 0) setState(() => _currentStep--);
  }

  Future<void> _savePath() async {
    setState(() => _isLoading = true);

    final course = LearningCourse(
      id:
          widget.courseToEdit?.id ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      title: _titleController.text,
      description: _descController.text,
      providerName: _providerName,
      providerLogo: widget.courseToEdit?.providerLogo ?? '',
      category: _selectedCategory,
      difficulty: _selectedDifficulty,
      curriculumCode: _curriculumCodeController.text.isNotEmpty
          ? _curriculumCodeController.text
          : null,
      prerequisites: _prerequisitesController.text.isNotEmpty
          ? _prerequisitesController.text
          : null,
      targetRole: _targetRoleController.text.isNotEmpty
          ? _targetRoleController.text
          : null,
      estimatedDurationWeeks: int.tryParse(_durationWeeksController.text),
      placementRelevance: _selectedPlacementRelevance,
      skillsGained: _skillsGained,
      learningOutcomes: _learningOutcomesController.text.isNotEmpty
          ? _learningOutcomesController.text
          : null,
      domainType: _domainType,
      durationHours:
          _sections.fold(
            0,
            (sum, s) =>
                sum + s.lectures.fold(0, (lsum, l) => lsum + l.durationMinutes),
          ) ~/
          60,
      rating: widget.courseToEdit?.rating ?? 0.0,
      studentsEnrolled: widget.courseToEdit?.studentsEnrolled ?? 0,
      hasCertificate: true,
      price: double.tryParse(_priceController.text) ?? 0,
      tags: [],
      sections: _sections,
      itMetadata: _domainType == 'IT'
          ? ITCourseMetadata(
              programmingLanguages: _programmingLanguages,
              toolsFrameworks: _toolsFrameworks,
              codePracticeRequired: _codePracticeRequired,
              miniProjectsCount: _miniProjectsCount,
              githubSubmissionRequired: _githubSubmissionRequired,
              systemDesignLevel: _systemDesignLevel,
              labSessionsRequired: _labSessionsRequired,
            )
          : null,
      managementMetadata: _domainType == 'Management'
          ? ManagementCourseMetadata(
              caseStudiesRequired: _caseStudiesRequired,
              presentationRequired: _presentationRequired,
              groupActivityRequired: _groupActivityRequired,
              communicationSkillWeight: _communicationSkillWeight,
              industryExamples: [],
              rolePlayRequired: _rolePlayRequired,
              reportSubmissionRequired: _reportSubmissionRequired,
            )
          : null,
    );

    try {
      if (widget.courseToEdit != null) {
        await ref.read(learningRepositoryProvider).updateCourse(course);
        if (_domainType == 'IT' && course.itMetadata != null) {
          await ref
              .read(learningRepositoryProvider)
              .updateITMetadata(course.id, course.itMetadata!);
        }
        if (_domainType == 'Management' && course.managementMetadata != null) {
          await ref
              .read(learningRepositoryProvider)
              .updateManagementMetadata(course.id, course.managementMetadata!);
        }
      } else {
        final newCourseId = await ref
            .read(learningRepositoryProvider)
            .addCourse(course);
        if (_domainType == 'IT' && course.itMetadata != null) {
          await ref
              .read(learningRepositoryProvider)
              .updateITMetadata(newCourseId, course.itMetadata!);
        }
        if (_domainType == 'Management' && course.managementMetadata != null) {
          await ref
              .read(learningRepositoryProvider)
              .updateManagementMetadata(
                newCourseId,
                course.managementMetadata!,
              );
        }
      }

      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.courseToEdit != null
                  ? 'Course Updated Successfully!'
                  : 'Course Published Successfully!',
            ),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _priceController.dispose();
    _mentorNameController.dispose();
    _curriculumCodeController.dispose();
    _targetRoleController.dispose();
    _durationWeeksController.dispose();
    _prerequisitesController.dispose();
    _learningOutcomesController.dispose();
    _languageInputController.dispose();
    _frameworkInputController.dispose();
    _skillInputController.dispose();
    super.dispose();
  }
}

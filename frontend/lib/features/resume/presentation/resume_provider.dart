import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/resume_model.dart';
import '../data/resume_providers.dart';
import '../data/resume_repository.dart';

// State for the current resume project
final resumeProjectProvider =
    NotifierProvider<ResumeProjectNotifier, ResumeProject?>(
      ResumeProjectNotifier.new,
    );

// State for the currently selected section/element for editing
final selectedIdProvider = NotifierProvider<SelectedIdNotifier, String?>(
  SelectedIdNotifier.new,
);

class SelectedIdNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  set state(String? value) => super.state = value;
}

class ResumeProjectNotifier extends Notifier<ResumeProject?> {
  final ResumeRepository _repository = ResumeRepository();
  Timer? _saveTimer;

  @override
  ResumeProject? build() {
    return null;
  }

  Future<void> loadProject(String projectId, {String? templateId}) async {
    // Always reset state first to clear any stale data from previous navigations.
    state = null;

    if (projectId == 'new') {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      final safeUserId = userId ?? 'mock-user-id';

      // Start with a mostly empty project.
      var project = ResumeProject.create(safeUserId);

      if (templateId != null) {
        project = project.copyWith(
          design: project.design.copyWith(templateId: templateId),
        );
      }
      state = project;

      // Automatically import from profile
      await importFromProfile();

      // Save the freshly-created project so it has a DB record.
      await _saveNow();
    } else {
      // Load an existing project from Supabase.
      try {
        final db = Supabase.instance.client;
        final userId = db.auth.currentUser?.id;
        if (userId == null) return;

        final row = await db
            .from('resumes')
            .select('data')
            .eq('id', projectId)
            .eq('user_id', userId)
            .maybeSingle();

        if (row != null && row['data'] != null) {
          state = ResumeProject.fromJson(
            Map<String, dynamic>.from(row['data'] as Map),
          );
        }
      } catch (e) {
        debugPrint('Failed to load resume from DB: $e');
      }
    }
  }

  void updateGlobalDesign(GlobalDesign newDesign) {
    if (state == null) return;
    state = state!.copyWith(design: newDesign);
    _save();
  }

  void addSection(ResumeSection section) {
    if (state == null) return;
    state = state!.copyWith(sections: [...state!.sections, section]);
    _save();
  }

  void removeSection(String sectionId) {
    if (state == null) return;
    state = state!.copyWith(
      sections: state!.sections.where((s) => s.id != sectionId).toList(),
    );
    _save();
  }

  void reorderSection(int oldIndex, int newIndex) {
    if (state == null) return;
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    final sections = List<ResumeSection>.from(state!.sections);
    final item = sections.removeAt(oldIndex);
    sections.insert(newIndex, item);
    state = state!.copyWith(sections: sections);
    _save();
  }

  Future<void> importFromProfile() async {
    if (state == null) return;

    final data = await ref.read(resumeDataServiceProvider).fetchProfileData();
    if (data.isEmpty) return;

    final updatedSections = List<ResumeSection>.from(state!.sections);

    // 1. Update Header
    final headerIndex = updatedSections.indexWhere((s) => s is HeaderSection);
    if (headerIndex != -1) {
      final header = updatedSections[headerIndex] as HeaderSection;
      final newHeader = header.copy() as HeaderSection;
      newHeader.fullName = data['full_name'] ?? newHeader.fullName;
      newHeader.email = data['email'] ?? newHeader.email;
      newHeader.phone = data['phone'] ?? newHeader.phone;
      newHeader.location = data['location'] ?? newHeader.location;
      newHeader.photoUrl = data['avatar_url'] ?? newHeader.photoUrl;
      updatedSections[headerIndex] = newHeader;
    }

    // 2. Update Summary if profile bio exists
    if (data['bio'] != null && data['bio'].toString().isNotEmpty) {
      final summaryIndex = updatedSections.indexWhere(
        (s) => s is SummarySection,
      );
      if (summaryIndex != -1) {
        final summary = updatedSections[summaryIndex] as SummarySection;
        final newSummary = summary.copy() as SummarySection;
        newSummary.text = data['bio'];
        updatedSections[summaryIndex] = newSummary;
      }
    }

    // 3. Update Skills
    if (data['skills'] != null) {
      final skillsIndex = updatedSections.indexWhere((s) => s is SkillsSection);
      if (skillsIndex != -1) {
        final skills = updatedSections[skillsIndex] as SkillsSection;
        final newSkills = skills.copy() as SkillsSection;
        newSkills.skills = List<String>.from(data['skills']);
        updatedSections[skillsIndex] = newSkills;
      }
    }

    // 4. Update Projects
    if (data['projects'] != null) {
      final projectsIndex = updatedSections.indexWhere(
        (s) => s is ProjectSection,
      );
      if (projectsIndex != -1) {
        final projects = updatedSections[projectsIndex] as ProjectSection;
        final newProjects = projects.copy() as ProjectSection;
        newProjects.items = (data['projects'] as List).map((p) {
          return ProjectItem.create()
            ..name = p['title'] ?? ''
            ..description = p['description'] ?? ''
            ..role = 'Contributor'
            ..startDate = p['created_at']?.toString().substring(0, 4) ?? '';
        }).toList();
        updatedSections[projectsIndex] = newProjects;
      }
    }

    state = state!.copyWith(sections: updatedSections);
    _save();
  }

  Future<void> importFromPdf(String url) async {
    if (state == null) return;

    final data = await ref
        .read(resumeDataServiceProvider)
        .parseResumeFromPdf(url);
    if (data == null) return;

    final updatedSections = List<ResumeSection>.from(state!.sections);

    // Helper to map map data to sections
    if (data['header'] != null) {
      final h = data['header'];
      final idx = updatedSections.indexWhere((s) => s is HeaderSection);
      if (idx != -1) {
        final header = updatedSections[idx] as HeaderSection;
        final newHeader = header.copy() as HeaderSection;
        newHeader.fullName = h['fullName'] ?? newHeader.fullName;
        newHeader.email = h['email'] ?? newHeader.email;
        newHeader.phone = h['phone'] ?? newHeader.phone;
        newHeader.location = h['location'] ?? newHeader.location;
        newHeader.linkedin = h['linkedin'] ?? newHeader.linkedin;
        newHeader.portfolio = h['portfolio'] ?? newHeader.portfolio;
        updatedSections[idx] = newHeader;
      }
    }

    if (data['summary'] != null) {
      final idx = updatedSections.indexWhere((s) => s is SummarySection);
      if (idx != -1) {
        final section = updatedSections[idx] as SummarySection;
        final newSection = section.copy() as SummarySection;
        newSection.text = data['summary'];
        updatedSections[idx] = newSection;
      }
    }

    if (data['experience'] != null) {
      final idx = updatedSections.indexWhere((s) => s is ExperienceSection);
      if (idx != -1) {
        final section = updatedSections[idx] as ExperienceSection;
        final newSection = section.copy() as ExperienceSection;
        newSection.items = (data['experience'] as List).map((e) {
          return ExperienceItem.create()
            ..company = e['company'] ?? ''
            ..role = e['role'] ?? ''
            ..location = e['location'] ?? ''
            ..startDate = e['startDate'] ?? ''
            ..endDate = e['endDate'] ?? ''
            ..isCurrent = e['isCurrent'] ?? false
            ..description = e['description'] ?? '';
        }).toList();
        updatedSections[idx] = newSection;
      }
    }

    if (data['education'] != null) {
      final idx = updatedSections.indexWhere((s) => s is EducationSection);
      if (idx != -1) {
        final section = updatedSections[idx] as EducationSection;
        final newSection = section.copy() as EducationSection;
        newSection.items = (data['education'] as List).map((e) {
          return EducationItem.create()
            ..school = e['school'] ?? ''
            ..degree = e['degree'] ?? ''
            ..location = e['location'] ?? ''
            ..startDate = e['startDate'] ?? ''
            ..endDate = e['endDate'] ?? ''
            ..grade = e['grade'];
        }).toList();
        updatedSections[idx] = newSection;
      }
    }

    if (data['skills'] != null) {
      final idx = updatedSections.indexWhere((s) => s is SkillsSection);
      if (idx != -1) {
        final section = updatedSections[idx] as SkillsSection;
        final newSection = section.copy() as SkillsSection;
        newSection.skills = List<String>.from(data['skills']);
        updatedSections[idx] = newSection;
      }
    }

    if (data['projects'] != null) {
      final idx = updatedSections.indexWhere((s) => s is ProjectSection);
      if (idx != -1) {
        final section = updatedSections[idx] as ProjectSection;
        final newSection = section.copy() as ProjectSection;
        newSection.items = (data['projects'] as List).map((e) {
          return ProjectItem.create()
            ..name = e['name'] ?? ''
            ..role = e['role'] ?? ''
            ..startDate = e['startDate'] ?? ''
            ..endDate = e['endDate'] ?? ''
            ..link = e['link'] ?? ''
            ..description = e['description'] ?? '';
        }).toList();
        updatedSections[idx] = newSection;
      }
    }

    state = state!.copyWith(sections: updatedSections);
    _save();
  }

  void updateSection(ResumeSection updatedSection) {
    if (state == null) return;
    final index = state!.sections.indexWhere((s) => s.id == updatedSection.id);
    if (index != -1) {
      final sections = List<ResumeSection>.from(state!.sections);
      sections[index] = updatedSection;
      state = state!.copyWith(sections: sections);
      _save();
    }
  }

  /// Debounced save — fires 800 ms after the last edit.
  void _save() {
    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(milliseconds: 800), () {
      _saveNow();
    });
  }

  /// Immediate save to Supabase.
  Future<void> _saveNow() async {
    if (state == null) return;
    try {
      final project = state!;
      final db = Supabase.instance.client;
      await db.from('resumes').upsert({
        'id': project.id,
        'user_id': project.userId,
        'template_id': project.design.templateId,
        'name': project.title,
        'data': project.toJson(),
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      }, onConflict: 'id');
      debugPrint('[Resume] Saved project ${project.id} to Supabase.');
    } catch (e) {
      debugPrint('[Resume] Save failed: $e');
    }
  }
}

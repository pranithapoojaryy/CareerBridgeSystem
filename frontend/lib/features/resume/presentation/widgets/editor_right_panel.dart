import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import 'dart:typed_data';
import '../../domain/resume_model.dart';
import '../resume_provider.dart';

class EditorRightPanel extends ConsumerWidget {
  const EditorRightPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final project = ref.watch(resumeProjectProvider);
    final selectedId = ref.watch(selectedIdProvider);

    if (project == null || selectedId == null) {
      return Container(
        width: 300,
        color: Colors.white,
        child: const Center(child: Text('Select a section to edit')),
      );
    }

    // Find the section by ID using indexWhere to handle not found gracefully
    final sectionIndex = project.sections.indexWhere((s) => s.id == selectedId);
    if (sectionIndex == -1) {
      return Container(
        width: 300,
        color: Colors.white,
        child: const Center(child: Text('Section not found')),
      );
    }
    final section = project.sections[sectionIndex];

    return Container(
      width: 300,
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Edit ${section.title}',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              IconButton(
                onPressed: () => ref
                    .read(resumeProjectProvider.notifier)
                    .removeSection(section.id),
                icon: const Icon(Icons.delete, color: Colors.orange),
              ),
            ],
          ),
          const Divider(),
          Expanded(
            child: SingleChildScrollView(
              child: _buildPropertiesForm(ref, section),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPropertiesForm(WidgetRef ref, ResumeSection section) {
    if (section is HeaderSection)
      return _HeaderForm(section: section, ref: ref);
    if (section is SummarySection)
      return _SummaryForm(section: section, ref: ref);
    if (section is ExperienceSection)
      return _ExperienceForm(section: section, ref: ref);
    if (section is EducationSection)
      return _EducationForm(section: section, ref: ref);
    if (section is SkillsSection)
      return _SkillsForm(section: section, ref: ref);
    if (section is ProjectSection)
      return _ProjectForm(section: section, ref: ref);
    if (section is LanguagesSection)
      return _LanguageForm(section: section, ref: ref);
    if (section is CertificateSection)
      return _CertificateForm(section: section, ref: ref);
    if (section is VolunteeringSection)
      return _VolunteeringForm(section: section, ref: ref);

    return Text('No editor for ${section.type}');
  }
}

class _HeaderForm extends StatelessWidget {
  final HeaderSection section;
  final WidgetRef ref;
  const _HeaderForm({required this.section, required this.ref});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _Input(
          key: ValueKey('${section.id}_fullName'),
          label: 'Full Name',
          value: section.fullName,
          onChanged: (v) {
            final s = section.copy() as HeaderSection;
            s.fullName = v;
            _update(s);
          },
        ),
        _Input(
          key: ValueKey('${section.id}_email'),
          label: 'Email',
          value: section.email,
          onChanged: (v) {
            final s = section.copy() as HeaderSection;
            s.email = v;
            _update(s);
          },
        ),
        _Input(
          key: ValueKey('${section.id}_phone'),
          label: 'Phone',
          value: section.phone,
          onChanged: (v) {
            final s = section.copy() as HeaderSection;
            s.phone = v;
            _update(s);
          },
        ),
        _Input(
          key: ValueKey('${section.id}_location'),
          label: 'Location',
          value: section.location ?? '',
          onChanged: (v) {
            final s = section.copy() as HeaderSection;
            s.location = v;
            _update(s);
          },
        ),
        _Input(
          key: ValueKey('${section.id}_linkedin'),
          label: 'LinkedIn',
          value: section.linkedin ?? '',
          onChanged: (v) {
            final s = section.copy() as HeaderSection;
            s.linkedin = v;
            _update(s);
          },
        ),
        _Input(
          key: ValueKey('${section.id}_portfolio'),
          label: 'Portfolio',
          value: section.portfolio ?? '',
          onChanged: (v) {
            final s = section.copy() as HeaderSection;
            s.portfolio = v;
            _update(s);
          },
        ),
        _Input(
          key: ValueKey('${section.id}_photoUrl'),
          label: 'Photo URL',
          value: section.photoUrl ?? '',
          onChanged: (v) {
            final s = section.copy() as HeaderSection;
            s.photoUrl = v;
            _update(s);
          },
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () async {
                  final ImagePicker picker = ImagePicker();
                  final XFile? image = await picker.pickImage(
                    source: ImageSource.gallery,
                  );
                  if (image != null) {
                    final Uint8List bytes = await image.readAsBytes();
                    final String base64String = base64Encode(bytes);
                    // Simple mime type detection or default to jpeg/png
                    final String mimeType = image.mimeType ?? 'image/jpeg';
                    final String dataUri =
                        'data:$mimeType;base64,$base64String';

                    final s = section.copy() as HeaderSection;
                    s.photoUrl = dataUri;
                    _update(s);
                  }
                },
                icon: const Icon(Icons.upload),
                label: const Text('Upload Photo'),
              ),
            ),
            if (section.photoUrl != null && section.photoUrl!.isNotEmpty) ...[
              const SizedBox(width: 8),
              IconButton(
                onPressed: () {
                  final s = section.copy() as HeaderSection;
                  s.photoUrl = '';
                  _update(s);
                },
                icon: const Icon(Icons.delete_outline, color: Colors.red),
              ),
            ],
          ],
        ),
      ],
    );
  }

  void _update(HeaderSection s) {
    ref.read(resumeProjectProvider.notifier).updateSection(s);
  }
}

class _SummaryForm extends StatelessWidget {
  final SummarySection section;
  final WidgetRef ref;

  const _SummaryForm({required this.section, required this.ref});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextFormField(
          key: ValueKey(section.id),
          initialValue: section.text,
          maxLines: 8,
          decoration: const InputDecoration(
            labelText: 'Summary Text',
            border: OutlineInputBorder(),
          ),
          onChanged: (v) {
            final newSection = section.copy() as SummarySection;
            newSection.text = v;
            ref.read(resumeProjectProvider.notifier).updateSection(newSection);
          },
        ),
        const SizedBox(height: 8),
        ElevatedButton.icon(
          onPressed: () async {
            // Mock AI call
          },
          icon: const Icon(Icons.auto_awesome),
          label: const Text('Generate with AI'),
        ),
      ],
    );
  }
}

class _ExperienceForm extends StatelessWidget {
  final ExperienceSection section;
  final WidgetRef ref;

  const _ExperienceForm({required this.section, required this.ref});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ...section.items.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () {
                          final s = section.copy() as ExperienceSection;
                          s.items.removeAt(index);
                          ref
                              .read(resumeProjectProvider.notifier)
                              .updateSection(s);
                        },
                      ),
                    ],
                  ),
                  _Input(
                    label: 'Role',
                    value: item.role,
                    onChanged: (v) {
                      final s = section.copy() as ExperienceSection;
                      s.items[index].role = v;
                      ref.read(resumeProjectProvider.notifier).updateSection(s);
                    },
                  ),
                  _Input(
                    label: 'Company',
                    value: item.company,
                    onChanged: (v) {
                      final s = section.copy() as ExperienceSection;
                      s.items[index].company = v;
                      ref.read(resumeProjectProvider.notifier).updateSection(s);
                    },
                  ),
                  _Input(
                    label: 'Location',
                    value: item.location,
                    onChanged: (v) {
                      final s = section.copy() as ExperienceSection;
                      s.items[index].location = v;
                      ref.read(resumeProjectProvider.notifier).updateSection(s);
                    },
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: _Input(
                          label: 'Start Date',
                          value: item.startDate,
                          onChanged: (v) {
                            final s = section.copy() as ExperienceSection;
                            s.items[index].startDate = v;
                            ref
                                .read(resumeProjectProvider.notifier)
                                .updateSection(s);
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _Input(
                          label: 'End Date',
                          value: item.endDate,
                          onChanged: (v) {
                            final s = section.copy() as ExperienceSection;
                            s.items[index].endDate = v;
                            ref
                                .read(resumeProjectProvider.notifier)
                                .updateSection(s);
                          },
                        ),
                      ),
                    ],
                  ),
                  CheckboxListTile(
                    title: const Text('Current Position'),
                    value: item.isCurrent,
                    onChanged: (v) {
                      final s = section.copy() as ExperienceSection;
                      s.items[index].isCurrent = v ?? false;
                      ref.read(resumeProjectProvider.notifier).updateSection(s);
                    },
                  ),
                  _Input(
                    label: 'Description',
                    value: item.description,
                    maxLines: 4,
                    onChanged: (v) {
                      final s = section.copy() as ExperienceSection;
                      s.items[index].description = v;
                      ref.read(resumeProjectProvider.notifier).updateSection(s);
                    },
                  ),
                ],
              ),
            ),
          );
        }),
        ElevatedButton(
          onPressed: () {
            final newSection = section.copy() as ExperienceSection;
            newSection.items.add(ExperienceItem.create());
            ref.read(resumeProjectProvider.notifier).updateSection(newSection);
          },
          child: const Text('Add Position'),
        ),
      ],
    );
  }
}

class _EducationForm extends StatelessWidget {
  final EducationSection section;
  final WidgetRef ref;

  const _EducationForm({required this.section, required this.ref});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ...section.items.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () {
                          final s = section.copy() as EducationSection;
                          s.items.removeAt(index);
                          ref
                              .read(resumeProjectProvider.notifier)
                              .updateSection(s);
                        },
                      ),
                    ],
                  ),
                  _Input(
                    label: 'School',
                    value: item.school,
                    onChanged: (v) {
                      final s = section.copy() as EducationSection;
                      s.items[index].school = v;
                      ref.read(resumeProjectProvider.notifier).updateSection(s);
                    },
                  ),
                  _Input(
                    label: 'Degree',
                    value: item.degree,
                    onChanged: (v) {
                      final s = section.copy() as EducationSection;
                      s.items[index].degree = v;
                      ref.read(resumeProjectProvider.notifier).updateSection(s);
                    },
                  ),
                  _Input(
                    label: 'Location',
                    value: item.location,
                    onChanged: (v) {
                      final s = section.copy() as EducationSection;
                      s.items[index].location = v;
                      ref.read(resumeProjectProvider.notifier).updateSection(s);
                    },
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: _Input(
                          label: 'Start Date',
                          value: item.startDate,
                          onChanged: (v) {
                            final s = section.copy() as EducationSection;
                            s.items[index].startDate = v;
                            ref
                                .read(resumeProjectProvider.notifier)
                                .updateSection(s);
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _Input(
                          label: 'End Date',
                          value: item.endDate,
                          onChanged: (v) {
                            final s = section.copy() as EducationSection;
                            s.items[index].endDate = v;
                            ref
                                .read(resumeProjectProvider.notifier)
                                .updateSection(s);
                          },
                        ),
                      ),
                    ],
                  ),
                  _Input(
                    label: 'Grade/GPA',
                    value: item.grade ?? '',
                    onChanged: (v) {
                      final s = section.copy() as EducationSection;
                      s.items[index].grade = v;
                      ref.read(resumeProjectProvider.notifier).updateSection(s);
                    },
                  ),
                ],
              ),
            ),
          );
        }),
        ElevatedButton(
          onPressed: () {
            final newSection = section.copy() as EducationSection;
            newSection.items.add(EducationItem.create());
            ref.read(resumeProjectProvider.notifier).updateSection(newSection);
          },
          child: const Text('Add Education'),
        ),
      ],
    );
  }
}

class _ProjectForm extends StatelessWidget {
  final ProjectSection section;
  final WidgetRef ref;
  const _ProjectForm({required this.section, required this.ref});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ...section.items.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () {
                          final s = section.copy() as ProjectSection;
                          s.items.removeAt(index);
                          ref
                              .read(resumeProjectProvider.notifier)
                              .updateSection(s);
                        },
                      ),
                    ],
                  ),
                  _Input(
                    label: 'Project Name',
                    value: item.name,
                    onChanged: (v) {
                      final s = section.copy() as ProjectSection;
                      s.items[index].name = v;
                      ref.read(resumeProjectProvider.notifier).updateSection(s);
                    },
                  ),
                  _Input(
                    label: 'Role',
                    value: item.role,
                    onChanged: (v) {
                      final s = section.copy() as ProjectSection;
                      s.items[index].role = v;
                      ref.read(resumeProjectProvider.notifier).updateSection(s);
                    },
                  ),
                  _Input(
                    label: 'Link',
                    value: item.link,
                    onChanged: (v) {
                      final s = section.copy() as ProjectSection;
                      s.items[index].link = v;
                      ref.read(resumeProjectProvider.notifier).updateSection(s);
                    },
                  ),
                  _Input(
                    label: 'Description',
                    value: item.description,
                    maxLines: 3,
                    onChanged: (v) {
                      final s = section.copy() as ProjectSection;
                      s.items[index].description = v;
                      ref.read(resumeProjectProvider.notifier).updateSection(s);
                    },
                  ),
                ],
              ),
            ),
          );
        }),
        ElevatedButton(
          onPressed: () {
            final newSection = section.copy() as ProjectSection;
            newSection.items.add(ProjectItem.create());
            ref.read(resumeProjectProvider.notifier).updateSection(newSection);
          },
          child: const Text('Add Project'),
        ),
      ],
    );
  }
}

class _CertificateForm extends StatelessWidget {
  final CertificateSection section;
  final WidgetRef ref;
  const _CertificateForm({required this.section, required this.ref});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ...section.items.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () {
                          final s = section.copy() as CertificateSection;
                          s.items.removeAt(index);
                          ref
                              .read(resumeProjectProvider.notifier)
                              .updateSection(s);
                        },
                      ),
                    ],
                  ),
                  _Input(
                    label: 'Name',
                    value: item.name,
                    onChanged: (v) {
                      final s = section.copy() as CertificateSection;
                      s.items[index].name = v;
                      ref.read(resumeProjectProvider.notifier).updateSection(s);
                    },
                  ),
                  _Input(
                    label: 'Issuer',
                    value: item.issuer,
                    onChanged: (v) {
                      final s = section.copy() as CertificateSection;
                      s.items[index].issuer = v;
                      ref.read(resumeProjectProvider.notifier).updateSection(s);
                    },
                  ),
                  _Input(
                    label: 'Date',
                    value: item.date,
                    onChanged: (v) {
                      final s = section.copy() as CertificateSection;
                      s.items[index].date = v;
                      ref.read(resumeProjectProvider.notifier).updateSection(s);
                    },
                  ),
                ],
              ),
            ),
          );
        }),
        ElevatedButton(
          onPressed: () {
            final newSection = section.copy() as CertificateSection;
            newSection.items.add(CertificateItem.create());
            ref.read(resumeProjectProvider.notifier).updateSection(newSection);
          },
          child: const Text('Add Certificate'),
        ),
      ],
    );
  }
}

class _LanguageForm extends StatelessWidget {
  final LanguagesSection section;
  final WidgetRef ref;
  const _LanguageForm({required this.section, required this.ref});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ...section.items.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () {
                          final s = section.copy() as LanguagesSection;
                          s.items.removeAt(index);
                          ref
                              .read(resumeProjectProvider.notifier)
                              .updateSection(s);
                        },
                      ),
                    ],
                  ),
                  _Input(
                    label: 'Language',
                    value: item.name,
                    onChanged: (v) {
                      final s = section.copy() as LanguagesSection;
                      s.items[index].name = v;
                      ref.read(resumeProjectProvider.notifier).updateSection(s);
                    },
                  ),
                  _Input(
                    label: 'Proficiency',
                    value: item.proficiency,
                    onChanged: (v) {
                      final s = section.copy() as LanguagesSection;
                      s.items[index].proficiency = v;
                      ref.read(resumeProjectProvider.notifier).updateSection(s);
                    },
                  ),
                ],
              ),
            ),
          );
        }),
        ElevatedButton(
          onPressed: () {
            final newSection = section.copy() as LanguagesSection;
            newSection.items.add(LanguageItem.create());
            ref.read(resumeProjectProvider.notifier).updateSection(newSection);
          },
          child: const Text('Add Language'),
        ),
      ],
    );
  }
}

class _VolunteeringForm extends StatelessWidget {
  final VolunteeringSection section;
  final WidgetRef ref;

  const _VolunteeringForm({required this.section, required this.ref});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ...section.items.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () {
                          final s = section.copy() as VolunteeringSection;
                          s.items.removeAt(index);
                          ref
                              .read(resumeProjectProvider.notifier)
                              .updateSection(s);
                        },
                      ),
                    ],
                  ),
                  _Input(
                    label: 'Role',
                    value: item.role,
                    onChanged: (v) {
                      final s = section.copy() as VolunteeringSection;
                      s.items[index].role = v;
                      ref.read(resumeProjectProvider.notifier).updateSection(s);
                    },
                  ),
                  _Input(
                    label: 'Organization',
                    value: item.company,
                    onChanged: (v) {
                      final s = section.copy() as VolunteeringSection;
                      s.items[index].company = v;
                      ref.read(resumeProjectProvider.notifier).updateSection(s);
                    },
                  ),
                  _Input(
                    label: 'Location',
                    value: item.location,
                    onChanged: (v) {
                      final s = section.copy() as VolunteeringSection;
                      s.items[index].location = v;
                      ref.read(resumeProjectProvider.notifier).updateSection(s);
                    },
                  ),
                  _Input(
                    label: 'Description',
                    value: item.description,
                    maxLines: 4,
                    onChanged: (v) {
                      final s = section.copy() as VolunteeringSection;
                      s.items[index].description = v;
                      ref.read(resumeProjectProvider.notifier).updateSection(s);
                    },
                  ),
                ],
              ),
            ),
          );
        }),
        ElevatedButton(
          onPressed: () {
            final newSection = section.copy() as VolunteeringSection;
            newSection.items.add(ExperienceItem.create());
            ref.read(resumeProjectProvider.notifier).updateSection(newSection);
          },
          child: const Text('Add Volunteering'),
        ),
      ],
    );
  }
}

class _SkillsForm extends StatelessWidget {
  final SkillsSection section;
  final WidgetRef ref;

  const _SkillsForm({required this.section, required this.ref});

  @override
  Widget build(BuildContext context) {
    final controller = TextEditingController(text: section.skills.join(', '));
    return Column(
      children: [
        TextField(
          controller: controller, // Controller needed to not lose cursor
          maxLines: 4,
          decoration: const InputDecoration(
            labelText: 'Skills (comma separated)',
            border: OutlineInputBorder(),
          ),
          onSubmitted: (v) {
            final newSection = section.copy() as SkillsSection;
            newSection.skills = v
                .split(',')
                .map((e) => e.trim())
                .where((e) => e.isNotEmpty)
                .toList();
            ref.read(resumeProjectProvider.notifier).updateSection(newSection);
          },
        ),
        const Text(
          'Press Enter to Apply',
          style: TextStyle(color: Colors.grey),
        ),
      ],
    );
  }
}

class _Input extends StatelessWidget {
  final String label;
  final String value;
  final int maxLines;
  final Function(String) onChanged;

  const _Input({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.maxLines = 1,
  });


  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        key: key,
        initialValue: value,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          isDense: true,
          border: const OutlineInputBorder(),
        ),
        onChanged: onChanged,
      ),
    );
  }
}

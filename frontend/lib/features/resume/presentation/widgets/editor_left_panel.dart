import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/resume_model.dart';
import '../resume_provider.dart';
import '../../data/resume_providers.dart';

class EditorLeftPanel extends ConsumerWidget {
  const EditorLeftPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      width: 250,
      color: Colors.white,
      child: DefaultTabController(
        length: 2,
        child: Column(
          children: [
            const TabBar(
              tabs: [
                Tab(icon: Icon(Icons.list), text: 'Structure'),
                Tab(icon: Icon(Icons.design_services), text: 'Design'),
              ],
            ),
            Expanded(
              child: TabBarView(children: [_StructureTab(), _DesignTab()]),
            ),
          ],
        ),
      ),
    );
  }
}

class _StructureTab extends ConsumerWidget {
  Widget _buildImportSyncSection(BuildContext context, WidgetRef ref) {
    final resumeUrl = ref.watch(resumeUrlProvider).asData?.value;
    final project = ref.watch(resumeProjectProvider);
    if (project == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Smart Sync',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: Colors.blue.shade700,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          ElevatedButton.icon(
            onPressed: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Import from Profile?'),
                  content: const Text(
                    'This will overwrite your current Personal Details, Summary, Skills, and Projects with data from your CareerBridge profile.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Import'),
                    ),
                  ],
                ),
              );

              if (confirmed == true) {
                await ref
                    .read(resumeProjectProvider.notifier)
                    .importFromProfile();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Profile data imported!')),
                  );
                }
              }
            },
            icon: const Icon(Icons.person_outline, size: 18),
            label: const Text('Import from Profile'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue.shade50,
              foregroundColor: Colors.blue.shade700,
              elevation: 0,
            ),
          ),
          if (resumeUrl != null) ...[
            const SizedBox(height: 4),
            ElevatedButton.icon(
              onPressed: () async {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('AI Sync with Uploaded Resume?'),
                    content: const Text(
                      'This uses AI to extract structured info from your existing PDF resume. It may take a few seconds and will update multiple sections.',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('Sync with AI'),
                      ),
                    ],
                  ),
                );

                if (confirmed == true) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('AI is analyzing your resume...'),
                      duration: Duration(seconds: 5),
                    ),
                  );
                  await ref
                      .read(resumeProjectProvider.notifier)
                      .importFromPdf(resumeUrl);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Resume data synced via AI!'),
                      ),
                    );
                  }
                }
              },
              icon: const Icon(Icons.auto_awesome, size: 18),
              label: const Text('Sync with Uploaded PDF'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple.shade50,
                foregroundColor: Colors.purple.shade700,
                elevation: 0,
              ),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final project = ref.watch(resumeProjectProvider);
    if (project == null)
      return const Center(child: CircularProgressIndicator());

    return Column(
      children: [
        _buildImportSyncSection(context, ref),
        const Divider(),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
            'Drag to Reorder',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
        Expanded(
          child: ReorderableListView.builder(
            buildDefaultDragHandles: true,
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: project.sections.length,
            onReorder: (oldIndex, newIndex) {
              if (oldIndex < newIndex) {
                newIndex -= 1;
              }
              ref
                  .read(resumeProjectProvider.notifier)
                  .reorderSection(oldIndex, newIndex);
            },
            itemBuilder: (context, index) {
              final section = project.sections[index];
              return Container(
                key: ValueKey(section.id),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: Colors.grey.shade200),
                  ),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 0,
                  ),
                  dense: true,
                  title: Text(
                    section.title,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(
                          section.isVisible
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          size: 18,
                          color: section.isVisible
                              ? Colors.black54
                              : Colors.grey,
                        ),
                        onPressed: () {
                          // Toggle visibility logic (to be better implemented in provider if needed,
                          // but for now just mutable update helper or direct mutable change which is bad practice but consistent with current codebase issues)
                          // Ideally: ref.read(resumeProjectProvider.notifier).toggleVisibility(section.id);
                          // Current quick fix matching existing patterns (though flawed):
                          final s = section.copy();
                          s.isVisible = !s.isVisible;
                          ref
                              .read(resumeProjectProvider.notifier)
                              .updateSection(s);
                        },
                        tooltip: section.isVisible ? 'Hide' : 'Show',
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(
                          Icons.delete_outline,
                          size: 18,
                          color: Colors.redAccent,
                        ),
                        onPressed: () {
                          ref
                              .read(resumeProjectProvider.notifier)
                              .removeSection(section.id);
                        },
                        tooltip: 'Remove',
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                      const SizedBox(
                        width: 16,
                      ), // Space for the drag handle that ReorderableListView adds
                    ],
                  ),
                  onTap: () {
                    ref.read(selectedIdProvider.notifier).state = section.id;
                  },
                  selected: ref.watch(selectedIdProvider) == section.id,
                  selectedTileColor: Colors.blue.withValues(alpha: 0.05),
                ),
              );
            },
          ),
        ),
        const Divider(),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
            'Add Section',
            style: Theme.of(context).textTheme.titleSmall,
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            children: [
              _buildAddButton(
                ref,
                'Experience',
                Icons.work,
                () => ExperienceSection.create(),
              ),
              _buildAddButton(
                ref,
                'Education',
                Icons.school,
                () => EducationSection.create(),
              ),
              _buildAddButton(
                ref,
                'Projects',
                Icons.code,
                () => ProjectSection.create(),
              ),
              _buildAddButton(
                ref,
                'Skills',
                Icons.psychology,
                () => SkillsSection.create(),
              ),
              _buildAddButton(
                ref,
                'Certifications',
                Icons.workspace_premium,
                () => CertificateSection.create(),
              ),
              _buildAddButton(
                ref,
                'Languages',
                Icons.language,
                () => LanguagesSection.create(),
              ),
              _buildAddButton(
                ref,
                'Volunteering',
                Icons.volunteer_activism,
                () => VolunteeringSection.create(),
              ),
              _buildAddButton(
                ref,
                'Summary',
                Icons.summarize,
                () => SummarySection.create(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAddButton(
    WidgetRef ref,
    String label,
    IconData icon,
    ResumeSection Function() create,
  ) {
    return OutlinedButton.icon(
      onPressed: () {
        ref.read(resumeProjectProvider.notifier).addSection(create());
      },
      icon: Icon(icon, size: 16),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
    );
  }
}

class _DesignTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final project = ref.watch(resumeProjectProvider);
    if (project == null) return const Center(child: Text('No Project'));

    final design = project.design;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('Template', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          value: design.templateId,
          isExpanded: true,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            labelText: 'Select Template',
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
          items: const [
            DropdownMenuItem(
              value: 'modern',
              child: Text('Modern Default', overflow: TextOverflow.ellipsis),
            ),
            DropdownMenuItem(
              value: 'classic',
              child: Text('Classic Minimal', overflow: TextOverflow.ellipsis),
            ),
            DropdownMenuItem(
              value: 'ivy',
              child: Text(
                'Ivy League (Professional)',
                overflow: TextOverflow.ellipsis,
              ),
            ),
            DropdownMenuItem(
              value: 'creative',
              child: Text('Creative (Modern)', overflow: TextOverflow.ellipsis),
            ),
          ],
          onChanged: (v) {
            if (v != null) {
              ref
                  .read(resumeProjectProvider.notifier)
                  .updateGlobalDesign(design.copyWith(templateId: v));
            }
          },
        ),
        const SizedBox(height: 24),
        const Text(
          'Global Design',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        _buildColorPicker(context, 'Primary Color', design.primaryColor, (c) {
          ref
              .read(resumeProjectProvider.notifier)
              .updateGlobalDesign(design.copyWith(primaryColor: c));
        }),
        const SizedBox(height: 16),
        _buildColorPicker(context, 'Secondary Color', design.secondaryColor, (
          c,
        ) {
          ref
              .read(resumeProjectProvider.notifier)
              .updateGlobalDesign(design.copyWith(secondaryColor: c));
        }),
        const SizedBox(height: 16),
        _buildColorPicker(context, 'Background', design.backgroundColor, (c) {
          ref
              .read(resumeProjectProvider.notifier)
              .updateGlobalDesign(design.copyWith(backgroundColor: c));
        }),
        const SizedBox(height: 16),
        Text('Font Size: ${design.baseFontSize.toStringAsFixed(1)}'),
        Slider(
          value: design.baseFontSize,
          min: 8,
          max: 16,
          divisions: 16,
          label: design.baseFontSize.toString(),
          onChanged: (v) {
            ref
                .read(resumeProjectProvider.notifier)
                .updateGlobalDesign(design.copyWith(baseFontSize: v));
          },
        ),
        const SizedBox(height: 16),
        Text('Page Margin: ${design.pageMargin.toStringAsFixed(0)}'),
        Slider(
          value: design.pageMargin,
          min: 0,
          max: 50,
          onChanged: (v) {
            ref
                .read(resumeProjectProvider.notifier)
                .updateGlobalDesign(design.copyWith(pageMargin: v));
          },
        ),
      ],
    );
  }

  Widget _buildColorPicker(
    BuildContext context,
    String label,
    Color color,
    Function(Color) onColorChanged,
  ) {
    final List<Color> palette = [
      Colors.black87,
      Colors.grey,
      Colors.blue.shade900,
      Colors.blue,
      Colors.teal,
      Colors.green.shade900,
      Colors.purple,
      Colors.red.shade900,
      Colors.white,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: palette
              .map(
                (c) => GestureDetector(
                  onTap: () => onColorChanged(c),
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: c,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: color == c ? Colors.black : Colors.grey.shade300,
                        width: 2,
                      ),
                      boxShadow: [
                        if (color == c)
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 4,
                            spreadRadius: 1,
                          ),
                      ],
                    ),
                  ),
                ),
              )
              .toList(),
        ),
      ],
    );
  }
}

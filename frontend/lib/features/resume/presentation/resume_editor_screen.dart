import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:printing/printing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/resume_repository.dart';
import '../data/resume_providers.dart';
import 'resume_provider.dart';
import 'widgets/editor_left_panel.dart';
import 'widgets/editor_right_panel.dart';
import 'widgets/resume_canvas.dart';

class ResumeEditorScreen extends ConsumerStatefulWidget {
  final String
  templateId; // Keeps the signature compatible, though templateId is less relevant now as we have a flexible project

  const ResumeEditorScreen({super.key, required this.templateId});

  @override
  ConsumerState<ResumeEditorScreen> createState() => _ResumeEditorScreenState();
}

class _ResumeEditorScreenState extends ConsumerState<ResumeEditorScreen> {
  bool _syncChecked = false;

  @override
  void initState() {
    super.initState();
    // Defer state update to next frame to avoid build conflicts
    Future.microtask(() async {
      // Check if the user already has a saved resume in the DB.
      // If yes, load it (so their previous edits are restored).
      // Only create a brand-new project when no saved record exists.
      String projectIdToLoad = 'new';
      try {
        final db = Supabase.instance.client;
        final userId = db.auth.currentUser?.id;
        if (userId != null) {
          final existing = await db
              .from('resumes')
              .select('id')
              .eq('user_id', userId)
              .order('updated_at', ascending: false)
              .limit(1)
              .maybeSingle();
          if (existing != null && existing['id'] != null) {
            projectIdToLoad = existing['id'] as String;
          }
        }
      } catch (e) {
        debugPrint('[ResumeEditor] Could not find existing resume: $e');
      }

      await ref
          .read(resumeProjectProvider.notifier)
          .loadProject(projectIdToLoad, templateId: widget.templateId);

      if (!_syncChecked && mounted) {
        _syncChecked = true;
        _possiblyPromptAISync();
      }
    });
  }

  Future<void> _possiblyPromptAISync() async {
    // Small delay to ensure UI is ready
    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;

    final resumeUrl = await ref.read(resumeUrlProvider.future);
    if (resumeUrl == null) return;

    if (!mounted) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.auto_awesome, color: Colors.purple),
            SizedBox(width: 8),
            Text('Auto-Fill with AI?'),
          ],
        ),
        content: const Text(
          'We found an uploaded resume in your profile. Would you like to use AI to automatically fill your experience, education, and other details from it?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Skip'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple,
              foregroundColor: Colors.white,
            ),
            child: const Text('Auto-Fill Now'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final scaffoldMessenger = ScaffoldMessenger.of(context);
      scaffoldMessenger.showSnackBar(
        const SnackBar(
          content: Text('AI is analyzing your resume...'),
          duration: Duration(seconds: 4),
        ),
      );
      await ref.read(resumeProjectProvider.notifier).importFromPdf(resumeUrl);
      if (mounted) {
        scaffoldMessenger.showSnackBar(
          const SnackBar(content: Text('Auto-fill complete!')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final project = ref.watch(resumeProjectProvider);

    if (project == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(project.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.undo),
            onPressed: () {
              // implementation_plan: Undo/Redo logic
            },
          ),
          IconButton(icon: const Icon(Icons.redo), onPressed: () {}),
          IconButton(
            icon: const Icon(Icons.upload_file),
            tooltip: 'Save to Profile',
            onPressed: () async {
              final scaffoldMessenger = ScaffoldMessenger.of(context);
              try {
                scaffoldMessenger.showSnackBar(
                  const SnackBar(
                    content: Text('Generating and uploading resume...'),
                  ),
                );

                final template = ResumeRepository().getTemplateById(
                  project.design.templateId,
                );
                final bytes = await template.generatePdf(project);

                await ResumeRepository().uploadResume(bytes: bytes);
                // Invalidate resume URL so other screens (Job Listing, Resume Hub) update
                ref.invalidate(resumeUrlProvider);

                if (context.mounted) {
                  scaffoldMessenger.showSnackBar(
                    const SnackBar(
                      content: Text('Resume uploaded to profile successfully!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  scaffoldMessenger.showSnackBar(
                    SnackBar(
                      content: Text('Error uploading resume: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.download),
            tooltip: 'Export',
            onSelected: (value) async {
              final scaffoldMessenger = ScaffoldMessenger.of(context);
              if (value == 'pdf') {
                final template = ResumeRepository().getTemplateById(
                  project.design.templateId,
                );
                final bytes = await template.generatePdf(project);
                await Printing.sharePdf(
                  bytes: bytes,
                  filename: '${project.title}.pdf',
                );
              } else if (value == 'docs') {
                scaffoldMessenger.showSnackBar(
                  const SnackBar(content: Text('Export to Docs coming soon!')),
                );
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'pdf', child: Text('Download PDF')),
              const PopupMenuItem(
                value: 'docs',
                child: Text('Export to Word (Docx)'),
              ),
            ],
          ),
        ],
      ),
      body: const Row(
        children: [
          EditorLeftPanel(),
          VerticalDivider(width: 1),
          Expanded(child: ResumeCanvas()),
          VerticalDivider(width: 1),
          EditorRightPanel(),
        ],
      ),
    );
  }
}

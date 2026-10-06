import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/logger_service.dart';

class AddEditProjectScreen extends StatefulWidget {
  final Map<String, dynamic>? project;

  const AddEditProjectScreen({super.key, this.project});

  @override
  State<AddEditProjectScreen> createState() => _AddEditProjectScreenState();
}

class _AddEditProjectScreenState extends State<AddEditProjectScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isSaving = false;
  bool _isOngoing = false;

  // Controllers
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _projectUrlController = TextEditingController();
  final _githubUrlController = TextEditingController();
  final _technologiesController = TextEditingController();

  DateTime? _startDate;
  DateTime? _endDate;
  List<String> _mediaUrls = [];

  @override
  void initState() {
    super.initState();
    if (widget.project != null) {
      _populateFields();
    }
  }

  void _populateFields() {
    final project = widget.project!;
    _titleController.text = project['title'] ?? '';
    _descriptionController.text = project['description'] ?? '';
    _projectUrlController.text = project['project_url'] ?? '';
    _githubUrlController.text = project['github_url'] ?? '';

    if (project['technologies'] != null && project['technologies'] is List) {
      _technologiesController.text = (project['technologies'] as List).join(
        ', ',
      );
    }

    _isOngoing = project['is_ongoing'] ?? false;
    if (project['start_date'] != null) {
      _startDate = DateTime.parse(project['start_date']);
    }
    if (project['end_date'] != null && !_isOngoing) {
      _endDate = DateTime.parse(project['end_date']);
    }

    if (project['media_urls'] != null && project['media_urls'] is List) {
      _mediaUrls = List<String>.from(project['media_urls']);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _projectUrlController.dispose();
    _githubUrlController.dispose();
    _technologiesController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStartDate
          ? (_startDate ?? DateTime.now())
          : (_endDate ?? DateTime.now()),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
      });
    }
  }

  Future<void> _pickImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image == null) return;

      setState(() => _isSaving = true);

      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) throw Exception('Not authenticated');

      // Read image as bytes
      final bytes = await image.readAsBytes();
      final fileName =
          '${user.id}/${DateTime.now().millisecondsSinceEpoch}_${image.name}';

      // Upload to Supabase storage
      await Supabase.instance.client.storage
          .from('project-media')
          .uploadBinary(fileName, bytes);

      // Get public URL
      final publicUrl = Supabase.instance.client.storage
          .from('project-media')
          .getPublicUrl(fileName);

      setState(() {
        _mediaUrls.add(publicUrl);
        _isSaving = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Image uploaded successfully')),
        );
      }
    } catch (e) {
      setState(() => _isSaving = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error uploading image: $e')));
      }
    }
  }

  Future<String?> _createFeedPost(Map<String, dynamic> project) async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return null;

      // Format project details for feed post
      final techStack = project['technologies'] is List
          ? (project['technologies'] as List).join(', ')
          : '';

      String postContent = '🚀 New Project: ${project['title']}\n\n';
      if (project['description'] != null &&
          project['description'].toString().isNotEmpty) {
        postContent += '${project['description']}\n\n';
      }
      if (techStack.isNotEmpty) {
        postContent += '💻 Tech Stack: $techStack\n\n';
      }
      if (project['project_url'] != null) {
        postContent += '🔗 Live Demo: ${project['project_url']}\n';
      }
      if (project['github_url'] != null) {
        postContent += '📂 GitHub: ${project['github_url']}\n';
      }

      final postResponse = await Supabase.instance.client
          .from('posts')
          .insert({
            'author_id': user.id,
            'content': postContent,
            'image_urls': project['media_urls'] ?? [],
            'post_type': 'general',
            'media_type': (project['media_urls'] as List?)?.isEmpty ?? true
                ? 'none'
                : ((project['media_urls'] as List).length > 1
                      ? 'carousel'
                      : 'image'),
            'created_at': DateTime.now().toIso8601String(),
          })
          .select()
          .single();

      return postResponse['id'];
    } catch (e) {
      LoggerService.error('Error creating feed post', e);
    }
    return null;
  }

  Future<void> _saveProject({bool postToFeed = false}) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) throw Exception('Not authenticated');

      final technologies = _technologiesController.text
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();

      final projectData = {
        'student_id': user.id,
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'technologies': technologies,
        'project_url': _projectUrlController.text.trim().isEmpty
            ? null
            : _projectUrlController.text.trim(),
        'github_url': _githubUrlController.text.trim().isEmpty
            ? null
            : _githubUrlController.text.trim(),
        'media_urls': _mediaUrls,
        'start_date': _startDate?.toIso8601String(),
        'end_date': _isOngoing ? null : _endDate?.toIso8601String(),
        'is_ongoing': _isOngoing,
        'posted_to_feed': postToFeed,
        'updated_at': DateTime.now().toIso8601String(),
      };

      String? feedPostId;
      String? projectId;

      if (widget.project == null) {
        // Create new project
        final response = await Supabase.instance.client
            .from('student_projects')
            .insert(projectData)
            .select()
            .single();

        projectId = response['id'];

        if (postToFeed) {
          feedPostId = await _createFeedPost(response);
        }
      } else {
        // Update existing project
        projectId = widget.project!['id'];

        await Supabase.instance.client
            .from('student_projects')
            .update(projectData)
            .eq('id', widget.project!['id']);

        if (postToFeed && widget.project!['feed_post_id'] == null) {
          feedPostId = await _createFeedPost({
            ...projectData,
            'id': widget.project!['id'],
          });
        }
      }

      // Update project with feed_post_id if created
      if (feedPostId != null && projectId != null) {
        await Supabase.instance.client
            .from('student_projects')
            .update({'feed_post_id': feedPostId})
            .eq('id', projectId);
      }

      if (mounted) {
        Navigator.pop(context, true); // Return true to indicate success
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              postToFeed
                  ? 'Project saved and posted to feed!'
                  : 'Project saved successfully!',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.project != null;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: Colors.grey[50],
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 600,
          maxHeight: MediaQuery.of(context).size.height * 0.9,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              color: AppTheme.primaryColor,
              child: Row(
                children: [
                  Icon(
                    isEditing
                        ? Icons.edit_note_rounded
                        : Icons.add_task_rounded,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    isEditing ? 'Edit Project' : 'Add New Project',
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                      fontSize: 18,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),

            // Form Content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title
                      Text(
                        'Project Details',
                        style: GoogleFonts.outfit(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textColor,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Title field
                      TextFormField(
                        controller: _titleController,
                        decoration: InputDecoration(
                          labelText: 'Project Title *',
                          hintText: 'E-commerce Website',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter a title';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Description field
                      TextFormField(
                        controller: _descriptionController,
                        maxLines: 5,
                        decoration: InputDecoration(
                          labelText: 'Description',
                          hintText: 'Describe your project...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Technologies
                      TextFormField(
                        controller: _technologiesController,
                        decoration: InputDecoration(
                          labelText: 'Technologies',
                          hintText: 'React, Node.js, MongoDB (comma-separated)',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // URLs Section
                      Text(
                        'Links',
                        style: GoogleFonts.outfit(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textColor,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Project URL
                      TextFormField(
                        controller: _projectUrlController,
                        decoration: InputDecoration(
                          labelText: 'Live Demo URL',
                          hintText: 'https://myproject.com',
                          prefixIcon: const Icon(Icons.language),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // GitHub URL
                      TextFormField(
                        controller: _githubUrlController,
                        decoration: InputDecoration(
                          labelText: 'GitHub Repository',
                          hintText: 'https://github.com/username/repo',
                          prefixIcon: const Icon(Icons.code),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Media Section
                      Text(
                        'Media',
                        style: GoogleFonts.outfit(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Add images or videos of your project (optional)',
                        style: GoogleFonts.outfit(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Media Grid - show uploaded images
                      if (_mediaUrls.isNotEmpty) ...[
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 3,
                                crossAxisSpacing: 8,
                                mainAxisSpacing: 8,
                                childAspectRatio: 1,
                              ),
                          itemCount: _mediaUrls.length,
                          itemBuilder: (context, index) {
                            return Stack(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(
                                    _mediaUrls[index],
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                    height: double.infinity,
                                  ),
                                ),
                                Positioned(
                                  top: 4,
                                  right: 4,
                                  child: InkWell(
                                    onTap: () {
                                      setState(() {
                                        _mediaUrls.removeAt(index);
                                      });
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        color: Colors.black54,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: const Icon(
                                        Icons.close,
                                        color: Colors.white,
                                        size: 16,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                        const SizedBox(height: 12),
                      ],

                      // Add Media Button
                      OutlinedButton.icon(
                        onPressed: _isSaving ? null : _pickImage,
                        icon: const Icon(Icons.add_photo_alternate_outlined),
                        label: Text(
                          _mediaUrls.isEmpty ? 'Add Images' : 'Add More Images',
                          style: GoogleFonts.outfit(),
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            vertical: 16,
                            horizontal: 24,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Dates Section
                      Text(
                        'Timeline',
                        style: GoogleFonts.outfit(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textColor,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Start Date
                      InkWell(
                        onTap: () => _selectDate(context, true),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.calendar_today,
                                color: AppTheme.primaryColor,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  _startDate == null
                                      ? 'Select Start Date'
                                      : '${_startDate!.day}/${_startDate!.month}/${_startDate!.year}',
                                  style: GoogleFonts.outfit(
                                    fontSize: 16,
                                    color: _startDate == null
                                        ? Colors.grey
                                        : AppTheme.textColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Ongoing checkbox
                      CheckboxListTile(
                        value: _isOngoing,
                        onChanged: (value) {
                          setState(() {
                            _isOngoing = value ?? false;
                            if (_isOngoing) _endDate = null;
                          });
                        },
                        title: Text(
                          'This project is ongoing',
                          style: GoogleFonts.outfit(),
                        ),
                        contentPadding: EdgeInsets.zero,
                        activeColor: AppTheme.primaryColor,
                      ),

                      // End Date (only if not ongoing)
                      if (!_isOngoing) ...[
                        const SizedBox(height: 8),
                        InkWell(
                          onTap: () => _selectDate(context, false),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.calendar_today,
                                  color: AppTheme.primaryColor,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    _endDate == null
                                        ? 'Select End Date'
                                        : '${_endDate!.day}/${_endDate!.month}/${_endDate!.year}',
                                    style: GoogleFonts.outfit(
                                      fontSize: 16,
                                      color: _endDate == null
                                          ? Colors.grey
                                          : AppTheme.textColor,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],

                      const SizedBox(height: 32),

                      // Save Buttons
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: _isSaving
                                  ? null
                                  : () => _saveProject(),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: AppTheme.primaryColor,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  side: BorderSide(
                                    color: AppTheme.primaryColor,
                                  ),
                                ),
                              ),
                              child: _isSaving
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : Text(
                                      'Save',
                                      style: GoogleFonts.outfit(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: _isSaving
                                  ? null
                                  : () => _saveProject(postToFeed: true),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primaryColor,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: _isSaving
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              Colors.white,
                                            ),
                                      ),
                                    )
                                  : Text(
                                      'Save & Post',
                                      style: GoogleFonts.outfit(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

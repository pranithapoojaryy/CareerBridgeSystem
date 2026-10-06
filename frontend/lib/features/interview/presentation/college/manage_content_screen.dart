import 'package:flutter/material.dart' hide Text;
import 'package:flutter/material.dart' as material show Text;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:typed_data';

import '../interview_providers.dart';
import 'package:google_fonts/google_fonts.dart';

class ManageContentScreen extends ConsumerStatefulWidget {
  const ManageContentScreen({super.key});

  @override
  ConsumerState<ManageContentScreen> createState() =>
      _ManageContentScreenState();
}

class _ManageContentScreenState extends ConsumerState<ManageContentScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _titleController = TextEditingController();
  final _youtubeUrlController = TextEditingController();
  String? _selectedCategoryId;
  Uint8List? _selectedFileBytes;
  String? _selectedFileName;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _titleController.dispose();
    _youtubeUrlController.dispose();
    super.dispose();
  }

  Future<void> _pickFile(List<String> extensions) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: extensions,
      withData: true,
    );

    if (result != null) {
      if (mounted) {
        setState(() {
          _selectedFileBytes = result.files.single.bytes;
          _selectedFileName = result.files.single.name;
        });
      }
    }
  }

  Future<void> _uploadContent() async {
    if (_titleController.text.isEmpty || _selectedCategoryId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: material.Text('Please fill all required fields'),
          ),
        );
      }
      return;
    }

    if (mounted) setState(() => _isLoading = true);
    try {
      String type = "";
      String? url;

      if (_tabController.index == 0) {
        type = "YouTube";
        url = _youtubeUrlController.text;
        if (url.isEmpty) throw "Please enter a YouTube URL";
      } else if (_tabController.index == 1) {
        type = "Video";
        if (_selectedFileBytes == null) throw "Please select a video file";
        final fileName =
            "${DateTime.now().millisecondsSinceEpoch}_${_selectedFileName}";
        await Supabase.instance.client.storage
            .from('learning-content')
            .uploadBinary(
              "videos/$fileName",
              _selectedFileBytes!,
              fileOptions: const FileOptions(contentType: 'video/mp4'),
            );
        url = Supabase.instance.client.storage
            .from('learning-content')
            .getPublicUrl("videos/$fileName");
      } else {
        type = "PDF";
        if (_selectedFileBytes == null) throw "Please select a PDF file";
        final fileName =
            "${DateTime.now().millisecondsSinceEpoch}_${_selectedFileName}";
        await Supabase.instance.client.storage
            .from('learning-content')
            .uploadBinary(
              "pdfs/$fileName",
              _selectedFileBytes!,
              fileOptions: const FileOptions(contentType: 'application/pdf'),
            );
        url = Supabase.instance.client.storage
            .from('learning-content')
            .getPublicUrl("pdfs/$fileName");
      }

      await ref
          .read(interviewRepositoryProvider)
          .addLearningContent(
            categoryId: _selectedCategoryId!,
            title: _titleController.text,
            type: type,
            url: url,
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: material.Text('Content uploaded successfully!'),
          ),
        );
        _titleController.clear();
        _youtubeUrlController.clear();
        _selectedFileBytes = null;
        _selectedFileName = null;
        ref.invalidate(learningContentProvider(_selectedCategoryId!));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: material.Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(interviewCategoriesProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          categoriesAsync.when(
            data: (categories) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: const Color(0xFFF9F9FF),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedCategoryId,
                  isExpanded: true,
                  hint: material.Text(
                    "Select Category",
                    style: GoogleFonts.poppins(fontSize: 14),
                  ),
                  items: categories
                      .map(
                        (c) => DropdownMenuItem(
                          value: c.id,
                          child: material.Text(
                            c.name,
                            style: GoogleFonts.poppins(fontSize: 14),
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (val) => setState(() => _selectedCategoryId = val),
                ),
              ),
            ),
            loading: () => const LinearProgressIndicator(),
            error: (e, _) => material.Text(
              "Error loading categories: $e",
              style: GoogleFonts.poppins(color: Colors.red),
            ),
          ),
          const SizedBox(height: 24),
          material.Text(
            "Add New Content",
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _titleController,
            decoration: InputDecoration(
              labelText: "Title",
              labelStyle: GoogleFonts.poppins(fontSize: 14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 16),
          TabBar(
            controller: _tabController,
            labelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            tabs: const [
              Tab(text: "YouTube"),
              Tab(text: "Video"),
              Tab(text: "PDF"),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 150,
            child: TabBarView(
              controller: _tabController,
              children: [
                TextField(
                  controller: _youtubeUrlController,
                  decoration: InputDecoration(
                    labelText: "YouTube URL",
                    labelStyle: GoogleFonts.poppins(fontSize: 14),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                Column(
                  children: [
                    ElevatedButton.icon(
                      onPressed: () => _pickFile(['mp4', 'mov', 'avi']),
                      icon: const Icon(Icons.upload_file),
                      label: material.Text(_selectedFileName ?? "Choose Video"),
                    ),
                  ],
                ),
                Column(
                  children: [
                    ElevatedButton.icon(
                      onPressed: () => _pickFile(['pdf']),
                      icon: const Icon(Icons.upload_file),
                      label: material.Text(_selectedFileName ?? "Choose PDF"),
                    ),
                  ],
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: _isLoading ? null : _uploadContent,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1A1F36),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: _isLoading
                ? const CircularProgressIndicator(color: Colors.white)
                : material.Text(
                    "Upload Content",
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                  ),
          ),
          const SizedBox(height: 32),
          material.Text(
            "Existing Content",
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 16),
          if (_selectedCategoryId == null)
            const Center(
              child: material.Text("Select a category to view content."),
            )
          else
            _buildContentList(_selectedCategoryId!),
        ],
      ),
    );
  }

  Widget _buildContentList(String categoryId) {
    final contentAsync = ref.watch(learningContentProvider(categoryId));

    return contentAsync.when(
      data: (contents) {
        if (contents.isEmpty) {
          return const Center(child: material.Text("No content found."));
        }
        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: contents.length,
          itemBuilder: (context, index) {
            final item = contents[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                leading: Icon(
                  item.type == 'YouTube' || item.type == 'Video'
                      ? Icons.play_circle_outline
                      : Icons.description_outlined,
                  color: const Color(0xFF5A6ACF),
                ),
                title: material.Text(
                  item.title,
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                ),
                subtitle: material.Text(
                  item.type,
                  style: GoogleFonts.poppins(),
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: () => _deleteContent(item.id),
                ),
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => material.Text("Error: $e"),
    );
  }

  Future<void> _deleteContent(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const material.Text("Delete Content?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const material.Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const material.Text(
              "Delete",
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      if (mounted) setState(() => _isLoading = true);
      try {
        await ref.read(interviewRepositoryProvider).deleteLearningContent(id);
        ref.invalidate(learningContentProvider(_selectedCategoryId!));
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }
}

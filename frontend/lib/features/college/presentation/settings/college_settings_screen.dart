import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:file_picker/file_picker.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../organization/data/organization_repository.dart';

class CollegeSettingsScreen extends ConsumerStatefulWidget {
  const CollegeSettingsScreen({super.key});

  @override
  ConsumerState<CollegeSettingsScreen> createState() =>
      _CollegeSettingsScreenState();
}

class _CollegeSettingsScreenState extends ConsumerState<CollegeSettingsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  Map<String, dynamic>? _orgData;

  // Controllers
  final _nameController = TextEditingController(); // Not editable usually?
  final _taglineController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _websiteController = TextEditingController();
  final _domainController = TextEditingController();

  // Branding Logic
  String? _logoUrl;
  String? _bannerUrl;

  // Academics
  List<Map<String, dynamic>> _departments = [];

  // Branding Colors
  Color _selectedColor = AppTheme.primaryColor;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(_handleTabChange);
    _fetchOrgData();
  }

  void _handleTabChange() {
    if (_tabController.index == 3 && _orgData != null) {
      _fetchDepartments();
    }
  }

  Future<void> _fetchOrgData() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      final repo = ref.read(organizationRepositoryProvider);
      final org = await repo.getOrganizationByUserId(user.id);
      if (mounted) {
        setState(() {
          _orgData = org;
          _isLoading = false;

          if (org != null) {
            _nameController.text = org['name'] ?? '';
            _taglineController.text = org['tagline'] ?? '';
            _descriptionController.text = org['description'] ?? '';
            _websiteController.text = org['website'] ?? '';
            _domainController.text = org['allowed_emails_domain'] ?? '';
            _logoUrl = org['logo_url'];
            _bannerUrl = org['banner_url'];

            if (org['primary_color'] != null) {
              try {
                String hex = org['primary_color'].replaceAll('#', '');
                _selectedColor = Color(int.parse('0xFF$hex'));
              } catch (_) {}
            }
          }
        });
        if (org != null) {
          _fetchDepartments();
        }
      }
    }
  }

  Future<void> _fetchDepartments() async {
    if (_orgData == null) return;
    final repo = ref.read(organizationRepositoryProvider);
    final depts = await repo.getDepartments(_orgData!['id']);
    if (mounted) {
      setState(() => _departments = depts);
    }
  }

  // ... (Existing save methods: _saveGeneral, _saveBranding, _saveSecurity)

  void _showAddDepartmentDialog() {
    final nameCtrl = TextEditingController();
    final codeCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Department'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: 'Department Name'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: codeCtrl,
              decoration: const InputDecoration(
                labelText: 'Short Code (e.g. CSE)',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              if (nameCtrl.text.isNotEmpty &&
                  codeCtrl.text.isNotEmpty &&
                  _orgData != null) {
                Navigator.pop(context);
                try {
                  await ref
                      .read(organizationRepositoryProvider)
                      .addDepartment(
                        _orgData!['id'],
                        nameCtrl.text,
                        codeCtrl.text,
                      );
                  _fetchDepartments(); // Refresh list
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Department Added')),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text('Failed: $e')));
                  }
                }
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  Widget _buildAcademicsTab() {
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _sectionTitle('Academic Departments'),
              OutlinedButton.icon(
                onPressed: _showAddDepartmentDialog,
                icon: const Icon(Icons.add),
                label: const Text('Add Department'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: _selectedColor,
                  side: BorderSide(color: _selectedColor),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          if (_departments.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(40.0),
                child: Text(
                  'No departments added yet.',
                  style: GoogleFonts.outfit(color: Colors.grey[500]),
                ),
              ),
            )
          else
            Expanded(
              child: ListView.builder(
                itemCount: _departments.length,
                itemBuilder: (context, index) {
                  final dept = _departments[index];
                  return Card(
                    elevation: 0,
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: Colors.grey[200]!),
                    ),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: _selectedColor.withValues(alpha: 0.1),
                        child: Text(
                          (dept['code'] ?? '?')[0],
                          style: TextStyle(color: _selectedColor),
                        ),
                      ),
                      title: Text(
                        dept['name'] ?? 'Unknown',
                        style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text('Code: ${dept['code']}'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        // Future: Navigate to Program/Batch management for this department
                      },
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _saveGeneral(BuildContext context) async {
    if (_orgData == null) return;
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final repo = ref.read(organizationRepositoryProvider);
    await repo.updateOrganizationProfile(
      orgId: _orgData!['id'],
      tagline: _taglineController.text,
      description: _descriptionController.text,
      // website is not in updateOrganizationProfile yet, might need update
    );
    if (mounted) {
      scaffoldMessenger.showSnackBar(
        const SnackBar(content: Text('General Settings Saved')),
      );
    }
  }

  Future<void> _saveBranding(BuildContext context) async {
    if (_orgData == null) return;
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final repo = ref.read(organizationRepositoryProvider);
    final hexCode =
        '#${_selectedColor.value.toRadixString(16).substring(2).toUpperCase()}';

    await repo.updateOrganizationProfile(
      orgId: _orgData!['id'],
      primaryColor: hexCode,
    );
    if (mounted) {
      scaffoldMessenger.showSnackBar(
        const SnackBar(content: Text('Branding Updated')),
      );
    }
  }

  Future<void> _saveSecurity(BuildContext context) async {
    if (_orgData == null) return;
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final repo = ref.read(organizationRepositoryProvider);

    await repo.updateOrganizationProfile(
      orgId: _orgData!['id'],
      allowedDomain: _domainController.text.trim().toLowerCase(),
    );
    if (mounted) {
      scaffoldMessenger.showSnackBar(
        const SnackBar(content: Text('Security Settings Updated')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      backgroundColor: Colors.transparent, // Parent handles background
      body: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'College Settings',
                  style: GoogleFonts.outfit(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 24),
                Container(
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: TabBar(
                    controller: _tabController,
                    isScrollable: true,
                    labelColor: Colors.black87,
                    unselectedLabelColor: Colors.grey[600],
                    indicator: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                    tabs: const [
                      Tab(text: 'General Profile'),
                      Tab(text: 'Branding & Identity'),
                      Tab(text: 'Security & Domain'),
                      Tab(text: 'Academic Structure'),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Content
          Expanded(
            child: Container(
              color: Colors.white,
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildGeneralTab(),
                  _buildBrandingTab(),
                  _buildSecurityTab(),
                  _buildAcademicsTab(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGeneralTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('Basic Information'),
          const SizedBox(height: 16),
          _textField('College Name', _nameController, enabled: false),
          const SizedBox(height: 16),
          _textField('Tagline / Motto', _taglineController),
          const SizedBox(height: 16),
          _textField('Description', _descriptionController, maxLines: 4),
          const SizedBox(height: 16),
          _textField('Website', _websiteController),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: () => _saveGeneral(context),
            style: FilledButton.styleFrom(backgroundColor: _selectedColor),
            child: const Text('Save Changes'),
          ),
        ],
      ),
    );
  }

  // --- LOGIC HELPERS ---

  Future<void> _pickAndUploadImage(String type) async {
    if (_orgData == null) return;
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        withData: true,
      );
      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        setState(() => _isLoading = true);

        final url = await ref
            .read(organizationRepositoryProvider)
            .uploadOrganizationAsset(
              orgId: _orgData!['id'],
              fileBytes: file.bytes!,
              fileName: file.name,
              type: type,
            );

        setState(() {
          if (type == 'logo') {
            _logoUrl = url;
            _orgData!['logo_url'] = url;
          } else {
            _bannerUrl = url;
            _orgData!['banner_url'] = url;
          }
          _isLoading = false;
        });

        // Auto save reference to org
        await ref
            .read(organizationRepositoryProvider)
            .updateOrganizationProfile(
              orgId: _orgData!['id'],
              bannerUrl: type == 'banner' ? url : null,
            );

        if (type == 'logo') {
          // If logo column missing, might need to add it or store in metadata.
          await Supabase.instance.client
              .from('organizations')
              .update({'logo_url': url})
              .eq('id', _orgData!['id']);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Upload failed: $e')));
      }
    }
  }

  Widget _buildBrandingTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('Visual Identity'),
          const SizedBox(height: 24),

          // Identity Uploads
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Logo
              Column(
                children: [
                  Text(
                    'College Logo',
                    style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () => _pickAndUploadImage('logo'),
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.grey[300]!),
                        image: _logoUrl != null
                            ? DecorationImage(
                                image: NetworkImage(_logoUrl!),
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                      child: _logoUrl == null
                          ? const Icon(
                              Icons.camera_alt,
                              color: Colors.grey,
                              size: 32,
                            )
                          : Stack(
                              children: [
                                Positioned(
                                  bottom: 0,
                                  right: 0,
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: const BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.edit, size: 16),
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 32),
              // Banner
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Dashboard Banner',
                      style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: () => _pickAndUploadImage('banner'),
                      child: Container(
                        height: 120,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey[300]!),
                          image: _bannerUrl != null
                              ? DecorationImage(
                                  image: NetworkImage(_bannerUrl!),
                                  fit: BoxFit.cover,
                                )
                              : null,
                        ),
                        child: Center(
                          child: _bannerUrl == null
                              ? Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.image, color: Colors.grey),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Upload Banner Image',
                                      style: GoogleFonts.outfit(
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                )
                              : Container(
                                  alignment: Alignment.bottomRight,
                                  padding: const EdgeInsets.all(8),
                                  child: Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color:
                                          Colors.white.withValues(alpha: 0.8),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.edit, size: 16),
                                  ),
                                ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 32),
          const Divider(),
          const SizedBox(height: 24),

          Text(
            'Primary Brand Color',
            style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            children:
                [
                  Colors.indigo,
                  Colors.red,
                  Colors.teal,
                  Colors.orange,
                  Colors.purple,
                  Colors.black,
                ].map((color) {
                  return GestureDetector(
                    onTap: () => setState(() => _selectedColor = color),
                    child: CircleAvatar(
                      backgroundColor: color,
                      radius: 20,
                      child: _selectedColor == color
                          ? const Icon(
                              Icons.check,
                              color: Colors.white,
                              size: 20,
                            )
                          : null,
                    ),
                  );
                }).toList(),
          ),
          const SizedBox(height: 32),
          FilledButton(
            onPressed: () => _saveBranding(context),
            style: FilledButton.styleFrom(backgroundColor: _selectedColor),
            child: const Text('Update Branding'),
          ),
        ],
      ),
    );
  }

  Widget _buildSecurityTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('Access Control'),
          const SizedBox(height: 16),
          _textField(
            'Allowed Email Domain',
            _domainController,
            hint: 'e.g., pim.ac.in',
          ),
          const SizedBox(height: 8),
          Text(
            'Students with this domain will be auto-verified and linked to your college.',
            style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey[600]),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: () => _saveSecurity(context),
            style: FilledButton.styleFrom(backgroundColor: _selectedColor),
            child: const Text('Update Security'),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.outfit(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
      ),
    );
  }

  Widget _textField(
    String label,
    TextEditingController controller, {
    bool enabled = true,
    int maxLines = 1,
    String? hint,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          enabled: enabled,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hint,
            filled: !enabled,
            fillColor: enabled ? Colors.white : Colors.grey[100],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
          ),
        ),
      ],
    );
  }
}

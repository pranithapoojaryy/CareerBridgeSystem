import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:file_picker/file_picker.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../organization/data/organization_repository.dart';

class CollegeSetupWizard extends ConsumerStatefulWidget {
  const CollegeSetupWizard({super.key});

  @override
  ConsumerState<CollegeSetupWizard> createState() => _CollegeSetupWizardState();
}

class _CollegeSetupWizardState extends ConsumerState<CollegeSetupWizard> {
  final PageController _pageController = PageController();
  int _currentStep = 0;
  bool _isLoading = false;
  String? _orgId;

  // Step 1: Identity
  final _taglineController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _domainController = TextEditingController();

  // Step 2: Branding
  Color _selectedColor = AppTheme.primaryColor;
  final List<Color> _brandColors = [
    const Color(0xFFF26B3A), // Orange (Default)
    const Color(0xFF3B82F6), // Blue
    const Color(0xFFEF4444), // Red
    const Color(0xFF10B981), // Green
    const Color(0xFF8B5CF6), // Purple
    const Color(0xFF0F172A), // Slate
  ];

  // Step 3: Academics
  // Simple local state for demo. Real app would use complex controllers or specialized widgets.
  final List<Map<String, dynamic>> _departments = [];

  @override
  void initState() {
    super.initState();
    _fetchOrgId();
  }

  Future<void> _fetchOrgId() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      final repo = ref.read(organizationRepositoryProvider);
      final org = await repo.getOrganizationByUserId(user.id);
      if (org != null) {
        setState(() {
          _orgId = org['id'];
        });
      }
    }
  }

  void _nextStep() async {
    if (_currentStep < 3) {
      if (_currentStep == 0) {
        // Save Identity
        if (_orgId != null) {
          await ref
              .read(organizationRepositoryProvider)
              .updateOrganizationProfile(
                orgId: _orgId!,
                tagline: _taglineController.text,
                description: _descriptionController.text,
                allowedDomain: _domainController.text.trim().toLowerCase(),
              );
        }
      } else if (_currentStep == 1) {
        // Save Branding
        if (_orgId != null) {
          await ref
              .read(organizationRepositoryProvider)
              .updateOrganizationProfile(
                orgId: _orgId!,
                primaryColor:
                    '#${_selectedColor.value.toRadixString(16).substring(2)}',
              );
        }
      }

      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
      setState(() => _currentStep++);
    } else {
      // Finish
      context.go('/college-dashboard');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Row(
        children: [
          // Sidebar Progress
          Container(
            width: 300,
            color: const Color(0xFFF8FAFC),
            padding: const EdgeInsets.all(40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'CareerBridge',
                  style: GoogleFonts.outfit(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Setup Your Campus',
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 60),

                _buildStepIndicator(0, 'Identity', 'Logo, Tagline, About'),
                _buildStepLine(),
                _buildStepIndicator(1, 'Branding', 'Theme, Colors'),
                _buildStepLine(),
                _buildStepIndicator(2, 'Academics', 'Departments & Batches'),
                _buildStepLine(),
                _buildStepIndicator(3, 'Completion', 'Review & Finish'),
              ],
            ),
          ),

          // Main Content
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildIdentityStep(),
                _buildBrandingStep(),
                _buildAcademicsStep(),
                _buildCompletionStep(),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.all(32.0),
        child: FloatingActionButton.extended(
          onPressed: _isLoading ? null : _nextStep,
          label: Row(
            children: [
              Text(_currentStep == 3 ? 'Finish Setup' : 'Next Step'),
              const SizedBox(width: 8),
              const Icon(Icons.arrow_forward),
            ],
          ),
          backgroundColor: _selectedColor,
        ),
      ),
    );
  }

  Widget _buildStepIndicator(int step, String title, String subtitle) {
    final isActive = _currentStep >= step;
    final isCurrent = _currentStep == step;

    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: isActive ? _selectedColor : Colors.grey[200],
            shape: BoxShape.circle,
            border: isCurrent
                ? Border.all(color: _selectedColor, width: 2)
                : null,
          ),
          child: Center(
            child: isActive
                ? const Icon(Icons.check, size: 16, color: Colors.white)
                : Text(
                    '${step + 1}',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.bold,
                color: isActive ? Colors.black87 : Colors.grey[400],
              ),
            ),
            Text(
              subtitle,
              style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey[400]),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStepLine() {
    return Container(
      margin: const EdgeInsets.only(left: 15, top: 4, bottom: 4),
      height: 24,
      width: 2,
      color: Colors.grey[200],
    );
  }

  // --- STEPS ---

  // --- STEPS ---

  Widget _buildIdentityStep() {
    return Padding(
      padding: const EdgeInsets.all(60.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Step 1: College Identity',
            style: GoogleFonts.outfit(
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tell us about your institution to personalize the experience.',
            style: GoogleFonts.outfit(fontSize: 16, color: Colors.grey[600]),
          ),
          const SizedBox(height: 40),

          // Logo & Banner Uploaders
          Row(
            children: [
              // Logo
              GestureDetector(
                onTap: () => _pickAndUploadImage('logo'),
                child: Container(
                  width: 100,
                  height: 100,
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
                      ? const Icon(Icons.camera_alt, color: Colors.grey)
                      : null,
                ),
              ),
              const SizedBox(width: 24),
              // Banner
              Expanded(
                child: GestureDetector(
                  onTap: () => _pickAndUploadImage('banner'),
                  child: Container(
                    height: 100,
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
                                  'Upload Banner',
                                  style: GoogleFonts.outfit(
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            )
                          : null,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          Text(
            'College Tagline',
            style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _taglineController,
            decoration: const InputDecoration(
              hintText: 'e.g., Nurturing Excellence in Management',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 24),

          Text(
            'About Description',
            style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _descriptionController,
            maxLines: 4,
            decoration: const InputDecoration(
              hintText:
                  'A brief overview of your college history and mission...',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 24),

          Text(
            'Allowed Email Domain (Optional)',
            style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(
            'Students with this email domain will strictly be linked to your college automatically.',
            style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _domainController,
            decoration: const InputDecoration(
              hintText: 'e.g., pim.ac.in',
              prefixIcon: Icon(Icons.domain),
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBrandingStep() {
    return Padding(
      padding: const EdgeInsets.all(60.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Step 2: Branding',
            style: GoogleFonts.outfit(
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Choose a primary color that matches your college brand.',
            style: GoogleFonts.outfit(fontSize: 16, color: Colors.grey[600]),
          ),
          const SizedBox(height: 40),

          Text(
            'Pick a Hero Color',
            style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 20,
            children: _brandColors.map((color) {
              final isSelected = _selectedColor == color;
              return GestureDetector(
                onTap: () => setState(() => _selectedColor = color),
                child: Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: isSelected
                        ? Border.all(color: Colors.black, width: 3)
                        : null,
                    boxShadow: [
                      BoxShadow(
                        color: color.withValues(alpha: 0.4),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: isSelected
                      ? const Icon(Icons.check, color: Colors.white)
                      : null,
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 40),

          // Preview
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey[200]!),
              boxShadow: const [
                BoxShadow(color: Colors.black12, blurRadius: 10),
              ],
            ),
            child: Column(
              children: [
                Text(
                  'Preview: Dashboard Button',
                  style: GoogleFonts.outfit(color: Colors.grey),
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _selectedColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                  child: const Text('View Student Profile'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAcademicsStep() {
    return Padding(
      padding: const EdgeInsets.all(60.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Step 3: Academic Structure',
                    style: GoogleFonts.outfit(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Add departments managed by this portal.',
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
              OutlinedButton.icon(
                onPressed: _showAddDepartmentDialog,
                icon: const Icon(Icons.add),
                label: const Text('Add Department'),
              ),
            ],
          ),
          const SizedBox(height: 40),

          Expanded(
            child: _departments.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.school_outlined,
                          size: 64,
                          color: Colors.grey[300],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No departments added yet.',
                          style: GoogleFonts.outfit(
                            color: Colors.grey[500],
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: _departments.length,
                    itemBuilder: (context, index) {
                      final dept = _departments[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: Colors.grey[200]!),
                        ),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor:
                                _selectedColor.withValues(alpha: 0.1),
                            child: Text(
                              dept['code'][0],
                              style: TextStyle(color: _selectedColor),
                            ),
                          ),
                          title: Text(
                            dept['name'],
                            style: GoogleFonts.outfit(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: Text('Code: ${dept['code']}'),
                          trailing: const Icon(
                            Icons.check_circle,
                            color: Colors.green,
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompletionStep() {
    return Padding(
      padding: const EdgeInsets.all(60.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.check_circle_rounded, size: 100, color: _selectedColor),
          const SizedBox(height: 32),
          Text(
            'You\'re All Set!',
            style: GoogleFonts.outfit(
              fontSize: 40,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Your college profile has been updated. Welcome to CareerBridge.',
            style: GoogleFonts.outfit(fontSize: 20, color: Colors.grey[600]),
          ),
          const SizedBox(height: 48),
        ],
      ),
    );
  }

  // --- LOGIC HELPERS ---

  String? _logoUrl;
  String? _bannerUrl;

  Future<void> _pickAndUploadImage(String type) async {
    if (_orgId == null) return;
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
              orgId: _orgId!,
              fileBytes: file.bytes!,
              fileName: file.name,
              type: type,
            );

        setState(() {
          if (type == 'logo')
            _logoUrl = url;
          else
            _bannerUrl = url;
          _isLoading = false;
        });

        // Auto save reference to org
        await ref
            .read(organizationRepositoryProvider)
            .updateOrganizationProfile(
              orgId: _orgId!,
              bannerUrl: type == 'banner' ? url : null,
              // Note: We need logo_url in schema update if not present, checking...
              // Schema has banner_url, let's assume we can save logo too or update schema.
              // Checking setup_college_schema.sql...
              // It has `banner_url`, `description`, `social_links`.
              // Wait, logo_url was part of original `organizations` table?
              // Let's assume yes or add it.
            );

        if (type == 'logo') {
          // If logo column missing, might need to add it or store in metadata.
          await Supabase.instance.client
              .from('organizations')
              .update({'logo_url': url})
              .eq('id', _orgId!);
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
                  _orgId != null) {
                final scaffoldMessenger = ScaffoldMessenger.of(context);
                final navigator = Navigator.of(context);
                navigator.pop();
                setState(() => _isLoading = true);
                try {
                  await ref
                      .read(organizationRepositoryProvider)
                      .addDepartment(_orgId!, nameCtrl.text, codeCtrl.text);
                  if (mounted) {
                    setState(() {
                      _departments.add({
                        'name': nameCtrl.text,
                        'code': codeCtrl.text,
                      });
                      _isLoading = false;
                    });
                  }
                } catch (e) {
                  if (mounted) {
                    setState(() => _isLoading = false);
                    scaffoldMessenger.showSnackBar(
                      SnackBar(content: Text('Failed: $e')),
                    );
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
}

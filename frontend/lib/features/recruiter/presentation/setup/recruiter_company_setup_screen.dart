import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/theme/app_theme.dart';

class RecruiterCompanySetupScreen extends ConsumerStatefulWidget {
  const RecruiterCompanySetupScreen({super.key});

  @override
  ConsumerState<RecruiterCompanySetupScreen> createState() =>
      _RecruiterCompanySetupScreenState();
}

class _RecruiterCompanySetupScreenState
    extends ConsumerState<RecruiterCompanySetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _companyNameController = TextEditingController();
  final _websiteController = TextEditingController();
  final _industryController = TextEditingController();
  final _addressController = TextEditingController();
  final _descriptionController = TextEditingController();

  PlatformFile? _pickedLogo;
  bool _isLoading = false;

  @override
  void dispose() {
    _companyNameController.dispose();
    _websiteController.dispose();
    _industryController.dispose();
    _addressController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickLogo() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image);
    if (result != null) {
      setState(() {
        _pickedLogo = result.files.first;
      });
    }
  }

  Future<void> _submitSetup() async {
    if (!_formKey.currentState!.validate()) return;
    if (_pickedLogo == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please upload a company logo')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final userId = Supabase.instance.client.auth.currentUser!.id;

      // 1. Upload Logo (Mock for now or implement real storage if bucket exists)
      // For MVP we might just use a placeholder URL or assume upload logic exists
      // Real implementation would look like:
      // final logoPath = '/companies/$userId/logo.${_pickedLogo!.extension}';
      // await Supabase.instance.client.storage.from('organization_assets').uploadBinary(logoPath, _pickedLogo!.bytes!);
      // final logoUrl = Supabase.instance.client.storage.from('organization_assets').getPublicUrl(logoPath);
      String logoUrl = 'https://via.placeholder.com/150'; // Placeholder

      // 2. Create Company
      final companyResponse = await Supabase.instance.client
          .from('companies')
          .insert({
            'name': _companyNameController.text.trim(),
            'website': _websiteController.text.trim(),
            'industry': _industryController.text.trim(),
            'address': _addressController.text.trim(),
            'description': _descriptionController.text.trim(),
            'logo_url': logoUrl,
            'is_verified': false,
            'trust_score': 10, // Starting score
            'created_by': userId, // Explicitly set owner for RLS policies
          })
          .select()
          .single();

      final companyId = companyResponse['id'];

      // 3. Create/Update Recruiter Profile
      // Check if profile exists first
      final existingProfile = await Supabase.instance.client
          .from('recruiters')
          .select()
          .eq('id', userId)
          .maybeSingle();

      if (existingProfile != null) {
        await Supabase.instance.client
            .from('recruiters')
            .update({'company_id': companyId, 'is_primary_contact': true})
            .eq('id', userId);
      } else {
        await Supabase.instance.client.from('recruiters').insert({
          'id': userId,
          'company_id': companyId,
          'is_primary_contact': true,
          // 'full_name': ... // Should fetch from auth meta
        });
      }

      // 4. Navigate to Dashboard
      if (mounted) {
        context.go('/recruiter-dashboard');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: AppTheme.gradientBackground,
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Card(
                elevation: 8,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Setup Company Profile',
                          style: GoogleFonts.outfit(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryColor,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Tell us about your organization to verify your account.',
                          style: GoogleFonts.outfit(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 32),

                        // Logo Upload
                        Center(
                          child: GestureDetector(
                            onTap: _pickLogo,
                            child: CircleAvatar(
                              radius: 50,
                              backgroundColor: Colors.grey[100],
                              backgroundImage: _pickedLogo != null
                                  ? MemoryImage(
                                      _pickedLogo!.bytes!,
                                    ) // Web compatibility
                                  : null,
                              child: _pickedLogo == null
                                  ? Icon(
                                      Icons.add_a_photo_rounded,
                                      size: 32,
                                      color: Colors.grey[400],
                                    )
                                  : null,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Center(
                          child: Text(
                            'Upload Logo',
                            style: GoogleFonts.outfit(
                              fontSize: 12,
                              color: AppTheme.primaryColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),

                        TextFormField(
                          controller: _companyNameController,
                          decoration: const InputDecoration(
                            labelText: 'Company Name',
                            prefixIcon: Icon(Icons.business),
                          ),
                          validator: (v) =>
                              v?.isEmpty == true ? 'Required' : null,
                        ),
                        const SizedBox(height: 16),

                        TextFormField(
                          controller: _websiteController,
                          decoration: const InputDecoration(
                            labelText: 'Website URL',
                            prefixIcon: Icon(Icons.language),
                          ),
                          validator: (v) =>
                              v?.isEmpty == true ? 'Required' : null,
                        ),
                        const SizedBox(height: 16),

                        TextFormField(
                          controller: _industryController,
                          decoration: const InputDecoration(
                            labelText: 'Industry (e.g. Fintech, Edtech)',
                            prefixIcon: Icon(Icons.category),
                          ),
                          validator: (v) =>
                              v?.isEmpty == true ? 'Required' : null,
                        ),
                        const SizedBox(height: 16),

                        TextFormField(
                          controller: _addressController,
                          decoration: const InputDecoration(
                            labelText: 'HQ Address',
                            prefixIcon: Icon(Icons.location_on),
                          ),
                          validator: (v) =>
                              v?.isEmpty == true ? 'Required' : null,
                        ),
                        const SizedBox(height: 16),

                        TextFormField(
                          controller: _descriptionController,
                          maxLines: 3,
                          decoration: const InputDecoration(
                            labelText: 'Short Description',
                            prefixIcon: Icon(Icons.description),
                            alignLabelWithHint: true,
                          ),
                          validator: (v) =>
                              v?.isEmpty == true ? 'Required' : null,
                        ),

                        const SizedBox(height: 32),

                        FilledButton(
                          onPressed: _isLoading ? null : _submitSetup,
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  height: 24,
                                  width: 24,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text('Save & Continue'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:file_picker/file_picker.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/certification_providers.dart';

class AddCertificationDialog extends ConsumerStatefulWidget {
  const AddCertificationDialog({super.key});

  @override
  ConsumerState<AddCertificationDialog> createState() =>
      _AddCertificationDialogState();
}

class _AddCertificationDialogState
    extends ConsumerState<AddCertificationDialog> {
  final _formKey = GlobalKey<FormState>();
  final _certificateNameController = TextEditingController();
  final _certificateIdController = TextEditingController();
  final _certificateUrlController = TextEditingController();
  final _customProviderController = TextEditingController(); // NEW

  String? _selectedProviderId;
  bool _isCustomProvider = false; // NEW
  DateTime? _issueDate;
  DateTime? _expiryDate;

  PlatformFile? _selectedFile; // Changed from String? _selectedFilePath
  bool _isLoading = false;

  @override
  void dispose() {
    _certificateNameController.dispose();
    _certificateIdController.dispose();
    _certificateUrlController.dispose();
    _customProviderController.dispose(); // NEW
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final providersAsync = ref.watch(certificationProvidersProvider);

    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 700),
        child: Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Add New Certificate',
                    style: GoogleFonts.outfit(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textColor,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Form
              Flexible(
                child: Form(
                  key: _formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Certificate Provider
                        _buildProviderDropdown(providersAsync),

                        // Custom Provider Name (Conditional)
                        if (_isCustomProvider) ...[
                          const SizedBox(height: 20),
                          _buildCustomProviderField(),
                        ],

                        const SizedBox(height: 20),

                        // Certificate Name
                        _buildCertificateNameField(),

                        const SizedBox(height: 20),

                        // Certificate ID
                        _buildCertificateIdField(),

                        const SizedBox(height: 20),

                        // Certificate URL
                        _buildCertificateUrlField(),

                        const SizedBox(height: 20),

                        // Dates Row
                        _buildDatesRow(),

                        const SizedBox(height: 20),

                        // File Upload
                        _buildFileUpload(),

                        const SizedBox(height: 24),

                        // Info Box
                        _buildInfoBox(),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Action Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: _isLoading
                        ? null
                        : () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 16),
                  FilledButton(
                    onPressed: _isLoading ? null : _submitCertification,
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Add Certificate'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProviderDropdown(
    AsyncValue<List<Map<String, dynamic>>> providersAsync,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Certification Provider *',
          style: GoogleFonts.outfit(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppTheme.textColor,
          ),
        ),
        const SizedBox(height: 8),
        providersAsync.when(
          data: (providers) {
            if (providers.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning, color: Colors.orange[600]),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'No certification providers found. Please run the database migration first.',
                        style: GoogleFonts.outfit(color: Colors.orange[700]),
                      ),
                    ),
                  ],
                ),
              );
            }

            // Use simple text-only dropdown to avoid layout issues
            return DropdownButtonFormField<String>(
              value: _selectedProviderId,
              decoration: InputDecoration(
                hintText: 'Select certification provider',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please select a provider';
                }
                return null;
              },
              items: [
                ...providers.map((provider) {
                  final displayText =
                      '${provider['name']} (${provider['trust_score']}%)';
                  return DropdownMenuItem<String>(
                    value: provider['id'],
                    child: Text(
                      displayText,
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  );
                }),
                // Add "Other" option
                DropdownMenuItem<String>(
                  value: 'OTHER',
                  child: Text(
                    'Other / Not Listed',
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedProviderId = value;
                  _isCustomProvider = value == 'OTHER';
                });
              },
              isExpanded: true,
              menuMaxHeight: 300,
            );
          },
          loading: () => Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                SizedBox(width: 12),
                Text('Loading providers...'),
              ],
            ),
          ),
          error: (err, stack) => Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.red[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.red[200]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.error, color: Colors.red[600]),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Error loading providers',
                        style: GoogleFonts.outfit(
                          color: Colors.red[700],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Please ensure the certification system database migration has been run.',
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    color: Colors.red[600],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCustomProviderField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Provider Name *',
          style: GoogleFonts.outfit(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppTheme.textColor,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _customProviderController,
          decoration: InputDecoration(
            hintText: 'Enter the name of the issuing organization',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          validator: (value) {
            if (_isCustomProvider && (value == null || value.trim().isEmpty)) {
              return 'Please enter provider name';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildCertificateNameField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Certificate Name *',
          style: GoogleFonts.outfit(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppTheme.textColor,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _certificateNameController,
          decoration: InputDecoration(
            hintText: 'e.g., Machine Learning Specialization',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter certificate name';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildCertificateIdField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Certificate ID',
          style: GoogleFonts.outfit(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppTheme.textColor,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _certificateIdController,
          decoration: InputDecoration(
            hintText: 'Certificate ID or number (if available)',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ],
    );
  }

  Widget _buildCertificateUrlField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Verification URL',
          style: GoogleFonts.outfit(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppTheme.textColor,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _certificateUrlController,
          decoration: InputDecoration(
            hintText: 'Public verification URL (if available)',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          validator: (value) {
            if (value != null && value.isNotEmpty) {
              final uri = Uri.tryParse(value);
              if (uri == null || !uri.hasAbsolutePath) {
                return 'Please enter a valid URL';
              }
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildDatesRow() {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Issue Date',
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textColor,
                ),
              ),
              const SizedBox(height: 8),
              InkWell(
                onTap: () => _selectDate(context, true),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _issueDate != null
                            ? '${_issueDate!.day}/${_issueDate!.month}/${_issueDate!.year}'
                            : 'Select date',
                        style: GoogleFonts.outfit(
                          color: _issueDate != null
                              ? AppTheme.textColor
                              : Colors.grey[600],
                        ),
                      ),
                      const Icon(Icons.calendar_today, size: 20),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Expiry Date',
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textColor,
                ),
              ),
              const SizedBox(height: 8),
              InkWell(
                onTap: () => _selectDate(context, false),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _expiryDate != null
                            ? '${_expiryDate!.day}/${_expiryDate!.month}/${_expiryDate!.year}'
                            : 'No expiry',
                        style: GoogleFonts.outfit(
                          color: _expiryDate != null
                              ? AppTheme.textColor
                              : Colors.grey[600],
                        ),
                      ),
                      const Icon(Icons.calendar_today, size: 20),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFileUpload() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Certificate File',
          style: GoogleFonts.outfit(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppTheme.textColor,
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: _pickFile,
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              border: Border.all(
                color: Colors.grey[300]!,
                style: BorderStyle.solid,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Icon(
                  _selectedFile != null
                      ? Icons.check_circle
                      : Icons.cloud_upload,
                  size: 48,
                  color: _selectedFile != null
                      ? Colors.green
                      : Colors.grey[400],
                ),
                const SizedBox(height: 12),
                Text(
                  _selectedFile != null
                      ? 'File selected: ${_selectedFile!.name}'
                      : 'Click to upload certificate image/PDF',
                  style: GoogleFonts.outfit(
                    color: _selectedFile != null
                        ? Colors.green[700]
                        : Colors.grey[600],
                    fontWeight: _selectedFile != null
                        ? FontWeight.w600
                        : FontWeight.normal,
                  ),
                  textAlign: TextAlign.center,
                ),
                if (_selectedFile == null) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Supported formats: JPG, PNG, PDF (Max 10MB)',
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoBox() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: Colors.blue[600]),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Your certificate will be automatically validated using our smart validation engine. This may take a few minutes.',
              style: GoogleFonts.outfit(fontSize: 12, color: Colors.blue[700]),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _selectDate(BuildContext context, bool isIssueDate) async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365 * 10)),
    );

    if (date != null) {
      setState(() {
        if (isIssueDate) {
          _issueDate = date;
        } else {
          _expiryDate = date;
        }
      });
    }
  }

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'png', 'jpeg', 'pdf'],
        withData: true, // Needed for Web to get bytes
      );

      if (result != null && result.files.isNotEmpty) {
        setState(() {
          _selectedFile = result.files.first;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error picking file: $e')));
      }
    }
  }

  Future<void> _submitCertification() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await ref
          .read(certificationNotifierProvider.notifier)
          .addCertification(
            certificateName: _certificateNameController.text.trim(),
            providerId: _isCustomProvider
                ? null
                : _selectedProviderId, // Pass null if custom
            issuerName: _isCustomProvider
                ? _customProviderController.text.trim()
                : null, // Pass custom name
            certificateId: _certificateIdController.text.trim().isNotEmpty
                ? _certificateIdController.text.trim()
                : null,
            certificateUrl: _certificateUrlController.text.trim().isNotEmpty
                ? _certificateUrlController.text.trim()
                : null,
            issueDate: _issueDate,
            expiryDate: _expiryDate,
            file: _selectedFile,
          );

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Certificate added successfully! Validation in progress...',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error adding certificate: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}

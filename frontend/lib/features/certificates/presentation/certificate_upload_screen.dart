import 'package:flutter/material.dart';
import '../domain/certificate_model.dart';
import 'widgets/trust_shield_widget.dart';

class CertificateUploadScreen extends StatefulWidget {
  const CertificateUploadScreen({super.key});

  @override
  State<CertificateUploadScreen> createState() =>
      _CertificateUploadScreenState();
}

class _CertificateUploadScreenState extends State<CertificateUploadScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _issuerController = TextEditingController();
  final _idController = TextEditingController();
  final _urlController = TextEditingController();

  // Dynamic State
  ProviderCategory _detectedCategory = ProviderCategory.D;
  String? _categoryMessage;

  @override
  void initState() {
    super.initState();
    _nameController.addListener(_analyzeInput);
    _issuerController.addListener(_analyzeInput);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _issuerController.dispose();
    _idController.dispose();
    _urlController.dispose();
    super.dispose();
  }

  // The "Brain" of the UI - runs on every keystroke
  void _analyzeInput() {
    final text = '${_nameController.text} ${_issuerController.text}'
        .toLowerCase();

    ProviderCategory newCat = ProviderCategory.D;
    String? msg;

    if (text.contains('coursera') ||
        text.contains('udemy') ||
        text.contains('nptel') ||
        text.contains('infosys') ||
        text.contains('aws') ||
        text.contains('google')) {
      newCat = ProviderCategory.A;
      msg = "🌟 Recognized Top Provider! Auto-Verification Enabled.";
    } else if (text.contains('university') ||
        text.contains('college') ||
        text.contains('institute') ||
        text.contains('iit') ||
        text.contains('nit')) {
      newCat = ProviderCategory.B;
      msg =
          "🏫 Educational Institution detected. Will require Faculty Approval.";
    } else if (text.contains('internship') ||
        text.contains('pv') ||
        text.contains('ltd')) {
      newCat = ProviderCategory.C;
      msg = "🏢 Company/Internship detected. We may check domain/email.";
    }

    if (newCat != _detectedCategory) {
      setState(() {
        _detectedCategory = newCat;
        _categoryMessage = msg;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Certificate')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeader(),
              const SizedBox(height: 24),

              // Name Input
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Certificate Name',
                  hintText: 'e.g. AWS Certified Cloud Practitioner',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.badge),
                ),
                validator: (v) => v?.isEmpty == true ? 'Required' : null,
              ),
              const SizedBox(height: 16),

              // Issuer Input
              TextFormField(
                controller: _issuerController,
                decoration: const InputDecoration(
                  labelText: 'Issuing Organization',
                  hintText: 'e.g. Coursera, Google, IIT Bombay',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.business),
                ),
                validator: (v) => v?.isEmpty == true ? 'Required' : null,
              ),

              // Dynamic Feedback Section
              if (_categoryMessage != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _getCategoryColor().withValues(alpha: 0.1),
                    border: Border.all(color: _getCategoryColor()),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.auto_awesome, color: _getCategoryColor()),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _categoryMessage!,
                          style: TextStyle(
                            color: _getCategoryColor(),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 16),

              // Credential Fields (Only show relevance based on category)
              Text(
                'Verification Details',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 16),

              if (_detectedCategory == ProviderCategory.A) ...[
                TextFormField(
                  controller: _urlController,
                  decoration: const InputDecoration(
                    labelText: 'Credential URL',
                    hintText: 'https://coursera.org/verify/...',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.link),
                    suffixIcon: Icon(Icons.check_circle, color: Colors.green),
                    helperText: 'Instant verification for supported providers',
                  ),
                ),
                const SizedBox(height: 16),
              ],

              TextFormField(
                controller: _idController,
                decoration: const InputDecoration(
                  labelText: 'Credential ID (Optional)',
                  hintText: 'ABC-123-XYZ',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.tag),
                ),
              ),

              const SizedBox(height: 24),

              // Upload Area (Mock)
              Container(
                height: 150,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.grey[100],
                ),
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.cloud_upload, size: 48, color: Colors.grey),
                    SizedBox(height: 8),
                    Text('Upload Certificate (PDF/JPG)'),
                  ],
                ),
              ),

              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Uploading... System is analyzing trust score.',
                        ),
                        backgroundColor: _getCategoryColor(),
                      ),
                    );
                    // Add submission logic here
                  }
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.black, // CareerBridge branding
                  foregroundColor: Colors.white,
                ),
                child: const Text('Add to Profile'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Showcase your achievements',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        Text(
          'Our engine automatically verifies certificates to boost your profile trust score.',
          style: TextStyle(color: Colors.grey),
        ),
      ],
    );
  }

  Color _getCategoryColor() {
    switch (_detectedCategory) {
      case ProviderCategory.A:
        return Colors.green;
      case ProviderCategory.B:
        return Colors.blue;
      case ProviderCategory.C:
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }
}

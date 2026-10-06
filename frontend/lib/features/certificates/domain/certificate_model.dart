enum ValidationStatus {
  pending,
  verified,
  partiallyVerified,
  collegeVerified,
  unverified,
  rejected,
}

enum ProviderCategory {
  A, // Auto-Verifiable (Coursera, etc.)
  B, // Educational (Colleges)
  C, // Companies
  D, // Unknown
}

class Certificate {
  final String id;
  final String studentId;
  final String name;
  final String issuerName;
  final ProviderCategory category; // Derived from provider or logic
  final ValidationStatus status;
  final int trustLevel;
  final String? certificateId;
  final String? certificateUrl;
  final String? fileUrl;
  final DateTime? issueDate;
  final DateTime? expiryDate;
  final List<String> extractedSkills;

  Certificate({
    required this.id,
    required this.studentId,
    required this.name,
    required this.issuerName,
    this.category = ProviderCategory.D,
    this.status = ValidationStatus.unverified,
    this.trustLevel = 0,
    this.certificateId,
    this.certificateUrl,
    this.fileUrl,
    this.issueDate,
    this.expiryDate,
    this.extractedSkills = const [],
  });

  factory Certificate.fromJson(Map<String, dynamic> json) {
    return Certificate(
      id: json['id'] as String,
      studentId: json['student_id'] as String,
      name: json['certificate_name'] as String,
      issuerName:
          json['issuer_name_snapshot'] ?? json['provider_name'] ?? 'Unknown',
      category: _parseCategory(json['provider_category']),
      status: _parseStatus(json['validation_status']),
      trustLevel: json['trust_level'] ?? 0,
      certificateId: json['certificate_id'],
      certificateUrl: json['certificate_url'],
      fileUrl: json['certificate_file_url'],
      issueDate: json['issue_date'] != null
          ? DateTime.parse(json['issue_date'])
          : null,
      expiryDate: json['expiry_date'] != null
          ? DateTime.parse(json['expiry_date'])
          : null,
      extractedSkills:
          (json['extracted_skills'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
    );
  }

  static ProviderCategory _parseCategory(String? val) {
    switch (val) {
      case 'A':
        return ProviderCategory.A;
      case 'B':
        return ProviderCategory.B;
      case 'C':
        return ProviderCategory.C;
      default:
        return ProviderCategory.D;
    }
  }

  static ValidationStatus _parseStatus(String? val) {
    switch (val) {
      case 'verified':
        return ValidationStatus.verified;
      case 'partially_verified':
        return ValidationStatus.partiallyVerified;
      case 'college_verified':
        return ValidationStatus.collegeVerified;
      case 'pending':
        return ValidationStatus.pending;
      case 'rejected':
        return ValidationStatus.rejected;
      default:
        return ValidationStatus.unverified;
    }
  }
}

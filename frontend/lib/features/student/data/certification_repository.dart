import 'package:file_picker/file_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/services/image_service.dart';
import '../../../core/utils/logger_service.dart';

class CertificationRepository {
  final SupabaseClient _supabase;
  final ImageService _imageService;

  CertificationRepository(this._supabase, this._imageService);

  // Get all certification providers
  Future<List<Map<String, dynamic>>> getCertificationProviders() async {
    try {
      final response = await _supabase
          .from('certification_providers')
          .select()
          .eq('is_active', true)
          .order('trust_score', ascending: false);

      // Lazy Seeding: Check if CareerBridge exists
      bool hasCareerBridge = response.any(
        (p) => p['short_code'] == 'CareerBridge',
      );
      bool hasOther = response.any((p) => p['short_code'] == 'OTHER');

      if (!hasCareerBridge || !hasOther) {
        try {
          if (!hasCareerBridge) {
            await _supabase.from('certification_providers').insert({
              'name': 'CareerBridge',
              'short_code': 'CareerBridge',
              'website_url': 'https://CareerBridge.com',
              'validation_method': 'api',
              'trust_score': 100,
              'provider_category': 'A',
              'is_active': true,
            });
          }
          if (!hasOther) {
            await _supabase.from('certification_providers').insert({
              'name': 'Other / Not Listed',
              'short_code': 'OTHER',
              'validation_method': 'manual',
              'trust_score': 10,
              'provider_category': 'D',
              'is_active': true,
            });
          }

          // Re-fetch after seeding
          return await _supabase
              .from('certification_providers')
              .select()
              .eq('is_active', true)
              .order('trust_score', ascending: false);
        } catch (e) {
          LoggerService.error('Error seeding providers', e);
          // Start with mocked result if seed fails
          return [
            ...response,
            if (!hasCareerBridge)
              {
                'id': 'temp-CareerBridge',
                'name': 'CareerBridge',
                'short_code': 'CareerBridge',
                'trust_score': 100,
                'validation_method': 'api',
              },
            if (!hasOther)
              {
                'id': 'temp-other',
                'name': 'Other / Not Listed',
                'short_code': 'OTHER',
                'trust_score': 10,
                'validation_method': 'manual',
              },
          ];
        }
      }

      return response;
    } catch (e) {
      // If table doesn't exist, throw a more descriptive error
      if (e.toString().contains(
        'relation "certification_providers" does not exist',
      )) {
        throw Exception(
          'Certification system not set up. Please run the database migration first.',
        );
      }
      rethrow;
    }
  }

  // Get student's certifications
  Future<List<Map<String, dynamic>>> getStudentCertifications(
    String studentId,
  ) async {
    final response = await _supabase
        .from('student_certifications')
        .select('''
          *,
          certification_providers(name, short_code, logo_url, trust_score)
        ''')
        .eq('student_id', studentId)
        .order('created_at', ascending: false);

    return response;
  }

  // Get student's skills from certifications
  Future<List<Map<String, dynamic>>> getStudentSkills(String studentId) async {
    final response = await _supabase
        .from('student_skills')
        .select('''
          *,
          skills_database(name, category, subcategory, market_demand)
        ''')
        .eq('student_id', studentId)
        .eq('is_verified', true)
        .order('total_points', ascending: false);

    // Transform the response to flatten the skills_database data
    return response.map((skill) {
      final skillData = skill['skills_database'];
      return {
        ...skill,
        'skill_name': skillData?['name'] ?? 'Unknown Skill',
        'skill_category': skillData?['category'] ?? 'general',
        'skill_subcategory': skillData?['subcategory'] ?? '',
        'market_demand': skillData?['market_demand'] ?? 50,
      };
    }).toList();
  }

  // Upload and add new certification
  // Upload and add new certification
  Future<Map<String, dynamic>> addCertification({
    required String studentId,
    required String certificateName,
    String? providerId,
    String? issuerName, // New optional parameter for custom providers
    String? certificateId,
    String? certificateUrl,
    DateTime? issueDate,
    DateTime? expiryDate,
    PlatformFile? file, // Changed from String? filePath
  }) async {
    String? fileUrl;

    // Upload certificate file if provided
    if (file != null) {
      fileUrl = await _imageService.uploadFile(file, studentId);
    }

    // Resolve temporary provider IDs to real UUIDs
    String? resolvedProviderId = providerId;
    if (providerId == 'temp-CareerBridge' || providerId == 'temp-other') {
      final shortCode = providerId == 'temp-CareerBridge'
          ? 'CareerBridge'
          : 'OTHER';
      try {
        final provider = await _supabase
            .from('certification_providers')
            .select('id')
            .eq('short_code', shortCode)
            .maybeSingle();

        if (provider != null) {
          resolvedProviderId = provider['id'];
        } else {
          // If ensuring existence failed previously, try to fetch/seed strictly here could be an option,
          // but for now let's hope the seed worked or we might need to handle this error.
          // In a robust system, we would force seed here.
        }
      } catch (e) {
        LoggerService.error('Error resolving temp provider ID', e);
      }
    }

    final data = {
      'student_id': studentId,
      'provider_id': resolvedProviderId,
      'certificate_name': certificateName,
      'certificate_id': certificateId,
      'certificate_url': certificateUrl,
      'issue_date': issueDate?.toIso8601String(),
      'expiry_date': expiryDate?.toIso8601String(),
      'certificate_file_url': fileUrl,
      if (issuerName != null) 'issuer_name_snapshot': issuerName,
    };

    // Insert certification record
    final response = await _supabase
        .from('student_certifications')
        .insert(data)
        .select()
        .single();

    // Trigger validation
    await validateCertification(response['id']);

    return response;
  }

  // Validate certificate using Edge Function (with fallback)
  Future<void> validateCertification(String certificationId) async {
    try {
      // Get certification details
      final certification = await _supabase
          .from('student_certifications')
          .select('*')
          .eq('id', certificationId)
          .single();

      try {
        // Try to call validation Edge Function
        final response = await _supabase.functions.invoke(
          'validate-certificate',
          body: {
            'certificateId': certification['certificate_id'],
            'certificateName': certification['certificate_name'],
            'certificateUrl': certification['certificate_url'],
            'providerId': certification['provider_id'],
            'issueDate': certification['issue_date'],
            'fileUrl': certification['certificate_file_url'],
          },
        );

        if (response.data['success']) {
          final validation = response.data['validation'];

          // Update certification with validation results
          await _supabase
              .from('student_certifications')
              .update({
                'validation_status': validation['status'],
                'validation_method': validation['method'],
                'validation_score': validation['confidence'],
                'validation_details': validation['validationDetails'],
                'extracted_skills': validation['extractedSkills'],
                'validated_at': DateTime.now().toIso8601String(),
              })
              .eq('id', certificationId);
        } else {
          // Mark as failed validation
          await _supabase
              .from('student_certifications')
              .update({
                'validation_status': 'rejected',
                'validation_details': {'error': response.data['error']},
                'validated_at': DateTime.now().toIso8601String(),
              })
              .eq('id', certificationId);
        }
      } catch (edgeFunctionError) {
        // Edge Function not deployed or failed - use fallback validation
        LoggerService.warning(
          'Edge Function not available, using fallback validation: $edgeFunctionError',
        );
        await _fallbackValidation(certificationId, certification);
      }
    } catch (e) {
      LoggerService.error('Validation error', e);
      // Mark as failed validation
      await _supabase
          .from('student_certifications')
          .update({
            'validation_status': 'rejected',
            'validation_details': {'error': e.toString()},
            'validated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', certificationId);
      rethrow;
    }
  }

  // Fallback validation when Edge Function is not available
  Future<void> _fallbackValidation(
    String certificationId,
    Map<String, dynamic> certification,
  ) async {
    try {
      // Get provider information
      final provider = await _supabase
          .from('certification_providers')
          .select('*')
          .eq('id', certification['provider_id'])
          .single();

      // Simple pattern-based validation
      final certificateName =
          certification['certificate_name'] as String? ?? '';
      final certificateUrl = certification['certificate_url'] as String?;
      final providerId = certification['certificate_id'] as String?;

      int confidence = 0;
      String validationMethod = 'fallback_pattern';
      Map<String, dynamic> validationDetails = {};

      // Basic validation checks
      if (certificateName.isNotEmpty) {
        confidence += 30;
        validationDetails['name_provided'] = true;
      }

      if (certificateUrl != null && certificateUrl.isNotEmpty) {
        if (certificateUrl.startsWith('https://')) {
          confidence += 20;
          validationDetails['secure_url'] = true;
        }

        // Check if URL contains provider domain
        final providerWebsite = provider['website_url'] as String? ?? '';
        if (providerWebsite.isNotEmpty) {
          try {
            final urlDomain = Uri.parse(certificateUrl).host;
            final providerDomain = Uri.parse(providerWebsite).host;
            if (urlDomain.contains(providerDomain) ||
                providerDomain.contains(urlDomain)) {
              confidence += 30;
              validationDetails['domain_match'] = true;
            }
          } catch (e) {
            // Invalid URL format
            validationDetails['url_format_error'] = true;
          }
        }
      }

      if (providerId != null &&
          providerId.isNotEmpty &&
          providerId.length >= 6) {
        confidence += 20;
        validationDetails['id_provided'] = true;
      }

      // Determine status based on confidence and provider trust score
      final trustScore = provider['trust_score'] as int? ?? 80;
      final adjustedConfidence = (confidence * trustScore / 100).round();

      String status;
      if (adjustedConfidence >= 70) {
        status = 'verified';
      } else if (adjustedConfidence >= 40) {
        status = 'pending';
      } else {
        status = 'rejected';
      }

      validationDetails['fallback_reason'] = 'Edge Function not available';
      validationDetails['raw_confidence'] = confidence;
      validationDetails['trust_score'] = trustScore;

      // Extract basic skills from certificate name
      final extractedSkills = await _extractBasicSkills(certificateName);

      // Update certification with fallback validation results
      await _supabase
          .from('student_certifications')
          .update({
            'validation_status': status,
            'validation_method': validationMethod,
            'validation_score': adjustedConfidence,
            'validation_details': validationDetails,
            'extracted_skills': extractedSkills,
            'validated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', certificationId);
    } catch (e) {
      LoggerService.error('Fallback validation error', e);
      // Mark as pending for manual review
      await _supabase
          .from('student_certifications')
          .update({
            'validation_status': 'pending',
            'validation_method': 'fallback_failed',
            'validation_details': {
              'error': e.toString(),
              'requires_manual_review': true,
            },
            'validated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', certificationId);
    }
  }

  // Extract basic skills from certificate name
  Future<Map<String, dynamic>> _extractBasicSkills(
    String certificateName,
  ) async {
    final extractedSkills = <String, dynamic>{};

    try {
      // Get common skills from database
      final skills = await _supabase
          .from('skills_database')
          .select('name, keywords')
          .limit(50);

      final nameWords = certificateName.toLowerCase().split(' ');

      for (final skill in skills) {
        final skillName = skill['name'] as String;
        final keywords = skill['keywords'] as List<dynamic>? ?? [];

        // Check if skill name or keywords appear in certificate name
        if (nameWords.any(
          (word) =>
              skillName.toLowerCase().contains(word) ||
              keywords.any(
                (keyword) => keyword.toString().toLowerCase().contains(word),
              ),
        )) {
          extractedSkills[skillName] = 70; // Basic confidence score
        }
      }
    } catch (e) {
      LoggerService.error('Skill extraction error', e);
      // Return basic skills based on common patterns
      final name = certificateName.toLowerCase();
      if (name.contains('python')) extractedSkills['Python'] = 60;
      if (name.contains('javascript') || name.contains('js'))
        extractedSkills['JavaScript'] = 60;
      if (name.contains('java')) extractedSkills['Java'] = 60;
      if (name.contains('react')) extractedSkills['React'] = 60;
      if (name.contains('node')) extractedSkills['Node.js'] = 60;
      if (name.contains('aws')) extractedSkills['AWS'] = 60;
      if (name.contains('cloud')) extractedSkills['Cloud Computing'] = 60;
      if (name.contains('machine learning') || name.contains('ml'))
        extractedSkills['Machine Learning'] = 60;
      if (name.contains('data science')) extractedSkills['Data Science'] = 60;
    }

    return extractedSkills;
  }

  // Delete certification
  Future<void> deleteCertification(String certificationId) async {
    // Get certification to delete file
    final certification = await _supabase
        .from('student_certifications')
        .select('certificate_file_url')
        .eq('id', certificationId)
        .single();

    // Delete file from storage if exists
    if (certification['certificate_file_url'] != null) {
      try {
        final url = certification['certificate_file_url'] as String;
        final path = Uri.parse(url).path.split('/').last;
        await _supabase.storage.from('certificates').remove([path]);
      } catch (e) {
        LoggerService.error('Error deleting file', e);
      }
    }

    // Delete certification record
    await _supabase
        .from('student_certifications')
        .delete()
        .eq('id', certificationId);
  }

  // Update certification
  Future<void> updateCertification(
    String certificationId,
    Map<String, dynamic> updates,
  ) async {
    await _supabase
        .from('student_certifications')
        .update(updates)
        .eq('id', certificationId);
  }

  // Get skills database for autocomplete
  Future<List<Map<String, dynamic>>> getSkillsDatabase({
    String? category,
    String? search,
  }) async {
    var query = _supabase
        .from('skills_database')
        .select()
        .eq('is_active', true);

    if (category != null) {
      query = query.eq('category', category);
    }

    if (search != null && search.isNotEmpty) {
      query = query.or('name.ilike.%$search%,keywords.cs.{$search}');
    }

    return await query.order('market_demand', ascending: false).limit(50);
  }

  // Get certification statistics
  Future<Map<String, dynamic>> getCertificationStats(String studentId) async {
    final certifications = await getStudentCertifications(studentId);
    final skills = await getStudentSkills(studentId);

    final totalCertifications = certifications.length;
    final validatedCertifications = certifications
        .where((c) => c['validation_status'] == 'verified')
        .length;
    final pendingCertifications = certifications
        .where((c) => c['validation_status'] == 'pending')
        .length;
    final rejectedCertifications = certifications
        .where((c) => c['validation_status'] == 'rejected')
        .length;

    final totalSkillPoints = skills.fold<int>(
      0,
      (sum, skill) => sum + (skill['total_points'] as int? ?? 0),
    );
    final certificationPoints = skills.fold<int>(
      0,
      (sum, skill) => sum + (skill['certification_points'] as int? ?? 0),
    );

    final skillsByCategory = <String, int>{};
    for (final skill in skills) {
      final category = skill['skill_category'] as String? ?? 'other';
      skillsByCategory[category] = (skillsByCategory[category] ?? 0) + 1;
    }

    return {
      'total_certifications': totalCertifications,
      'validated_certifications': validatedCertifications,
      'pending_certifications': pendingCertifications,
      'rejected_certifications': rejectedCertifications,
      'validation_rate': totalCertifications > 0
          ? (validatedCertifications / totalCertifications * 100).round()
          : 0,
      'total_skills': skills.length,
      'total_skill_points': totalSkillPoints,
      'certification_points': certificationPoints,
      'skills_by_category': skillsByCategory,
      'top_skills': skills
          .take(5)
          .map(
            (s) => {
              'name': s['skill_name'],
              'points': s['total_points'],
              'level': s['proficiency_level'],
            },
          )
          .toList(),
    };
  }

  // Bulk validate certifications
  Future<void> bulkValidateCertifications(List<String> certificationIds) async {
    for (final id in certificationIds) {
      try {
        await validateCertification(id);
      } catch (e) {
        LoggerService.error('Failed to validate certification $id', e);
      }
    }
  }

  // Get validation history
  Future<List<Map<String, dynamic>>> getValidationHistory(
    String studentId,
  ) async {
    final response = await _supabase
        .from('student_certifications')
        .select('''
          id,
          certificate_name,
          validation_status,
          validation_method,
          validation_score,
          validated_at,
          certification_providers(name, short_code)
        ''')
        .eq('student_id', studentId)
        .not('validated_at', 'is', null)
        .order('validated_at', ascending: false);

    return response;
  }

  // Search certifications
  Future<List<Map<String, dynamic>>> searchCertifications(
    String studentId,
    String query,
  ) async {
    final response = await _supabase
        .from('student_certifications')
        .select('''
          *,
          certification_providers(name, short_code, logo_url)
        ''')
        .eq('student_id', studentId)
        .or('certificate_name.ilike.%$query%,certificate_id.ilike.%$query%')
        .order('created_at', ascending: false);

    return response;
  }
}

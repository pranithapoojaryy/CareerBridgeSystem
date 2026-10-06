import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../utils/logger_service.dart';

class ImageService {
  static final ImageService _instance = ImageService._internal();
  factory ImageService() => _instance;
  ImageService._internal();

  final ImagePicker _picker = ImagePicker();
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Pick image from gallery or camera
  Future<XFile?> pickImage({ImageSource source = ImageSource.gallery}) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );
      return image;
    } catch (e) {
      LoggerService.error('Error picking image', e);
      return null;
    }
  }

  /// Upload image to Supabase Storage and return the public URL
  Future<String?> uploadProfilePhoto(XFile imageFile, String userId) async {
    try {
      // Generate unique filename
      final String fileName =
          'profile_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final String filePath =
          '$userId/$fileName'; // Use userId as folder name for RLS

      Uint8List imageBytes;
      if (kIsWeb) {
        imageBytes = await imageFile.readAsBytes();
      } else {
        imageBytes = await File(imageFile.path).readAsBytes();
      }

      // Upload to Supabase Storage
      await _supabase.storage
          .from('profile_photos')
          .uploadBinary(filePath, imageBytes);

      // Get public URL
      final String publicUrl = _supabase.storage
          .from('profile_photos')
          .getPublicUrl(filePath);

      return publicUrl;
    } catch (e) {
      LoggerService.error('Error uploading profile photo', e);
      return null;
    }
  }

  /// Upload certificate file (PDF/Image) to Supabase Storage
  Future<String?> uploadFile(PlatformFile file, String folderPath) async {
    try {
      // Generate unique filename with original extension
      final ext = file.extension ?? 'jpg';
      final String fileName =
          'cert_${DateTime.now().millisecondsSinceEpoch}.$ext';
      final String storagePath = '$folderPath/$fileName';

      Uint8List fileBytes;
      if (kIsWeb) {
        if (file.bytes != null) {
          fileBytes = file.bytes!;
        } else {
          // Fallback if bytes missing on web (unexpected for FilePicker)
          return null;
        }
      } else {
        if (file.path != null) {
          fileBytes = await File(file.path!).readAsBytes();
        } else {
          return null;
        }
      }

      // Upload to Supabase Storage
      await _supabase.storage
          .from('certificates')
          .uploadBinary(
            storagePath,
            fileBytes,
            fileOptions: FileOptions(
              contentType: ext == 'pdf' ? 'application/pdf' : 'image/$ext',
              upsert: false,
            ),
          );

      // Get public URL
      final String publicUrl = _supabase.storage
          .from('certificates')
          .getPublicUrl(storagePath);

      return publicUrl;
    } catch (e) {
      LoggerService.error('Error uploading file', e);
      return null;
    }
  }

  /// RESTORED: Old method for backward compatibility if needed, though we should migrate users.
  /// Upload certificate file to Supabase Storage and return the public URL
  Future<String?> uploadCertificate(String filePath, String folderPath) async {
    try {
      // Generate unique filename
      final String fileName =
          'cert_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final String storagePath = '$folderPath/$fileName';

      Uint8List fileBytes;
      if (kIsWeb) {
        // For web, filePath would be the XFile path
        final XFile file = XFile(filePath);
        fileBytes = await file.readAsBytes();
      } else {
        fileBytes = await File(filePath).readAsBytes();
      }

      // Upload to Supabase Storage
      await _supabase.storage
          .from('certificates')
          .uploadBinary(storagePath, fileBytes);

      // Get public URL
      final String publicUrl = _supabase.storage
          .from('certificates')
          .getPublicUrl(storagePath);

      return publicUrl;
    } catch (e) {
      LoggerService.error('Error uploading certificate', e);
      return null;
    }
  }

  /// Update user profile with new profile photo URL
  Future<bool> updateProfilePhoto(String userId, String photoUrl) async {
    try {
      await _supabase
          .from('profiles')
          .update({'profile_photo_url': photoUrl})
          .eq('id', userId);

      return true;
    } catch (e) {
      LoggerService.error('Error updating profile photo', e);
      return false;
    }
  }

  /// Delete old profile photo from storage
  Future<void> deleteOldPhoto(String? oldPhotoUrl) async {
    if (oldPhotoUrl == null || oldPhotoUrl.isEmpty) return;

    try {
      // Extract file path from URL
      final uri = Uri.parse(oldPhotoUrl);
      final pathSegments = uri.pathSegments;

      // For profile_photos bucket, path should be: /storage/v1/object/public/profile_photos/userId/filename
      if (pathSegments.length >= 4 && pathSegments[3] == 'profile_photos') {
        final filePath = pathSegments.sublist(4).join('/'); // userId/filename
        await _supabase.storage.from('profile_photos').remove([filePath]);
      }
    } catch (e) {
      LoggerService.error('Error deleting old profile photo', e);
    }
  }

  /// Complete profile picture update process
  Future<String?> updateProfilePicture(
    String userId, {
    ImageSource source = ImageSource.gallery,
  }) async {
    try {
      // Pick image
      final XFile? imageFile = await pickImage(source: source);
      if (imageFile == null) return null;

      // Get current profile photo URL for cleanup
      final currentProfile = await _supabase
          .from('profiles')
          .select('profile_photo_url')
          .eq('id', userId)
          .single();

      final String? oldPhotoUrl = currentProfile['profile_photo_url'];

      // Upload new image
      final String? newPhotoUrl = await uploadProfilePhoto(imageFile, userId);
      if (newPhotoUrl == null) return null;

      // Update profile
      final bool success = await updateProfilePhoto(userId, newPhotoUrl);
      if (!success) return null;

      // Delete old photo
      if (oldPhotoUrl != null && oldPhotoUrl != newPhotoUrl) {
        deleteOldPhoto(oldPhotoUrl); // Don't await, run in background
      }

      return newPhotoUrl;
    } catch (e) {
      LoggerService.error('Error in complete profile picture update', e);
      return null;
    }
  }
}
